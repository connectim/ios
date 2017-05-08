//
//  RegexKit.m
//  Connect
//
//  Created by MoHuilin on 16/5/10.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "RegexKit.h"
#import "NBPhoneNumberUtil.h"
#import "NBPhoneNumber.h"

@implementation RegexKit

+ (BOOL)vilidatePhoneNum:(NSString *)phoneNum region:(NSString *)localCode{
    
    if (!localCode || localCode.length <= 0) {
        localCode = [self countryCode];
    }
    NBPhoneNumberUtil *phoneUtil = [[NBPhoneNumberUtil alloc] init];
    NSError *anError = nil;
    NBPhoneNumber *myNumber = [phoneUtil parse:phoneNum
                                 defaultRegion:localCode error:&anError];
    if (anError) {
        return NO;
    }
    
    return [phoneUtil isValidNumber:myNumber];

}
+ (BOOL)vilidateEmail:(NSString *)email{
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",emailRegex];
    if ([predicate evaluateWithObject:email]) {
        return YES;
    } else{
        return NO;
    }
}

+ (BOOL)vilidatePassword:(NSString *)password{
    NSString *regex = @"^(?!^(\\d+|[a-zA-Z]+|[~!\\*@#$%^&?\\/\\.,;:()-]+)$)^[\\w~!\\*@#$%\\^&?\\/\\.,;:()-]{8,32}$";
    NSPredicate* pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    if ([pred evaluateWithObject:password]) {
        return YES;
    }else{
        return NO;
    }
}

+ (BOOL)isOuterTransferWithurl:(NSString *)url{
    if (GJCFStringIsNull(url)) {
        return NO;
    }
    NSString *transfer_PackgeRegex = @"(http|https)://transfer.connect.im/share/v\\d/transfer\?token=\\w{128}$";
    NSPredicate* pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", transfer_PackgeRegex];
    if ([pred evaluateWithObject:url]) {
        return YES ;
    }else{
        return NO;
    }
}

+ (BOOL)isOuterRedpackgeWithurl:(NSString *)url{
    if (GJCFStringIsNull(url)) {
        return NO;
    }
    NSString *transfer_PackgeRegex = @"(http|https):\/\/luckypacket.connect.im\/share\/v\\d\/packet\?token=\\w{128}$";
    NSString *anyUrlRegex = transfer_PackgeRegex;
    NSError *AnyError = NULL;
    NSRegularExpression *regexAnyLink = [NSRegularExpression regularExpressionWithPattern:anyUrlRegex options:NSRegularExpressionCaseInsensitive error:&AnyError];
    NSArray *regexAnyLinkArray = [regexAnyLink matchesInString:url options:NSMatchingReportCompletion range:NSMakeRange(0, url.length)];
    return regexAnyLinkArray.count;
}

+ (BOOL)isPaymentWithurl:(NSString *)url{
    if (GJCFStringIsNull(url)) {
        return NO;
    }
    NSString *transfer_PackgeRegex = @"(http|https)://(cd.snowball.io:5502|short.connect.im)/share/v\\d/pay\?address=\\w{20,200}?(amount=\\w{1,})$";
    NSPredicate* pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", transfer_PackgeRegex];
    if ([pred evaluateWithObject:url]) {
        return YES ;
    }else{
        return NO;
    }
}
+ (BOOL)isNotChinsesWithUrl:(NSString*)str{
    NSString *regex = @"^[^\u4e00-\u9fa5]{0,}$";
    NSPredicate* pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    if ([pred evaluateWithObject:str]) {
        return YES ;
    }else{
        return NO;
    }

}
+ (BOOL)nameLengthLimit:(NSString *)name{
    int len = [self countTheStrLength:name];
    if (len > 10 || len < 2) {
        return NO;
    }
    return YES;
}
+ (BOOL)updateIdLengthLimit:(NSString *)idString
{
    //6-20 numbers, letters (?! ^ \\ d + $) (?! ^ [A-zA-Z] + $) [0-9a-zA-Z] {6,20}
    NSString *regex = @"^[0-9a-zA-Z]{6,20}$";
    NSPredicate * pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    if ([pred evaluateWithObject:idString]) {
        return YES ;
    }else
        return NO;
}
+ (NSString *)countryCode{
    NSLocale *locale = [NSLocale currentLocale];
    NSString *countryCode = [locale objectForKey: NSLocaleCountryCode];
    return countryCode;
}

+ (NSNumber *)phoneCode{
    NBPhoneNumberUtil *phoneUtil = [[NBPhoneNumberUtil alloc] init];
    NSNumber *countryPhoneCode = [phoneUtil getCountryCodeForRegion:[self countryCode]];
    return countryPhoneCode;
}

+ (int)countTheStrLength:(NSString*)strtemp {
    int strlength = 0;
    char* p = (char*)[strtemp cStringUsingEncoding:NSUnicodeStringEncoding];
    for (int i=0 ; i<[strtemp lengthOfBytesUsingEncoding:NSUnicodeStringEncoding] ;i++) {
        if (*p) {
            p++;
            strlength++;
        }
        else {
            p++;
        }
    }
    return (strlength+1)/2;
}

@end
