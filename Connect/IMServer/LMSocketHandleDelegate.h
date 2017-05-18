//
//  LMSocketHandleDelegate.h
//  Connect
//
//  Created by MoHuilin on 2017/5/15.
//  Copyright © 2017年 Connect. All rights reserved.
//

#ifndef LMSocketHandleDelegate_h
#define LMSocketHandleDelegate_h
@class MessagePost;
@class ChatMessageInfo;

@protocol IMPeerMessageHandler <NSObject>

- (BOOL)handleMessage:(MessagePost *)msg;
- (BOOL)handleBatchMessages:(NSArray *)messages;

@end

@protocol IMGroupMessageHandler <NSObject>

- (BOOL)handleGroupInviteMessage:(MessagePost *)msg;
- (BOOL)handleBatchGroupInviteMessage:(NSArray *)messages;
- (BOOL)handleMessage:(MessagePost *)msg;
- (BOOL)handleBatchGroupMessage:(NSArray *)messages;

@end

@protocol SystemMessageHandlerGetNewMessage <NSObject>

- (void)getNewSystemMessage:(ChatMessageInfo *)message;
- (void)getNewSystemMessages:(NSArray *)messages;

@end


#endif /* LMSocketHandleDelegate_h */
