//
//  RegexKit.h
//  Connect
//
//  Created by MoHuilin on 16/5/10.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RegexKit : NSObject

+ (BOOL)vilidatePhoneNum:(NSString *)phoneNum region:(NSString *)localCode;

+ (BOOL)vilidateEmail:(NSString *)email;

+ (BOOL)vilidatePassword:(NSString *)password;

+ (BOOL)nameLengthLimit:(NSString *)name;

+ (BOOL)updateIdLengthLimit:(NSString *)idString;

+ (NSString *)countryCode;

+ (NSNumber *)phoneCode;

+ (int)countTheStrLength:(NSString*)strtemp;
+ (BOOL)isOuterTransferWithurl:(NSString *)url;
+ (BOOL)isOuterRedpackgeWithurl:(NSString *)url;
+ (BOOL)isPaymentWithurl:(NSString *)url;
+ (BOOL)isNotChinsesWithUrl:(NSString*)str;



@end
