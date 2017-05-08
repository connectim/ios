//
//  NSData+Base64.h
//  iOS-Categories (https://github.com/shaojiankui/iOS-Categories)
//
//  Created by Jakey on 15/1/26.
//  Copyright (c) 2015年 www.skyfox.org. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (Base64)
/**
   * @brief String base64 after the transfer data
   *
   * @param string passed in the string
   *
   * @return passed string data after base64a
 */
+ (NSData *)dataWithBase64EncodedString:(NSString *)string;
/**
   * @brief NSData to string
   *
   * @param wrapWidth line length 76 64
   *
   * @return base64 after the string
 */
- (NSString *)base64EncodedStringWithWrapWidth:(NSUInteger)wrapWidth;
/**
   * @brief NSData to string the length of the new line 64
   *
   * @return base64 after the string
 */
- (NSString *)base64EncodedString;
@end
