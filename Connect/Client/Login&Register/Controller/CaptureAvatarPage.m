//
//  CaptureAvatarPage.m
//  Connect
//
//  Created by MoHuilin on 16/5/10.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "CaptureAvatarPage.h"
#import "CameraSessionView.h"

@interface CaptureAvatarPage () <CameraSessionViewDelegate>

@property(nonatomic, copy) NSString *mobile;
@property(nonatomic, strong) NSString *token;

@property(nonatomic, copy) NSString *prikey;

@end

@implementation CaptureAvatarPage

#pragma mark - life cricle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    [self.navigationController.navigationBar lt_setBackgroundColor:[UIColor clearColor]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar lt_reset];
}

- (instancetype)initWithPrivkey:(NSString *)prikey {
    if (self = [super init]) {
        self.prikey = prikey;
    }
    return self;

}

- (instancetype)initWithMobile:(NSString *)mobile token:(NSString *)token {
    if (self = [super init]) {
        self.mobile = mobile;
        self.token = token;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setNeedsStatusBarAppearanceUpdate];

    self.title = LMLocalizedString(@"Login Take Photo", nil);
}

- (void)setup {
    CameraSessionView *cameraView;
    cameraView = [[CameraSessionView alloc] initWithFrame:self.view.bounds];
    NSUInteger type = self.sourceType;
    cameraView.cameraSourceType = type;
    cameraView.viewController = self;
    [self.view addSubview:cameraView];
    cameraView.delegate = self;
}


- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - CameraSessionViewDelegate

- (void)didCaptureImage:(UIImage *)image originImage:(UIImage *)originImage {
    if (image && originImage) {
        if (self.sourceType == SourceTypeSet) {
            if (self.imageBlock) {
                self.imageBlock(image);
            }
        } else {
            if (self.token && self.mobile) {
                if (self.registImageBlock) {
                    self.registImageBlock(image, originImage);
                }
            } else {
                image = [self fixOrientation:image];
                if (self.registImageBlock) {
                    self.registImageBlock(image, originImage);
                }
            }
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
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
@end
