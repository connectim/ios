//
//  ScanAddPage.m
//  Connect
//
//  Created by MoHuilin on 16/5/22.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "ScanAddPage.h"
#import <AVFoundation/AVFoundation.h>
#import "BarCodeTool.h"
#import "TopImageBottomTitleButton.h"
#import "CaptureSessionManager.h"
#import "UIAlertController+Blocks.h"

#define scanViewWH (DEVICE_SIZE.width - 100)

#define animationDuration 0.2

@interface ScanAddPage () <AVCaptureMetadataOutputObjectsDelegate, UIGestureRecognizerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate> {
    MASConstraint *scanviewBotton;
}

@property(nonatomic, strong) UIView *scanView;

@property(nonatomic, strong) UIControl *myCodeView;
@property(nonatomic, strong) UIImageView *codeImageView;
@property(nonatomic, strong) UILabel *IDLabel;

@property(nonatomic, strong) AVCaptureSession *session;

@property(nonatomic, assign) BOOL isShowScanView;

@property(nonatomic, copy) ScanComplete complateBlock;

@property(nonatomic, assign) BOOL isCallBacked; //is call backed

@property(nonatomic, strong) TopImageBottomTitleButton *qrCodeButton;

@property(nonatomic, strong) UIImageView *tipUpArrowImageView; //tips view
@property(nonatomic, copy) NSString *resultString; //result string

@end

@implementation ScanAddPage

- (instancetype)initWithScanComplete:(ScanComplete)complete {
    if (self = [super init]) {
        self.complateBlock = complete;
    }
    return self;
}

- (void)loadView {
    [super loadView];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = XCColor(22, 26, 33);

    UILabel *titleLabel = [UILabel new];
    [self.view addSubview:titleLabel];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.view).offset(30);
    }];
    titleLabel.text = LMLocalizedString(@"Link Scan", nil);
    titleLabel.textColor = [UIColor whiteColor];

    UIButton *closeBtn = [UIButton new];
    [self.view addSubview:closeBtn];

    [closeBtn setImage:[UIImage imageNamed:@"close_white"] forState:UIControlStateNormal];
    [closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(AUTO_WIDTH(60), AUTO_WIDTH(60)));
        make.centerY.equalTo(titleLabel);
        make.right.equalTo(self.view).offset(-15);
    }];
    [closeBtn addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];


    UIButton *AlbumBtn = [UIButton new];
    [self.view addSubview:AlbumBtn];
    [AlbumBtn setTitle:LMLocalizedString(@"Chat Album", nil) forState:UIControlStateNormal];
    [AlbumBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [AlbumBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(titleLabel);
        make.left.equalTo(self.view).offset(15);
    }];
    [AlbumBtn addTarget:self action:@selector(openAlbum) forControlEvents:UIControlEventTouchUpInside];


    [self.view addSubview:self.scanView];
    _scanView.layer.cornerRadius = 15;
    _scanView.layer.masksToBounds = YES;

    if (self.showMyQrCode) {
        [_scanView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(scanViewWH, scanViewWH));
            make.bottom.equalTo(self.view.mas_top);
            make.centerX.equalTo(self.view);
        }];

        [self.view addSubview:self.myCodeView];
        _myCodeView.alpha = 0;
        [_myCodeView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.view);
            make.size.mas_equalTo(CGSizeMake(DEVICE_SIZE.width / 3, DEVICE_SIZE.width / 3 + 25));
            make.bottom.equalTo(self.view).offset(-60).priorityLow();
        }];

        [self.view addSubview:self.qrCodeButton];
        _qrCodeButton.alpha = 0;
        [_qrCodeButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.view);
            make.size.mas_equalTo(CGSizeMake(DEVICE_SIZE.width / 3 - 30, DEVICE_SIZE.width / 3 - 30));
            make.bottom.equalTo(self.view).offset(-80);
        }];

        [self.view addSubview:self.tipUpArrowImageView];
        [_tipUpArrowImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(AUTO_SIZE(35, 20));
            make.centerX.equalTo(self.view.mas_centerX);
            make.bottom.equalTo(_myCodeView.mas_top).offset(-14);
        }];

        [self.view layoutIfNeeded];

        self.isShowScanView = YES;

        [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            _myCodeView.alpha = 1;
            [_scanView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.size.mas_equalTo(CGSizeMake(scanViewWH, scanViewWH));
                make.top.equalTo(self.view.mas_top).offset(120);
                make.centerX.equalTo(self.view);

            }];

            [self.view layoutIfNeeded];
        }                completion:nil];
    } else {
        [_scanView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(scanViewWH, scanViewWH));
            make.top.equalTo(self.view.mas_top).offset(120);
            make.centerX.equalTo(self.view);
        }];
        [self.view layoutIfNeeded];
    }
    [self beginScanning];


    if (![CaptureSessionManager isCanUseCrame]) {
        [GCDQueue executeInMainQueue:^{
            [UIAlertController showAlertInViewController:self withTitle:LMLocalizedString(@"Link Phone Setting allowing access camera", nil) message:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@[LMLocalizedString(@"Common OK", nil)] tapBlock:nil];
        }             afterDelaySecs:.4f];
    }

}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects.count > 0) {
        [_session stopRunning];
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects objectAtIndexCheck:0];
        if (!self.isCallBacked) {
            self.resultString = metadataObject.stringValue;
            [self close];
        }
        self.isCallBacked = YES;
    }

}


