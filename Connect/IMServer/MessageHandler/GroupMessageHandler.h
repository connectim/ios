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

@protocol GroupMessageHandlerGetNewMessage <NSObject>

@optional

/**
 *  recive group message
 *
 *  @param message
 */
- (void)getNewGroupMessage:(ChatMessageInfo *)message;

/**
 * recive bitch group messages
 * @param messages
 */
- (void)getBitchGroupMessage:(NSArray *)messages;

@end

@interface GroupMessageHandler : NSObject <IMGroupMessageHandler>
+ (GroupMessageHandler *)instance;

@property(nonatomic, strong) NSHashTable *recentChatObservers;
@property(nonatomic, strong) NSHashTable *getNewMessageObservers;

/**
 * set obersrver to obervr new message
 * @param oberver
 */
- (void)addGetNewMessageObserver:(id <GroupMessageHandlerGetNewMessage>)oberver;

/**
 * remove obersrver
 * @param oberver
 */
- (void)removeGetNewMessageObserver:(id <GroupMessageHandlerGetNewMessage>)oberver;

@end
