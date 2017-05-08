//
//  GcmDataModel.h
//  Connect
//
//  Created by MoHuilin on 16/6/29.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

extern const NSString *aad_gcmdata_Key;
extern const NSString *iv_gcmdata_Key;
extern const NSString *ciphertext_gcmdata_Key;
extern const NSString *tag_gcmdata_Key;


@interface GcmDataModel : NSObject

@property (nonatomic ,copy) NSString *aad;

@property (nonatomic ,copy) NSString *iv;

@property (nonatomic ,copy) NSString *ciphertext;

@property (nonatomic ,copy) NSString *tag;

+ (instancetype)gcmDataWith:(NSDictionary *)dict;

- (BOOL)savaToPath:(NSString *)path;

+ (GcmDataModel *)getgcmDataModelFromPath:(NSString *)path;

@end
