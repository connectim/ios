//
//  ScanQRCodePage.m
//  Xtalk
//
//  Created by MoHuilin on 16/2/23.
//  Copyright © 2016年 MoHuilin. All rights reserved.
//

#import "ScanQRCodePage.h"
#import <AVFoundation/AVFoundation.h>
#import "CaptureSessionManager.h"


static const CGFloat kBorderW = 100;
static const CGFloat kMargin = 30;

@interface ScanQRCodePage () <AVCaptureMetadataOutputObjectsDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property(nonatomic, strong) AVCaptureSession *session;
@property(nonatomic, strong) UIView *maskView;
@property(nonatomic, strong) UIView *scanWindow;
@property(nonatomic, strong) UIImageView *scanNetImageView;


@property(copy, nonatomic) CallBackWithScanValue callBack;
@end

@implementation ScanQRCodePage

- (instancetype)initWithCallBack:(CallBackWithScanValue)callBack {
    if (self = [super init]) {
        self.callBack = callBack;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [super viewWillAppear:animated];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBar.hidden = YES;
    [self resumeAnimation];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.hidden = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blueColor];


    if (![CaptureSessionManager isCanUseCrame]) {
        [UIAlertController showAlertInViewController:self withTitle:LMLocalizedString(@"Link Phone Setting allowing access camera", nil) message:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@[LMLocalizedString(@"Common OK", nil)] tapBlock:nil];
    }


    // This property must be opened or will appear when the black edge
    self.view.clipsToBounds = YES;
    //1.Cover
    [self setupMaskView];
    //4.top navigation
    [self setupNavView];
    //5.Top navigation
    [self setupScanWindowView];
    //6.begin animation
    [self beginScanning];


    //1.photo
    UIButton *albumBtn = [UIButton new];
    [albumBtn setTitle:LMLocalizedString(@"Login Select form album", nil) forState:UIControlStateNormal];
    [albumBtn setTitleColor:GJCFQuickHexColor(@"00C400") forState:UIControlStateNormal];
    [albumBtn addTarget:self action:@selector(myAlbum) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:albumBtn];

    [albumBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_bottom).offset(-AUTO_HEIGHT(90));
        make.centerX.equalTo(self.view);
    }];

    UILabel *tipLabel = [[UILabel alloc] init];
    tipLabel.numberOfLines = 0;
    tipLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:tipLabel];
    tipLabel.text = LMLocalizedString(@"Login Import your backup", nil);
    tipLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    tipLabel.textColor = [UIColor whiteColor];
    [tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_bottom).offset(-AUTO_HEIGHT(357));
        make.left.mas_equalTo(self.view).offset(10);
        make.right.mas_equalTo(self.view).offset(-10);

    }];


    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resumeAnimation) name:@"EnterForeground" object:nil];

}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}


- (void)setupNavView {


    // set navigation
    UIButton *backBtn = [UIButton new];
    [self.view addSubview:backBtn];
    [backBtn setImage:[UIImage imageNamed:@"back_white"] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(disMiss) forControlEvents:UIControlEventTouchUpInside];

    [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top).offset(AUTO_HEIGHT(75));
        make.left.equalTo(self.view.mas_left).offset(AUTO_WIDTH(32));
        make.size.mas_equalTo(CGSizeMake(22, 22));
    }];


    UILabel *titleLabel = [[UILabel alloc] init];
    [self.view addSubview:titleLabel];
    titleLabel.text = LMLocalizedString(@"Login Import private key", nil);
    titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(36)];
    titleLabel.textColor = [UIColor whiteColor];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(backBtn);
        make.centerX.equalTo(self.view);
    }];


}

- (void)setupMaskView {
    UIView *mask = [[UIView alloc] init];
    _maskView = mask;

    mask.layer.borderColor = [UIColor blackColor].CGColor;
    mask.layer.borderWidth = kBorderW;

    mask.bounds = CGRectMake(0, 0, self.view.width + kBorderW + kMargin, self.view.width + kBorderW + kMargin);
    mask.center = CGPointMake(self.view.width * 0.5, self.view.height * 0.5);
    mask.top = 0;
    [self.view addSubview:mask];

    UIView *mask2 = [UIView new];
    mask2.backgroundColor = [UIColor blackColor];
    [self.view addSubview:mask2];

    [mask2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.right.equalTo(self.view);
        make.top.equalTo(mask.mas_bottom);
    }];
}

