//
//  MessageDBManager.m
//  Connect
//
//  Created by MoHuilin on 16/7/29.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "MessageDBManager.h"
#import "LMMessageExtendManager.h"
#import "ConnectTool.h"

@interface MessageDBManager ()

@property(nonatomic, strong) NSMutableArray *trasactionMessageType;

@end


static MessageDBManager *manager = nil;

@implementation MessageDBManager

+ (MessageDBManager *)sharedManager {
    @synchronized (self) {
        if (manager == nil) {
            manager = [[[self class] alloc] init];
        }
    }
    return manager;
}

+ (void)tearDown {
    manager = nil;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized (self) {
        if (manager == nil) {
            manager = [super allocWithZone:zone];
            return manager;
        }
    }
    return nil;
}

- (NSMutableArray *)trasactionMessageType {
    if (!_trasactionMessageType) {
        _trasactionMessageType = @[@(GJGCChatFriendContentTypePayReceipt), @(GJGCChatFriendContentTypeTransfer), @(GJGCChatFriendContentTypeRedEnvelope)].mutableCopy;

    }

    return _trasactionMessageType;
}


- (BOOL)isMessageIsExistWithMessageId:(NSString *)messageId messageOwer:(NSString *)messageOwer {

    if (GJCFStringIsNull(messageOwer) || GJCFStringIsNull(messageId)) {
        return NO;
    }
    NSInteger count = [self getCountFromCurrentDBWithTableName:MessageTable condition:@{@"message_id": messageId, @"message_ower": messageOwer} symbol:0];
    if (count > 0) {
        DDLogError(@"message is existis");
        return YES;
    }

    return NO;

}

- (void)saveTransactionMessage:(NSArray *)messageInfos {

    if (messageInfos.count <= 0) {
        return;
    }
    NSMutableArray *tras = [NSMutableArray array];
    for (ChatMessageInfo *chatMessage in messageInfos) {
        int payCount = 0;
        int crowdCunt = 0;
        if (chatMessage.messageType == GJGCChatFriendContentTypePayReceipt) {
            NSDictionary *dict = chatMessage.message.ext1;
            if ([[dict safeObjectForKey:@"isCrowdfundRceipt"] boolValue]) {
                payCount = chatMessage.payCount;
                crowdCunt = chatMessage.crowdCount;
            }
        }
        int status = 0;
        if (chatMessage.messageType == GJGCChatFriendContentTypeTransfer) {
            if ([SessionManager sharedManager].talkType != GJGCChatFriendTalkTypePostSystem) {
                status = [[LMMessageExtendManager sharedManager] getStatus:chatMessage.message.content];
                if (status == 0) {
                    status = 1;
                }

            }
        }
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic safeSetObject:chatMessage.messageId forKey:@"message_id"];
        [dic safeSetObject:chatMessage.message.content forKey:@"hashid"];
        [dic safeSetObject:@(status) forKey:@"status"];
        [dic safeSetObject:@(chatMessage.payCount) forKey:@"pay_count"];
        [dic safeSetObject:@(chatMessage.crowdCount) forKey:@"crowd_count"];
        [tras addObject:dic];
    }

    [[LMMessageExtendManager sharedManager] saveBitchMessageExtend:tras];
}

