//
//  CameraSessionView.m
//  Connect
//
//  Created by MoHuilin on 16/5/10.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "CameraSessionView.h"
#import "CaptureSessionManager.h"

#import "FXBlurView.h"


@interface CameraSessionView () <CaptureSessionManagerDelegate, UIGestureRecognizerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    UIImageView *_imageView;
    UIImage *_image;
    FXBlurView *_overView;

    NSData *_imageData;

    UIButton *switchCameraBtn;

    UIButton *ablumBtn;
    UIButton *capturePhotoBtn;
    UIButton *flashBtn;

    //Variable vith the current camera being used (Rear/Front)
    CameraType cameraBeingUsed;

    UIImageView *focalReticule;

    CGAffineTransform temTransform;

    UIButton *recaptureBtn;


    UIView *viewLayer;
}

@property(nonatomic, strong) CaptureSessionManager *captureManager;
//The maximum magnification of the image
@property(nonatomic, assign) CGFloat scaleRation;
//Round the radius of the frame
@property(nonatomic, assign) CGFloat radius;
//Cut the frame of the frame
@property(nonatomic, assign) CGRect circularFrame;
@property(nonatomic, assign) CGRect OriginalFrame;
@property(nonatomic, assign) CGRect currentFrame;

@property(nonatomic, strong) UIButton *nextBtn;
@property(nonatomic, assign) BOOL isBehind;


@end

@implementation CameraSessionView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self captureAction];
    }

    return self;
}

- (instancetype)initWithPrikey:(NSString *)prikey withFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self captureAction];
    }
    return self;
}

- (void)captureAction {
    __weak __typeof(&*self) weakSelf = self;

    [UIView animateWithDuration:0.3 animations:^{
        recaptureBtn.top = DEVICE_SIZE.height;
        _nextBtn.top = DEVICE_SIZE.height;
    }                completion:^(BOOL finished) {
        for (UIView *sub in self.subviews) {
            [sub removeFromSuperview];
        }

        viewLayer = [[UIView alloc] init];
        [weakSelf addSubview:viewLayer];
        viewLayer.frame = CGRectMake(0, 64, DEVICE_SIZE.width, DEVICE_SIZE.height);
#if (TARGET_IPHONE_SIMULATOR)
#else
        [weakSelf setupCaptureManager:FrontFacingCamera];
        [[_captureManager captureSession] startRunning];
#endif
        [weakSelf loadSubView];
    }];
}

- (void)closeView {
    [self.viewController.navigationController popViewControllerAnimated:YES];
}

