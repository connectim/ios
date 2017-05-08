//
//  DBTableNameFormart.m
//  Connect
//
//  Created by MoHuilin on 16/7/14.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "DBTableNameFormart.h"

@implementation DBTableNameFormart

+ (NSString *)formartTableName:(NSString *)tableName {
    if ([tableName hasPrefix:@"t_"]) {
        return tableName;
    }

    return [NSString stringWithFormat:@"t_%@", tableName];
}

@end
