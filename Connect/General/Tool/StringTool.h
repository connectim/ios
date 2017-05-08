//
//  StringTool.h
//  Connect
//
//  Created by MoHuilin on 16/5/11.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StringTool : NSObject

+ (NSString *)pinxCreator:(NSString *)pan withPinv:(NSString *)pinv;

/**
   * Binary exclusive OR method
   *
   * @param data1
   * @param data2
   *
   * @return
 */
+(NSData *) DataXOR1:(NSData *)data1
            DataXOR2:(NSData *)data2;


/**
 *  data to hex
 *
 *  @param data
 *
 *  @return
 */
+ (NSString *)hexStringFromData:(NSData *)data;


/**
 *  hex to data
 *
 *  @param hex
 *
 *  @return 
 */
+ (NSData *)hexStringToData:(NSString *)hex;
/**
 *  Return to the page to determine the regular expression of the test string
 *
 */
+ (NSString *)regHttp;
/**
 * Can only enter numeric decimal points and @ ""
 */
+ (BOOL)checkString:(NSString*)currentString;
/**
 * Guolv string, remove the first space
 */
+ (NSString*)filterStr:(NSString*)str;
/**
 *
 *  Move data to str
 */
+(NSString*)stringWithData:(NSData*)data;
/**
 *  get SystemUrl
 *
 */
+(NSString*)getSystemUrl;


@end
