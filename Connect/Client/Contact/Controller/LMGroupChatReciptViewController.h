//
//  LMGroupChatReciptViewController.h
//  Connect
//
//  Created by Edwin on 16/8/24.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMBaseViewController.h"

@interface LMGroupChatReciptViewController : LMBaseViewController

@property(nonatomic, copy) void (^didGetNumberAndMoney)(int totalMemeber, NSDecimalNumber *money, NSString *hashId, NSString *note);

- (instancetype)initWithIdentifier:(NSString *)groupIdentifier;
//group members
@property(nonatomic, assign) NSInteger groupMemberCount;

@end
