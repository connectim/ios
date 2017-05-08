//
//  NSDictionary+JSONString.h
//  iOS-Categories (https://github.com/shaojiankui/iOS-Categories)
//
//  Created by Jakey on 15/4/25.
//  Copyright (c) 2015年 www.skyfox.org. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (JSONString)
/**
    @brief NSDictionary is converted to a JSON string
   *
   * @return JSON string
 */
-(NSString *)LK_JSONString;
@end
