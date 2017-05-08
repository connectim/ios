//
//  GJGCChatGroupDataSourceManager.m
//  Connect
//
//  Created by KivenLin on 14-11-29.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJGCChatGroupDataSourceManager.h"
#import "GJCFFileDownloadManager.h"


@interface GJGCChatGroupDataSourceManager ()

@end

@implementation GJGCChatGroupDataSourceManager

- (instancetype)initWithTalk:(GJGCChatFriendTalkModel *)talk withDelegate:(id <GJGCChatDetailDataSourceManagerDelegate>)aDelegate {
    if (self = [super initWithTalk:talk withDelegate:aDelegate]) {

        self.title = talk.name;

        [self readLastMessagesFromDB];

    }
    return self;
}

- (void)observeHistoryMessage:(NSNotification *)noti {
    dispatch_async(dispatch_get_main_queue(), ^{

        [self recievedHistoryMessage:noti];

    });
}

- (void)recievedHistoryMessage:(NSNotification *)noti {
    /* 是否当前会话的历史消息 */

    /* 悬停在第一次加载后的第一条消息上 */
    if (self.delegate && [self.delegate respondsToSelector:@selector(dataSourceManagerRequireFinishRefresh:)]) {

        [self.delegate dataSourceManagerRequireFinishRefresh:self];
    }

    /* 如果没有历史消息了 */
    self.isFinishLoadAllHistoryMsg = YES;

}


