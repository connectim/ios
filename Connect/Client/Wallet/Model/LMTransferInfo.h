//
//  LMTransferInfo.h
//  Connect
//
//  Created by Edwin on 16/7/25.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, LMTransferInfoType) {
    LMTransferInfoTypeWithPayer = 0,
    LMTransferInfoTypeWithPayee
};

@interface LMTransferInfo : NSObject

@property(nonatomic, copy) NSString *userName;

@property(nonatomic, copy) NSString *amount;

@property(nonatomic, assign) LMTransferInfoType type;
@end
