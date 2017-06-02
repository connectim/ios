//
//  GJGCChatFriendDataSourceManager.m
//  Connect
//
//  Created by KivenLin on 14-11-12.
//  Copyright (c) 2014年 ConnectSoft. All rights reserved.
//

#import "GJGCChatFriendDataSourceManager.h"
#import "NSString+DictionaryValue.h"
#import "GJCFFileDownloadManager.h"

@interface GJGCChatFriendDataSourceManager () {

}

@end

@implementation GJGCChatFriendDataSourceManager

- (void)dealloc {

}

- (instancetype)initWithTalk:(GJGCChatFriendTalkModel *)talk withDelegate:(id <GJGCChatDetailDataSourceManagerDelegate>)aDelegate {
    if (self = [super initWithTalk:talk withDelegate:aDelegate]) {
        self.title = talk.name;
        [self readLastMessagesFromDB];
    }
    return self;
}

- (GJGCChatFriendContentModel *)addMMMessage:(ChatMessageInfo *)chatMessage {

    MMMessage *aMessage = chatMessage.message;
    [self.orginMessageListArray objectAddObject:aMessage];

    GJGCChatFriendContentModel *chatContentModel = [[GJGCChatFriendContentModel alloc] init];
    chatContentModel.contentType = aMessage.type;
    chatContentModel.autoMsgid = chatMessage.ID;
    chatContentModel.gifLocalId = aMessage.content;
    chatContentModel.originTextMessage = aMessage.content;
    chatContentModel.baseMessageType = GJGCChatBaseMessageTypeChatMessage;
    chatContentModel.userName = aMessage.user_name;
    chatContentModel.sendStatus = aMessage.sendstatus;
    chatContentModel.sendTime = aMessage.sendtime;
    chatContentModel.publicKey = aMessage.publicKey;
    chatContentModel.localMsgId = aMessage.message_id;
    chatContentModel.talkType = self.taklInfo.talkType;
    chatContentModel.isRead = chatMessage.state > 0;
    chatContentModel.isSnapChatMode = self.taklInfo.snapChatOutDataTime > 0;
    chatContentModel.isFriend = YES;
    chatContentModel.downloadTaskIdentifier = [[GJCFFileDownloadManager shareDownloadManager] getDownloadIdentifierWithMessageId:[NSString stringWithFormat:@"%@_%@", self.taklInfo.chatIdendifier, chatContentModel.localMsgId]];
    chatContentModel.isDownloading = chatContentModel.downloadTaskIdentifier != nil;

    if (aMessage.type != GJGCChatFriendContentTypeSnapChat) {
        if ([aMessage.user_id isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) { //if user_id is self ,the message is sent to me
            chatContentModel.isFromSelf = NO;
            chatContentModel.headUrl = self.taklInfo.headUrl;
            chatContentModel.senderName = self.taklInfo.name;
        } else {
            chatContentModel.headUrl = [[LKUserCenter shareCenter] currentLoginUser].avatar;
            chatContentModel.isFromSelf = YES;
            chatContentModel.senderName = [[LKUserCenter shareCenter] currentLoginUser].normalShowName;
        }
    }
    GJGCChatFriendContentType contentType = [self formateChatFriendContent:chatContentModel withMsgModel:aMessage];
    if (contentType != GJGCChatFriendContentTypeNotFound) {
        if (![self contentModelByMsgId:aMessage.message_id]) {
            [self addChatContentModel:chatContentModel];
        }
        if (contentType != GJGCChatFriendContentTypeSnapChat) {
            chatContentModel.isSnapChatMode = self.taklInfo.snapChatOutDataTime > 0;
            chatContentModel.readState = chatMessage.state;
            chatContentModel.readTime = chatMessage.readTime;
            if (chatMessage.messageType == GJGCChatFriendContentTypeAudio &&
                    chatMessage.state != 2) { //Voice message not played complete
                chatContentModel.readTime = 0;
            }
            if ([self.ignoreMessageTypes containsObject:@(chatContentModel.contentType)]) {

            } else {
                NSInteger snapTime = 0;
                NSDictionary *ext = aMessage.ext;
                if ([aMessage.ext isKindOfClass:[NSString class]]) {
                    ext = [aMessage.ext dictionaryValue];
                } else if ([aMessage.ext isKindOfClass:[NSDictionary class]]) {
                    ext = aMessage.ext;
                }
                if (ext) {
                    if ([ext.allKeys containsObject:@"luck_delete"]) {
                        snapTime = [[ext valueForKey:@"luck_delete"] integerValue];
                    }
                }
                //Set expiration time
                chatContentModel.snapTime = snapTime;
                if (chatContentModel.snapTime > 0) {
                    if (chatContentModel.readTime > 0) {
                        [self openSnapMessageCounterState:chatContentModel];
                    }
                }
            }
        }
    }

    return chatContentModel;
}


#pragma mark - Database read the last twenty messages

- (void)readLastMessagesFromDB {

    [super readLastMessagesFromDB];

    NSArray *messages = [[MessageDBManager sharedManager] getMessagesWithMessageOwer:self.taklInfo.chatIdendifier Limit:20 beforeTime:0];

    //Show encrypted chat tips
    ChatMessageInfo *fristMessage = [messages firstObject];
    if (self.taklInfo.talkType != GJGCChatFriendTalkTypePostSystem && messages.count != 20) {
        [self showfirstChatSecureTipWithTime:fristMessage.message.sendtime];
    }

    for (ChatMessageInfo *messageInfo in messages) {
        if (messageInfo.sendstatus == GJGCChatFriendSendMessageStatusSending) {
            [self.sendingMessages objectAddObject:messageInfo.message];
        }
        [self addMMMessage:messageInfo];
    }
    //Send message is being sent
    [self reSendUnSendingMessages];


    [self updateAllMsgTimeShowString];

    [self resetFirstAndLastMsgId];
    self.isFinishFirstHistoryLoad = YES;
}

#pragma mark -load more messages

- (void)pushAddMoreMsg:(NSArray *)messages {

    for (ChatMessageInfo *messageInfo in messages) {
        [self addMMMessage:messageInfo];
    }

    [self resortAllChatContentBySendTime];

    if (self.delegate && [self.delegate respondsToSelector:@selector(dataSourceManagerRequireFinishRefresh:)]) {
        [self.delegate dataSourceManagerRequireFinishRefresh:self];
        self.isLoadingMore = NO;
    }
}


#pragma mark -

- (void)updateMsgContentHeightWithContentModel:(GJGCChatContentBaseModel *)contentModel {
}

- (void)updateAudioFinishRead:(NSString *)localMsgId {
}

@end
