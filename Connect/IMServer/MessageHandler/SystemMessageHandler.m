//
//  SystemMessageHandler.m
//  Connect
//
//  Created by MoHuilin on 16/9/27.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "SystemMessageHandler.h"
#import "LMMessageValidationTool.h"
#import "LMBaseSSDBManager.h"
#import "SystemTool.h"
#import "LMConversionManager.h"
#import "GroupDBManager.h"
#import "LMMessageExtendManager.h"

#define kSystemIdendifier @"connect"

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
        MMMessage *messageInfo = [self packSendMessage:sysMsg];
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

    ChatMessageInfo *fda = [pushMessages firstObject];

    [[MessageDBManager sharedManager] updateMessageTimeWithMessageOwer:@"connect" messageId:fda.messageId];

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
        if (![[[SessionManager sharedManager].chatSession lowercaseString] isEqualToString:@"connect"]) {
            [SystemTool vibrateOrVoiceNoti];
        }
        return [self handleBatchMessages:@[sysMsg]];
    }
    return NO;
}


- (MMMessage *)packSendMessage:(MSMessage *)sysMsg {
    MMMessage *message = [[MMMessage alloc] init];
    message.user_name = @"connect";
    message.type = sysMsg.category;
    message.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
    message.message_id = sysMsg.msgId;
    message.publicKey = [[LKUserCenter shareCenter] currentLoginUser].pub_key;
    message.user_id = [[LKUserCenter shareCenter] currentLoginUser].address;
    message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
    switch (sysMsg.category) {
        case GJGCChatFriendContentTypeText: {
            TextMessage *textMsg = [TextMessage parseFromData:sysMsg.body error:nil];
            message.content = textMsg.content;
        }
            break;
        case GJGCChatFriendContentTypeAudio: {

            Voice *voiceMsg = [Voice parseFromData:sysMsg.body error:nil];
            message.content = voiceMsg.URL;
            //duration
            message.size = (int) voiceMsg.duration * 50;
        }
            break;
        case GJGCChatFriendContentTypeImage: {
            Image *imageMsg = [Image parseFromData:sysMsg.body error:nil];
            message.content = imageMsg.URL;
            message.imageOriginWidth = AUTO_WIDTH(200);
            message.imageOriginHeight = AUTO_WIDTH(250);
            if ([imageMsg.width floatValue] > 0) {
                message.imageOriginWidth = [imageMsg.width floatValue];
            }
            if ([imageMsg.height floatValue] > 0) {
                message.imageOriginHeight = [imageMsg.height floatValue];
            }
        }
            break;
        case GJGCChatFriendContentTypeVideo: {
            message.content = @"封面url";
            message.url = @"视频url";
        }
            break;
        case GJGCChatFriendContentTypeMapLocation: {
            if (message.type == GJGCChatFriendContentTypeMapLocation) {
                message.locationExt = @{@"locationLatitude": @(1),
                        @"locationLongitude": @(2),
                        @"address": @"address"};
            }

        }
            break;
        case GJGCChatFriendContentTypeGif: {
            message.content = @"1";
        }
            break;
        case GJGCChatFriendContentTypeTransfer: {
            /*
             message.ext1 = @(messageContent.amount);
             message.ext = messageContent.tipNote;
             message.ext = messageContent.tipNote;
             */
            SystemTransferPackage *transfer = [SystemTransferPackage parseFromData:sysMsg.body error:nil];
            message.content = transfer.txid;
            message.ext = transfer.tips;
            message.ext1 = @{@"amount": @(transfer.amount),
                    @"tips": @""};
            message.locationExt = transfer.sender;


            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict safeSetObject:message.message_id forKey:@"message_id"];
            [dict safeSetObject:message.content forKey:@"hashid"];
            [dict safeSetObject:@(1) forKey:@"status"];
            [dict safeSetObject:@(0) forKey:@"pay_count"];
            [dict safeSetObject:@(0) forKey:@"crowd_count"];
            [[LMMessageExtendManager sharedManager] saveBitchMessageExtendDict:dict];

        }
            break;
        case GJGCChatFriendContentTypeRedEnvelope: //luckypackage
        {
            NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary]; //CFBundleIdentifier
            NSString *versionNum = [infoDict objectForKey:@"CFBundleShortVersionString"];
            int currentVer = [[versionNum stringByReplacingOccurrencesOfString:@"." withString:@""] intValue];
            if (currentVer < 6) {
                message.type = GJGCChatFriendContentTypeNotFound;
            } else {
                SystemRedPackage *redPackMsg = [SystemRedPackage parseFromData:sysMsg.body error:nil];
                message.content = redPackMsg.hashId;
                message.ext1 = redPackMsg.tips;
            }
        }
            break;
        case 101: //group reviewed
        {
            Reviewed *reviewed = [Reviewed parseFromData:sysMsg.body error:nil];
            message.ext1 = @{@"username": reviewed.userInfo.username,
                    @"avatar": reviewed.userInfo.avatar,
                    @"pubKey": reviewed.userInfo.pubKey,
                    @"identifier": reviewed.identifier,
                    @"category": @(reviewed.category),
                    @"tips": reviewed.tips ? reviewed.tips : @"",
                    @"verificationCode": reviewed.verificationCode ? reviewed.verificationCode : @"",
                    @"groupname": reviewed.name,
                    @"source": @(reviewed.source)};
            message.type = GJGCChatApplyToJoinGroup;


            if (!GJCFStringIsNull(reviewed.verificationCode)) {
                LMBaseSSDBManager *ssdbManager = [LMBaseSSDBManager open:@"system_message"];

                NSData *applyMessageData = nil;
                [ssdbManager get:reviewed.verificationCode data:&applyMessageData];
                if (applyMessageData) {
                    GroupApplyMessage *applyMessage = [GroupApplyMessage parseFromData:applyMessageData error:nil];

                    BOOL isExist = [[MessageDBManager sharedManager] isMessageIsExistWithMessageId:applyMessage.messageId messageOwer:@"connect"];
                    if (isExist) {
                        [GCDQueue executeInMainQueue:^{
                            SendNotify(@"deleteGroupReviewedMessageNotification", applyMessage.messageId);
                        }];

                        [[MessageDBManager sharedManager] deleteMessageByMessageId:applyMessage.messageId messageOwer:@"connect"];
                    }
                    GroupApplyChange *applyChange = [GroupApplyChange parseFromData:applyMessage.applyData error:nil];
                    if (reviewed.tips && ![applyChange.tipsHistoryArray containsObject:reviewed.tips]) {
                        [applyChange.tipsHistoryArray objectAddObject:reviewed.tips];
                    }

                    applyMessage = [GroupApplyMessage new];
                    applyMessage.applyData = applyChange.data;
                    applyMessage.messageId = message.message_id;
                    [ssdbManager set:reviewed.verificationCode data:applyMessage.data];
                } else {
                    GroupApplyChange *applyChange = [GroupApplyChange new];
                    applyChange.verificationCode = reviewed.verificationCode;
                    applyChange.source = reviewed.source;
                    if (reviewed.tips) {
                        applyChange.tipsHistoryArray = @[reviewed.tips].mutableCopy;
                    }
                    GroupApplyMessage *applyMessage = [GroupApplyMessage new];
                    applyMessage.applyData = applyChange.data;
                    applyMessage.messageId = message.message_id;
                    [ssdbManager set:applyChange.verificationCode data:applyMessage.data];
                }
                [ssdbManager close];
            }
        }
            break;
        case 102: //announcement
        {
            Announcement *announcement = [Announcement parseFromData:sysMsg.body error:nil];
            if (GJCFStringIsNull(announcement.title) || GJCFStringIsNull(announcement.desc)) {
                return nil;
            }
            NSMutableDictionary *ext1 = @{}.mutableCopy;
            [ext1 setObject:announcement.title forKey:@"title"];
            [ext1 setObject:announcement.desc forKey:@"content"];
            [ext1 setObject:@(announcement.category) forKey:@"category"];
            if (GJCFCheckObjectNull(@(announcement.createdAt))) {
                [ext1 setObject:@([[NSDate date] timeIntervalSince1970]) forKey:@"createAt"];
            } else {
                [ext1 setObject:@(announcement.createdAt) forKey:@"createAt"];
            }
            if (!GJCFStringIsNull(announcement.URL)) {
                [ext1 setObject:announcement.URL forKey:@"jumpUrl"];
            }
            if (!GJCFStringIsNull(announcement.coversURL)) {
                [ext1 setObject:announcement.coversURL forKey:@"coversURL"];
            }
            message.ext1 = ext1;
        }
            break;
        case 103://luckypackage garb tips
        {
            SystemRedpackgeNotice *repackNotict = [SystemRedpackgeNotice parseFromData:sysMsg.body error:nil];
            message.content = repackNotict.receiver.username;
            message.ext1 = @{@"type": @"redpackge",
                    @"hashid": repackNotict.hashid};
            message.type = GJGCChatFriendContentTypeStatusTip;
        }
            break;

        case 104://group apply refuse or accepy tips
        {
            ReviewedResponse *repackNotict = [ReviewedResponse parseFromData:sysMsg.body error:nil];
            NSString *contentMessage = [NSString stringWithFormat:LMLocalizedString(@"Link You apply to join rejected", nil), repackNotict.name];
            if (repackNotict.success) {
                contentMessage = [NSString stringWithFormat:LMLocalizedString(@"Link You apply to join has passed", nil), repackNotict.name];
            }
            LMBaseSSDBManager *ssdbManager = [LMBaseSSDBManager open:@"system_message"];
            [ssdbManager set:repackNotict.identifier data:repackNotict.data];
            [ssdbManager close];
            message.ext1 = @{@"type": @"groupreviewed",
                    @"message": contentMessage};
            message.type = GJGCChatFriendContentTypeStatusTip;
        }
            break;
        case 105://phone number change
        {
            UpdateMobileBind *nameBind = [UpdateMobileBind parseFromData:sysMsg.body error:nil];
            message.type = GJGCChatFriendContentTypeText;
            message.content = [NSString stringWithFormat:LMLocalizedString(@"Chat Your Connect ID will no longer be linked with mobile number", nil), nameBind.username];

            [[LKUserCenter shareCenter] currentLoginUser].bondingPhone = @"";
            [[LKUserCenter shareCenter] updateUserInfo:[[LKUserCenter shareCenter] currentLoginUser]];
        }
            break;
        case 106: //dismiss group note
        {
            RemoveGroup *dismissGroup = [RemoveGroup parseFromData:sysMsg.body error:nil];
            NSString *tips = [NSString stringWithFormat:LMLocalizedString(@"Chat Group has been disbanded", nil), dismissGroup.name];
            message.ext1 = @{@"type": @"groupdismiss",
                    @"message": tips};


            if ([[SessionManager sharedManager].chatSession isEqualToString:dismissGroup.groupId]) {
                SendNotify(ConnnectGroupDismissNotification, dismissGroup.groupId)
            }
            message.type = GJGCChatFriendContentTypeStatusTip;

            [[LMConversionManager sharedManager] deleteConversation:[[SessionManager sharedManager] getRecentChatWithIdentifier:dismissGroup.groupId]];

            [[GroupDBManager sharedManager] deletegroupWithGroupId:dismissGroup.groupId];
            //clear group avatar
        }
            break;
        case 200: {//outer address transfer to self
            AddressNotify *addressNot = [AddressNotify parseFromData:sysMsg.body error:nil];
            message.content = addressNot.txId;
            message.ext1 = @{@"amount": @(addressNot.amount),
                    @"tips": @""};
            message.type = GJGCChatFriendContentTypeTransfer;
        }
            break;
        default:
            break;
    }
    return message;
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
