//
//  BaseTableViewController.h
//  Connect
//
//  Created by MoHuilin on 16/5/9.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"


@interface BaseTableViewController : BaseViewController <UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) UITableView *tableView; //list

@end
