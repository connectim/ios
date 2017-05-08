//
//  LMSetMoneyResultViewController.h
//  Connect
//
//  Created by Edwin on 16/7/29.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMBaseViewController.h"

@interface LMSetMoneyResultViewController : LMBaseViewController

@property(nonatomic, strong) AccountInfo *info;
@property(nonatomic, strong) NSDecimalNumber *trasferAmount;

@end