- (void)setupScanWindowView {
    CGFloat scanWindowH = self.view.width - kMargin * 2;
    CGFloat scanWindowW = self.view.width - kMargin * 2;
    _scanWindow = [[UIView alloc] initWithFrame:CGRectMake(kMargin, kBorderW - 3, scanWindowW, scanWindowH)];
    _scanWindow.clipsToBounds = YES;
    [self.view addSubview:_scanWindow];

    _scanNetImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"scan_net"]];
    CGFloat buttonWH = 18;

    UIButton *topLeft = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, buttonWH, buttonWH)];
    topLeft.enabled = NO;
    [topLeft setImage:[UIImage imageNamed:@"scan_1"] forState:UIControlStateNormal];
    [_scanWindow addSubview:topLeft];

    UIButton *topRight = [[UIButton alloc] initWithFrame:CGRectMake(scanWindowW - buttonWH, 0, buttonWH, buttonWH)];
    topRight.enabled = NO;
    [topRight setImage:[UIImage imageNamed:@"scan_2"] forState:UIControlStateNormal];
    [_scanWindow addSubview:topRight];

    UIButton *bottomLeft = [[UIButton alloc] initWithFrame:CGRectMake(0, scanWindowH - buttonWH, buttonWH, buttonWH)];
    bottomLeft.enabled = NO;
    [bottomLeft setImage:[UIImage imageNamed:@"scan_3"] forState:UIControlStateNormal];
    [_scanWindow addSubview:bottomLeft];

    UIButton *bottomRight = [[UIButton alloc] initWithFrame:CGRectMake(topRight.left, bottomLeft.top, buttonWH, buttonWH)];
    bottomRight.enabled = NO;
    [bottomRight setImage:[UIImage imageNamed:@"scan_4"] forState:UIControlStateNormal];
    [_scanWindow addSubview:bottomRight];
}

- (void)beginScanning {
    // Get the camera device
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    // Create input stream
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    if (!input) return;
    // Create an output stream
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    // Set the proxy to refresh in the main thread
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    // Set the effective scan area
    CGRect scanCrop = [self getScanCrop:_scanWindow.bounds readerViewBounds:self.view.frame];
    output.rectOfInterest = scanCrop;
    // Initialize the link object
    _session = [[AVCaptureSession alloc] init];
    // High quality collection rate
    [_session setSessionPreset:AVCaptureSessionPresetHigh];

    [_session addInput:input];
    [_session addOutput:output];
    // Set the encoding format supported by the sweep code (set bar code and two-dimensional code as follows)
    output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];

    AVCaptureVideoPreviewLayer *layer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    layer.frame = self.view.layer.bounds;
    [self.view.layer insertSublayer:layer atIndex:0];
    // Start capturing
    [_session startRunning];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects.count > 0) {
        [_session stopRunning];
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects objectAtIndexCheck:0];
        [self callBackScanValue:metadataObject.stringValue];
    }
}

#pragma mark-> my photo

- (void)myAlbum {

    DDLogInfo(@"My album");
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        //1.Initialize the album pickup
        UIImagePickerController *controller = [[UIImagePickerController alloc] init];
        //2.Set up proxy
        controller.delegate = self;
        //3.Set the resources：
        controller.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        //4.Casually give him a transition animation
        [self presentViewController:controller animated:YES completion:NULL];
    } else {

        [UIAlertController showAlertInViewController:self withTitle:LMLocalizedString(@"Set tip title", nil) message:LMLocalizedString(@"Chat Allow Connect to access your album", nil) cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@[LMLocalizedString(@"Common OK", nil)] tapBlock:^(UIAlertController *_Nonnull controller, UIAlertAction *_Nonnull action, NSInteger buttonIndex) {

        }];
    }

}