- (GJGCChatFriendContentModel *)addMMMessage:(ChatMessageInfo *)chatMessage {
    /**
     添加到通讯消息数组中
     */

    MMMessage *aMessage = chatMessage.message;

    [self.orginMessageListArray objectAddObject:aMessage];

    /* 格式化消息 */

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
    chatContentModel.isGroupChat = self.taklInfo.talkType == GJGCChatFriendTalkTypeGroup;
    chatContentModel.snapTime = 0;
    chatContentModel.isSnapChatMode = NO;
    chatContentModel.readTime = chatMessage.readTime;
    chatContentModel.isRead = chatMessage.state > 0;
    chatContentModel.downloadTaskIdentifier = [[GJCFFileDownloadManager shareDownloadManager] getDownloadIdentifierWithMessageId:[NSString stringWithFormat:@"%@_%@", self.taklInfo.chatIdendifier, chatContentModel.localMsgId]];
    chatContentModel.isDownloading = chatContentModel.downloadTaskIdentifier != nil;
    if (aMessage.type != GJGCChatFriendContentTypeStatusTip && aMessage.type != GJGCChatInviteNewMemberTip) {
        NSDictionary *senderInfoExt = aMessage.senderInfoExt;
        if ([senderInfoExt isKindOfClass:[NSString class]]) {
            senderInfoExt = [senderInfoExt mj_JSONObject];
            NSAssert(senderInfoExt != nil, @"senderInfoExt should not be nil");
        } else {
            DDLogError(@"senderInfoExt %@", senderInfoExt);
        }
        if (![[senderInfoExt valueForKey:@"address"] isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) { //发送者不是自己
            chatContentModel.isFromSelf = NO;
            AccountInfo *member = [self.taklInfo.chatGroupInfo.addressMemberDict valueForKey:[senderInfoExt valueForKey:@"address"]];
            if (member) {
                chatContentModel.headUrl = member.avatar;
                chatContentModel.senderName = member.groupShowName;
                chatContentModel.senderAddress = member.address;
            } else {
                chatContentModel.headUrl = [senderInfoExt valueForKey:@"avatar"];
                chatContentModel.senderName = [senderInfoExt valueForKey:@"username"];
                chatContentModel.senderAddress = [senderInfoExt valueForKey:@"address"];
            }
        } else {
            chatContentModel.headUrl = [[LKUserCenter shareCenter] currentLoginUser].avatar;
            chatContentModel.senderName = [[LKUserCenter shareCenter] currentLoginUser].normalShowName;
            chatContentModel.isFromSelf = YES;
        }
    }
    chatContentModel.readState = GJGCChatFriendMessageReadStateReaded;
    /* 格式内容字段 */
    GJGCChatFriendContentType contentType = [self formateChatFriendContent:chatContentModel withMsgModel:aMessage];

    if (contentType != GJGCChatFriendContentTypeNotFound) {
        // 界面消息去重
        if (![self contentModelByMsgId:aMessage.message_id]) {
            [self addChatContentModel:chatContentModel];
        }

    }

    return chatContentModel;
}

#pragma mark - 读取最近历史消息

- (void)readLastMessagesFromDB {
    [super readLastMessagesFromDB];
    //读取最近的20条消息    
    NSArray *messages = [[MessageDBManager sharedManager] getMessagesWithMessageOwer:self.taklInfo.chatIdendifier Limit:20 beforeTime:0];

    //显示安全提示
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

    //发送正在发送的消息
    [self reSendUnSendingMessages];

    /* 更新时间区间 */
    [self updateAllMsgTimeShowString];

    /* 设置加载完后第一条消息和最后一条消息 */
    [self resetFirstAndLastMsgId];

    self.isFinishFirstHistoryLoad = YES;
}

- (void)pushAddMoreMsg:(NSArray *)messages {
    //添加消息数组
    for (ChatMessageInfo *messageInfo in messages) {
        [self addMMMessage:messageInfo];
    }

    /* 重排时间顺序 */
    [self resortAllChatContentBySendTime];

    /* 上一次悬停的第一个cell的索引 */
    if (self.delegate && [self.delegate respondsToSelector:@selector(dataSourceManagerRequireFinishRefresh:)]) {
        [self.delegate dataSourceManagerRequireFinishRefresh:self];
        self.isLoadingMore = NO; //标记刷新结束
    }
}

#pragma mark - 删除消息

- (NSArray *)deleteMessageAtIndex:(NSInteger)index {
    BOOL isDelete = YES;//数据库删除消息结果
    NSMutableArray *willDeletePaths = [NSMutableArray array];

    if (isDelete) {

        /* 更新最近联系人列表得最后一条消息 */
        if (index == self.totalCount - 1 && self.chatContentTotalCount > 1) {

            GJGCChatFriendContentModel *lastContentAfterDelete = nil;
            lastContentAfterDelete = (GJGCChatFriendContentModel *) [self contentModelAtIndex:index - 1];
            if (lastContentAfterDelete.isTimeSubModel) {

                if (self.chatContentTotalCount - 1 >= 1) {

                    lastContentAfterDelete = (GJGCChatFriendContentModel *) [self contentModelAtIndex:index - 2];

                }

            }

            if (lastContentAfterDelete) {

                /* 更新最近会话信息 */
                [self updateLastMsg:lastContentAfterDelete];

            }
        }

        NSString *willDeleteTimeSubIdentifier = [self updateMsgContentTimeStringAtDeleteIndex:index];

        [self removeChatContentModelAtIndex:index];

        [willDeletePaths objectAddObject:[NSIndexPath indexPathForRow:index inSection:0]];

        if (willDeleteTimeSubIdentifier) {

            [willDeletePaths objectAddObject:[NSIndexPath indexPathForRow:index - 1 inSection:0]];

            [self removeTimeSubByIdentifier:willDeleteTimeSubIdentifier];
        }
    }

    return willDeletePaths;
}


#pragma mark - 更新附件地址

- (void)updateAudioUrl:(NSString *)audioUrl withLocalMsg:(NSString *)localMsgId toId:(NSString *)toId {
    for (GJGCChatFriendContentModel *contentModel in self.chatListArray) {
        if ([contentModel.localMsgId longLongValue] == [localMsgId longLongValue]) {
            contentModel.audioModel.localStorePath = [[GJCFCachePathManager shareManager] mainAudioCacheFilePathForUrl:audioUrl];
            break;
        }

    }
}

- (void)updateImageUrl:(NSString *)imageUrl withLocalMsg:(NSString *)localMsgId toId:(NSString *)toId {
    for (GJGCChatFriendContentModel *contentModel in self.chatListArray) {

        if ([contentModel.localMsgId longLongValue] == [localMsgId longLongValue]) {

            contentModel.imageMessageUrl = imageUrl;
            NSLog(@"更新内存中图片的地址为:%@", imageUrl);

            break;
        }

    }
}

- (void)updateAudioFinishRead:(NSString *)localMsgId {

}

#pragma mark - 更新数据库中消息得高度

- (void)updateMsgContentHeightWithContentModel:(GJGCChatContentBaseModel *)contentModel {

}

#pragma mark - 重试发送状态消息

- (void)reTryAllSendingStateMsgDetailAction {

}

- (void)mockSendAnMesssage:(GJGCChatFriendContentModel *)messageContent {
    //收到消息
    [self addChatContentModel:messageContent];

    [self updateTheNewMsgTimeString:messageContent];

    //模拟一条对方发来的消息
    GJGCChatFriendContentModel *chatContentModel = [[GJGCChatFriendContentModel alloc] init];
    chatContentModel.baseMessageType = GJGCChatBaseMessageTypeChatMessage;
    chatContentModel.contentType = GJGCChatFriendContentTypeText;
    NSString *text = @"其实我也很喜欢和你聊天，网址:http://www.163.com 个人QQ:1003081775";
    NSDictionary *parseTextDict = [GJGCChatFriendCellStyle formateSimpleTextMessage:text];
    chatContentModel.simpleTextMessage = [parseTextDict objectForKey:@"contentString"];
    chatContentModel.originTextMessage = text;
    chatContentModel.emojiInfoArray = [parseTextDict objectForKey:@"imageInfo"];
    chatContentModel.phoneNumberArray = [parseTextDict objectForKey:@"phone"];
    chatContentModel.publicKey = self.taklInfo.chatIdendifier;
    chatContentModel.userName = self.taklInfo.name;
    NSDate *sendTime = GJCFDateFromStringByFormat(@"2015-7-15 10:22:11", @"Y-M-d HH:mm:ss");
    chatContentModel.sendTime = [sendTime timeIntervalSince1970];
    chatContentModel.timeString = [GJGCChatSystemNotiCellStyle formateTime:GJCFDateToString(sendTime)];
    chatContentModel.sendStatus = GJGCChatFriendSendMessageStatusSuccess;
    chatContentModel.isFromSelf = NO;
    chatContentModel.isGroupChat = YES;
    chatContentModel.senderName = [GJGCChatFriendCellStyle formateGroupChatSenderName:@"莱纳德"].string;
    chatContentModel.talkType = self.taklInfo.talkType;
    chatContentModel.headUrl = @"http://photocdn.sohu.com/20100131/Img269941132.jpg";
    [self addChatContentModel:chatContentModel];

    [self updateTheNewMsgTimeString:chatContentModel];

    if (self.delegate && [self.delegate respondsToSelector:@selector(dataSourceManagerRequireUpdateListTable:)]) {

        [self.delegate dataSourceManagerRequireUpdateListTable:self];

    }
}

@end
