//
//  LMPhotoViewController.m
//  MKCustomCamera
//
//  Created by bitmain on 2017/2/4.
//  Copyright © 2017年 MK. All rights reserved.
//

#import "LMPhotoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "LMProgressView.h"

#define  ScreenWidth [UIScreen mainScreen].bounds.size.width
#define  ScreenHeight [UIScreen mainScreen].bounds.size.height

#define  ShutLableScale 1.8
#define  ShutLableBeginBorderWidth 10
#define  ShutLableEndBorderWidth 25
#define  VideoMaxDuration 10

#define ProgressColor [UIColor greenColor]
//Exposure of small frame color
#define HaloColor [UIColor greenColor]

#define ButtonBgColor GJCFQuickRGBColorAlpha(22, 26, 33, 0.3)


@interface LMPhotoViewController () <AVCaptureFileOutputRecordingDelegate> {

    AVCaptureDevice *_videoDevice;
    AVCaptureDevice *_audioDevice;
    AVCaptureDeviceInput *_videoNewInput;
    AVCaptureDeviceInput *_audioInput;
    AVCaptureMovieFileOutput *_movieOutput;

    AVPlayer *_player;
    AVPlayerItem *_playItem;
    AVPlayerLayer *_playerLayer;
    BOOL _isPlaying;
}
@property(nonatomic, strong) AVCaptureSession *session;

@property(nonatomic, strong) AVCaptureDeviceInput *videoInput;
// Photo output stream object
@property(nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
// Preview the layer to show the camera
@property(nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property(nonatomic, strong) UIButton *toggleButton;
@property(nonatomic, strong) UIView *shutterLable;
@property(nonatomic, strong) UIButton *cancelButton;
@property(nonatomic, strong) UIButton *saveButton;
@property(nonatomic, strong) UIButton *resetButton;
@property(nonatomic, strong) UIView *cameraShowView;
@property(nonatomic, strong) UIImageView *imageShowView;
@property(assign, nonatomic) BOOL canSave;
@property(strong, nonatomic) LMProgressView *progressView;
@property(strong, nonatomic) CADisplayLink *link;
@property(assign, nonatomic) NSInteger currentCount;
@property(nonatomic, weak) UIView *focusCircle;
@property(strong, nonatomic) UILabel *tipLable;
@property(assign, nonatomic) BOOL isVideo;
@property(copy, nonatomic) NSURL *videoUrl;
@property(assign, nonatomic) BOOL isBack;


@end

@implementation LMPhotoViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    [self initCameraShowView];
    [self initImageShowView];
    [self initButton];
    [self initialSession];
    [self addTapGesterOnView];
    [self addTipLable];
    [self addBeginHalo];
}

/**
 * init
 */
- (void)addBeginHalo {
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CGPoint point = CGPointMake(ScreenWidth / 2.0, ScreenHeight / 2.0);
        CGPoint cameraPoint = [self.previewLayer captureDevicePointOfInterestForPoint:point];
        [self setFocusCursorAnimationWithPoint:point];

        [weakSelf changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {

            if ([captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                [captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            } else {
                DDLogInfo(@"Focus mode modification failed");
            }

            if ([captureDevice isFocusPointOfInterestSupported]) {
                [captureDevice setFocusPointOfInterest:cameraPoint];
            }

            //Exposure mode
            if ([captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
                [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
            } else {
                DDLogInfo(@"failed");
            }
            if ([captureDevice isExposurePointOfInterestSupported]) {
                [captureDevice setExposurePointOfInterest:cameraPoint];
            }

        }];
    });
}

- (void)addTipLable {
    self.tipLable = [[UILabel alloc] init];
    self.tipLable.frame = CGRectMake(10, (ScreenHeight - 20) - 2 * CommonButtonWidth - 50, ScreenWidth - 20, 20);
    self.tipLable.text = LMLocalizedString(@"Login Camera guide tip", nil);
    self.tipLable.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
    self.tipLable.textAlignment = NSTextAlignmentCenter;
    self.tipLable.numberOfLines = 0;
    self.tipLable.textColor = [UIColor whiteColor];
    [self.view addSubview:self.tipLable];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tipLable removeFromSuperview];
        self.tipLable = nil;
    });

}

- (void)addTapGesterOnView {
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleGes:)];
    [self.view addGestureRecognizer:singleTap];
}

