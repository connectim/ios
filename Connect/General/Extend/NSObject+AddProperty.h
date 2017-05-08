//
//  NSObject+AddProperty.h
//  iOS-Categories (https://github.com/shaojiankui/iOS-Categories)
//
//  Created by Jakey on 14/12/15.
//  Copyright (c) 2014年 www.skyfox.org. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (AddProperty)
/**
 *  @brief catgory runtime implements the get set method to add a string attribute
 */
@property (nonatomic,strong) NSString *stringProperty;
/**
 *  @brief catgory runtime implements the get set method to add an NSInteger property
 */
@property (nonatomic,assign) NSInteger integerProperty;
@end
