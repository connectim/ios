//
//  NSURL+Param.h
//  iOS-Categories (https://github.com/shaojiankui/iOS-Categories)
//
//  Created by Jakey on 14/12/30.
//  Copyright (c) 2014年 www.skyfox.org. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (Param)
/**
   * @brief url parameters to the dictionary
   *
   * @return parameter to the dictionary result
 */
- (NSDictionary *)parameters;
/**
   * @brief takes the parameter value according to the parameter name
   *
   * @param parameterKey The key of the parameter name
   *
   * @return parameter value
 */
- (NSString *)valueForParameter:(NSString *)parameterKey;
@end