- (void)singleGes:(UITapGestureRecognizer *)tapGesture {
    __weak typeof(self) weakSelf = self;
    CGPoint point = [tapGesture locationInView:self.view];

    CGPoint cameraPoint = [self.previewLayer captureDevicePointOfInterestForPoint:point];
    [self setFocusCursorAnimationWithPoint:point];

    [weakSelf changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {

        if ([captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            [captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        } else {
            DDLogError(@"failed");
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:cameraPoint];
        }

        if ([captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
            [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        } else {
            DDLogError(@"falied");
        }

        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:cameraPoint];
        }

    }];

}

- (void)setFocusCursorAnimationWithPoint:(CGPoint)point {
    self.focusCircle.center = point;
    self.focusCircle.transform = CGAffineTransformIdentity;
    self.focusCircle.alpha = 1.0;
    [UIView animateWithDuration:0.5 animations:^{
        self.focusCircle.transform = CGAffineTransformMakeScale(0.5, 0.5);
        self.focusCircle.alpha = 0.0;
    }];
}

- (UIView *)focusCircle {
    if (!_focusCircle) {
        UIView *focusCircle = [[UIView alloc] init];
        focusCircle.frame = CGRectMake(0, 0, 100, 100);
        focusCircle.layer.borderColor = HaloColor.CGColor;
        focusCircle.layer.borderWidth = 2;
        focusCircle.layer.masksToBounds = YES;
        _focusCircle = focusCircle;
        [self.view addSubview:focusCircle];
    }
    return _focusCircle;
}

- (void)changeDevicePropertySafety:(void (^)(AVCaptureDevice *captureDevice))propertyChange {
    AVCaptureDevice *captureDevice = [_videoInput device];
    NSError *error;
    BOOL lockAcquired = [captureDevice lockForConfiguration:&error];
    if (lockAcquired) {
        [self.session beginConfiguration];
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
        [self.session commitConfiguration];
    }
}

//session
- (void)initialSession {
    self.session = [[AVCaptureSession alloc] init];
    [self.session setSessionPreset:AVCaptureSessionPreset1920x1080];
    [self.session beginConfiguration];


    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backCamera] error:nil];
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    //AVVideoCodecJPEG
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];

    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }

    if ([self.session canAddOutput:self.stillImageOutput]) {
        [self.session addOutput:self.stillImageOutput];
    }

    [self addVideo];
    [self addAudio];
    [self setUpCameraLayer];
    [self.session commitConfiguration];

    [self.session startRunning];

}

- (void)initCameraShowView {
    self.cameraShowView = [[UIView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:self.cameraShowView];
}

- (void)initImageShowView {

    self.imageShowView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    self.imageShowView.contentMode = UIViewContentModeScaleToFill;
    self.imageShowView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.imageShowView];
}

#pragma mark - start/stop record

- (void)startRecordVideo {
    [self startVideoAnimation];
}

- (void)recordComplete {
    self.canSave = YES;
}

- (void)stopRecordVideo {
    [self stopVideoAnimation];
}

- (void)startRecord {
    [_movieOutput startRecordingToOutputFileURL:[self outPutFileURL] recordingDelegate:self];

}

- (void)stopRecord {
    [_movieOutput stopRecording];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.shutterLable removeFromSuperview];
        self.shutterLable = nil;
    });
    [self.progressView removeFromSuperview];
    self.progressView = nil;
    [self.cancelButton removeFromSuperview];
    self.cancelButton = nil;
    [self.toggleButton removeFromSuperview];
    self.toggleButton = nil;


}

- (NSURL *)outPutFileURL {
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"outPut.mov"]];
}

