//
//  CaptureSessionManager.m
//  CameraWithAVFoundation
//
//  Created by Gabriel Alvarado on 4/16/14.
//  Copyright (c) 2014 Gabriel Alvarado. All rights reserved.
//

#import "CaptureSessionManager.h"
#import <ImageIO/ImageIO.h>

@implementation CaptureSessionManager

#pragma mark Capture Session Configuration

- (id)init {
    if ((self = [super init])) {
        [self setCaptureSession:[[AVCaptureSession alloc] init]];
        _captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    }
    return self;
}

- (void)addVideoPreviewLayer {
    [self setPreviewLayer:[[AVCaptureVideoPreviewLayer alloc] initWithSession:[self captureSession]]];
    [[self previewLayer] setVideoGravity:AVLayerVideoGravityResizeAspectFill];
}

- (void)initiateCaptureSessionForCamera:(CameraType)cameraType {
    
    //Iterate through devices and assign 'active camera' per parameter
    for (AVCaptureDevice *device in AVCaptureDevice.devices) if ([device hasMediaType:AVMediaTypeVideo]) {
        switch (cameraType) {
            case RearFacingCamera:  if ([device position] == AVCaptureDevicePositionBack)   _activeCamera = device; break;
            case FrontFacingCamera: if ([device position] == AVCaptureDevicePositionFront)  _activeCamera = device; break;
        }
    }
    
    NSError *error          = nil;
    BOOL deviceAvailability = YES;
    
    AVCaptureDeviceInput *cameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_activeCamera error:&error];
    if (!error && [[self captureSession] canAddInput:cameraDeviceInput]) [[self captureSession] addInput:cameraDeviceInput];
    else deviceAvailability = NO;
    
    //Report camera device availability
    if (self.delegate) [self.delegate cameraSessionManagerDidReportAvailability:deviceAvailability forCameraType:cameraType];
    
//    [self initiateStatisticsReportWithInterval:.125];
}

-(void)initiateStatisticsReportWithInterval:(CGFloat)interval {
    
    __block id blockSafeSelf = self;
    
    [[NSOperationQueue new] addOperationWithBlock:^{
        do {
            [NSThread sleepForTimeInterval:interval];
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (self.delegate) [self.delegate cameraSessionManagerDidReportDeviceStatistics:cameraStatisticsMake(_activeCamera.lensAperture, CMTimeGetSeconds(_activeCamera.exposureDuration), _activeCamera.ISO, _activeCamera.lensPosition)];
            }];
        } while (blockSafeSelf);
    }];
}

- (void)addStillImageOutput
{
    [self setStillImageOutput:[[AVCaptureStillImageOutput alloc] init]];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil];
    [[self stillImageOutput] setOutputSettings:outputSettings];
    
    [self getOrientationAdaptedCaptureConnection];
    
    [[self captureSession] addOutput:[self stillImageOutput]];
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
    {
        [device lockForConfiguration:nil];
        [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        [device unlockForConfiguration];
    }
}

- (void)captureStillImage:(BOOL)isFront
{
    AVCaptureConnection *videoConnection = [self getOrientationAdaptedCaptureConnection];
    
    if (videoConnection) {
        [[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:
         ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
             if (!error && imageSampleBuffer) {
                 NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
                 UIImage *image = [[UIImage alloc] initWithData:imageData];
                 if (isFront==NO) {
                  image = [UIImage imageWithCGImage:[image CGImage] scale:1.0 orientation:UIImageOrientationLeftMirrored];
                 }
                 [self setStillImage:image];
                 [self setStillImageData:imageData];
                 if ([self.delegate respondsToSelector:@selector(cameraSessionManagerDidCaptureImage)])
                     [self.delegate cameraSessionManagerDidCaptureImage];
             } else{
                 if ([self.delegate respondsToSelector:@selector(cameraSessionManagerFailedToCaptureImage)]) {
                     [self.delegate cameraSessionManagerFailedToCaptureImage];
                 }
             }
         }];
    }
    
    //Turn off the flash if on
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch])
    {
        [device lockForConfiguration:nil];
        [device setTorchMode:AVCaptureTorchModeOff];
        [device unlockForConfiguration];
    }
}

- (void)setEnableTorch:(BOOL)enableTorch
{
    _enableTorch = enableTorch;
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch] && [device hasFlash])
    {
        [device lockForConfiguration:nil];
        if (enableTorch) { [device setTorchMode:AVCaptureTorchModeOn]; }
        else { [device setTorchMode:AVCaptureTorchModeOff]; }
        [device unlockForConfiguration];
    }
}

#pragma mark - Helper Method(s)

- (void)assignVideoOrienationForVideoConnection:(AVCaptureConnection *)videoConnection
{
    AVCaptureVideoOrientation newOrientation;
    switch ([[UIDevice currentDevice] orientation]) {
        case UIDeviceOrientationPortrait:
            newOrientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            newOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIDeviceOrientationLandscapeLeft:
            newOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        case UIDeviceOrientationLandscapeRight:
            newOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        default:
            newOrientation = AVCaptureVideoOrientationPortrait;
    }
    [videoConnection setVideoOrientation: newOrientation];
}

- (AVCaptureConnection *)getOrientationAdaptedCaptureConnection
{
    AVCaptureConnection *videoConnection = nil;
    
    for (AVCaptureConnection *connection in [[self stillImageOutput] connections]) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
                [self assignVideoOrienationForVideoConnection:videoConnection];
                break;
            }
        }
        if (videoConnection) {
            [self assignVideoOrienationForVideoConnection:videoConnection];
            break;
        }
    }
    
    return videoConnection;
}

#pragma mark - Cleanup Functions

// stop the camera, otherwise it will lead to memory crashes
- (void)stop
{
    [self.captureSession stopRunning];
    
    if(self.captureSession.inputs.count > 0) {
        AVCaptureInput* input = [self.captureSession.inputs objectAtIndexCheck:0];
        [self.captureSession removeInput:input];
    }
    if(self.captureSession.outputs.count > 0) {
        AVCaptureVideoDataOutput* output = [self.captureSession.outputs objectAtIndexCheck:0];
        [self.captureSession removeOutput:output];
    }
    
}

- (void)dealloc {
    [self stop];
}

+ (BOOL)isCanUseCrame{
    
    
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusAuthorized || status == AVAuthorizationStatusNotDetermined) {
        return YES;
    }
    return NO;

}

@end
