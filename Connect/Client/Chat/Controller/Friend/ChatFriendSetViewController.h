//
//  ChatFriendSetViewController.h
//  Connect
//
//  Created by MoHuilin on 16/7/14.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseSetViewController.h"
#import "GJGCChatFriendTalkModel.h"

@interface ChatFriendSetViewController : BaseSetViewController

/**
 *  init
 *
 *  @return 
 */
- (instancetype)initWithTalkModel:(GJGCChatFriendTalkModel *)talkModel;

@end
