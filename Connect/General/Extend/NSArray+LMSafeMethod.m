//
//  NSArray+LMSafeMethod.m
//  Connect
//
//  Created by Connect on 2017/4/6.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "NSArray+LMSafeMethod.h"

@implementation NSArray (LMSafeMethod)
+(void)load
{
    [super load];
    [self ObjectAtIndexMethodExchange];
    
    
    
}
+(void)ObjectAtIndexMethodExchange
{
    Method systemMethod = class_getInstanceMethod(objc_getClass("__NSArrayI"), @selector(objectAtIndex:));
    Method meMethod = class_getInstanceMethod(objc_getClass("__NSArrayI"), @selector(con_objectAtIndex:));
    method_exchangeImplementations(systemMethod, meMethod);
   
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
