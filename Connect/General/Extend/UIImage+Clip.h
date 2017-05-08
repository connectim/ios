//
//  UIImage+Clip.h
//  Connect
//
//  Created by MoHuilin on 16/8/31.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Clip)

/**
 *   Change the image size proportionally)
 */
-(UIImage*)changeImageSizeWithOriginalImage:(UIImage*)image percent:(float)percent;
/**
 *  circle
 */
-(UIImage*)circleImage:(UIImage*)image;
/**
 *  Intercept part of the image
 */
-(UIImage*)getSubImage:(CGRect)rect;
/**
 *  Scale scaling
 */
-(UIImage*)scaleToSize:(CGSize)size;

-(UIImage *)rotateImage:(UIImage *)aImage with:(UIImageOrientation)theorient;

-(UIImage *)fixOrientation:(UIImage *)aImage;

@end
