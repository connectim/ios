//
//  LMTransactionModel.h
//  Connect
//
//  Created by MoHuilin on 2017/6/2.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMTransactionModel : NSObject

@property (nonatomic ,copy) NSString *messageId;
@property (nonatomic ,copy) NSString *note;
@property (nonatomic ,copy) NSString *hashId;
@property (nonatomic ,strong) NSDecimalNumber *amount;
@property (nonatomic ,assign) BOOL isCrowding;
@property (nonatomic ,assign) int size;
@property (nonatomic ,assign) int status;

@end
