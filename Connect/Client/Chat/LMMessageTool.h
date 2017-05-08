//
//  LMMessageTool.h
//  Connect
//
//  Created by MoHuilin on 2017/3/29.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMMessage.h"
#import "GJGCChatFriendContentModel.h"

@interface LMMessageTool : NSObject

/**
 * Save message to db
 */
+ (void)savaSendMessageToDB:(MMMessage *)message;

/**
 * update status
 */
+ (void)updateSendMessageStatus:(MMMessage *)message;

/**
 * fomart audio local save path
 */
+ (NSData *)formateVideoLoacalPath:(GJGCChatFriendContentModel *)messageContent;

/**
 * pack message
 */
+ (MMMessage *)packSendMessageWithChatContent:(GJGCChatFriendContentModel *)messageContent snapTime:(int)snapTime;

/**
 * formart message to chatmessage model
 */
+ (GJGCChatFriendContentType)formateChatFriendContent:(GJGCChatFriendContentModel *)chatContentModel withMsgModel:(MMMessage *)message;

@end