- (void)saveMessage:(ChatMessageInfo *)messageInfo {

    NSString *messageString = [messageInfo.message mj_JSONString];
    if (GJCFStringIsNull(messageInfo.messageId) ||
            GJCFStringIsNull(messageInfo.messageOwer) ||
            GJCFStringIsNull(messageString)) {
        return;
    }

    NSString *aad = [[NSString stringWithFormat:@"%d", arc4random() % 100 + 1000] sha1String];
    NSString *iv = [[NSString stringWithFormat:@"%d", arc4random() % 100 + 1000] sha1String];
    NSDictionary *encodeDict = [KeyHandle xtalkEncodeAES_GCM:[[LKUserCenter shareCenter] getLocalGCDEcodePass] data:messageString aad:aad iv:iv];
    NSString *ciphertext = encodeDict[@"encryptedDatastring"];
    NSString *tag = encodeDict[@"tagstring"];

    NSMutableDictionary *content = [NSMutableDictionary dictionary];
    [content safeSetObject:aad forKey:@"aad"];
    [content safeSetObject:iv forKey:@"iv"];
    [content safeSetObject:ciphertext forKey:@"ciphertext"];
    [content safeSetObject:tag forKey:@"tag"];

    NSMutableArray *bitchValues = [NSMutableArray array];
    [bitchValues objectAddObject:@[messageInfo.messageId,
            messageInfo.messageOwer,
            content.mj_JSONString,
            @(messageInfo.sendstatus),
            @(messageInfo.snapTime),
            @(messageInfo.readTime),
            @(messageInfo.state),
            @(messageInfo.createTime)]];
    BOOL result = [self executeUpdataOrInsertWithTable:MessageTable fields:@[@"message_id", @"message_ower", @"content", @"send_status", @"snap_time", @"read_time", @"state", @"createtime"] batchValues:bitchValues];
    if (result) {
        DDLogInfo(@"Save success");
    } else {
        DDLogInfo(@"Save fail");
    }

}


- (void)saveBitchMessage:(NSArray *)messages {
    NSMutableArray *bitchValues = [NSMutableArray array];
    for (ChatMessageInfo *messageInfo in messages) {

        NSString *messageString = [messageInfo.message mj_JSONString];
        if (GJCFStringIsNull(messageInfo.messageId) ||
                GJCFStringIsNull(messageInfo.messageOwer) ||
                GJCFStringIsNull(messageString)) {
            continue;
        }

        NSString *aad = [[NSString stringWithFormat:@"%d", arc4random() % 100 + 1000] sha1String];
        NSString *iv = [[NSString stringWithFormat:@"%d", arc4random() % 100 + 1000] sha1String];
        NSDictionary *encodeDict = [KeyHandle xtalkEncodeAES_GCM:[[LKUserCenter shareCenter] getLocalGCDEcodePass] data:messageString aad:aad iv:iv];
        NSString *ciphertext = encodeDict[@"encryptedDatastring"];
        NSString *tag = encodeDict[@"tagstring"];

        NSMutableDictionary *content = [NSMutableDictionary dictionary];
        [content safeSetObject:aad forKey:@"aad"];
        [content safeSetObject:iv forKey:@"iv"];
        [content safeSetObject:ciphertext forKey:@"ciphertext"];
        [content safeSetObject:tag forKey:@"tag"];

        [bitchValues objectAddObject:@[messageInfo.messageId,
                messageInfo.messageOwer,
                content.mj_JSONString,
                @(messageInfo.sendstatus),
                @(messageInfo.snapTime),
                @(messageInfo.readTime),
                @(messageInfo.state),
                @(messageInfo.createTime)]];
    }

    BOOL result = [self executeUpdataOrInsertWithTable:MessageTable fields:@[@"message_id", @"message_ower", @"content", @"send_status", @"snap_time", @"read_time", @"state", @"createtime"] batchValues:bitchValues];
    if (result) {
        DDLogInfo(@"Save success");
    } else {
        DDLogInfo(@"Save fail");
    }

}


- (MMMessage *)createTransactionMessageWithUserInfo:(AccountInfo *)user hashId:(NSString *)hashId monney:(NSString *)money {

    MMMessage *message = [[MMMessage alloc] init];
    message.type = GJGCChatFriendContentTypeTransfer;
    message.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
    message.message_id = [ConnectTool generateMessageId];
    message.publicKey = user.pub_key;
    message.user_id = user.address;
    message.sendstatus = GJGCChatFriendSendMessageStatusSending;
    message.content = hashId;
    message.ext1 = @{@"amount": @([money doubleValue] * pow(10, 8)),
            @"tips": @""};

    message.senderInfoExt = @{@"username": [[LKUserCenter shareCenter] currentLoginUser].username,
            @"address": [[LKUserCenter shareCenter] currentLoginUser].address,
            @"publickey": [[LKUserCenter shareCenter] currentLoginUser].pub_key,
            @"avatar": [[LKUserCenter shareCenter] currentLoginUser].avatar};

    ChatMessageInfo *messageInfo = [[ChatMessageInfo alloc] init];
    messageInfo.messageId = message.message_id;
    messageInfo.messageType = message.type;
    messageInfo.createTime = message.sendtime;
    messageInfo.messageOwer = user.pub_key;
    messageInfo.sendstatus = GJGCChatFriendSendMessageStatusSending;
    messageInfo.message = message;
    messageInfo.snapTime = 0;
    messageInfo.readTime = 0;


    [self saveMessage:messageInfo];

    return message;

}


