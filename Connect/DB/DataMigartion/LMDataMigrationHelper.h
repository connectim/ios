//
//  LMDataMigrationHelper.h
//  Connect
//
//  Created by MoHuilin on 2017/4/11.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMDataMigrationHelper : NSObject

/**
 * 数据迁移函数
 * @param complete
 */
+ (void)dataMigrationWithComplete:(void (^)(CGFloat progress))complete;

@end
