//
//  LMchatGroupManageViewController.h
//  Connect
//
//  Created by bitmain on 2016/12/27.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import "BaseSetViewController.h"
#import "GJGCChatFriendTalkModel.h"

typedef void(^changeSwitchBlock)(BOOL verifiy);

@interface LMchatGroupManageViewController : BaseSetViewController

@property(copy, nonatomic) NSString *titleName;
@property(nonatomic, weak) GJGCChatFriendTalkModel *talkModel;
@property(strong, nonatomic) changeSwitchBlock switchChangeBlock;
@property(weak, nonatomic) AccountInfo *groupMasterInfo;

@property(nonatomic, copy) void (^groupAdminChangeCallBack)(NSString *address);

@end