- (MMMessage *)createSendtoOtherTransactionMessageWithMessageOwer:(AccountInfo *)ower hashId:(NSString *)hashId monney:(NSString *)money isOutTransfer:(BOOL)isOutTransfer {
    MMMessage *message = [[MMMessage alloc] init];
    message.type = GJGCChatFriendContentTypeTransfer;
    message.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
    message.message_id = [ConnectTool generateMessageId];
    message.publicKey = ower.pub_key;
    message.user_id = ower.address;
    message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
    message.content = hashId;
    message.ext1 = @{@"amount": [[NSDecimalNumber decimalNumberWithString:money] decimalNumberByMultiplyingBy:[[NSDecimalNumber alloc] initWithLong:pow(10, 8)]].stringValue,
            @"tips": @""};
    message.senderInfoExt = @{@"username": [[LKUserCenter shareCenter] currentLoginUser].username,
            @"address": [[LKUserCenter shareCenter] currentLoginUser].address,
            @"publickey": [[LKUserCenter shareCenter] currentLoginUser].pub_key,
            @"avatar": [[LKUserCenter shareCenter] currentLoginUser].avatar};

    message.locationExt = @(isOutTransfer);

    ChatMessageInfo *messageInfo = [[ChatMessageInfo alloc] init];
    messageInfo.messageId = message.message_id;
    messageInfo.messageType = message.type;
    messageInfo.createTime = message.sendtime;
    messageInfo.messageOwer = ower.pub_key;
    messageInfo.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
    messageInfo.message = message;
    messageInfo.snapTime = 0;
    messageInfo.readTime = 0;

    [self saveMessage:messageInfo];

    return message;
}


- (MMMessage *)createSendtoMyselfTransactionMessageWithMessageOwer:(AccountInfo *)messageOwer hashId:(NSString *)hashId monney:(NSString *)money isOutTransfer:(BOOL)isOutTransfer {


    MMMessage *message = [[MMMessage alloc] init];
    message.type = GJGCChatFriendContentTypeTransfer;
    message.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
    message.message_id = [ConnectTool generateMessageId];
    message.publicKey = messageOwer.pub_key;
    message.user_id = [[LKUserCenter shareCenter] currentLoginUser].address;
    message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
    message.content = hashId;
    message.ext1 = @{@"amount": [[NSDecimalNumber decimalNumberWithString:money] decimalNumberByMultiplyingBy:[[NSDecimalNumber alloc] initWithLong:pow(10, 8)]].stringValue,
            @"tips": @""};
    message.senderInfoExt = @{@"username": messageOwer.username,
            @"address": messageOwer.address,
            @"publickey": messageOwer.pub_key,
            @"avatar": messageOwer.avatar};

    message.locationExt = @(isOutTransfer);
    ChatMessageInfo *messageInfo = [[ChatMessageInfo alloc] init];
    messageInfo.messageId = message.message_id;
    messageInfo.messageType = message.type;
    messageInfo.createTime = message.sendtime;
    messageInfo.messageOwer = messageOwer.pub_key;
    messageInfo.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
    messageInfo.message = message;
    messageInfo.snapTime = 0;
    messageInfo.readTime = 0;

    [self saveMessage:messageInfo];

    return message;

}


- (void)updateMessageSendStatus:(GJGCChatFriendSendMessageStatus)sendStatus withMessageId:(NSString *)messageId messageOwer:(NSString *)messageOwer {
    if (GJCFStringIsNull(messageId) || GJCFStringIsNull(messageOwer)) {
        return;
    }

    [self updateTableName:MessageTable fieldsValues:@{@"send_status": @(sendStatus)} conditions:@{@"message_id": messageId, @"message_ower": messageOwer}];
}

