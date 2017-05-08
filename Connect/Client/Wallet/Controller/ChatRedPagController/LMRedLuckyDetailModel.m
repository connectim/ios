//
//  LMRedLuckyDetailModel.m
//  Connect
//
//  Created by Qingxu Kuang on 16/7/30.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMRedLuckyDetailModel.h"

@implementation LMRedLuckyDetailModel
- (instancetype)initModelWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        [self assignValueWithDictionary:dict];
    }
    return self;
}

+ (instancetype)modelWithDictionary:(NSDictionary *)dict {
    return [[self alloc] initModelWithDictionary:dict];
}
@end
