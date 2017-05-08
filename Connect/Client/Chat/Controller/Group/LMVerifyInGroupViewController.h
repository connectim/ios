//
//  LMVerifyInGroupViewController.h
//  Connect
//
//  Created by bitmain on 2016/12/28.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import "BaseViewController.h"
#import "LMOtherModel.h"

@interface LMVerifyInGroupViewController : BaseViewController
@property(weak, nonatomic) IBOutlet UITableView *displayTbaleView;

@property(nonatomic, strong) LMOtherModel *model;
@property(nonatomic, copy) void (^VerifyCallback)(BOOL refused);

@end
