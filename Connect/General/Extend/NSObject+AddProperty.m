//
//  NSObject+AddProperty.m
//  iOS-Categories (https://github.com/shaojiankui/iOS-Categories)
//
//  Created by Jakey on 14/12/15.
//  Copyright (c) 2014年 www.skyfox.org. All rights reserved.
//

#import "NSObject+AddProperty.h"
#import <objc/runtime.h>


static const void *StringProperty = &StringProperty;
static const void *IntegerProperty = &IntegerProperty;
//static char IntegerProperty;
@implementation NSObject (AddProperty)

@dynamic stringProperty;
//set
/**
 *  @brief catgory runtime implements the get set method to add a string attribute
 */
-(void)setStringProperty:(NSString *)stringProperty{
 
    objc_setAssociatedObject(self, StringProperty, stringProperty, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
}
//get
-(NSString *)stringProperty{
    return objc_getAssociatedObject(self, StringProperty);
}

//set
/**
 * @brief catgory runtime implements the get set method to add an NSInteger property
 */
-(void)setIntegerProperty:(NSInteger)integerProperty{
    NSNumber *number = [[NSNumber alloc]initWithInteger:integerProperty];
    objc_setAssociatedObject(self, IntegerProperty, number, OBJC_ASSOCIATION_ASSIGN);
}
//get
-(NSInteger)integerProperty{
    return [objc_getAssociatedObject(self, IntegerProperty) integerValue];
}

@end