- (void)loadSubView; {

    for (UIView *sub in self.subviews) {
        [sub removeFromSuperview];
    }

    UIView *topView = [[UIView alloc] init];
    [self addSubview:topView];
    topView.backgroundColor = [UIColor blackColor];
    [topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self);
        make.height.mas_equalTo(64);
    }];
    if (self.cameraSourceType == CameraSourceTypeSet) {
        UIButton *rightButton = [[UIButton alloc] init];
        [rightButton setImage:[UIImage imageNamed:@"close_white"] forState:UIControlStateNormal];
        [rightButton addTarget:self action:@selector(rightButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [topView addSubview:rightButton];
        [rightButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self).offset(-25);
            make.top.mas_equalTo(self).offset(25);
        }];
        UILabel *titleLable = [[UILabel alloc] init];
        titleLable.text = LMLocalizedString(@"Login Take Photo", nil);
        titleLable.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
        titleLable.textColor = [UIColor whiteColor];
        [topView addSubview:titleLable];
        [titleLable mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self);
            make.top.mas_equalTo(self).offset(25);
        }];
    }
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *bottomView = [[UIVisualEffectView alloc] initWithEffect:blur];
    [self addSubview:bottomView];
    [bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.left.right.equalTo(self);
        make.top.equalTo(self.mas_top).offset(64 + DEVICE_SIZE.width);
    }];

    if ([CaptureSessionManager isCanUseCrame]) {
        if (!switchCameraBtn) {
            switchCameraBtn = [UIButton new];
        }
        [switchCameraBtn addTarget:self action:@selector(onTapSwitchCameraBtn) forControlEvents:UIControlEventTouchUpInside];
        [switchCameraBtn setImage:[UIImage imageNamed:@"switch_camera_button"] forState:UIControlStateNormal];
        [self addSubview:switchCameraBtn];

        [switchCameraBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.mas_bottom).offset(-AUTO_HEIGHT(155));
            make.right.equalTo(self).offset(-AUTO_WIDTH(60));
        }];

        if (!flashBtn) {
            flashBtn = [UIButton new];
            flashBtn.hidden = YES;
        }

        [self addSubview:flashBtn];
        [flashBtn setBackgroundImage:[UIImage imageNamed:@"record_flashlight_normal"] forState:UIControlStateNormal];
        [flashBtn setBackgroundImage:[UIImage imageNamed:@"record_flashlight_highlighted"] forState:UIControlStateSelected];
        [flashBtn addTarget:self action:@selector(openFlash:) forControlEvents:UIControlEventTouchUpInside];
        [flashBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(switchCameraBtn.mas_top).offset(-20);
            make.right.equalTo(self).offset(-20);
            make.size.mas_equalTo(CGSizeMake(35, 25));
        }];
        if (!ablumBtn) {
            ablumBtn = [UIButton new];
        }
        ablumBtn.contentEdgeInsets = UIEdgeInsetsMake(2, 2, 2, 2);
        [ablumBtn setImage:[UIImage imageNamed:@"Album"] forState:UIControlStateNormal];
        [self addSubview:ablumBtn];
        [ablumBtn addTarget:self action:@selector(openAlbum) forControlEvents:UIControlEventTouchUpInside];
        [ablumBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.mas_bottom).offset(-AUTO_HEIGHT(150));
            make.left.mas_equalTo(self.mas_left).offset(AUTO_WIDTH(60));
        }];


        if (!capturePhotoBtn) {
            capturePhotoBtn = [UIButton new];
        }
        [self addSubview:capturePhotoBtn];
        [capturePhotoBtn setBackgroundImage:[UIImage imageNamed:@"button_takephoto"] forState:UIControlStateNormal];
        [capturePhotoBtn addTarget:self action:@selector(tapCaptureBtn) forControlEvents:UIControlEventTouchUpInside];
        [capturePhotoBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self);
            make.bottom.equalTo(self).offset(-AUTO_HEIGHT(125));
            make.size.mas_equalTo(CGSizeMake(AUTO_WIDTH(135), AUTO_HEIGHT(135)));
        }];

        if (!focalReticule) {
            focalReticule = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"focal_reticule"]];
            focalReticule.frame = CGRectMake(0, 0, 60, 60);
        }
        [self addSubview:focalReticule];
        focalReticule.alpha = 0.0;
        focalReticule.hidden = NO;
        UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusGesture:)];
        if (singleTapGestureRecognizer) [viewLayer addGestureRecognizer:singleTapGestureRecognizer];

    } else {

        UILabel *tipLabel = [UILabel new];
        tipLabel.text = LMLocalizedString(@"Please on the IPhone \"Settings - Privacy - Camera\", allowing the Connect access to your mobile phone's camera", nil);
        [self addSubview:tipLabel];
        tipLabel.numberOfLines = 0;
        tipLabel.textAlignment = NSTextAlignmentCenter;
        [tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
            make.right.left.equalTo(self);
        }];
        if (!ablumBtn) {
            ablumBtn = [UIButton new];
        }
        ablumBtn.contentEdgeInsets = UIEdgeInsetsMake(2, 2, 2, 2);
        [ablumBtn setTitleColor:LMBasicGreen forState:UIControlStateNormal];
        [ablumBtn setTitle:LMLocalizedString(@"Chat Album", nil) forState:UIControlStateNormal];
        [self addSubview:ablumBtn];
        [ablumBtn addTarget:self action:@selector(openAlbum) forControlEvents:UIControlEventTouchUpInside];
        [ablumBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.mas_bottom).offset(-AUTO_HEIGHT(36));
            make.centerX.equalTo(self);
        }];
    }
}


#pragma mark -event

- (void)rightButtonAction {
    [self.viewController dismissViewControllerAnimated:YES completion:nil];

}

#pragma mark-> flash

- (void)openFlash:(UIButton *)button {

    NSLog(@"闪光灯");
    button.selected = !button.selected;
    if (button.selected) {
        [self turnTorchOn:YES];
    } else {
        [self turnTorchOn:NO];
    }

}

#pragma mark-> Switch flash

- (void)turnTorchOn:(BOOL)on {
    [_captureManager setEnableTorch:on];
}


- (void)openAlbum {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self.viewController presentViewController:imagePicker animated:YES completion:nil];
}

