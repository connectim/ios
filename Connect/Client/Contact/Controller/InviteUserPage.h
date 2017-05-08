//
//  InviteUserPage.h
//  Connect
//
//  Created by MoHuilin on 16/7/21.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseSetViewController.h"
#import "AccountInfo.h"

@interface InviteUserPage : BaseSetViewController

- (instancetype)initWithUser:(AccountInfo *)user;
//source 
@property(nonatomic, assign) UserSourceType sourceType;

@end
