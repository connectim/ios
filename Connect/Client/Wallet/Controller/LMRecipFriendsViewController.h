//
//  LMRecipFriendsViewController.h
//  Connect
//
//  Created by Edwin on 16/7/23.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMBaseViewController.h"
#import "AccountInfo.h"

@interface LMRecipFriendsViewController : LMBaseViewController

@property(nonatomic, strong) AccountInfo *info;

@property(nonatomic, copy) void (^didGetMoneyAndWithAccountID)(NSDecimalNumber *money, NSString *hashId, NSString *note);

@end
