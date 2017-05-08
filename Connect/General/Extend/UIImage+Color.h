//
//  UIImage+Color.h
//  iOS-Categories (https://github.com/shaojiankui/iOS-Categories)
//
//  Created by Jakey on 14/12/15.
//  Copyright (c) 2014年 www.skyfox.org. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Color)
/**
   * @brief generates solid color images according to color
   *
   * @param color
   *
   * @return solid color picture
 */
+ (UIImage *)imageWithColor:(UIColor *)color;

+ (UIImage *)imageWithColor:(UIColor *)color withSize:(CGSize)size;
/**
   * @brief take a picture of the color
   *
   * @param point a point
   *
   * @return color
 */
- (UIColor *)colorAtPoint:(CGPoint )point;
//more accurate method ,colorAtPixel 1x1 pixel
/**
   * @brief take the color of a pixel
   *
   * @param point a pixel
   *
   * @return color
 */
- (UIColor *)colorAtPixel:(CGPoint)point;
/**
   * @brief returns whether the picture has a transparent channel
   *
   * @return whether there is a transparent channel
 */
- (BOOL)hasAlphaChannel;

/**
   * @brief gets grayscale
   *
   * @param sourceImage picture
   *
   * @return get gray image
 */
+ (UIImage*)covertToGrayImageFromImage:(UIImage*)sourceImage;

@end
