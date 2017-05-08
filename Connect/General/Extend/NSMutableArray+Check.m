//
//  NSMutableArray+Check.m
//  Connect
//
//  Created by MoHuilin on 2017/3/27.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "NSMutableArray+Check.h"

@implementation NSMutableArray (Check)

- (void)removeObjectAtIndexCheck:(NSInteger)index{
    if (index < 0 || index >= [self count]) {
        return;
    }
    [self removeObjectAtIndex:index];
}

@end
