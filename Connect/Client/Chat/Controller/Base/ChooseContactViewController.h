//
//  ChooseContactViewController.h
//  Connect
//
//  Created by MoHuilin on 16/7/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseViewController.h"

typedef void (^ChooseContactComplete)(NSArray *selectContactArray);

@interface ChooseContactViewController : BaseViewController

- (instancetype)initWithChooseComplete:(ChooseContactComplete)complete defaultSelectedUser:(AccountInfo *)selectedUser;

- (instancetype)initWithChooseComplete:(ChooseContactComplete)complete defaultSelectedUsers:(NSArray *)selectedUsers;

@end
