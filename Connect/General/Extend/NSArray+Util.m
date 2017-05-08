//
//  NSArray+Util.m
//  Connect
//
//  Created by MoHuilin on 2017/3/22.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "NSArray+Util.h"

@implementation NSArray (Util)

- (id)objectAtIndexCheck:(NSInteger)index{
    if (index < 0 || index >= [self count]) {
        return nil;
    }
    
    id value = [self objectAtIndex:index];
    if (value == [NSNull null]) {
        return nil;
    }
    return value;
}

@end