- (void)addMovieOutput:(BOOL)flag {
    _movieOutput = [[AVCaptureMovieFileOutput alloc] init];
    if ([self.session canAddOutput:_movieOutput]) {
        [self.session addOutput:_movieOutput];
        AVCaptureConnection *captureConnection = [_movieOutput connectionWithMediaType:AVMediaTypeVideo];
        //video revert
        if (flag == NO) {
            if ([captureConnection isVideoMirroringSupported]) {
                [captureConnection setVideoMirrored:YES];
            }
        }
        if ([captureConnection isVideoStabilizationSupported]) {
            captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
        captureConnection.videoScaleAndCropFactor = captureConnection.videoMaxScaleAndCropFactor;
    }
}

- (void)addVideoInput {
    NSError *videoError;
    _videoNewInput = [[AVCaptureDeviceInput alloc] initWithDevice:_videoDevice error:&videoError];
    if (!videoError) {
        if ([self.session canAddInput:_videoNewInput]) {
            [self.session addInput:_videoNewInput];
        }
    }
}

- (void)addVideo {
    /* MediaType
     AVF_EXPORT NSString *const AVMediaTypeVideo                 NS_AVAILABLE(10_7, 4_0);
     AVF_EXPORT NSString *const AVMediaTypeAudio                 NS_AVAILABLE(10_7, 4_0);
     AVF_EXPORT NSString *const AVMediaTypeText                  NS_AVAILABLE(10_7, 4_0);
     AVF_EXPORT NSString *const AVMediaTypeClosedCaption         NS_AVAILABLE(10_7, 4_0);
     AVF_EXPORT NSString *const AVMediaTypeSubtitle              NS_AVAILABLE(10_7, 4_0);
     AVF_EXPORT NSString *const AVMediaTypeTimecode              NS_AVAILABLE(10_7, 4_0);
     AVF_EXPORT NSString *const AVMediaTypeMetadata              NS_AVAILABLE(10_8, 6_0);
     AVF_EXPORT NSString *const AVMediaTypeMuxed                 NS_AVAILABLE(10_7, 4_0);
     */

    /* AVCaptureDevicePosition
     typedef NS_ENUM(NSInteger, AVCaptureDevicePosition) {
     AVCaptureDevicePositionUnspecified         = 0,
     AVCaptureDevicePositionBack                = 1,
     AVCaptureDevicePositionFront               = 2
     } NS_AVAILABLE(10_7, 4_0) __TVOS_PROHIBITED;
     */
    _videoDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
    self.isBack = YES;
    [self addVideoInput];
    [self addMovieOutput:self.isBack];
}

#pragma mark - video delete

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
    if (self.toggleButton != nil) {
        [self.toggleButton removeFromSuperview];
        self.toggleButton = nil;
    }
    if (self.cancelButton != nil) {
        [self.cancelButton removeFromSuperview];
        self.cancelButton = nil;
    }
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    if (outputFileURL.absoluteString.length == 0 && captureOutput.outputFileURL.absoluteString.length == 0) {
        return;
    }

    if (self.canSave) {
        [self playPlayer:outputFileURL];
        [self.view bringSubviewToFront:self.resetButton];
        [self.view bringSubviewToFront:self.saveButton];
        [self.view bringSubviewToFront:self.shutterLable];
        [self updateSaveButton];
        self.canSave = NO;
        self.videoUrl = outputFileURL;
    }
}

#pragma mark - video play

- (void)playPlayer:(NSURL *)videoUrl {
    [self create:videoUrl];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

- (void)create:(NSURL *)videoUrl {
    _playItem = [AVPlayerItem playerItemWithURL:videoUrl];
    _player = [AVPlayer playerWithPlayerItem:_playItem];
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    _playerLayer.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight);
    _playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;//视频填充模式
    [self.view.layer addSublayer:_playerLayer];
    [_player play];
}

- (void)playbackFinished:(NSNotification *)notification {
    [_player seekToTime:CMTimeMake(0, 1)];
    [_player play];
}

#pragma mark device type

- (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position {

    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = devices.firstObject;

    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            captureDevice = device;
            break;
        }
    }

    return captureDevice;
}

- (void)addProgressView {
    self.progressView = [[LMProgressView alloc] init];
    self.progressView.frame = CGRectMake((ScreenWidth - CommonButtonWidth * 2) / 2.0, ScreenHeight - CommonButtonWidth * 2.5, CommonButtonWidth * 2, CommonButtonWidth * 2);
    self.progressView.userInteractionEnabled = YES;
    self.progressView.backgroundColor = [UIColor clearColor];
    self.progressView.currentColor = ProgressColor;
    [self.view addSubview:self.progressView];
}

#pragma mark - progress

- (void)refresh:(CADisplayLink *)link {

    self.currentCount += 1;
    if (self.currentCount > VideoMaxDuration * 60) {
        [self stopRecordVideo];
    }

    self.progressView.progress = (double) (self.currentCount / (VideoMaxDuration * 60.0));
}

#pragma mark - timer

- (void)startLink {
    if (self.link) {
        self.link.paused = YES;
        [self.link invalidate];
        self.link = nil;
    }
    self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(refresh:)];
    [self.link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)stopLink {
    if (self.link) {
        [self.link invalidate];
        self.link = nil;
        self.currentCount = 0;
    }
}