- (void)tapCaptureBtn {
    [_captureManager captureStillImage:self.isBehind];
}

- (void)onTapSwitchCameraBtn {
    if (cameraBeingUsed == RearFacingCamera) {
        [self setupCaptureManager:FrontFacingCamera];
        flashBtn.hidden = YES;
        self.isBehind = NO;
        [[_captureManager captureSession] startRunning];
    } else {
        [self setupCaptureManager:RearFacingCamera];
        flashBtn.hidden = NO;
        self.isBehind = YES;
        [[_captureManager captureSession] startRunning];
    }
    [self loadSubView];
}

- (void)focusGesture:(id)sender {

    if ([sender isKindOfClass:[UITapGestureRecognizer class]]) {
        UITapGestureRecognizer *tap = sender;
        if (tap.state == UIGestureRecognizerStateRecognized) {
            CGPoint location = [sender locationInView:self];
            [self focusAtPoint:location completionHandler:^{
                [self animateFocusReticuleToPoint:location];
            }];
        }
    }
}

- (void)animateFocusReticuleToPoint:(CGPoint)targetPoint {

    [focalReticule setCenter:targetPoint];
    [UIView animateWithDuration:0.4 animations:^{
        focalReticule.alpha = 1.0;
    }                completion:^(BOOL finished) {
        [UIView animateWithDuration:0.4 animations:^{
            focalReticule.alpha = 0.0;
        }                completion:nil];
    }];

    // Zoom animation
    CAKeyframeAnimation *theAnimation;
    theAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    theAnimation.duration = 0.4;
    theAnimation.removedOnCompletion = YES;
    theAnimation.values = @[@(1), @(1.4), @(1.1), @(1.3), @(1)].copy;
    [focalReticule.layer addAnimation:theAnimation forKey:@"animateTransform"];
    // center point
    [focalReticule.layer setAnchorPoint:CGPointMake(0.5, 0.5)];
}

- (void)focusAtPoint:(CGPoint)point completionHandler:(void (^)())completionHandler {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];;
    CGPoint pointOfInterest = CGPointZero;
    CGSize frameSize = self.bounds.size;
    pointOfInterest = CGPointMake(point.y / frameSize.height, 1.f - (point.x / frameSize.width));

    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {

        //Lock camera for configuration if possible
        NSError *error;
        if ([device lockForConfiguration:&error]) {

            if ([device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
                [device setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
            }

            if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                [device setFocusMode:AVCaptureFocusModeAutoFocus];
                [device setFocusPointOfInterest:pointOfInterest];
            }

            if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
                [device setExposurePointOfInterest:pointOfInterest];
                [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            }

            [device unlockForConfiguration];

            completionHandler();
        }
    } else {completionHandler();}
}

- (void)nextBtnClick {
    UIImage *clipImage = [self getSmallImage];
    clipImage = [self fixOrientation:clipImage];
    // clip image
    if ([self.delegate respondsToSelector:@selector(didCaptureImage:originImage:)]) {
        [self.delegate didCaptureImage:clipImage originImage:_image];
    }
}


#pragma mark - Setup

- (void)setupCaptureManager:(CameraType)camera {


    [_captureManager.previewLayer removeFromSuperlayer];
    cameraBeingUsed = camera;
    // remove existing input
    AVCaptureInput *currentCameraInput = [self.captureManager.captureSession.inputs objectAtIndexCheck:0];
    [self.captureManager.captureSession removeInput:currentCameraInput];

    _captureManager = nil;

    if ([CaptureSessionManager isCanUseCrame]) {

        _captureManager = [CaptureSessionManager new];
        [self.captureManager.captureSession beginConfiguration];

        if (_captureManager) {

            //Configure
            [_captureManager setDelegate:self];
            [_captureManager addStillImageOutput];
            [_captureManager addVideoPreviewLayer];
            [_captureManager initiateCaptureSessionForCamera:camera];
            [self.captureManager.captureSession commitConfiguration];

            _captureManager.previewLayer.frame = viewLayer.bounds;
            [viewLayer.layer addSublayer:_captureManager.previewLayer];

            //Apply animation effect to the camera's preview layer
            CATransition *applicationLoadViewIn = [CATransition animation];
            [applicationLoadViewIn setDuration:0.6];
            [applicationLoadViewIn setType:kCATransitionReveal];
            [applicationLoadViewIn setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
            [_captureManager.previewLayer addAnimation:applicationLoadViewIn forKey:kCATransitionReveal];

            //Add to self.view's layer
            [self.layer addSublayer:_captureManager.previewLayer];
        }
    } else {
        _captureManager = nil;
    }
}

- (void)setupClipView {
    UIButton *reCaptureBtn = [UIButton new];
    [self addSubview:reCaptureBtn];
    self.radius = DEVICE_SIZE.width / 2;
    self.scaleRation = 3;

    self.backgroundColor = [UIColor blackColor];
    [self CreatUI];
    [self addAllGesture];

}

- (void)addAllGesture {
    // pinGesture
    UIPinchGestureRecognizer *pinGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinGesture:)];
    [_imageView addGestureRecognizer:pinGesture];
    // panGesture
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [_imageView addGestureRecognizer:panGesture];
}

