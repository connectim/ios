//
//  LMChatRedLuckyDetailController.h
//  Connect
//
//  Created by Qingxu Kuang on 16/7/30.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMBaseViewController.h"

@class RedPackageInfo;

@interface LMChatRedLuckyDetailController : LMBaseViewController
// group member
@property(nonatomic, strong) NSArray *groupMembers;

- (instancetype)initWithUserInfo:(AccountInfo *)info redLuckyInfo:(RedPackageInfo *)redLuckyInfo;


- (instancetype)initWithUserInfo:(AccountInfo *)info redLuckyInfo:(RedPackageInfo *)redLuckyInfo isFromHistory:(BOOL)isFromHistory;

@end
