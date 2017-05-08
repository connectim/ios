//
//  NSMutableArray+LMSafeMethod.m
//  Connect
//
//  Created by Connect on 2017/4/6.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "NSMutableArray+LMSafeMethod.h"
#import <objc/message.h>

@implementation NSMutableArray (LMSafeMethod)
+(void)load
{
    [super load];
    [self addobjectMethodExchange];
    [self insertIndexMethodExchange];
    [self replaceObjectAtIndex];
    [self ObjectAtIndexMethodExchange];
    
}
+(void)replaceObjectAtIndex
{
    Method systemReMethod = class_getInstanceMethod(objc_getClass("__NSArrayM"), @selector(replaceObjectAtIndex:withObject:));
    Method meReMethod = class_getInstanceMethod(objc_getClass("__NSArrayM"), @selector(con_replaceObjectAtIndex:withObject:));
    method_exchangeImplementations(systemReMethod, meReMethod);
}
+(void)insertIndexMethodExchange
{
    Method systemInMethod = class_getInstanceMethod(objc_getClass("__NSArrayM"), @selector(insertObject:atIndex:));
    Method meInMethod = class_getInstanceMethod(objc_getClass("__NSArrayM"), @selector(con_insertObject:atIndex:));
    method_exchangeImplementations(systemInMethod, meInMethod);
}
+(void)addobjectMethodExchange
{
    Method systemAddMethod = class_getInstanceMethod(objc_getClass("__NSArrayM"), @selector(addObject:));
    Method meAddMethod = class_getInstanceMethod(objc_getClass("__NSArrayM"), @selector(con_addObject:));
    method_exchangeImplementations(systemAddMethod, meAddMethod);
}
+(void)ObjectAtIndexMethodExchange
{
    Method systemObMethod = class_getInstanceMethod(objc_getClass("__NSArrayM"), @selector(objectAtIndex:));
    Method meObMethod = class_getInstanceMethod(objc_getClass("__NSArrayM"), @selector(con_objectAtIndex:));
    method_exchangeImplementations(systemObMethod, meObMethod);
}
-(void)con_replaceObjectAtIndex:(NSInteger)index withObject:(id)object
{
    if (self.count == 0) {
        return;
    }
    if (index < 0 || index >= [self count] || object == nil) {
        return ;
    }
    [self con_replaceObjectAtIndex:index withObject:object];
    
}
- (void)con_insertObject:(id)object atIndex:(NSInteger)index
{
    if (index < 0 || index > [self count] || object == nil) {
        return ;
    }
     [self con_insertObject:object atIndex:index];
    
}
-(void)con_addObject:(id)object
{
    if (object == nil) {
        return;
    }
    [self con_addObject:object];
}
-(id)con_objectAtIndex:(NSInteger)index
{
    if (self.count == 0) {
        return nil;
    }
    if (index < 0 || index >= self.count) {
        return nil;
    }else
    {
        return [self con_objectAtIndex:index];
    }
}

@end
