//
//  NSString+iTunes.m
//  Connect
//
//  Created by bitmain on 2017/2/17.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "NSString+iTunes.h"

@implementation NSString (iTunes)

- (BOOL)isMatch:(NSString *)pattern {
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    if (error) {
        return NO;
    }
    NSTextCheckingResult *res = [regex firstMatchInString:self options:0 range:NSMakeRange(0, self.length)];
    return res != nil;
}

- (BOOL)isiTunesURL {
    return [self isMatch:@"\\/\\/itunes\\.apple\\.com\\/"];
}

@end