- (BOOL)deleteMessageByMessageId:(NSString *)messageId messageOwer:(NSString *)messageOwer {
    if (GJCFStringIsNull(messageId) || GJCFStringIsNull(messageId)) {
        return NO;
    }
    BOOL result = [self deleteTableName:MessageTable conditions:@{@"message_id": messageId, @"message_ower": messageOwer}];

    if (result) {
        DDLogInfo(@"---》delete success");
    } else {
        DDLogError(@"---》delete fail");
    }
    return result;
}

- (void)deleteSnapOutTimeMessageByMessageOwer:(NSString *)messageOwer {

}

- (void)updataMessage:(ChatMessageInfo *)messageInfo {
    [self deleteMessageByMessageId:messageInfo.messageId messageOwer:messageInfo.messageOwer];
    [self saveMessage:messageInfo];
}

- (void)updateMessageTimeWithMessageOwer:(NSString *)messageOwer messageId:(NSString *)messageId {
    if (GJCFStringIsNull(messageId) || GJCFStringIsNull(messageOwer)) {
        return;
    }
    long long readTime = (long long) ([[NSDate date] timeIntervalSince1970] * 1000);
    BOOL result = [self executeSql:[NSString stringWithFormat:@"UPDATE %@ SET createtime = %lld WHERE message_id = '%@' AND message_ower = '%@'", MessageTable, readTime, messageId, messageOwer]];
    if (result) {
        DDLogInfo(@"---》更新消息时间成功");
    } else {
        DDLogError(@"---》更新消息时间失败");
    }
}

- (void)updateMessageReadTimeWithMsgID:(NSString *)messageId messageOwer:(NSString *)messageOwer {

    if (GJCFStringIsNull(messageId) || GJCFStringIsNull(messageOwer)) {
        return;
    }

    long long readTime = (long long) ([[NSDate date] timeIntervalSince1970] * 1000);

    BOOL result = [self executeSql:[NSString stringWithFormat:@"UPDATE %@ SET read_time = %lld WHERE message_id = '%@' AND read_time == 0 AND message_ower = '%@'", MessageTable, readTime, messageId, messageOwer]];

    if (result) {
        DDLogInfo(@"---》success");
    } else {
        DDLogError(@"---》fail");
    }
}

- (void)updateAudioMessageWithMsgID:(NSString *)messageId messageOwer:(NSString *)messageOwer {

    if (GJCFStringIsNull(messageId) || GJCFStringIsNull(messageOwer)) {
        return;
    }

    long long readTime = (long long) ([[NSDate date] timeIntervalSince1970] * 1000);

    BOOL result = [self executeSql:[NSString stringWithFormat:@"UPDATE %@ SET read_time = %lld,state = 2 WHERE message_id = '%@' AND read_time == 0 AND message_ower = '%@'", MessageTable, readTime, messageId, messageOwer]];

    if (result) {
        DDLogInfo(@"---》update read statue success");
    } else {
        DDLogError(@"---》update read statue failed");
    }
}

- (void)updateAudioMessageReadCompleteWithMsgID:(NSString *)messageId messageOwer:(NSString *)messageOwer {

    if (GJCFStringIsNull(messageId) || GJCFStringIsNull(messageOwer)) {
        return;
    }
    BOOL result = [self executeSql:[NSString stringWithFormat:@"UPDATE %@ SET state = 2 WHERE message_id = '%@' AND message_ower = '%@'", MessageTable, messageId, messageOwer]];
    if (result) {
        DDLogInfo(@"---》update read statue success");
    } else {
        DDLogError(@"---》update read statue failed");
    }
}


- (NSInteger)getReadTimeByMessageId:(NSString *)messageId messageOwer:(NSString *)messageOwer {

    if (GJCFStringIsNull(messageId) || GJCFStringIsNull(messageOwer)) {
        return 0;
    }

    NSDictionary *dictD = [[self getDatasFromTableName:MessageTable conditions:@{@"message_id": messageId, @"message_ower": messageOwer} fields:@[@"read_time"]] lastObject];
    return [[dictD safeObjectForKey:@"read_time"] integerValue];

}


