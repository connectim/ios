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

@protocol MessageHandlerGetNewMessage <NSObject>

@optional

//get messages
- (void)getBitchNewMessage:(NSArray *)messages;

//get message read ack
- (void)getReadAckWithMessageID:(NSString *)messageId chatUserPublickey:(NSString *)publickey;

@end


#endif /* LMSocketHandleDelegate_h */