- (void)handlePinGesture:(UIPinchGestureRecognizer *)pinGesture {
    UIView *view = _imageView;
    if (pinGesture.state == UIGestureRecognizerStateBegan || pinGesture.state == UIGestureRecognizerStateChanged) {
        view.transform = CGAffineTransformScale(temTransform, pinGesture.scale, pinGesture.scale);
    } else if (pinGesture.state == UIGestureRecognizerStateEnded) {
        CGFloat ration = view.frame.size.width / self.OriginalFrame.size.width;

        if (ration > _scaleRation) {
            CGRect newFrame = CGRectMake(0, 0, self.OriginalFrame.size.width * _scaleRation, self.OriginalFrame.size.height * _scaleRation);
            view.frame = newFrame;

        } else if (view.frame.size.width < self.circularFrame.size.width && self.OriginalFrame.size.width <= self.OriginalFrame.size.height) {
            CGFloat rat = self.OriginalFrame.size.height / self.OriginalFrame.size.width;
            CGRect newFrame = CGRectMake(0, 0, self.circularFrame.size.width, self.circularFrame.size.height * rat);
            view.frame = newFrame;
        } else if (view.frame.size.height < self.circularFrame.size.height && self.OriginalFrame.size.height <= self.OriginalFrame.size.width) {
            CGFloat rat = self.OriginalFrame.size.width / self.OriginalFrame.size.height;
            CGRect newFrame = CGRectMake(0, 0, self.circularFrame.size.width * rat, self.circularFrame.size.height);
            view.frame = newFrame;
        }
        temTransform = view.transform;
        [view setCenter:self.center];
        self.currentFrame = view.frame;
    }
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)panGesture {
    UIView *view = _imageView;

    if (panGesture.state == UIGestureRecognizerStateBegan || panGesture.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [panGesture translationInView:view.superview];
        [view setCenter:CGPointMake(view.center.x + translation.x, view.center.y + translation.y)];

        [panGesture setTranslation:CGPointZero inView:view.superview];
    } else if (panGesture.state == UIGestureRecognizerStateEnded) {
        CGRect currentFrame = view.frame;
        // Swipe to the right and beyond the crop range
        if (currentFrame.origin.x >= self.circularFrame.origin.x) {
            currentFrame.origin.x = self.circularFrame.origin.x;

        }
        // Slide down and beyond the crop range
        if (currentFrame.origin.y >= self.circularFrame.origin.y) {
            currentFrame.origin.y = self.circularFrame.origin.y;
        }
        // Swipe left and beyond the crop range
        if (currentFrame.size.width + currentFrame.origin.x < self.circularFrame.origin.x + self.circularFrame.size.width) {
            CGFloat movedLeftX = fabs(currentFrame.size.width + currentFrame.origin.x - (self.circularFrame.origin.x + self.circularFrame.size.width));
            currentFrame.origin.x += movedLeftX;
        }
        // Swipe up and beyond the crop range
        if (currentFrame.size.height + currentFrame.origin.y < self.circularFrame.origin.y + self.circularFrame.size.height) {
            CGFloat moveUpY = fabs(currentFrame.size.height + currentFrame.origin.y - (self.circularFrame.origin.y + self.circularFrame.size.height));
            currentFrame.origin.y += moveUpY;
        }
        [UIView animateWithDuration:0.05 animations:^{
            [view setFrame:currentFrame];
        }];
    }
}

