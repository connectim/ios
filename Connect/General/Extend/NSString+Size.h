//
//  NSString+Size.h
//  iOS-Categories (https://github.com/shaojiankui/iOS-Categories)
//
//  Created by Jakey on 15/5/22.
//  Copyright (c) 2015年 www.skyfox.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface NSString (Size)
/**
   * @brief calculates the height of the text
   *
   * @param font font (default is system font)
   * @param width constraint width
 */
- (CGFloat)heightWithFont:(UIFont *)font constrainedToWidth:(CGFloat)width;
/**
   * @brief calculates the width of the text
   *
   * @param font font (default is system font)
   * @param height Constraint height
 */
- (CGFloat)widthWithFont:(UIFont *)font constrainedToHeight:(CGFloat)height;

/**
   * @brief calculates the size of the text
   *
   * @param font font (default is system font)
   * @param width constraint width
 */
- (CGSize)sizeWithFont:(UIFont *)font constrainedToWidth:(CGFloat)width;
/**
   * @brief calculates the size of the text
   *
   * @param font font (default is system font)
   * @param height Constraint height
 */
- (CGSize)sizeWithFont:(UIFont *)font constrainedToHeight:(CGFloat)height;

/**
   * @brief reverses the string
   *
   * @param strSrc is reversed by the string
   *
   * @return after reversing the string
 */
+ (NSString *)reverseString:(NSString *)strSrc;
@end
