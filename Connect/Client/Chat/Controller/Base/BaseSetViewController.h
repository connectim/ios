//
//  BaseSetViewController.h
//  Connect
//
//  Created by MoHuilin on 16/7/14.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "GJGCBaseViewController.h"
#import "NCellHeader.h"
#import "AccountInfo.h"

#import "MyInfoCell.h"
#import "MainSetLogoutCell.h"
#import "GroupMembersCell.h"
#import "MainSetLogoutCell.h"
#import "NCellValue1.h"
#import "SetAvatarCell.h"


@interface BaseSetViewController : GJGCBaseViewController <UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, strong) UITableView *tableView;

@property(nonatomic, strong) NSMutableArray *groups;


- (void)setupCellData;

- (void)configTableView;

- (void)hidenTabbarWhenPushController:(UIViewController *)page;

@end