- (void)CreatUI {

    // Verify that the crop radius is valid
    self.radius = self.radius > self.width / 2 ? self.width / 2 : self.radius;

    CGFloat width = self.width;
    CGFloat height = (_image.size.height / _image.size.width) * width;

    _imageView = [[UIImageView alloc] init];
    _imageView.userInteractionEnabled = YES;
    [_imageView setImage:_image];
    temTransform = _imageView.transform;
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    [_imageView setFrame:CGRectMake(0, 0, width, height)];
    [_imageView setCenter:self.center];
    self.OriginalFrame = _imageView.frame;
    [self addSubview:_imageView];


    [self drawClipPath];
    [self MakeImageViewFrameAdaptClipFrame];

    CGFloat buttonW = AUTO_WIDTH(135);
    self.nextBtn = [UIButton new];
    [self addSubview:_nextBtn];
    [_nextBtn setImage:[UIImage imageNamed:@"send_photo"] forState:UIControlStateNormal];
    _nextBtn.backgroundColor = [UIColor whiteColor];
    _nextBtn.layer.cornerRadius = buttonW / 2.0;
    _nextBtn.layer.masksToBounds = YES;
    [_nextBtn addTarget:self action:@selector(nextBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [_nextBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self).offset(-AUTO_HEIGHT(150));
        make.right.mas_equalTo(self.mas_right).offset(-AUTO_WIDTH(60));
        make.width.mas_equalTo(buttonW);
        make.height.mas_equalTo(buttonW);
    }];


    recaptureBtn = [UIButton new];
    [self addSubview:recaptureBtn];
    recaptureBtn.titleLabel.textColor = [UIColor whiteColor];
    [recaptureBtn setImage:[UIImage imageNamed:@"retake_photo"] forState:UIControlStateNormal];
    [recaptureBtn addTarget:self action:@selector(captureAction) forControlEvents:UIControlEventTouchUpInside];
    recaptureBtn.backgroundColor = GJCFQuickRGBColorAlpha(255, 255, 255, 0.3);
    recaptureBtn.layer.cornerRadius = buttonW / 2.0;
    recaptureBtn.layer.masksToBounds = YES;
    [recaptureBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.nextBtn);
        make.left.equalTo(self).offset(AUTO_WIDTH(60));
        make.width.mas_equalTo(buttonW);
        make.height.mas_equalTo(buttonW);
    }];
}

- (NSAttributedString *)setSepTitle:(NSString *)titleString withColor:(UIColor *)color withFont:(UIFont *)font {
    NSString *interceptionString = nil;
    NSString *lastString = nil;
    if ([titleString hasPrefix:@"N"]) {  // The description is in English
        interceptionString = [titleString substringToIndex:4];
        lastString = [titleString substringFromIndex:4];
    } else                                // The description is in chinese
    {
        interceptionString = [titleString substringToIndex:3];
        lastString = [titleString substringFromIndex:3];
    }
    NSDictionary *dic = @{
            NSForegroundColorAttributeName: color,
            NSFontAttributeName: font
    };
    NSDictionary *lastDic = @{
            NSForegroundColorAttributeName: [UIColor whiteColor],
            NSFontAttributeName: [UIFont systemFontOfSize:FONT_SIZE(25)]
    };
    NSMutableAttributedString *interceptionMutableStr = [[NSMutableAttributedString alloc] initWithString:interceptionString attributes:dic];
    NSMutableAttributedString *lastMutableString = [[NSMutableAttributedString alloc] initWithString:lastString attributes:lastDic];
    [interceptionMutableStr appendAttributedString:lastMutableString];
    return [interceptionMutableStr copy];
}

#pragma mark - clip

/**
 *  square clip
 */
- (UIImage *)getSmallImage {
    CGFloat width = _imageView.frame.size.width;
    CGFloat rationScale = (width / _image.size.width);

    CGFloat origX = (self.circularFrame.origin.x - _imageView.frame.origin.x) / rationScale;
    CGFloat origY = (self.circularFrame.origin.y - _imageView.frame.origin.y) / rationScale;
    CGFloat oriWidth = self.circularFrame.size.width / rationScale;
    CGFloat oriHeight = self.circularFrame.size.height / rationScale;

    CGRect myRect = CGRectMake(origX, origY, oriWidth, oriHeight);
    CGImageRef imageRef = CGImageCreateWithImageInRect(_image.CGImage, myRect);
    UIGraphicsBeginImageContext(myRect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, myRect, imageRef);
    UIImage *clipImage = [UIImage imageWithCGImage:imageRef];
    UIGraphicsEndImageContext();
    return clipImage;
}

/**
 *  Circular clip
 */
