//
//  UserDetailInfoCell.h
//  Connect
//
//  Created by MoHuilin on 16/7/21.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseCell.h"

typedef NS_ENUM(NSInteger, ButtonType) {
    ButtonTypeChat = 1,
    ButtonTypeTransfer = 2,
    ButtonTypeMessage = 3,
    ButtonTypeShare = 4

};

typedef void (^SwitchValueChangeBlock)(BOOL on);

typedef void (^InviteUserSendBlock)(NSString *message);

typedef void (^CopyAddressBlock)();

typedef void (^FriendButtonBlock)(NSInteger buttonTag);


@interface UserDetailInfoCell : BaseCell
@property(nonatomic, copy) SwitchValueChangeBlock switchValueChangeBlock;
// invite block
@property(nonatomic, copy) InviteUserSendBlock inviteBlock;
// copy user address block
@property(nonatomic, copy) CopyAddressBlock copyBlock;
@property(copy, nonatomic) void (^TextValueChangeBlock)(NSString *text);
@property(strong, nonatomic) FriendButtonBlock friendButtonBlock;


@end
