//
//  LMPhotoViewController.h
//  MKCustomCamera
//
//  Created by bitmain on 2017/2/4.
//  Copyright © 2017年 MK. All rights reserved.
//

#import <UIKit/UIKit.h>

#define  CommonButtonWidth AUTO_WIDTH(135)

typedef void(^SavePhotoBlock)(UIImage *, BOOL isBack);

typedef void(^SaveVideoBlock)(NSURL *);

@interface LMPhotoViewController : UIViewController
//save photo callback
@property(strong, nonatomic) SavePhotoBlock savePhotoBlock;
//save video callback
@property(strong, nonatomic) SaveVideoBlock saveVideoBlock;

@end
