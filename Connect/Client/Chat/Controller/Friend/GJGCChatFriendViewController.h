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
/* 
 *Click phone number
 */
- (void)makePhoneCall:(NSString *)phoneNumber;

/**
 * garb private luckypackage
 * @param hashId
 */
- (void)getSystemRedBagDetailWithHashId:(NSString *)hashId;

/**
 * garb connect term luckypackage
 * @param hashId
 */
- (void)showRedBagDetailWithHashId:(NSString *)hashId;

@property(nonatomic, copy) NSString *outterRedpackHashid;

@end
