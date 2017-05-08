//
//  LMGroupIntroductionViewController.h
//  Connect
//
//  Created by bitmain on 2016/12/27.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import "BaseViewController.h"
#import "GJGCChatFriendTalkModel.h"

@interface LMGroupIntroductionViewController : BaseViewController

@property(copy, nonatomic) NSString *titleName;
@property(nonatomic, weak) GJGCChatFriendTalkModel *talkModel;


@end
