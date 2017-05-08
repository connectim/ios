/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import <Foundation/Foundation.h>
#import "IMService.h"
#import "RecentChatModel.h"
#import "ChatMessageInfo.h"

@protocol PeerMessageHandlerGetNewMessage <NSObject>

@optional

- (void)getNewMessage:(ChatMessageInfo *)message;

- (void)getBitchNewMessage:(NSArray *)messages;

- (void)getReadAckWithMessageID:(NSString *)messageId chatUserPublickey:(NSString *)publickey;

@end

@interface PeerMessageHandler : NSObject <IMPeerMessageHandler>
+ (PeerMessageHandler *)instance;

@property(nonatomic, strong) NSHashTable *getNewMessageObservers;

/**
 * Add new messsage observer
 * @param oberver
 */
- (void)addGetNewMessageObserver:(id <PeerMessageHandlerGetNewMessage>)oberver;

/**
 * remove GetNewMessage Observer
 * @param oberver
 */
- (void)removeGetNewMessageObserver:(id <PeerMessageHandlerGetNewMessage>)oberver;

@end
