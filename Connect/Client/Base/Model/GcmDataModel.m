//
//  GcmDataModel.m
//  Connect
//
//  Created by MoHuilin on 16/6/29.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "GcmDataModel.h"

NSString *aad_gcmdata_Key = @"aad";
NSString *iv_gcmdata_Key = @"iv";
NSString *ciphertext_gcmdata_Key = @"ciphertext";
NSString *tag_gcmdata_Key = @"tag";


@implementation GcmDataModel

+ (instancetype)gcmDataWith:(NSString *)dict{
    GcmDataModel *model = [[GcmDataModel alloc] init];
    model.aad = [dict valueForKey:aad_gcmdata_Key];
    model.iv = [dict valueForKey:iv_gcmdata_Key];
    model.tag = [dict valueForKey:tag_gcmdata_Key];
    model.ciphertext = [dict valueForKey:ciphertext_gcmdata_Key];
    return model;
}

- (BOOL)savaToPath:(NSString *)path{
    NSDictionary *dict = [self mj_JSONObject];
    return [dict writeToFile:path atomically:YES];
}

+ (GcmDataModel *)getgcmDataModelFromPath:(NSString *)path{
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    return [GcmDataModel mj_objectWithKeyValues:dict];
}

@end