#pragma mark - event

- (void)openAlbum {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        
        UIImagePickerController *controller = [[UIImagePickerController alloc] init];
        
        controller.delegate = self;
        
        /**
         UIImagePickerControllerSourceTypePhotoLibrary,相册
         UIImagePickerControllerSourceTypeCamera,相机
         UIImagePickerControllerSourceTypeSavedPhotosAlbum,照片库
         */
        controller.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        
        [self presentViewController:controller animated:YES completion:NULL];
    } else {
        if (!SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
            [UIAlertController showAlertInViewController:self withTitle:LMLocalizedString(@"Set tip title", nil) message:LMLocalizedString(@"The device does not support access to the album, please set in the privacy settings - > Privacy - > Photo！", nil) cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@[LMLocalizedString(@"Common OK", nil)] tapBlock:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action, NSInteger buttonIndex) {
                
            }];
        }
    }

}

#pragma mark-> imagePickerController delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];

    __weak __typeof(&*self) weakSelf = self;
    [picker dismissViewControllerAnimated:YES completion:^{
    
        NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
        if (features.count >= 1) {
    
            CIQRCodeFeature *feature = [features objectAtIndexCheck:0];
            weakSelf.resultString = feature.messageString;
            [weakSelf close];
        } else {
            [UIAlertController showAlertInViewController:self withTitle:LMLocalizedString(@"Set tip title", nil) message:LMLocalizedString(@"Wallet No qr code in the picture", nil) cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@[LMLocalizedString(@"Common OK", nil)] tapBlock:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action, NSInteger buttonIndex) {
                
            }];
        }
    }];
}

- (void)close {
    [UIView animateWithDuration:0.2f animations:^{
        self.view.alpha = 0;
    }                completion:^(BOOL finished) {
        [self dismissViewControllerAnimated:YES completion:^{
            if (self.resultString) {
                self.complateBlock ? self.complateBlock(self.resultString) : nil;
            }
        }];
    }];
}

- (void)beginScanning {
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    if (!input) return;
    
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    output.rectOfInterest = _scanView.bounds;
    
    _session = [[AVCaptureSession alloc] init];

    [_session setSessionPreset:AVCaptureSessionPresetHigh];

    [_session addInput:input];
    [_session addOutput:output];
    
    output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];

    AVCaptureVideoPreviewLayer *layer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    layer.frame = self.scanView.layer.bounds;
    [self.scanView.layer insertSublayer:layer atIndex:0];

    [_session startRunning];
}

- (void)showScanView {


    [_session startRunning];
    [_scanView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(scanViewWH, scanViewWH));
        make.top.equalTo(self.view.mas_top).offset(120);
        make.centerX.equalTo(self.view);
    }];

    CGFloat scaleMargin = 8;
    [_myCodeView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.size.mas_equalTo(CGSizeMake(DEVICE_SIZE.width / 3 - scaleMargin, DEVICE_SIZE.width / 3 + 40 - scaleMargin));
        make.bottom.equalTo(self.view).offset(-60 + scaleMargin).priorityLow();
    }];

    [_codeImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(_myCodeView).offset(10);
        make.right.equalTo(_myCodeView).offset(-10);
        make.height.equalTo(_codeImageView.mas_width);
    }];


    [_tipUpArrowImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(AUTO_SIZE(35, 20));
        make.centerX.equalTo(self.view.mas_centerX);
        make.bottom.equalTo(_myCodeView.mas_top).offset(-15);

    }];
    _tipUpArrowImageView.transform = CGAffineTransformMakeRotation(0);

    [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        _qrCodeButton.alpha = 0;
        [self.view layoutIfNeeded];
    }                completion:^(BOOL finished) {
        [_myCodeView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.view);
            make.size.mas_equalTo(CGSizeMake(DEVICE_SIZE.width / 3, DEVICE_SIZE.width / 3 + 40));
            make.bottom.equalTo(self.view).offset(-60).priorityLow();
        }];
        [UIView animateWithDuration:animationDuration / 2.f animations:^{

            [self.view layoutIfNeeded];
        }];
    }];
}

