//
//  LMApplyJoinToGroupViewController.h
//  Connect
//
//  Created by MoHuilin on 2017/1/1.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "BaseViewController.h"

@interface LMApplyJoinToGroupViewController : BaseViewController

- (instancetype)initWithGroupIdentifier:(NSString *)identifier inviteToken:(NSString *)inviteToken inviteByAddress:(NSString *)inviteBy;

- (instancetype)initWithGroupToken:(NSString *)token;

- (instancetype)initWithGroupIdentifier:(NSString *)identifier hashP:(NSString *)hashP;

@end
