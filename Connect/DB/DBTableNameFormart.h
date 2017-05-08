//
//  DBTableNameFormart.h
//  Connect
//
//  Created by MoHuilin on 16/7/14.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DBTableNameFormart : NSObject

/**
 * formart table name eg:contact -> t_contact
 * @param tableName
 * @return
 */
+ (NSString *)formartTableName:(NSString *)tableName;

@end