- (ChatMessageInfo *)getMessageInfoByMessageid:(NSString *)messageid messageOwer:(NSString *)messageOwer {

    if (GJCFStringIsNull(messageid) || GJCFStringIsNull(messageOwer)) {
        return nil;
    }

    NSDictionary *temD = [[self getDatasFromTableName:MessageTable conditions:@{@"message_id": messageid, @"message_ower": messageOwer} fields:@[@"id", @"message_id", @"state", @"message_ower", @"createtime", @"send_status", @"read_time", @"snap_time", @"content"]] lastObject];

    if (temD) {
        ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
        chatMessage.ID = [[temD safeObjectForKey:@"id"] integerValue];
        chatMessage.messageOwer = [temD safeObjectForKey:@"message_ower"];
        chatMessage.messageId = [temD safeObjectForKey:@"message_id"];
        chatMessage.createTime = [[temD safeObjectForKey:@"createtime"] integerValue];
        chatMessage.readTime = [[temD safeObjectForKey:@"read_time"] integerValue];
        chatMessage.snapTime = [[temD safeObjectForKey:@"snap_time"] integerValue];
        chatMessage.sendstatus = [[temD safeObjectForKey:@"send_status"] integerValue];
        chatMessage.messageType = [[temD safeObjectForKey:@"message_type"] integerValue];
        chatMessage.state = [[temD safeObjectForKey:@"state"] intValue];
        if (chatMessage.state == 0) {
            chatMessage.state = chatMessage.readTime > 0 ? 1 : 0;
        }

        NSDictionary *contentDict = [[temD safeObjectForKey:@"content"] mj_JSONObject];
        NSString *aad = [contentDict safeObjectForKey:@"aad"];
        NSString *iv = [contentDict safeObjectForKey:@"iv"];
        NSString *tag = [contentDict safeObjectForKey:@"tag"];
        NSString *ciphertext = [contentDict safeObjectForKey:@"ciphertext"];
        NSString *messageString = [KeyHandle xtalkDecodeAES_GCM:[[LKUserCenter shareCenter] getLocalGCDEcodePass] data:ciphertext aad:aad iv:iv tag:tag];

        chatMessage.message = [MMMessage mj_objectWithKeyValues:messageString];
        chatMessage.message.sendstatus = chatMessage.sendstatus;
        chatMessage.messageType = chatMessage.message.type;
        chatMessage.message.isRead = chatMessage.readTime > 0;

        return chatMessage;
    }

    return nil;
}


- (GJGCChatFriendSendMessageStatus)getMessageSendStatusByMessageid:(NSString *)messageid messageOwer:(NSString *)messageOwer {
    
    if (GJCFStringIsNull(messageid) || GJCFStringIsNull(messageOwer)) {
        return GJGCChatFriendSendMessageStatusFaild;
    }
    NSDictionary *temD = [[self getDatasFromTableName:MessageTable conditions:@{@"message_id": messageid, @"message_ower": messageOwer} fields:@[@"send_status"]] lastObject];
    
    if (temD) {
        return [[temD safeObjectForKey:@"send_status"] integerValue];
    }
    return GJGCChatFriendSendMessageStatusFaild;
}



- (NSArray *)getAllMessagesWithMessageOwer:(NSString *)messageOwer {

    if (GJCFStringIsNull(messageOwer)) {
        return @[];
    }

    NSArray *messages = [self getDatasFromTableName:MessageTable conditions:@{@"message_ower": messageOwer} fields:@[@"id", @"message_id", @"message_ower", @"state", @"createtime", @"read_time", @"send_status", @"snap_time", @"content"]];
    if (messages.count <= 0) {
        return @[];
    }

    NSMutableArray *chatMessages = [NSMutableArray array];
    for (NSDictionary *temD in messages) {
        ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
        chatMessage.ID = [[temD safeObjectForKey:@"id"] integerValue];
        chatMessage.messageOwer = [temD safeObjectForKey:@"message_ower"];
        chatMessage.messageId = [temD safeObjectForKey:@"message_id"];
        chatMessage.createTime = [[temD safeObjectForKey:@"createtime"] integerValue];
        chatMessage.readTime = [[temD safeObjectForKey:@"read_time"] integerValue];
        chatMessage.snapTime = [[temD safeObjectForKey:@"snap_time"] integerValue];
        chatMessage.sendstatus = [[temD safeObjectForKey:@"send_status"] integerValue];
        chatMessage.state = [[temD safeObjectForKey:@"state"] intValue];
        if (chatMessage.state == 0) {
            chatMessage.state = chatMessage.readTime > 0 ? 1 : 0;
        }

        NSDictionary *contentDict = [[temD safeObjectForKey:@"content"] mj_JSONObject];
        NSString *aad = [contentDict safeObjectForKey:@"aad"];
        NSString *iv = [contentDict safeObjectForKey:@"iv"];
        NSString *tag = [contentDict safeObjectForKey:@"tag"];
        NSString *ciphertext = [contentDict safeObjectForKey:@"ciphertext"];
        NSString *messageString = [KeyHandle xtalkDecodeAES_GCM:[[LKUserCenter shareCenter] getLocalGCDEcodePass] data:ciphertext aad:aad iv:iv tag:tag];

        chatMessage.message = [MMMessage mj_objectWithKeyValues:messageString];
        chatMessage.message.sendstatus = chatMessage.sendstatus;
        chatMessage.message.isRead = chatMessage.readTime > 0;
        chatMessage.messageType = chatMessage.message.type;
        [chatMessages objectAddObject:chatMessage];
    }

    return chatMessages.copy;
}

