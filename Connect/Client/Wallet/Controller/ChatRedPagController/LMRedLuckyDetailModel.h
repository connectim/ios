//
//  LMRedLuckyDetailModel.h
//  Connect
//
//  Created by Qingxu Kuang on 16/7/30.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMRootModel.h"

@interface LMRedLuckyDetailModel : LMRootModel
@property(nonatomic, copy) NSString *userName;
@property(nonatomic, copy) NSString *dateString;
@property(nonatomic, copy) NSString *moneyString;
@property(nonatomic, copy) NSString *iconURLString;
@property(nonatomic, assign) BOOL winer;// winer

/**
 *  @brief singleton Model object
 *  @param dict: data array。
 */
+ (instancetype)modelWithDictionary:(NSDictionary *)dict;
@end
