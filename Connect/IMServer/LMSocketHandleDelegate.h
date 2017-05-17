//
//  LMSocketHandleDelegate.h
//  Connect
//
//  Created by MoHuilin on 2017/5/15.
//  Copyright © 2017年 Connect. All rights reserved.
//

#ifndef LMSocketHandleDelegate_h
#define LMSocketHandleDelegate_h
@class Message;
@class MessagePost;

@protocol LMSocketHandleDelegate <NSObject>

- (void)handleMessage:(Message *)msg;
- (void)sendAck;

@end

@protocol IMPeerMessageHandler <NSObject>

- (BOOL)handleMessage:(MessagePost *)msg;
- (BOOL)handleBatchMessages:(NSArray *)messages;
- (BOOL)handleMessageFailure:(MessagePost *)msg;

@end

@protocol IMGroupMessageHandler <NSObject>

- (BOOL)handleGroupInviteMessage:(MessagePost *)msg;
- (BOOL)handleBatchGroupInviteMessage:(NSArray *)messages;
- (BOOL)handleMessage:(MessagePost *)msg;
- (BOOL)handleBatchGroupMessage:(NSArray *)messages;

@end

#endif /* LMSocketHandleDelegate_h */
