//
//  NSDictionary+LMSafety.m
//  Connect
//
//  Created by MoHuilin on 2017/1/4.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "NSDictionary+LMSafety.h"

@implementation NSDictionary (LMSafety)

- (id)safeObjectForKey:(id)aKey {
    NSObject *object = self[aKey];
    
    if (object == [NSNull null]) {
        return @"";
    }
    
    return object;
}
- (void)safeSetObject:(id)object forKey:(id)aKey {
    if (object && aKey) {
        [self setValue:object forKey:aKey];
    }
}

@end
