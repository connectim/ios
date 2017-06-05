//
//  LMConversionManager.h
//  Connect
//
//  Created by MoHuilin on 2017/1/18.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RecentChatModel.h"
#import "GJGCChatContentBaseModel.h"

@class ChatMessageInfo;
@class MMMessage;

@protocol LMConversionListChangeManagerDelegate <NSObject>

- (void)conversationListDidChanged:(NSArray<RecentChatModel *> *)conversationList;
- (void)unreadMessageNumberDidChanged;
- (void)unreadMessageNumberDidChangedNeedSyncbadge;

@end

@interface LMConversionManager : NSObject

+ (instancetype)sharedManager;

/**
 clear status
 */
- (void)clearAllModel;

/**
 Gets all session data for the first time
 */
- (void)getAllConversationFromDB;

/**
 * delete conversation
 */
- (BOOL)deleteConversation:(RecentChatModel *)conversationModel;

- (BOOL)deleteConversationWithIdentifier:(NSString *)identifier;

/**
 * clear all unread
 */
- (void)markAllMessagesAsRead:(RecentChatModel *)conversation;

/**
 * update cell stranger statue
 */
- (void)setRecentStrangerStatusWithIdentifier:(NSString *)identifier stranger:(BOOL)stranger;

/**
 * clear one conversion as read
 */
- (void)markConversionMessagesAsReadWithIdentifier:(NSString *)conversationIdentifier;

/**
 * clear unread and group @ note
 */
- (void)clearConversionUnreadAndGroupNoteWithIdentifier:(NSString *)conversationIdentifier;

/**
 * get new message
 */
- (void)getNewMessageToUpdateUnreadCountWithRecentChatIdentifier:(NSString *)identifier;

/**
 * group mute change
 */
- (void)setConversationMute:(RecentChatModel *)conversationModel complete:(void (^)(BOOL complete))complete;

/**
 * get peer messge
 */
- (void)getNewMessagesWithLastMessage:(ChatMessageInfo *)lastMessage newMessageCount:(int)messageCount type:(GJGCChatFriendTalkType)type withSnapChatTime:(long long)snapChatTime;
/**
 * get group message
 */
- (void)getNewMessagesWithLastMessage:(ChatMessageInfo *)lastMessage newMessageCount:(int)messageCount  groupNoteMyself:(BOOL)groupNoteMyself;

/**
 * send message
 */
- (void)sendMessage:(MMMessage *)message type:(GJGCChatFriendTalkType)type;


- (void)chatTop:(BOOL)topChat identifier:(NSString *)identifier;

@property (nonatomic, weak) id<LMConversionListChangeManagerDelegate> conversationListDelegate;

@end