- (UIImage *)CircularClipImage:(UIImage *)image {
    CGFloat arcCenterX = image.size.width / 2;
    CGFloat arcCenterY = image.size.height / 2;

    UIGraphicsBeginImageContext(image.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextBeginPath(context);
    CGContextAddArc(context, arcCenterX, arcCenterY, image.size.width / 2, 0.0, 2 * M_PI, NO);
    CGContextClip(context);
    CGRect myRect = CGRectMake(0, 0, image.size.width, image.size.height);
    [image drawInRect:myRect];

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

/**
 * drawClipPath
 */
- (void)drawClipPath {
    CGFloat ScreenWidth = [UIScreen mainScreen].bounds.size.width;
    CGPoint center = self.center;
    self.circularFrame = CGRectMake(center.x - self.radius, 64, self.radius * 2, self.radius * 2);

    UIControl *topBlurView = [[UIControl alloc] init];
    topBlurView.backgroundColor = [UIColor blackColor];
    topBlurView.frame = CGRectMake(0, 0, ScreenWidth, 64);
    [self addSubview:topBlurView];

    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *bottomBlurView = [[UIVisualEffectView alloc] initWithEffect:blur];
    bottomBlurView.frame = CGRectMake(0, _circularFrame.origin.y + _circularFrame.size.height, ScreenWidth, DEVICE_SIZE.height - _circularFrame.origin.y + _circularFrame.size.height);
    [self addSubview:bottomBlurView];

}

/**
 *  Let the picture itself fit the size of the crop frame
 */
- (void)MakeImageViewFrameAdaptClipFrame {
    CGFloat width = _imageView.frame.size.width;
    CGFloat height = _imageView.frame.size.height;
    if (height < self.circularFrame.size.height) {
        width = (width / height) * self.circularFrame.size.height;
        height = self.circularFrame.size.height;
        CGRect frame = CGRectMake(0, 0, width, height);
        [_imageView setFrame:frame];
        [_imageView setCenter:self.center];
    }
}

- (UIImage *)fixOrientation:(UIImage *)image {
    if (image.imageOrientation == UIImageOrientationUp)
        return image;

    CGAffineTransform transform = CGAffineTransformIdentity;

    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;

        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;

        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }

    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;

        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }

    CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
            CGImageGetBitsPerComponent(image.CGImage), 0,
            CGImageGetColorSpace(image.CGImage),
            CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0, 0, image.size.height, image.size.width), image.CGImage);
            break;

        default:
            CGContextDrawImage(ctx, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
            break;
    }
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

#pragma mark - get photo method action

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)info {
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:@"public.image"]) {
        _image = info[UIImagePickerControllerOriginalImage];
        _image = [self fixOrientation:_image];
        [[_captureManager captureSession] stopRunning];
        __weak __typeof(&*self) weakSelf = self;
        [UIView animateWithDuration:0.3 animations:^{
            switchCameraBtn.top = DEVICE_SIZE.height;
            capturePhotoBtn.top = DEVICE_SIZE.height;
            ablumBtn.top = DEVICE_SIZE.height;
        }                completion:^(BOOL finished) {
            for (UIView *sub in self.subviews) {
                [sub removeFromSuperview];
            }
            [_captureManager.previewLayer removeFromSuperlayer];
            [weakSelf setupClipView];
        }];
    }

    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Camera Session Manager Delegate Methods

- (void)cameraSessionManagerDidCaptureImage {

    UIImage *captureImage = [[self captureManager] stillImage];
    _imageData = [[self captureManager] stillImageData];
    _image = [self fixOrientation:captureImage];
    [[_captureManager captureSession] stopRunning];
    __weak __typeof(&*self) weakSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
        switchCameraBtn.top = DEVICE_SIZE.height;
        capturePhotoBtn.top = DEVICE_SIZE.height;
        ablumBtn.top = DEVICE_SIZE.height;
    }                completion:^(BOOL finished) {
        for (UIView *sub in self.subviews) {
            [sub removeFromSuperview];
        }
        [_captureManager.previewLayer removeFromSuperlayer];
        [weakSelf setupClipView];
    }];
}

- (void)cameraSessionManagerFailedToCaptureImage {
}

- (void)cameraSessionManagerDidReportAvailability:(BOOL)deviceAvailability forCameraType:(CameraType)cameraType {

}

- (void)cameraSessionManagerDidReportDeviceStatistics:(CameraStatistics)deviceStatistics {
}
@end
