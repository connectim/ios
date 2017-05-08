//
//  NSURL+Param.m
//  iOS-Categories (https://github.com/shaojiankui/iOS-Categories)
//
//  Created by Jakey on 14/12/30.
//  Copyright (c) 2014年 www.skyfox.org. All rights reserved.
//

#import "NSURL+Param.h"

@implementation NSURL (Param)
/**
   * @brief url parameters to the dictionary
   *
   * @return parameter to the dictionary result
 */
- (NSDictionary *)parameters
{
    NSMutableDictionary * parametersDictionary = [NSMutableDictionary dictionary];
    NSArray * queryComponents = [self.query componentsSeparatedByString:@"&"];
    for (NSString * queryComponent in queryComponents) {
        NSArray *pairComponents = [queryComponent componentsSeparatedByString:@"="];
        NSString *key = [[pairComponents firstObject] stringByRemovingPercentEncoding];
        NSString *value = [[pairComponents lastObject] stringByRemovingPercentEncoding];
        if (key && value) {
            [parametersDictionary setObject:value forKey:key];
        }
    }
    return parametersDictionary;
}
/**
   * @brief takes the parameter value according to the parameter name
   *
   * @param parameterKey The key of the parameter name
   *
   * @return parameter value
 */
- (NSString *)valueForParameter:(NSString *)parameterKey
{
    return [[self parameters] objectForKey:parameterKey];
}
@end
