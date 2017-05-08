//
//  ChatMessageInfo.m
//  Connect
//
//  Created by MoHuilin on 16/7/29.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "ChatMessageInfo.h"
#import "NSDictionary+LMSafety.h"

@implementation ChatMessageInfo

- (NSInteger)snapTime{
    if (!self.message.ext) {
        return 0;
    }
    if (self.message.ext && [self.message.ext isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = self.message.ext;
        if ([dict.allKeys containsObject:@"luck_delete"]) {
            _snapTime = [[dict safeObjectForKey:@"luck_delete"] integerValue];
        }
    }
    return _snapTime;
}

@end
