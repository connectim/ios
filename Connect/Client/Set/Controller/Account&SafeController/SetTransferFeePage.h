//
//  SetTransferFeePage.h
//  Connect
//
//  Created by MoHuilin on 16/7/30.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseSetViewController.h"


@interface SetTransferFeePage : BaseSetViewController

- (instancetype)initWithChangeBlock:(void (^)(BOOL result, long long displayValue))changeBlock;

@property(nonatomic, copy) void (^changeCallBack)(BOOL result, long long displayValue);
@end
