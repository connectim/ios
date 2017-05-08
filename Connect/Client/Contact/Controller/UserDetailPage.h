//
//  UserDetailPage.h
//  Connect
//
//  Created by MoHuilin on 16/7/21.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseSetViewController.h"
#import "AccountInfo.h"

@interface UserDetailPage : BaseSetViewController

- (instancetype)initWithUser:(AccountInfo *)user;

@end