#pragma mark-> imagePickerController delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    //1.Get the selected image
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    //2.Initialize a monitor
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
    [picker dismissViewControllerAnimated:YES completion:^{
        // The array of results is monitored
        NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
        if (features.count >= 1) {
            CIQRCodeFeature *feature = [features objectAtIndexCheck:0];
            NSString *scannedResult = feature.messageString;
            [self callBackScanValue:scannedResult];
        } else {
            [UIAlertController showAlertInViewController:self withTitle:LMLocalizedString(@"Set tip title", nil) message:LMLocalizedString(@"Login The qrCode can not be identified", nil) cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@[LMLocalizedString(@"Common OK", nil)] tapBlock:^(UIAlertController *_Nonnull controller, UIAlertAction *_Nonnull action, NSInteger buttonIndex) {

            }];
        }
    }];
}

#pragma mark -Callback scan result string

- (void)callBackScanValue:(NSString *)scannedResult {
    [self disMiss];
    self.callBack ? self.callBack(scannedResult) : nil;
}

#pragma mark-> flash

- (void)openFlash:(UIButton *)button {

    NSLog(@"Flash lamp");
    button.selected = !button.selected;
    if (button.selected) {
        [self turnTorchOn:YES];
    } else {
        [self turnTorchOn:NO];
    }

}

#pragma mark-> Switch flash

- (void)turnTorchOn:(BOOL)on {

    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

        if ([device hasTorch] && [device hasFlash]) {

            [device lockForConfiguration:nil];
            if (on) {
                [device setTorchMode:AVCaptureTorchModeOn];
                [device setFlashMode:AVCaptureFlashModeOn];

            } else {
                [device setTorchMode:AVCaptureTorchModeOff];
                [device setFlashMode:AVCaptureFlashModeOff];
            }
            [device unlockForConfiguration];
        }
    }
}


#pragma mark Restore animation

- (void)resumeAnimation {
    CAAnimation *anim = [_scanNetImageView.layer animationForKey:@"translationAnimation"];
    if (anim) {
        // 1. The time offset of the animation is used as the time point when the pause is made
        CFTimeInterval pauseTime = _scanNetImageView.layer.timeOffset;
        // 2. 根据媒体时间计算出准确的启动动画时间，对之前暂停动画的时间进行修正
        CFTimeInterval beginTime = CACurrentMediaTime() - pauseTime;

        // 3. According to the media time to calculate the exact start animation time, the time before the suspension of animation to amend
        [_scanNetImageView.layer setTimeOffset:0.0];
        // 4. Sets the start time of the layer
        [_scanNetImageView.layer setBeginTime:beginTime];

        [_scanNetImageView.layer setSpeed:1.0];

    } else {

        CGFloat scanNetImageViewH = 241;
        CGFloat scanWindowH = self.view.width - kMargin * 2;
        CGFloat scanNetImageViewW = _scanWindow.width;

        _scanNetImageView.frame = CGRectMake(0, -scanNetImageViewH, scanNetImageViewW, scanNetImageViewH);
        CABasicAnimation *scanNetAnimation = [CABasicAnimation animation];
        scanNetAnimation.keyPath = @"transform.translation.y";
        scanNetAnimation.byValue = @(scanWindowH);
        scanNetAnimation.duration = 1.0;
        scanNetAnimation.repeatCount = MAXFLOAT;
        [_scanNetImageView.layer addAnimation:scanNetAnimation forKey:@"translationAnimation"];
        [_scanWindow addSubview:_scanNetImageView];
    }


}

#pragma mark-> Get the scale of the scan area

- (CGRect)getScanCrop:(CGRect)rect readerViewBounds:(CGRect)readerViewBounds {

    CGFloat x, y, width, height;

    x = (CGRectGetHeight(readerViewBounds) - CGRectGetHeight(rect)) / 2 / CGRectGetHeight(readerViewBounds);
    y = (CGRectGetWidth(readerViewBounds) - CGRectGetWidth(rect)) / 2 / CGRectGetWidth(readerViewBounds);
    width = CGRectGetHeight(rect) / CGRectGetHeight(readerViewBounds);
    height = CGRectGetWidth(rect) / CGRectGetWidth(readerViewBounds);

    return CGRectMake(x, y, width, height);

}

#pragma mark-> 返回

- (void)disMiss {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
