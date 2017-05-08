//
//  InviteToGroupCell.h
//  Connect
//
//  Created by MoHuilin on 2016/12/29.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import "GJGCChatFriendBaseCell.h"

@interface InviteToGroupCell : GJGCChatFriendBaseCell

@property(nonatomic, strong) UIImageView *contactAvatarImageView;
@property(nonatomic, strong) UILabel *contactNameView;
@property(nonatomic, strong) GJCFCoreTextContentView *subTipMessageView;

- (void)tapOnSelf;

@end
