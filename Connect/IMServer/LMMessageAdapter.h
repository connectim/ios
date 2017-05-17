//
//  LMMessageAdapter.h
//  Connect
//
//  Created by MoHuilin on 2017/5/16.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Protofile.pbobjc.h"
#import "MMMessage.h"

@interface LMMessageAdapter : NSObject

+ (GPBMessage *)sendAdapterIMPostWithMessage:(MMMessage *)message talkType:(GJGCChatFriendTalkType)talkType ecdhKey:(NSString *)ecdhKey;

+ (MessagePost *)sendAdapterIMReadAckPostWithMessage:(MMMessage *)message;

@end