- (void)startVideoAnimation {
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.2 animations:^{
        self.shutterLable.transform = CGAffineTransformMakeScale(ShutLableScale, ShutLableScale);
        self.shutterLable.layer.borderWidth = ShutLableEndBorderWidth;
    }                completion:^(BOOL finished) {
        if (finished) {
            [weakSelf startRecord];
            [weakSelf addProgressView];
            [weakSelf startLink];
            self.isVideo = YES;
        } else {
            [weakSelf shutterCamera];
        }
    }];
}

- (void)stopVideoAnimation {
    [self recordComplete];
    [self stopRecord];
    [self stopLink];
}

#pragma mark - audio

- (void)addAudio {
    NSError *audioError;

    _audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];

    _audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:_audioDevice error:&audioError];
    if (!audioError) {
        if ([self.session canAddInput:_audioInput]) {
            [self.session addInput:_audioInput];
        }
    }
}


#pragma mark - ui

- (void)initButton {

    self.toggleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.toggleButton.frame = CGRectMake((ScreenWidth - AUTO_HEIGHT(135) - 10), ScreenHeight - CommonButtonWidth - CommonButtonWidth, AUTO_HEIGHT(135), AUTO_HEIGHT(135));
    [self.toggleButton setImage:[UIImage imageNamed:@"switch_camera_button"] forState:UIControlStateNormal];
    [self.toggleButton addTarget:self action:@selector(toggleCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.toggleButton];

    self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.cancelButton.frame = CGRectMake(10, ScreenHeight - CommonButtonWidth - CommonButtonWidth, AUTO_HEIGHT(135), AUTO_HEIGHT(135));
    [self.cancelButton addTarget:self action:@selector(cancelAction) forControlEvents:UIControlEventTouchUpInside];
    [self.cancelButton setImage:[UIImage imageNamed:@"cancel_take_photo"] forState:UIControlStateNormal];
    [self.view addSubview:self.cancelButton];

    self.saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.saveButton.frame = CGRectMake((ScreenWidth - CommonButtonWidth) / 2.0, ScreenHeight - CommonButtonWidth - CommonButtonWidth, CommonButtonWidth, CommonButtonWidth);
    self.saveButton.layer.cornerRadius = CommonButtonWidth / 2.0;
    self.saveButton.layer.masksToBounds = YES;
    [self.saveButton setImage:[UIImage imageNamed:@"send_photo"] forState:UIControlStateNormal];
    [self.saveButton addTarget:self action:@selector(saveButtonAction) forControlEvents:UIControlEventTouchUpInside];
    self.saveButton.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.saveButton];

    self.resetButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.resetButton.frame = self.saveButton.frame;
    self.resetButton.layer.cornerRadius = CommonButtonWidth / 2.0;
    self.resetButton.layer.masksToBounds = YES;
    [self.resetButton addTarget:self action:@selector(resetButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.resetButton setImage:[UIImage imageNamed:@"retake_photo"] forState:UIControlStateNormal];
    self.resetButton.backgroundColor = ButtonBgColor;
    [self.view addSubview:self.resetButton];

    self.shutterLable = [[UIView alloc] init];
    self.shutterLable.frame = self.saveButton.frame;
    self.shutterLable.backgroundColor = [UIColor whiteColor];
    self.shutterLable.layer.cornerRadius = CommonButtonWidth / 2.0;
    self.shutterLable.layer.borderColor = ButtonBgColor.CGColor;
    self.shutterLable.layer.borderWidth = ShutLableBeginBorderWidth;
    self.shutterLable.layer.masksToBounds = YES;
    self.shutterLable.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGester = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(shutterCamera)];
    [self.shutterLable addGestureRecognizer:tapGester];
    UILongPressGestureRecognizer *longPressGester = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(shutterVideo:)];
    [self.shutterLable addGestureRecognizer:longPressGester];

    [self.view addSubview:self.shutterLable];
}

- (void)updateSaveButton {
    [self.toggleButton removeFromSuperview];
    self.toggleButton = nil;
    [self.cancelButton removeFromSuperview];
    self.cancelButton = nil;

    [UIView animateWithDuration:0.5 animations:^{

        self.saveButton.left = ScreenWidth - CommonButtonWidth - 50;

        self.resetButton.left = 50;
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.shutterLable removeFromSuperview];
        self.shutterLable = nil;
    });
}

