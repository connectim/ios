//
//  UUAVAudioPlayer.m
//  BloodSugarForDoc
//
//  Created by shake on 14-9-1.
//  Copyright (c) 2014年 shake. All rights reserved.
//

#import "UUImageAvatarBrowser.h"

static UIImageView *orginImageView;
static UIImageView *newImageView;
static CGRect latestFrame;
static CGRect oldFrame;
static CGRect largeFrame;
@implementation UUImageAvatarBrowser

+(void)showImage:(UIImageView *)avatarImageView{
    UIImage *image=avatarImageView.image;
    oldFrame = CGRectMake(0,([UIScreen mainScreen].bounds.size.height-image.size.height*[UIScreen mainScreen].bounds.size.width/image.size.width)/2, [UIScreen mainScreen].bounds.size.width, image.size.height*[UIScreen mainScreen].bounds.size.width/image.size.width);
    latestFrame = oldFrame;
    largeFrame = CGRectMake(0, 0, 3 * oldFrame.size.width, 3 * oldFrame.size.height);

    
    orginImageView = avatarImageView;
    orginImageView.alpha = 0;
    UIWindow *window=[UIApplication sharedApplication].keyWindow;
    UIView *backgroundView=[[UIView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    CGRect oldframe=[avatarImageView convertRect:avatarImageView.bounds toView:window];
    backgroundView.backgroundColor=[UIColor blackColor];
    backgroundView.alpha=1;
    UIImageView *imageView=[[UIImageView alloc]initWithFrame:oldframe];
    newImageView = imageView;
    newImageView.userInteractionEnabled = YES;
    imageView.image=image;
    imageView.tag=1;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    [backgroundView addSubview:imageView];
    [window addSubview:backgroundView];
    UITapGestureRecognizer *tap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideImage:)];
    [backgroundView addGestureRecognizer: tap];

    
    [self addGestureRecognizers];
    
    [UIView animateWithDuration:0.3 animations:^{
        imageView.frame=oldFrame;
        backgroundView.alpha=1;
    } completion:^(BOOL finished) {
        
    }];
}

// register all gestures
+ (void) addGestureRecognizers
{
    // add pan gesture
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panView:)];
    [newImageView addGestureRecognizer:panGestureRecognizer];
    // add pinch gesture
    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchView:)];
    [newImageView addGestureRecognizer:pinchGestureRecognizer];
}

// pinch gesture handler
+ (void) pinchView:(UIPinchGestureRecognizer *)pinchGestureRecognizer
{
    
    if (pinchGestureRecognizer.state == UIGestureRecognizerStateBegan || pinchGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        newImageView.transform = CGAffineTransformScale(newImageView.transform, pinchGestureRecognizer.scale, pinchGestureRecognizer.scale);
        pinchGestureRecognizer.scale = 1;
    }
    else if (pinchGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        CGRect newFrame = newImageView.frame;
        newFrame = [self handleScaleOverflow:newFrame];
        newFrame = [self handleBorderOverflow:newFrame];
        [UIView animateWithDuration:0.3 animations:^{
            newImageView.frame = newFrame;
            latestFrame = newFrame;
        }];
    }
}

// pan gesture handler
+ (void) panView:(UIPanGestureRecognizer *)panGestureRecognizer
{
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan || panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        // calculate accelerator
        CGFloat scaleRatio = newImageView.frame.size.width / DEVICE_SIZE.width;
        CGFloat acceleratorX = 1 - ABS(DEVICE_SIZE.width/2 - newImageView.center.x) / (scaleRatio * DEVICE_SIZE.width/2);
        CGFloat acceleratorY = 1 - ABS(DEVICE_SIZE.height/2 - newImageView.center.y) / (scaleRatio * DEVICE_SIZE.height/2);
        CGPoint translation = [panGestureRecognizer translationInView:newImageView.superview];
        [newImageView setCenter:(CGPoint){newImageView.center.x + translation.x * acceleratorX, newImageView.center.y + translation.y * acceleratorY}];
        [panGestureRecognizer setTranslation:CGPointZero inView:newImageView.superview];
    }
    else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        // bounce to original frame
        CGRect newFrame = newImageView.frame;
        
        newFrame = [self handleBorderOverflow:newFrame];
        
        [UIView animateWithDuration:0.3 animations:^{
            newImageView.frame = newFrame;
            latestFrame = newFrame;
        }];
    }
}

+ (CGRect)handleBorderOverflow:(CGRect)newFrame {
//    // horizontally
    if (newFrame.origin.x < 0) newFrame.origin.x = 0;
    if (CGRectGetMaxX(newFrame) > DEVICE_SIZE.width) newFrame.origin.x = DEVICE_SIZE.width - newFrame.size.width;
    // vertically
    if (newFrame.origin.y < 0) newFrame.origin.y = 0;
    if (CGRectGetMaxY(newFrame) > DEVICE_SIZE.height) {
        newFrame.origin.y = DEVICE_SIZE.height - newFrame.size.height;
    }
    // adapt horizontally rectangle
    if (newImageView.frame.size.width > newImageView.frame.size.height && newFrame.size.height <= DEVICE_SIZE.height) {
        newFrame.origin.y = (DEVICE_SIZE.height - newFrame.size.height) / 2;
    }
    return newFrame;
}


+ (CGRect)handleScaleOverflow:(CGRect)newFrame {
    // bounce to original frame
    CGPoint oriCenter = CGPointMake(newFrame.origin.x + newFrame.size.width/2, newFrame.origin.y + newFrame.size.height/2);
    if (newFrame.size.width < oldFrame.size.width) {
        newFrame = oldFrame;
    }
    if (newFrame.size.width > largeFrame.size.width) {
        newFrame = largeFrame;
    }
    newFrame.origin.x = oriCenter.x - newFrame.size.width/2;
    newFrame.origin.y = oriCenter.y - newFrame.size.height/2;
    return newFrame;
}



+(void)hideImage:(UITapGestureRecognizer*)tap{
    UIView *backgroundView=tap.view;
    UIImageView *imageView=(UIImageView*)[tap.view viewWithTag:1];
    [UIView animateWithDuration:0.3 animations:^{
        imageView.frame=[orginImageView convertRect:orginImageView.bounds toView:[UIApplication sharedApplication].keyWindow];
    } completion:^(BOOL finished) {
        [backgroundView removeFromSuperview];
        orginImageView.alpha = 1;
        backgroundView.alpha=0;
    }];
}

@end