- (long long int)messageCountWithMessageOwer:(NSString *)messageOwer {
    if (GJCFStringIsNull(messageOwer)) {
        return 0;
    }
    return [self getCountFromCurrentDBWithTableName:MessageTable condition:@{@"message_ower": messageOwer} symbol:0];
}

- (void)deleteAllMessageByMessageOwer:(NSString *)messageOwer {

    if (GJCFStringIsNull(messageOwer)) {
        return;
    }
    [self deleteTableName:MessageTable conditions:@{@"message_ower": messageOwer}];
}

- (void)deleteAllMessages {
    [self deleteTableName:MessageTable conditions:nil];
}

- (NSArray *)getMessagesWithMessageOwer:(NSString *)messageOwer Limit:(int)limit beforeTime:(long long int)time messageAutoID:(NSInteger)autoMsgid {

    if (GJCFStringIsNull(messageOwer)) {
        return @[];
    }

    NSMutableDictionary *condition = @{}.mutableCopy;
    [condition safeSetObject:messageOwer forKey:@"message_ower ="];
    if (time > 0) {
        [condition safeSetObject:@(time) forKey:@"createtime <= "];
        [condition safeSetObject:@(autoMsgid) forKey:@"id < "];
    }

    NSArray *messages = [self getDatasFromTableName:MessageTable fields:@[@"id", @"message_id", @"state", @"message_ower", @"createtime", @"read_time", @"send_status", @"snap_time", @"content"] conditions:condition limit:limit orderBy:@"createtime" sortWay:2];

    if (messages.count <= 0) {
        return @[];
    }

    NSMutableArray *chatMessages = [NSMutableArray array];
    for (NSDictionary *temD in messages) {
        ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
        chatMessage.ID = [[temD safeObjectForKey:@"id"] integerValue];
        chatMessage.messageOwer = [temD safeObjectForKey:@"message_ower"];
        chatMessage.messageId = [temD safeObjectForKey:@"message_id"];
        chatMessage.createTime = [[temD safeObjectForKey:@"createtime"] integerValue];
        chatMessage.readTime = [[temD safeObjectForKey:@"read_time"] integerValue];
        chatMessage.snapTime = [[temD safeObjectForKey:@"snap_time"] integerValue];
        chatMessage.sendstatus = [[temD safeObjectForKey:@"send_status"] integerValue];
        chatMessage.state = [[temD safeObjectForKey:@"state"] intValue];
        if (chatMessage.state == 0) {
            chatMessage.state = chatMessage.readTime > 0 ? 1 : 0;
        }

        NSDictionary *contentDict = [[temD safeObjectForKey:@"content"] mj_JSONObject];
        NSString *aad = [contentDict safeObjectForKey:@"aad"];
        NSString *iv = [contentDict safeObjectForKey:@"iv"];
        NSString *tag = [contentDict safeObjectForKey:@"tag"];
        NSString *ciphertext = [contentDict safeObjectForKey:@"ciphertext"];
        NSString *messageString = [KeyHandle xtalkDecodeAES_GCM:[[LKUserCenter shareCenter] getLocalGCDEcodePass] data:ciphertext aad:aad iv:iv tag:tag];
        MMMessage *msg = [MMMessage mj_objectWithKeyValues:messageString];
        msg.sendstatus = chatMessage.sendstatus;
        msg.isRead = chatMessage.readTime > 0;
        chatMessage.message = msg;
        chatMessage.messageType = chatMessage.message.type;
        [chatMessages objectAddObject:chatMessage];
    }

    return chatMessages.copy;
}

