//
//  GJGCChatFriendViewController.h
//  Connect
//
//  Created by KivenLin on 14-11-3.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJGCChatDetailViewController.h"
#import "GJGCChatFriendDataSourceManager.h"

@interface GJGCChatFriendViewController : GJGCChatDetailViewController <UIActionSheetDelegate>

- (void)setSendChatContentModelWithTalkInfo:(GJGCChatFriendContentModel *)contentModel;

/* 
 *Click phone number
 */
- (void)makePhoneCall:(NSString *)phoneNumber;

@property(nonatomic, copy) NSString *outterRedpackHashid;

@end
