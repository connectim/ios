//
//  ImageClipViewController.h
//  Connect
//
//  Created by MoHuilin on 16/8/13.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>

@class ImageClipViewController;

@protocol ImageClipViewControllerDelegate <NSObject>

- (void)imageCropper:(ImageClipViewController *)cropperViewController didFinished:(UIImage *)editedImage;

- (void)imageCropperDidCancel:(ImageClipViewController *)cropperViewController;

@end


@interface ImageClipViewController : UIViewController

@property(nonatomic, assign) NSInteger tag;
@property(nonatomic, assign) id <ImageClipViewControllerDelegate> delegate;
@property(nonatomic, assign) CGRect cropFrame;

- (id)initWithImage:(UIImage *)originalImage cropFrame:(CGRect)cropFrame limitScaleRatio:(NSInteger)limitRatio;


@end
