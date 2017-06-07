//
//  LMAddMoreViewController.h
//  Connect
//
//  Created by bitmain on 2017/1/19.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "BaseTableViewController.h"

typedef void(^DeleBlock)();

@interface LMAddMoreViewController : BaseTableViewController

@property(nonatomic, strong) DeleBlock  deleBlcok;

@end