- (NSArray *)getMessagesWithMessageOwer:(NSString *)messageOwer Limit:(int)limit beforeTime:(long long int)time {

    if (GJCFStringIsNull(messageOwer)) {
        return @[];
    }

    NSMutableDictionary *condition = @{}.mutableCopy;
    [condition safeSetObject:messageOwer forKey:@"message_ower ="];
    if (time > 0) {
        [condition safeSetObject:@(time) forKey:@"createtime <= "];
    }

    NSArray *messages = [self getDatasFromTableName:MessageTable fields:@[@"id", @"state", @"message_id", @"message_ower", @"createtime", @"read_time", @"send_status", @"snap_time", @"content"] conditions:condition limit:limit orderBy:@"createtime" sortWay:2];

    if (messages.count <= 0) {
        return @[];
    }

    NSMutableArray *chatMessages = [NSMutableArray array];
    for (NSDictionary *temD in messages) {
        ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
        chatMessage.ID = [[temD safeObjectForKey:@"auto_incrementid"] integerValue];
        chatMessage.messageOwer = [temD safeObjectForKey:@"message_ower"];
        chatMessage.messageId = [temD safeObjectForKey:@"message_id"];
        chatMessage.createTime = [[temD safeObjectForKey:@"createtime"] integerValue];
        chatMessage.readTime = [[temD safeObjectForKey:@"read_time"] integerValue];
        chatMessage.snapTime = [[temD safeObjectForKey:@"snap_time"] integerValue];
        chatMessage.sendstatus = [[temD safeObjectForKey:@"send_status"] integerValue];
        chatMessage.state = [[temD safeObjectForKey:@"state"] intValue];
        if (chatMessage.state == 0) {
            chatMessage.state = chatMessage.readTime > 0 ? 1 : 0;
        }

        NSDictionary *contentDict = [[temD safeObjectForKey:@"content"] mj_JSONObject];
        NSString *aad = [contentDict safeObjectForKey:@"aad"];
        NSString *iv = [contentDict safeObjectForKey:@"iv"];
        NSString *tag = [contentDict safeObjectForKey:@"tag"];
        NSString *ciphertext = [contentDict safeObjectForKey:@"ciphertext"];
        NSString *messageString = [KeyHandle xtalkDecodeAES_GCM:[[LKUserCenter shareCenter] getLocalGCDEcodePass] data:ciphertext aad:aad iv:iv tag:tag];
        MMMessage *msg = [MMMessage mj_objectWithKeyValues:messageString];
        msg.sendstatus = chatMessage.sendstatus;
        msg.isRead = chatMessage.readTime > 0;
        chatMessage.message = msg;
        chatMessage.messageType = chatMessage.message.type;
        [chatMessages objectAddObject:chatMessage];
    }

    return chatMessages.copy;
}


- (void)createTipMessageWithMessageOwer:(NSString *)messageOwer isnoRelationShipType:(BOOL)isnoRelationShipType content:(NSString *)content{
    GJGCChatFriendContentType type = GJGCChatFriendContentTypeStatusTip;
    if (isnoRelationShipType) {
        type = GJGCChatFriendContentTypeNoRelationShipTip;
    }
    
    ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
    chatMessage.messageId = [ConnectTool generateMessageId];
    chatMessage.messageOwer = messageOwer;
    chatMessage.messageType = type;
    chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
    chatMessage.createTime = (long long) ([[NSDate date] timeIntervalSince1970] * 1000);
    MMMessage *message = [[MMMessage alloc] init];
    message.type = type;
    message.content = content;
    message.sendtime = chatMessage.createTime;
    message.message_id = chatMessage.messageId;
    message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
    chatMessage.message = message;
    [self saveMessage:chatMessage];
}

@end