#pragma mark  -AVCaptureDevice

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            return device;
        }
    }
    return nil;
}

- (AVCaptureDevice *)frontCamera {
    self.isBack = NO;
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

- (AVCaptureDevice *)backCamera {
    self.isBack = YES;
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].statusBarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].statusBarHidden = NO;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.session) {
        [self.session stopRunning];
    }
    if (_player != nil) {
        [_player.currentItem cancelPendingSeeks];
        [_player.currentItem.asset cancelLoading];
        _player = nil;
    }
    if (_playerLayer != nil) {
        [_playerLayer removeFromSuperlayer];
        _playerLayer = nil;
    }
}

- (void)setUpCameraLayer {
    if (self.previewLayer == nil) {
        self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        UIView *view = self.cameraShowView;
        CALayer *viewLayer = [view layer];
        [viewLayer setMasksToBounds:YES];

        CGRect bounds = [view bounds];
        [self.previewLayer setFrame:bounds];
        [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];

        [viewLayer addSublayer:self.previewLayer];
    }
}

#pragma mark - action

- (void)resetButtonAction {
    self.isVideo = NO;

    if (_player != nil) {
        [_player.currentItem cancelPendingSeeks];
        [_player.currentItem.asset cancelLoading];
        _player = nil;
    }
    if (_playerLayer != nil) {
        [_playerLayer removeFromSuperlayer];
        _playerLayer = nil;
    }
    self.imageShowView.image = nil;
    [self.saveButton removeFromSuperview];
    self.saveButton = nil;
    [self.resetButton removeFromSuperview];
    self.resetButton = nil;
    [self.cancelButton removeFromSuperview];
    self.cancelButton = nil;
    [self.toggleButton removeFromSuperview];
    self.toggleButton = nil;
    [self initButton];
    [self addTipLable];

}

- (void)saveButtonAction {
    __weak typeof(self) weakSelf = self;
    if (self.isVideo) {
        [self compressVideo];
    } else {
        if (self.savePhotoBlock) {
            self.savePhotoBlock(weakSelf.imageShowView.image, self.isBack);
        }
        [self savePhotoAbulm:self.imageShowView.image];
        [self dismissViewControllerAnimated:YES completion:nil];
        [self removeSomeThing];
    }
    self.isVideo = NO;
}

- (NSURL *)compressedURL {
    NSString *movie = [NSString stringWithFormat:@"%f.mp4", [[NSDate date] timeIntervalSince1970]];
    NSString *temVideoPath = GJCFAppCachePath(movie);
    return [NSURL fileURLWithPath:temVideoPath];

}

- (CGFloat)fileSize:(NSURL *)path {
    return [[NSData dataWithContentsOfURL:path] length] / 1024.00 / 1024.00;
}

- (void)compressVideo {
    __weak typeof(self) weakSelf = self;
    [GCDQueue executeInMainQueue:^{
        [MBProgressHUD showMessage:LMLocalizedString(@"Chat Compressing", nil) toView:weakSelf.view];
    }];
    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:self.videoUrl options:nil];
    NSArray *presets = [AVAssetExportSession exportPresetsCompatibleWithAsset:videoAsset];
    if ([presets containsObject:AVAssetExportPreset1920x1080]) {
        AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:videoAsset presetName:AVAssetExportPreset1920x1080];
        session.outputURL = [weakSelf compressedURL];
        session.shouldOptimizeForNetworkUse = YES;
        session.outputFileType = AVFileTypeMPEG4;
        [session exportAsynchronouslyWithCompletionHandler:^{
            if ([session status] == AVAssetExportSessionStatusCompleted) {
                [weakSelf saveVideo:session.outputURL];
            } else {
                [weakSelf saveVideo:session.outputURL];
            }
        }];
    }


}

- (void)saveVideo:(NSURL *)outputFileURL {
    __weak typeof(self) weakSelf = self;
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:outputFileURL
                                completionBlock:^(NSURL *assetURL, NSError *error) {
                                    if (error) {
                                        if (self.saveVideoBlock) {
                                            self.saveVideoBlock(weakSelf.videoUrl);
                                        }
                                    } else {
                                        if (self.saveVideoBlock) {
                                            self.saveVideoBlock(weakSelf.videoUrl);
                                        }
                                    }
                                }];
}

