//
//  SystemMessageHandler.m
//  Connect
//
//  Created by MoHuilin on 16/9/27.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "SystemMessageHandler.h"
#import "LMMessageValidationTool.h"
#import "SystemTool.h"
#import "LMConversionManager.h"
#import "LMMessageAdapter.h"

@implementation SystemMessageHandler

+ (SystemMessageHandler *)instance {
    static SystemMessageHandler *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!m) {
            m = [[SystemMessageHandler alloc] init];
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

- (BOOL)handleBatchMessages:(NSArray *)sysMsgs {
    NSMutableArray *messages = [NSMutableArray array];
    NSMutableArray *groupReviewArray = [NSMutableArray array];
    for (MSMessage *sysMsg in sysMsgs) {
        //package message
        MMMessage *messageInfo = [LMMessageAdapter packSystemMessage:sysMsg];
        if (![LMMessageValidationTool checkMessageValidata:messageInfo messageType:MessageTypeSystem]) {
            continue;
        }
        messageInfo.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
        ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
        chatMessage.messageId = sysMsg.msgId;
        chatMessage.createTime = (NSInteger) messageInfo.sendtime;
        chatMessage.messageType = messageInfo.type;
        chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
        chatMessage.readTime = 0;
        chatMessage.message = messageInfo;
        chatMessage.messageOwer = kSystemIdendifier;
        if (chatMessage.messageType == GJGCChatApplyToJoinGroup) {
            [groupReviewArray objectAddObject:chatMessage];
        } else {
            [messages objectAddObject:chatMessage];
        }
    }

    if (groupReviewArray.count) {
        if (groupReviewArray.count == 1) {
            [messages addObjectsFromArray:groupReviewArray];
        } else {

            [groupReviewArray sortUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
                ChatMessageInfo *r1 = obj1;
                ChatMessageInfo *r2 = obj2;
                int long long time1 = r1.createTime;
                int long long time2 = r2.createTime;
                if (time1 > time2) {
                    return NSOrderedAscending;
                } else if (time1 == time2) {
                    return NSOrderedSame;
                } else {
                    return NSOrderedDescending;
                }
            }];

            NSMutableDictionary *verificationCodeMessage = [NSMutableDictionary dictionary];
            for (ChatMessageInfo *msg in groupReviewArray) {
                NSString *verificationCode = [msg.message.ext1 valueForKey:@"verificationCode"];
                if (verificationCode) {
                    [verificationCodeMessage setValue:msg forKey:verificationCode];
                }
            }

            [messages addObjectsFromArray:verificationCodeMessage.allValues];
        }
    }


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
            NSInteger location = 0;
            NSMutableArray *pushArray = [NSMutableArray arrayWithArray:[pushMessages subarrayWithRange:NSMakeRange(location, 20)]];
            [pushMessages removeObjectsInRange:NSMakeRange(location, 20)];
            [self pushGetBitchNewMessages:pushArray];

            [[MessageDBManager sharedManager] saveBitchMessage:pushArray];

            ChatMessageInfo *lastMsg = [pushArray lastObject];
            int temUnReadCount = (int) pushArray.count;
            if ([[SessionManager sharedManager].chatSession isEqualToString:kSystemIdendifier]) {
                temUnReadCount = 0;
            }

            [self updataRecentChatLastMessageStatus:lastMsg messageCount:temUnReadCount];

        } else {
            NSMutableArray *pushArray = [NSMutableArray arrayWithArray:pushMessages];

            [self pushGetBitchNewMessages:pushArray];

            [[MessageDBManager sharedManager] saveBitchMessage:pushArray];

            ChatMessageInfo *lastMsg = [pushArray lastObject];
            int temUnReadCount = (int) pushArray.count;
            if ([[SessionManager sharedManager].chatSession isEqualToString:kSystemIdendifier]) {
                temUnReadCount = 0;
            }

            [self updataRecentChatLastMessageStatus:lastMsg messageCount:temUnReadCount];

            [pushMessages removeAllObjects];
        }
    }

    ChatMessageInfo *lastMessage = [pushMessages firstObject];

    [[MessageDBManager sharedManager] updateMessageTimeWithMessageOwer:kSystemIdendifier messageId:lastMessage.messageId];

    return YES;
}


/**
 *  Update session last message
 *
 *  @param chatMsg
 *  @param messageCount
 */
- (void)updataRecentChatLastMessageStatus:(ChatMessageInfo *)chatMsg messageCount:(int)messageCount {
    [[LMConversionManager sharedManager] getNewMessagesWithLastMessage:chatMsg newMessageCount:messageCount type:GJGCChatFriendTalkTypePostSystem withSnapChatTime:0];
}


- (BOOL)handleMessage:(MSMessage *)sysMsg {
    if (sysMsg) {
        if (![[[SessionManager sharedManager].chatSession lowercaseString] isEqualToString:kSystemIdendifier]) {
            [SystemTool vibrateOrVoiceNoti];
        }
        return [self handleBatchMessages:@[sysMsg]];
    }
    return NO;
}

- (void)addGetNewMessageObserver:(id <SystemMessageHandlerGetNewMessage>)oberver {
    [self.getNewMessageObservers addObject:oberver];
}

- (void)removeGetNewMessageObserver:(id <SystemMessageHandlerGetNewMessage>)oberver {
    [self.getNewMessageObservers removeObject:oberver];
}

- (void)pushGetBitchNewMessages:(NSArray *)messages {
    if ([[SessionManager sharedManager].chatSession isEqualToString:kSystemIdendifier]) {
        for (id <SystemMessageHandlerGetNewMessage> ob in self.getNewMessageObservers) {
            if ([ob respondsToSelector:@selector(getNewSystemMessages:)]) {
                [GCDQueue executeInMainQueue:^{
                    [ob getNewSystemMessages:messages];
                }];
            }
        }
    }
}

@end
