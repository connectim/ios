//
//  CameraSessionView.h
//  Connect
//
//  Created by MoHuilin on 16/5/10.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseView.h"

typedef NS_ENUM(NSUInteger, CameraSourceType) {
    CameraSourceTypeLogin = 1 << 0,
    CameraSourceTypeSet = 1 << 1
};

@protocol CameraSessionViewDelegate <NSObject>
@optional
- (void)didCaptureImage:(UIImage *)image originImage:(UIImage *)originImage;

- (void)didCaptureImage:(UIImage *)image;


@end

@interface CameraSessionView : BaseView

//Delegate Property
@property(nonatomic, weak) id <CameraSessionViewDelegate> delegate;

@property(assign, nonatomic) CameraSourceType cameraSourceType;

@property(nonatomic, weak) UIViewController *viewController;

// next
- (void)nextBtnClick;

// back Action
- (void)captureAction;


@end