- (void)savePhotoAbulm:(UIImage *)image {
    image = [self fixOrientation:image];

    __block ALAssetsLibrary *lib = [[ALAssetsLibrary alloc] init];
    [lib writeImageToSavedPhotosAlbum:image.CGImage metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {

        DDLogInfo(@"assetURL = %@, error = %@", assetURL, error);
        lib = nil;
    }];

}

- (UIImage *)fixOrientation:(UIImage *)aImage {
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;

    CGAffineTransform transform = CGAffineTransformIdentity;

    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;

        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;

        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }

    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;

        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }

    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
            CGImageGetBitsPerComponent(aImage.CGImage), 0,
            CGImageGetColorSpace(aImage.CGImage),
            CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0, 0, aImage.size.height, aImage.size.width), aImage.CGImage);
            break;

        default:
            CGContextDrawImage(ctx, CGRectMake(0, 0, aImage.size.width, aImage.size.height), aImage.CGImage);
            break;
    }

    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

- (void)cancelAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)shutterVideo:(UILongPressGestureRecognizer *)longPressGes {
    if (longPressGes.state == UIGestureRecognizerStateBegan) {

        [self startRecordVideo];

    } else if (longPressGes.state == UIGestureRecognizerStateEnded) {
        [self stopRecordVideo];

    }
}

- (void)shutterCamera {
    __weak typeof(self) weakSelf = self;
    AVCaptureConnection *videoConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (!videoConnection) {
        return;
    }

    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {

        if (imageDataSampleBuffer == NULL) {
            return;
        }
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *image = [UIImage imageWithData:imageData];
        DDLogInfo(@"image size = %@", NSStringFromCGSize(image.size));
        if (self.isBack == NO) {
            image = [UIImage imageWithCGImage:[image CGImage] scale:1 orientation:UIImageOrientationLeftMirrored];
        }
        weakSelf.imageShowView.image = image;

        [weakSelf updateSaveButton];
    }];
}

- (void)toggleCamera {
    NSUInteger cameraCount = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
    if (cameraCount > 1) {
        NSError *error;
        AVCaptureDeviceInput *newVideoInput;
        AVCaptureDevicePosition position = [[self.videoInput device] position];

        if (position == AVCaptureDevicePositionBack) {
            newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontCamera] error:&error];
        } else if (position == AVCaptureDevicePositionFront) {
            newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backCamera] error:&error];
        } else {
            return;
        }

        if (newVideoInput != nil) {
            [self.session beginConfiguration];
            if (position == AVCaptureDevicePositionBack) { //bact to front
                [self.session setSessionPreset:AVCaptureSessionPresetHigh];
            }
            [self.session removeInput:self.videoInput];
            if ([self.session canAddInput:newVideoInput]) {
                [self.session addInput:newVideoInput];
                self.videoInput = newVideoInput;
            } else {
                [self.session addInput:self.videoInput];
            }
            [self.session removeOutput:_movieOutput];
            [self addMovieOutput:self.isBack];
            [self.session commitConfiguration];
        } else if (error) {
            DDLogInfo(@"toggle carema failed, error = %@", error);
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeSomeThing];
    [self stopLink];


}

- (void)removeSomeThing {
    if (_player != nil) {
        [_player.currentItem cancelPendingSeeks];
        [_player.currentItem.asset cancelLoading];
        _player = nil;
    }
    if (_playerLayer != nil) {
        [_playerLayer removeFromSuperlayer];
        _playerLayer = nil;
    }
    [self.imageShowView removeFromSuperview];
    self.imageShowView = nil;

    [self.cameraShowView removeFromSuperview];
    self.cameraShowView = nil;

    [self.saveButton removeFromSuperview];
    self.saveButton = nil;

    [self.resetButton removeFromSuperview];
    self.resetButton = nil;

    [self.cancelButton removeFromSuperview];
    self.cancelButton = nil;

    [self.toggleButton removeFromSuperview];
    self.toggleButton = nil;

    [self.shutterLable removeFromSuperview];
    self.shutterLable = nil;

    [self.progressView removeFromSuperview];
    self.progressView = nil;

    [self.focusCircle removeFromSuperview];
    self.focusCircle = nil;

    [self.tipLable removeFromSuperview];
    self.tipLable = nil;

    self.stillImageOutput = nil;

    self.videoUrl = nil;
    self.currentCount = 0;

    self.link = nil;

    self.savePhotoBlock = nil;
    self.saveVideoBlock = nil;
}
@end
