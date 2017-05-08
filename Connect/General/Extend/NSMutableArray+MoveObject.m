//
//  NSMutableArray+MoveObject.m
//  Connect
//
//  Created by MoHuilin on 2016/12/8.
//  Copyright © 2016年 Connect - P2P Encrypted Instant Message. All rights reserved.
//

#import "NSMutableArray+MoveObject.h"

@implementation NSMutableArray (MoveObject)


- (void)moveObjectFromIndex:(NSUInteger)from toIndex:(NSUInteger)to
{
    if (to != from) {
        id obj = [self objectAtIndexCheck:from];
        [self removeObjectAtIndex:from];
        if (to >= [self count]) {
            [self addObject:obj];
        } else {
            [self insertObject:obj atIndex:to];
        }
    }
}

- (void)moveObject:(id)obj toIndex:(NSUInteger)to
{
    NSUInteger from = [self indexOfObject:obj];
    [self moveObjectFromIndex:from toIndex:to];
}

- (void)repleteObject:(id)obj1 withObj:(id)obj2{
    NSUInteger index = [self indexOfObject:obj1];
    [self replaceObjectAtIndex:index withObject:obj2];
}
- (void)objectInsert:(id)object atIndex:(NSInteger)index
{
    if (index < 0 || index > [self count] || object == nil) {
        return ;
    }
    [self insertObject:object atIndex:index];
    
}
- (void)objectAddObject:(id)object
{
    if (object == nil) {
        return;
    }
    [self addObject:object];
}


@end
