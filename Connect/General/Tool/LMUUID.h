//
//  LMUUID.h
//  Connect
//
//  Created by MoHuilin on 2017/5/9.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMUUID : NSObject

///--------------------------------------------------------------------
/// Usually, the method `+ (NSString *)value` is enough for you to use.
///--------------------------------------------------------------------
/**
 *  method             value, Requires iOS6.0 and later
 *  abstract           Obtain UDID(Unique Device Identity). If it already exits in keychain, return the exit one; otherwise generate a new one and store it into the keychain then return.
 *  discussion         Use 'identifierForVendor + keychain' to make sure UDID consistency even if the App has been removed or reinstalled.
 *  param              NULL
 *  param result       return UDID String
 */
+ (NSString *)uuid;

@end