- (void)tapMycodeView {

    if (!_isShowScanView) {
        _isShowScanView = YES;
        _IDLabel.text = LMLocalizedString(@"Set My QR code", nil);
        _IDLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
        [self showScanView];
        return;
    }

    _isShowScanView = NO;
    _IDLabel.text = [[LKUserCenter shareCenter] currentLoginUser].address;
    _IDLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];

    [_session stopRunning];
    [_scanView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(scanViewWH, scanViewWH));
        make.bottom.equalTo(self.view.mas_top);
        make.centerX.equalTo(self.view);
    }];
    CGFloat scaleMargin = 15;
    [_myCodeView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(scanViewWH + scaleMargin, scanViewWH + scaleMargin));
        make.top.equalTo(self.view.mas_top).offset(120 - scaleMargin);
        make.centerX.equalTo(self.view);
    }];

    [_codeImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(_myCodeView.mas_width).multipliedBy(0.8);
        make.center.equalTo(_myCodeView);
    }];

    [_tipUpArrowImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(AUTO_SIZE(35, 20));
        make.centerX.equalTo(self.view.mas_centerX);
        make.top.equalTo(_myCodeView.mas_bottom).offset(15);
    }];
    _tipUpArrowImageView.transform = CGAffineTransformMakeRotation(M_PI);


    [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        [self.view layoutIfNeeded];

    }                completion:^(BOOL finished) {
        [_myCodeView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(scanViewWH, scanViewWH));
            make.top.equalTo(self.view.mas_top).offset(120);
            make.centerX.equalTo(self.view);
        }];

        [UIView animateWithDuration:animationDuration / 2.f animations:^{
            [self.view layoutIfNeeded];
            _qrCodeButton.alpha = 1;
        }];
    }];
}

- (void)swipeMycode:(UISwipeGestureRecognizer *)sender {
    [self tapMycodeView];
}


#pragma mark - getter setter

- (UIView *)scanView {
    if (!_scanView) {
        _scanView = [UIView new];
    }
    return _scanView;
}

- (UIControl *)myCodeView {
    if (!_myCodeView) {
        _myCodeView = [[UIControl alloc] init];
        _myCodeView.layer.cornerRadius = 5;
        _myCodeView.layer.masksToBounds = YES;
        _myCodeView.backgroundColor = XCColor(43, 254, 192);

        UISwipeGestureRecognizer *swipeGestuer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeMycode:)];
        swipeGestuer.direction = UISwipeGestureRecognizerDirectionUp | UISwipeGestureRecognizerDirectionDown;
        [_myCodeView addGestureRecognizer:swipeGestuer];

        [_myCodeView addTarget:self action:@selector(tapMycodeView) forControlEvents:UIControlEventTouchUpInside];

        _codeImageView = [UIImageView new];
        _codeImageView.image = [BarCodeTool barCodeImageWithString:[[LKUserCenter shareCenter] currentLoginUser].address withSize:200];
        [_myCodeView addSubview:_codeImageView];
        [_codeImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.equalTo(_myCodeView).offset(10);
            make.right.equalTo(_myCodeView).offset(-10);
            make.height.equalTo(_codeImageView.mas_width);
        }];

        _IDLabel = [UILabel new];
        _IDLabel.text = LMLocalizedString(@"Set My QR code", nil);
        _IDLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
        _IDLabel.textColor = [UIColor blackColor];
        [_myCodeView addSubview:_IDLabel];
        [_IDLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_codeImageView.mas_bottom);
            make.centerX.equalTo(_myCodeView);
            make.bottom.equalTo(_myCodeView);
        }];
    }
    return _myCodeView;
}

- (TopImageBottomTitleButton *)qrCodeButton {
    if (!_qrCodeButton) {
        _qrCodeButton = [TopImageBottomTitleButton new];
        [_qrCodeButton setImage:[UIImage imageNamed:@"add_friend_qrcode"] forState:UIControlStateNormal];
        [_qrCodeButton setTitle:LMLocalizedString(@"Link Scan", nil) forState:UIControlStateNormal];
        _qrCodeButton.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
        [_qrCodeButton addTarget:self action:@selector(tapMycodeView) forControlEvents:UIControlEventTouchUpInside];
    }
    return _qrCodeButton;
}

- (UIImageView *)tipUpArrowImageView {
    if (!_tipUpArrowImageView) {
        _tipUpArrowImageView = [[UIImageView alloc] init];
        _tipUpArrowImageView.image = [UIImage imageNamed:@"add_friend_qrtiparrow"];
    }

    return _tipUpArrowImageView;
}


@end
