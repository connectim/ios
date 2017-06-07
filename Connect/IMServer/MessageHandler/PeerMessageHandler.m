
/*
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "PeerMessageHandler.h"
#import "NSString+DictionaryValue.h"
#import "UserDBManager.h"
#import "RecentChatDBManager.h"
#import "MessageDBManager.h"
#import "LMBaseSSDBManager.h"
#import "SystemTool.h"
#import "LMMessageValidationTool.h"
#import "LMConversionManager.h"
#import "LMMessageExtendManager.h"
#import "LMHistoryCacheManager.h"
#import "LMMessageAdapter.h"

@interface PeerMessageHandler ()

@end

@implementation PeerMessageHandler
+ (PeerMessageHandler *)instance {
    static PeerMessageHandler *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!m) {
            m = [[PeerMessageHandler alloc] init];
        }
    });
    return m;
}

- (instancetype)init {
    if (self = [super init]) {
        self.getNewMessageObservers = [NSHashTable weakObjectsHashTable];
    }
    return self;
}


- (void)addGetNewMessageObserver:(id <MessageHandlerGetNewMessage>)oberver {
    [self.getNewMessageObservers addObject:oberver];
}

- (void)removeGetNewMessageObserver:(id <MessageHandlerGetNewMessage>)oberver {
    [self.getNewMessageObservers removeObject:oberver];
}

- (void)pushGetBitchNewMessages:(NSArray *)messages {
    ChatMessageInfo *lastMsg = [messages lastObject];
    if ([[SessionManager sharedManager].chatSession isEqualToString:lastMsg.messageOwer]) {
        for (id <MessageHandlerGetNewMessage> ob in self.getNewMessageObservers) {
            if ([ob respondsToSelector:@selector(getBitchNewMessage:)]) {
                [GCDQueue executeInMainQueue:^{
                    [ob getBitchNewMessage:messages];
                }];
            }
        }
    }
}

- (void)pushGetReadAckWithMessageId:(NSString *)messageId chatUserPublickey:(NSString *)pulickey {

    for (id <MessageHandlerGetNewMessage> ob in self.getNewMessageObservers) {
        if ([ob respondsToSelector:@selector(getReadAckWithMessageID:chatUserPublickey:)]) {
            [ob getReadAckWithMessageID:messageId chatUserPublickey:pulickey];
        }
    }
}

- (BOOL)handleBatchMessages:(NSArray *)messages {

    NSMutableDictionary *owerMessagesDict = [NSMutableDictionary dictionary];
    NSMutableArray *messageExtendArray = [NSMutableArray array];
    for (MessagePost *msg in messages) {
        NSString *messageString = [LMMessageAdapter decodeMessageWithMassagePost:msg];
        MMMessage *messageInfo = [MMMessage mj_objectWithKeyValues:[messageString dictionaryValue]];
        messageInfo.publicKey = msg.pubKey;
        if (![LMMessageValidationTool checkMessageValidata:messageInfo messageType:MessageTypePersion]) {
            continue;
        }
        if (messageInfo.type == GJGCChatInviteToGroup) {
            NSString *identifier = [messageInfo.ext1 valueForKey:@"groupidentifier"];
            LMBaseSSDBManager *ssdbManager = [LMBaseSSDBManager open:@"system_message"];
            [ssdbManager del:identifier];
            [ssdbManager close];
        }
        
        if (messageInfo.type == GJGCChatFriendContentTypeSnapChatReadedAck) { //ack
            [[MessageDBManager sharedManager] updateAudioMessageWithMsgID:messageInfo.content messageOwer:msg.pubKey];
            DDLogError(@"messageInfo.content : %@", messageInfo.content);
            [GCDQueue executeInMainQueue:^{
                [self pushGetReadAckWithMessageId:messageInfo.content chatUserPublickey:msg.pubKey];
            }];
            continue;
        }
        
        messageInfo.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
        ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
        chatMessage.messageId = messageInfo.message_id;
        chatMessage.createTime = (NSInteger) messageInfo.sendtime;
        chatMessage.readTime = 0;
        chatMessage.message = messageInfo;
        chatMessage.messageOwer = msg.pubKey;
        chatMessage.messageType = messageInfo.type;
        chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
        chatMessage.senderAddress = [KeyHandle getAddressByPubkey:msg.pubKey];
        
        //transfer message
        if (chatMessage.messageType == GJGCChatFriendContentTypeTransfer) {
            [[LMHistoryCacheManager sharedManager] cacheTransferHistoryWith:chatMessage.senderAddress];
        }
        
        if (messageInfo.type == GJGCChatFriendContentTypeSnapChat) {
            chatMessage.snapTime = [messageInfo.content integerValue];
        } else {
            NSDictionary *snapchatExt = messageInfo.ext;
            if ([snapchatExt isKindOfClass:[NSDictionary class]]) {
                if (snapchatExt && [snapchatExt.allKeys containsObject:@"luck_delete"]) {
                    chatMessage.snapTime = [[snapchatExt valueForKey:@"luck_delete"] integerValue];
                }
            }
        }
        
        NSMutableDictionary *msgDict = [owerMessagesDict valueForKey:chatMessage.messageOwer];
        NSMutableArray *messages = [msgDict valueForKey:@"messages"];
        int unReadCount = [[msgDict valueForKey:@"unReadCount"] intValue];
        if (messages) {
            [messages objectAddObject:chatMessage];
            if ([GJGCChatFriendConstans shouldNoticeWithType:chatMessage.messageType]) {
                unReadCount++;
                [msgDict setValue:@(unReadCount) forKey:@"unReadCount"];
            }
        } else {
            messages = [NSMutableArray array];
            [messages objectAddObject:chatMessage];
            if ([GJGCChatFriendConstans shouldNoticeWithType:chatMessage.messageType]) {
                unReadCount = 1;
            }
            NSMutableDictionary *msgDict = @{@"messages": messages,
                                             @"unReadCount": @(unReadCount)}.mutableCopy;
            [owerMessagesDict setObject:msgDict forKey:chatMessage.messageOwer];
        }
        if (chatMessage.messageType == GJGCChatFriendContentTypePayReceipt ||
            chatMessage.messageType == GJGCChatFriendContentTypeTransfer) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict safeSetObject:messageInfo.message_id forKey:@"message_id"];
            [dict safeSetObject:messageInfo.content forKey:@"hashid"];
            if (chatMessage.messageType == GJGCChatFriendContentTypePayReceipt) {
                [dict safeSetObject:@(1) forKey:@"status"];
            } else {
                [dict safeSetObject:@(0) forKey:@"status"];
            }
            [dict safeSetObject:@(0) forKey:@"pay_count"];
            [dict safeSetObject:@(0) forKey:@"crowd_count"];
            [messageExtendArray addObject:dict];
        }
    }
    [[LMMessageExtendManager sharedManager] saveBitchMessageExtend:messageExtendArray];

    for (NSDictionary *msgDict in owerMessagesDict.allValues) {
        NSMutableArray *messages = [msgDict valueForKey:@"messages"];
        int unReadCount = [[msgDict valueForKey:@"unReadCount"] intValue];
        [messages sortUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
            ChatMessageInfo *r1 = obj1;
            ChatMessageInfo *r2 = obj2;
            int long long time1 = r1.createTime;
            int long long time2 = r2.createTime;
            if (time1 < time2) {
                return NSOrderedAscending;
            } else if (time1 == time2) {
                return NSOrderedSame;
            } else {
                return NSOrderedDescending;
            }
        }];

        NSMutableArray *pushMessages = [NSMutableArray arrayWithArray:messages];
        while (pushMessages.count > 0) {
            if (pushMessages.count > 20) {
                NSUInteger location = 0;
                NSMutableArray *pushArray = [NSMutableArray arrayWithArray:[pushMessages subarrayWithRange:NSMakeRange(location, 20)]];
                [pushMessages removeObjectsInRange:NSMakeRange(location, 20)];
                [self pushGetBitchNewMessages:pushArray];

                [[MessageDBManager sharedManager] saveBitchMessage:pushArray];
                ChatMessageInfo *lastMsg = [pushArray lastObject];
                if ([[SessionManager sharedManager].chatSession isEqualToString:lastMsg.messageOwer]) {
                    unReadCount = 0;
                }

                [self updataRecentChatLastMessageStatus:lastMsg messageCount:unReadCount withSnapChatTime:lastMsg.snapTime];

            } else {
                NSMutableArray *pushArray = [NSMutableArray arrayWithArray:pushMessages];

                [self pushGetBitchNewMessages:pushArray];

                [[MessageDBManager sharedManager] saveBitchMessage:pushArray];

                ChatMessageInfo *lastMsg = [pushArray lastObject];

                if ([[SessionManager sharedManager].chatSession isEqualToString:lastMsg.messageOwer]) {
                    unReadCount = 0;
                }

                [self updataRecentChatLastMessageStatus:lastMsg messageCount:unReadCount withSnapChatTime:lastMsg.snapTime];

                [pushMessages removeAllObjects];
            }
        }
    }
    return YES;
}

/**
 * Update session last message
 * @param chatMsg
 * @param messageCount
 * @param snapChatTime
 */
- (void)updataRecentChatLastMessageStatus:(ChatMessageInfo *)chatMsg messageCount:(int)messageCount withSnapChatTime:(long long)snapChatTime {
    [[LMConversionManager sharedManager] getNewMessagesWithLastMessage:chatMsg newMessageCount:messageCount type:GJGCChatFriendTalkTypePrivate withSnapChatTime:snapChatTime];
}

- (BOOL)handleMessage:(MessagePost *)msg {
    if (![[RecentChatDBManager sharedManager] getMuteStatusWithIdentifer:msg.pubKey] && [GJGCChatFriendConstans shouldNoticeWithType:msg.msgData.typ]) {
        if (![[SessionManager sharedManager].chatSession isEqualToString:msg.pubKey]) {
            [SystemTool vibrateOrVoiceNoti];
        }
    };
    return [self handleBatchMessages:@[msg]];
}

@end
