//
//  SessionManager.h
//  Connect
//
//  Created by MoHuilin on 2016/11/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GJGCChatContentBaseModel.h"
@class VersionResponse;
@class ChatCacheCookie;
@class ChatCookieData;

#define SessionManagerClearReadCountNoti @"SessionManagerClearReadCountNoti"

@class RecentChatModel;

@interface SessionManager : NSObject

+ (SessionManager *)sharedManager;
@property (nonatomic ,strong) ChatCacheCookie *loginUserChatCookie; // Login User Zero at ChatCookie
@property (nonatomic ,copy) NSString *chatSession;
@property (nonatomic ,strong) id chatObject; // Session object model (user, group, system)
@property (nonatomic ,assign) GJGCChatFriendTalkType talkType;


- (ChatCookieData *)getChatCookieWithChatSession:(NSString *)chatSession;
- (void)removeChatCookieWithChatSession:(NSString *)chatSession;
- (void)setChatCookie:(ChatCookieData *)chatCookie chatSession:(NSString *)chatSession;

- (BOOL)chatCookieExpire:(NSString *)chatSession;
- (void)chatCookie:(BOOL)expire chatSession:(NSString *)chatSession;

- (void)setRecentChats:(NSArray *)recentChats;
- (void)setRecentChat:(RecentChatModel *)model;
- (void)removeRecentChatWithIdentifier:(NSString *)identifier;
- (RecentChatModel *)getRecentChatWithIdentifier:(NSString *)identifier;
- (int)allRecentChatsUnreadCount;

@property (nonatomic ,assign) int topChatCount; // top count
@property (nonatomic ,strong) NSMutableArray *allRecentChats;// session ui

- (void)clearAllModel;

- (void)clearUnreadWithIdentifier:(NSString *)identifier;



#pragma mark - force Update

@property (nonatomic ,strong) VersionResponse *currentNewVersionInfo; // new message

@property (nonatomic ,copy) void (^GetNewVersionInfoCallback)(VersionResponse *currentNewVersionInfo);

@end
