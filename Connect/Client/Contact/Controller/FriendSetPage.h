//
//  FriendSetPage.h
//  Connect
//
//  Created by MoHuilin on 16/7/21.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseSetViewController.h"
#import "AccountInfo.h"

typedef void (^nickNameChangeBlcok)(NSString *nickName);

@interface FriendSetPage : BaseSetViewController

- (instancetype)initWithUser:(AccountInfo *)user;

@property(strong, nonatomic) nickNameChangeBlcok nickNameChageBlcock;

@end
