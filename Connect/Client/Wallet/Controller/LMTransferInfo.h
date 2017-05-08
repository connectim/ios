//
//  LMTransferInfo.h
//  Connect
//
//  Created by Edwin on 16/7/25.
//  Copyright © 2016年 bitmain. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, LMTransferInfoType) {
    LMTransferInfoTypeWithPayer = 0,
    LMTransferInfoTypeWithPayee
};

@interface LMTransferInfo : NSObject

/**
 *  姓名
 */
@property(nonatomic, copy) NSString *userName;
/**
 *  金额
 */
@property(nonatomic, copy) NSString *amount;
/**
 *  类型
 */
@property(nonatomic, assign) LMTransferInfoType type;
@end
