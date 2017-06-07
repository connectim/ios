//
//  GJGCChatDetailDataSourceManager.m
//  Connect
//
//  Created by KivenLin on 14-11-3.
//  Copyright (c) 2014年 ConnectSoft. All rights reserved.
//

#import "GJGCChatDetailDataSourceManager.h"
#import "NSString+DictionaryValue.h"
#import "IMService.h"
#import "RecentChatDBManager.h"
#import "LMConversionManager.h"
#import "ConnectTool.h"
#import "StringTool.h"
#import "SystemTool.h"
#import "PeerMessageHandler.h"
#import "GroupMessageHandler.h"
#import "SystemMessageHandler.h"
#import "GJCFFileUploadManager.h"
#import "LMMessageTool.h"

@interface GJGCChatDetailDataSourceManager () <MessageHandlerGetNewMessage>

@property(nonatomic, strong) dispatch_source_t refreshListSource;
@property(nonatomic, strong) NSMutableArray *snapDeleteModels;
@property(nonatomic, strong) NSMutableArray *snapDeleteIndexPaths;

@end

@implementation GJGCChatDetailDataSourceManager

- (instancetype)initWithTalk:(GJGCChatFriendTalkModel *)talk withDelegate:(id <GJGCChatDetailDataSourceManagerDelegate>)aDelegate {
    if (self = [super init]) {

        _taklInfo = talk;
        [SessionManager sharedManager].talkType = talk.talkType;
        _uniqueIdentifier = [NSString stringWithFormat:@"GJGCChatDetailDataSourceManager_%@", GJCFStringCurrentTimeStamp];

        self.delegate = aDelegate;

        //Short message interval 500 ms
        self.lastSendMsgTime = 0;
        self.sendTimeLimit = 500;

        [self initState];
        [[PeerMessageHandler instance] addGetNewMessageObserver:self];
        [[GroupMessageHandler instance] addGetNewMessageObserver:self];
        [[SystemMessageHandler instance] addGetNewMessageObserver:self];

        RegisterNotify(GroupAdminChangeNotification, @selector(groupTipMessage:));
        RegisterNotify(GroupNewMemberEnterNotification, @selector(groupTipMessage:))
    }
    return self;
}

- (void)groupTipMessage:(NSNotification *)note {
    ChatMessageInfo *msgInfo = note.object;
    if (msgInfo) {
        [self getNewMessage:msgInfo];
    }
}

#pragma mark - Need to ignore the type of burn after reading

- (NSArray *)ignoreMessageTypes {
    if (!_ignoreMessageTypes) {
        _ignoreMessageTypes = IgnoreSnapchatMessageTypes.copy;
    }
    return _ignoreMessageTypes;
}


- (void)updateLastMsg:(GJGCChatFriendContentModel *)contentModel {

}

- (void)dealloc {
    [[PeerMessageHandler instance] removeGetNewMessageObserver:self];
    [[GroupMessageHandler instance] removeGetNewMessageObserver:self];
    [[SystemMessageHandler instance] removeGetNewMessageObserver:self];
    [[GJCFFileUploadManager shareUploadManager] clearBlockForObserver:self];

    if (self.refreshListSource) {
        dispatch_source_cancel(self.refreshListSource);

        _refreshListSource = NULL;

    }

    [self.snapChatDisplayLink invalidate];
    self.snapChatDisplayLink = nil;

    RemoveNofify;
}

#pragma mark - Internal interface

- (NSArray *)heightForContentModel:(GJGCChatContentBaseModel *)contentModel {
    if (!contentModel) {
        return nil;
    }

    Class cellClass;

    switch (contentModel.baseMessageType) {
        case GJGCChatBaseMessageTypeSystemNoti: {
            GJGCChatSystemNotiModel *notiModel = (GJGCChatSystemNotiModel *) contentModel;
            cellClass = [GJGCChatSystemNotiConstans classForNotiType:notiModel.notiType];
        }
            break;
        case GJGCChatBaseMessageTypeChatMessage: {
            GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) contentModel;
            cellClass = [GJGCChatFriendConstans classForContentType:chatContentModel.contentType];
        }
            break;
        default:
            break;
    }
    CGFloat cellHeight = ((CGFloat (*)(id, SEL, id)) objc_msgSend)([cellClass class], @selector(cellHeightForContentModel:), contentModel);
    return @[@(cellHeight), [NSValue valueWithCGSize:CGSizeZero]];
}

- (NSMutableArray *)sendingMessages {
    if (!_sendingMessages) {
        _sendingMessages = [NSMutableArray array];
    }

    return _sendingMessages;
}

- (void)initState {
    if (!self.insertIndexPathsQueue) {
        self.insertIndexPathsQueue = dispatch_queue_create("_im_insertIndexPathsQueue_queue", DISPATCH_QUEUE_SERIAL);
    }
    __weak __typeof(&*self) weakSelf = self;
    if (!self.refreshListSource) {
        self.refreshListSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, self.insertIndexPathsQueue);
        dispatch_source_set_event_handler(_refreshListSource, ^{
            if ([weakSelf.delegate respondsToSelector:@selector(dataSourceManagerInsertNewMessagesReloadTableView:)]) {
                [weakSelf.delegate dataSourceManagerInsertNewMessagesReloadTableView:weakSelf];
            }
        });
    }
    dispatch_resume(self.refreshListSource);

    self.ReadedMessageBlock = ^(NSString *messageid) {
        [weakSelf readMessageAck:messageid];
    };
    self.isFinishFirstHistoryLoad = NO;
    self.chatListArray = [[NSMutableArray alloc] init];
    self.orginMessageListArray = [[NSMutableArray alloc] init];
    self.timeShowSubArray = [[NSMutableArray alloc] init];
}

#pragma mark - snapchat


- (NSMutableArray *)snapMessageContents {
    if (!_snapMessageContents) {
        _snapMessageContents = [NSMutableArray array];
    }
    return _snapMessageContents;
}

- (NSMutableArray *)snapDeleteModels {
    if (!_snapDeleteModels) {
        _snapDeleteModels = [NSMutableArray array];
    }
    return _snapDeleteModels;
}


- (NSMutableArray *)snapDeleteIndexPaths {
    if (!_snapDeleteIndexPaths) {
        _snapDeleteIndexPaths = [NSMutableArray array];
    }
    return _snapDeleteIndexPaths;
}


- (CADisplayLink *)snapChatDisplayLink {
    if (!_snapChatDisplayLink &&
        self.taklInfo.talkType == GJGCChatFriendTalkTypePrivate &&
        self.snapMessageContents.count > 0) {
        _snapChatDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateProgressSnapMessageCell)];
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
            _snapChatDisplayLink.preferredFramesPerSecond = 1;
        } else {
            _snapChatDisplayLink.frameInterval = 60;
        }
        [_snapChatDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        _snapChatDisplayLink.paused = NO;
    }

    return _snapChatDisplayLink;
}

#pragma mark - 更新阅后即焚的消息状态

- (void)updateProgressSnapMessageCell {
    if (self.isLoadingMore) {
        return;
    }
    if (self.snapMessageContents.count <= 0) {
        self.snapChatDisplayLink.paused = YES;
        return;
    }
    
    for (GJGCChatFriendContentModel *model in self.snapMessageContents) {
        int long long readTime = model.readTime;
        int long long currentTime = [[NSDate date] timeIntervalSince1970] * 1000;
        CGFloat progress = (currentTime - readTime) / (model.snapTime * 1.f);
        model.snapProgress = progress;
        NSInteger findIndex = [self getContentModelIndexByLocalMsgId:model.localMsgId];
        if (progress > 1) {
            //delete
            [self.snapDeleteModels objectAddObject:model];
            [self.snapDeleteIndexPaths objectAddObject:[NSIndexPath indexPathForRow:findIndex inSection:0]];
        }
    }
    //Delete expired messages
    if (self.snapDeleteModels.count > 0) {
        [self.chatListArray removeObjectsInArray:self.snapDeleteModels];
        [self.snapMessageContents removeObjectsInArray:self.snapDeleteModels];
        //To delete a file, you need to create a new array object to avoid Collection <__NSArrayM:> was mutated while being enumerated.
        if ([self.delegate respondsToSelector:@selector(dataSourceManagerRequireDeleteMessages:deletePaths:deleteModels:)]) {
            [self.delegate dataSourceManagerRequireDeleteMessages:self
                                                      deletePaths:[NSMutableArray arrayWithArray:self.snapDeleteIndexPaths]
                                                     deleteModels:[NSMutableArray arrayWithArray:self.snapDeleteModels]];
        }
        //clear
        [self.snapDeleteModels removeAllObjects];
        [self.snapDeleteIndexPaths removeAllObjects];
    }
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (GJGCChatFriendContentModel *model in self.snapMessageContents) {
        NSInteger index = [self.chatListArray indexOfObject:model];
        if (index != NSNotFound) {
            [indexPaths addObject:[NSIndexPath indexPathForRow:index inSection:0]];
        }
    }
    if ([self.delegate respondsToSelector:@selector(dataSourceManager:snapChatUpdateProgressWithIndexPaths:)]) {
        [self.delegate dataSourceManager:self snapChatUpdateProgressWithIndexPaths:indexPaths];
    }
}

- (void)handleSnapChatMessageWithMessageID:(NSString *)messageid {
    GJGCChatFriendContentModel *model = (GJGCChatFriendContentModel *) [self contentModelByMsgId:messageid];

    model.readState = GJGCChatFriendMessageReadStateReaded;
    model.isRead = YES;
    long long readTime = (long long) ([[NSDate date] timeIntervalSince1970] * 1000);
    model.readTime = readTime;

    [self updateChatContentMessageCounterCricleAnimation:model];
}

- (void)readMessageAck:(NSString *)messageid {
    MMMessage *readedMessage = [[MMMessage alloc] init];
    readedMessage.type = GJGCChatFriendContentTypeSnapChatReadedAck;
    readedMessage.publicKey = self.taklInfo.chatIdendifier;
    readedMessage.user_id = self.taklInfo.chatUser.address;
    readedMessage.message_id = [ConnectTool generateMessageId];
    readedMessage.content = messageid;

    [[IMService instance] asyncSendMessageReadAck:readedMessage onQueue:nil completion:^(MMMessage *message, NSError *error) {
        if (message.sendstatus == GJGCChatFriendSendMessageStatusSuccess) {
            GJGCChatFriendContentModel *model = (GJGCChatFriendContentModel *) [self contentModelByMsgId:messageid];
            [GCDQueue executeInMainQueue:^{
                [self updateChatContentMessageCounterCricleAnimation:model];
            }];
        }
    }                                     onQueue:nil];
}


#pragma mark - Dispatch reload tableview

- (void)dispatchOptimzeRefresh {
    [GCDQueue executeInMainQueue:^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(dataSourceManagerRequireUpdateListTable:)]) {
            [self.delegate dataSourceManagerRequireUpdateListTable:self];
        }
    }];
}

#pragma mark - public interface

- (NSInteger)totalCount {
    return self.chatListArray.count;
}

- (NSInteger)chatContentTotalCount {
    return self.chatListArray.count - self.timeShowSubArray.count;
}

- (Class)contentCellAtIndex:(NSInteger)index {
    Class resultClass;

    if (index > self.totalCount - 1) {
        return nil;
    }
    GJGCChatContentBaseModel *contentModel = [self.chatListArray objectAtIndex:index];

    switch (contentModel.baseMessageType) {
        case GJGCChatBaseMessageTypeSystemNoti: {
            GJGCChatSystemNotiModel *notiModel = (GJGCChatSystemNotiModel *) contentModel;
            resultClass = [GJGCChatSystemNotiConstans classForNotiType:notiModel.notiType];
        }
            break;
        case GJGCChatBaseMessageTypeChatMessage: {
            GJGCChatFriendContentModel *messageModel = (GJGCChatFriendContentModel *) contentModel;
            resultClass = [GJGCChatFriendConstans classForContentType:messageModel.contentType];
        }
            break;
        default:

            break;
    }

    return resultClass;
}

- (NSString *)contentCellIdentifierAtIndex:(NSInteger)index {
    if (index > self.totalCount - 1) {
        return nil;
    }
    NSString *resultIdentifier = nil;
    GJGCChatContentBaseModel *contentModel = [self.chatListArray objectAtIndex:index];
    switch (contentModel.baseMessageType) {
        case GJGCChatBaseMessageTypeSystemNoti: {
            GJGCChatSystemNotiModel *notiModel = (GJGCChatSystemNotiModel *) contentModel;
            resultIdentifier = [GJGCChatSystemNotiConstans identifierForNotiType:notiModel.notiType];
        }
            break;
        case GJGCChatBaseMessageTypeChatMessage: {
            GJGCChatFriendContentModel *messageModel = (GJGCChatFriendContentModel *) contentModel;
            resultIdentifier = [GJGCChatFriendConstans identifierForContentType:messageModel.contentType];
        }
            break;
        default:
            break;
    }
    return resultIdentifier;
}

- (GJGCChatContentBaseModel *)contentModelAtIndex:(NSInteger)index {

    if (index >= 0 && index < self.chatListArray.count) {
        return [self.chatListArray objectAtIndex:index];
    }

    return nil;

}

- (CGFloat)rowHeightAtIndex:(NSInteger)index {
    if (index > self.totalCount - 1) {
        return 0.f;
    }

    GJGCChatContentBaseModel *contentModel = [self contentModelAtIndex:index];

    return contentModel.contentHeight - 5;
}

- (GJGCChatContentBaseModel *)contentModelByLocalMsgId:(NSString *)localMsgId {
    for (int i = 0; i < self.chatListArray.count; i++) {

        GJGCChatContentBaseModel *contentItem = [self.chatListArray objectAtIndex:i];

        if ([contentItem.localMsgId isEqualToString:localMsgId]) {

            return contentItem;

            break;
        }
    }
    return nil;
}

- (void)updateContentModelValuesNotEffectRowHeight:(GJGCChatContentBaseModel *)contentModel atIndex:(NSInteger)index {
    GJGCChatFriendContentModel *friendChatModel = (GJGCChatFriendContentModel *) contentModel;
    if (friendChatModel.contentType == GJGCChatFriendContentTypeAudio && friendChatModel.isPlayingAudio) {
    }
    [self.chatListArray replaceObjectAtIndex:index withObject:contentModel];
}

- (NSNumber *)addChatContentModel:(GJGCChatContentBaseModel *)contentModel {

    contentModel.contentSourceIndex = self.chatListArray.count;

    NSNumber *heightNew = [NSNumber numberWithFloat:contentModel.contentHeight];
    if (contentModel.contentHeight == 0) {
        NSArray *contentHeightArray = [self heightForContentModel:contentModel];
        contentModel.contentHeight = [[contentHeightArray firstObject] floatValue];
        contentModel.contentSize = [[contentHeightArray lastObject] CGSizeValue];
    }
    [self.chatListArray objectAddObject:contentModel];
    return heightNew;
}

- (void)removeChatContentModelAtIndex:(NSInteger)index {
    [self.chatListArray removeObjectAtIndexCheck:index];
}

- (void)readLastMessagesFromDB {

    long long int count = [[MessageDBManager sharedManager] messageCountWithMessageOwer:self.taklInfo.chatIdendifier];
    if (count <= 20) {
        self.isFinishLoadAllHistoryMsg = YES;
    } else {
        self.isFinishLoadAllHistoryMsg = NO;
    }

}

- (NSArray *)deleteMessageAtIndex:(NSInteger)index {
    BOOL isDelete = NO;
    GJGCChatFriendContentModel *deleteContentModel = [self.chatListArray objectAtIndex:index];

    isDelete = [[MessageDBManager sharedManager] deleteMessageByMessageId:deleteContentModel.localMsgId messageOwer:self.taklInfo.chatIdendifier];

    NSMutableArray *willDeletePaths = [NSMutableArray array];

    if (isDelete) {

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


#pragma mark - 加载历史消息

- (void)trigglePullHistoryMsgForEarly {

    __weak __typeof(&*self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

        if (weakSelf.chatListArray && [weakSelf.chatListArray count] > 0) {
            /* Remove the time model to find the top message content */
            GJGCChatFriendContentModel *lastMsgContent;
            for (int i = 0; i < weakSelf.totalCount; i++) {
                GJGCChatFriendContentModel *item = (GJGCChatFriendContentModel *) [weakSelf contentModelAtIndex:i];
                if (!item.isTimeSubModel) {
                    lastMsgContent = item;
                    break;
                }

            }
            /* Last message sending time */
            long long lastMsgSendTime;
            if (lastMsgContent) {
                lastMsgSendTime = lastMsgContent.sendTime;
            } else {
                lastMsgSendTime = 0;
            }
            lastMsgSendTime = lastMsgSendTime;
            //time * 1000
            NSArray *localHistroyMsgArray = [[MessageDBManager sharedManager] getMessagesWithMessageOwer:weakSelf.taklInfo.chatIdendifier Limit:20 beforeTime:lastMsgSendTime messageAutoID:lastMsgContent.autoMsgid];
            if (localHistroyMsgArray.count < 20) {
                weakSelf.isFinishLoadAllHistoryMsg = YES;
            } else {
                weakSelf.isFinishLoadAllHistoryMsg = NO;
            }

            if (localHistroyMsgArray && localHistroyMsgArray.count > 0) {
                [weakSelf pushAddMoreMsg:localHistroyMsgArray];
            } else {
                [GCDQueue executeInMainQueue:^{
                    /* Hover on the first message after the first load */
                    if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(dataSourceManagerRequireFinishRefresh:)]) {
                        [weakSelf.delegate dataSourceManagerRequireFinishRefresh:weakSelf];
                    }

                    weakSelf.isLoadingMore = NO;
                }];
            }
        }
    });

}

- (void)pushAddMoreMsg:(NSArray *)array {

}

#pragma mark - Message reordering by time

- (void)resortAllChatContentBySendTime {
    for (GJGCChatContentBaseModel *contentBaseModel in self.timeShowSubArray) {
        if (contentBaseModel.isTimeSubModel) {
            [self.chatListArray removeObject:contentBaseModel];
        }

    }
    NSArray *sortedArray = [self.chatListArray sortedArrayUsingSelector:@selector(compareContent:)];
    [self.chatListArray removeAllObjects];
    [self.chatListArray addObjectsFromArray:sortedArray];
    [self updateAllMsgTimeShowString];
}

- (void)resortAllSystemNotiContentBySendTime {
    NSArray *sortedArray = [self.chatListArray sortedArrayUsingSelector:@selector(compareContent:)];
    [self.chatListArray removeAllObjects];
    [self.chatListArray addObjectsFromArray:sortedArray];
}

#pragma mark - Reset the first message of msgId

- (void)resetFirstAndLastMsgId {
    if (self.chatListArray.count > 0) {
        GJGCChatContentBaseModel *firstMsgContent = [self.chatListArray firstObject];
        NSInteger nextMsgIndex = 0;
        while (firstMsgContent.isTimeSubModel) {
            nextMsgIndex++;
            firstMsgContent = [self.chatListArray objectAtIndex:nextMsgIndex];
        }
        self.lastFirstLocalMsgId = firstMsgContent.localMsgId;
    }
}

#pragma mark - Update time block for all chat messages

- (void)updateAllMsgTimeShowString {
    /* Always use the current time as the base of the calculation and the last time is up */
    [self.timeShowSubArray removeAllObjects];

    NSTimeInterval firstMsgTimeInterval = 0;

    GJGCChatFriendContentModel *currentTimeSubModel = nil;
    for (NSInteger i = 0; i < self.totalCount; i++) {
        GJGCChatFriendContentModel *contentModel = [self.chatListArray objectAtIndex:i];
        NSString *timeString = [GJGCChatSystemNotiCellStyle timeAgoStringByLastMsgTime:contentModel.sendTime lastMsgTime:firstMsgTimeInterval];
        if (timeString) {
            /* Create a time block and insert it into the data source */
            firstMsgTimeInterval = contentModel.sendTime;
            GJGCChatFriendContentModel *timeSubModel = [GJGCChatFriendContentModel timeSubModel];
            timeSubModel.baseMessageType = GJGCChatBaseMessageTypeChatMessage;
            timeSubModel.contentType = GJGCChatFriendContentTypeTime;
            timeSubModel.timeString = [GJGCChatSystemNotiCellStyle formateTime:timeString];
            NSArray *contentHeightArray = [self heightForContentModel:timeSubModel];
            timeSubModel.contentHeight = [[contentHeightArray firstObject] floatValue];
            timeSubModel.sendTime = contentModel.sendTime;
            timeSubModel.timeSubMsgCount = 1;
            currentTimeSubModel = timeSubModel;
            contentModel.timeSubIdentifier = timeSubModel.uniqueIdentifier;
            [self.chatListArray replaceObjectAtIndex:i withObject:contentModel];
            [self.chatListArray objectInsert:timeSubModel atIndex:i];
            i++;
            [self.timeShowSubArray objectAddObject:timeSubModel];
        } else {
            contentModel.timeSubIdentifier = currentTimeSubModel.uniqueIdentifier;
            currentTimeSubModel.timeSubMsgCount = currentTimeSubModel.timeSubMsgCount + 1;
            [self updateContentModelByUniqueIdentifier:contentModel];
            [self updateContentModelByUniqueIdentifier:currentTimeSubModel];
        }
    }
}

#pragma mark - Open or close the burn after reading

- (void)openSnapChatModeWithTime:(int)time {

    self.taklInfo.snapChatOutDataTime = time;
    GJGCChatFriendContentModel *snapChatModel = [GJGCChatFriendContentModel timeSubModel];
    snapChatModel.baseMessageType = GJGCChatBaseMessageTypeChatMessage;
    snapChatModel.contentType = GJGCChatFriendContentTypeSnapChat;
    snapChatModel.snapChatTipString = [GJGCChatSystemNotiCellStyle formateOpensnapChatWithTime:time isSendToMe:NO chatUserName:self.taklInfo.chatUser.normalShowName];
    snapChatModel.originTextMessage = snapChatModel.snapChatTipString.string;
    NSArray *contentHeightArray = [self heightForContentModel:snapChatModel];
    snapChatModel.contentHeight = [[contentHeightArray firstObject] floatValue];
    NSDate *sendTime = [NSDate date];
    snapChatModel.sendTime = [sendTime timeIntervalSince1970] * 1000;

    snapChatModel.localMsgId = [ConnectTool generateMessageId];

    [self addChatContentModel:snapChatModel];

    MMMessage *message = [[MMMessage alloc] init];
    message.content = [NSString stringWithFormat:@"%d", time];
    message.type = GJGCChatFriendContentTypeSnapChat;
    message.message_id = snapChatModel.localMsgId;
    message.sendtime = snapChatModel.sendTime;
    message.publicKey = self.taklInfo.chatIdendifier;
    message.user_id = self.taklInfo.chatUser.address;
    message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;

    [LMMessageTool savaSendMessageToDB:message];

    [[RecentChatDBManager sharedManager] openSnapChatWithIdentifier:self.taklInfo.chatIdendifier snapTime:time openOrCloseByMyself:YES];
    [self sendMessagePost:message];
    if (time == 0) {
        [self outSnapchatMode];
    } else {
        [self enterSnapchatMode];
    }
}

- (void)closeSnapChatMode {
    [self openSnapChatModeWithTime:0];
}


- (void)enterSnapchatMode {
    for (GJGCChatFriendContentModel *model in self.chatListArray) {
        /**
         *  Control avatar display or hide
         */
        model.isSnapChatMode = YES;
    }
    [self dispatchOptimzeRefresh];
}

- (void)outSnapchatMode {
    for (GJGCChatFriendContentModel *model in self.chatListArray) {
        model.isSnapChatMode = NO;
    }
    [self dispatchOptimzeRefresh];
}


- (void)updateContentModelByUniqueIdentifier:(GJGCChatContentBaseModel *)contentModel {
    for (NSInteger i = 0; i < self.totalCount; i++) {

        GJGCChatContentBaseModel *itemModel = [self.chatListArray objectAtIndex:i];

        if ([itemModel.uniqueIdentifier isEqualToString:contentModel.uniqueIdentifier]) {

            [self.chatListArray replaceObjectAtIndex:i withObject:contentModel];

            break;
        }
    }
}

- (GJGCChatContentBaseModel *)timeSubModelByUniqueIdentifier:(NSString *)identifier {
    for (GJGCChatContentBaseModel *timeSubModel in self.chatListArray) {

        if ([timeSubModel.uniqueIdentifier isEqualToString:identifier]) {

            return timeSubModel;
        }
    }
    return nil;
}

- (GJGCChatContentBaseModel *)updateTheNewMsgTimeString:(GJGCChatContentBaseModel *)contentModel {
    NSTimeInterval lastSubTimeInteval;
    GJGCChatFriendContentModel *lastTimeSubModel = [self.timeShowSubArray lastObject];
    if (self.timeShowSubArray.count > 0) {
        lastSubTimeInteval = lastTimeSubModel.sendTime;
    } else {
        lastSubTimeInteval = 0;
    }

    NSString *timeString = [GJGCChatSystemNotiCellStyle timeAgoStringByLastMsgTime:contentModel.sendTime lastMsgTime:lastSubTimeInteval];

    if (timeString) {

        DDLogError(@"newTimeModel");

        GJGCChatFriendContentModel *newLastTimeSubModel = [GJGCChatFriendContentModel timeSubModel];
        newLastTimeSubModel.baseMessageType = GJGCChatBaseMessageTypeChatMessage;
        newLastTimeSubModel.contentType = GJGCChatFriendContentTypeTime;
        newLastTimeSubModel.sendTime = contentModel.sendTime;
        newLastTimeSubModel.timeString = [GJGCChatSystemNotiCellStyle formateTime:timeString];


        NSArray *contentHeightArray = [self heightForContentModel:newLastTimeSubModel];
        newLastTimeSubModel.contentHeight = [[contentHeightArray firstObject] floatValue];
        newLastTimeSubModel.timeSubMsgCount = 1;

        contentModel.timeSubIdentifier = newLastTimeSubModel.uniqueIdentifier;

        [self updateContentModelByUniqueIdentifier:contentModel];


        [self.timeShowSubArray objectAddObject:newLastTimeSubModel];

        return newLastTimeSubModel;

    } else {

        contentModel.timeSubIdentifier = lastTimeSubModel.uniqueIdentifier;
        lastTimeSubModel.timeSubMsgCount = lastTimeSubModel.timeSubMsgCount + 1;

        [self updateContentModelByUniqueIdentifier:contentModel];
        [self updateContentModelByUniqueIdentifier:lastTimeSubModel];

        return nil;
    }

}

/* Delete a message to update the next message interval */
- (NSString *)updateMsgContentTimeStringAtDeleteIndex:(NSInteger)index {
    GJGCChatContentBaseModel *contentModel = [self.chatListArray objectAtIndex:index];

    GJGCChatContentBaseModel *timeSubModel = [self timeSubModelByUniqueIdentifier:contentModel.timeSubIdentifier];
    timeSubModel.timeSubMsgCount = timeSubModel.timeSubMsgCount - 1;

    if (timeSubModel.timeSubMsgCount == 0) {

        return timeSubModel.uniqueIdentifier;

    } else {

        [self updateContentModelByUniqueIdentifier:timeSubModel];

        return nil;
    }
}

- (void)removeContentModelByIdentifier:(NSString *)identifier {
    for (GJGCChatContentBaseModel *item in self.chatListArray) {

        if ([item.uniqueIdentifier isEqualToString:identifier]) {

            [self.chatListArray removeObject:item];

            break;
        }
    }
}

- (void)removeTimeSubByIdentifier:(NSString *)identifier {
    [self removeContentModelByIdentifier:identifier];

    for (GJGCChatContentBaseModel *item in self.timeShowSubArray) {

        if ([item.uniqueIdentifier isEqualToString:identifier]) {

            [self.timeShowSubArray removeObject:item];

            break;
        }
    }
}


- (NSInteger)getContentModelIndexByDownloadTaskIdentifier:(NSString *)downloadTaskIdentifier {
    NSInteger resultIndex = NSNotFound;

    if (GJCFStringIsNull(downloadTaskIdentifier)) {
        return resultIndex;
    }

    for (int i = 0; i < self.chatListArray.count; i++) {

        GJGCChatFriendContentModel *contentModel = [self.chatListArray objectAtIndex:i];
        if ([contentModel.downloadTaskIdentifier isEqualToString:downloadTaskIdentifier]) {
            resultIndex = i;
            break;
        }
    }

    return resultIndex;
}

- (GJGCChatFriendContentModel *)getContentModelByDownloadTaskIdentifier:(NSString *)downloadTaskIdentifier {
    if (GJCFStringIsNull(downloadTaskIdentifier)) {
        return nil;
    }
    for (int i = 0; i < self.chatListArray.count; i++) {
        GJGCChatFriendContentModel *contentModel = [self.chatListArray objectAtIndex:i];
        if ([contentModel.downloadTaskIdentifier isEqualToString:downloadTaskIdentifier]) {
            return contentModel;
            break;
        }
    }
    return nil;
}


- (NSInteger)getContentModelIndexByLocalMsgId:(NSString *)msgId {
    NSInteger resultIndex = NSNotFound;

    if (GJCFStringIsNull(msgId)) {
        return resultIndex;
    }

    for (int i = 0; i < self.chatListArray.count; i++) {

        GJGCChatContentBaseModel *contentModel = [self.chatListArray objectAtIndex:i];

        if ([contentModel.localMsgId isEqualToString:msgId]) {

            resultIndex = i;

            break;
        }

    }

    return resultIndex;
}

- (GJGCChatContentBaseModel *)contentModelByMsgId:(NSString *)msgId {
    for (GJGCChatContentBaseModel *model in self.chatListArray) {
        if ([model.localMsgId isEqualToString:msgId]) {
            return model;
            break;
        }
    }
    return nil;
}

- (MMMessage *)messageByMessageId:(NSString *)msgId {

    if (GJCFStringIsNull(msgId)) {
        return nil;
    }

    MMMessage *findMessage = nil;

    for (int i = 0; i < self.orginMessageListArray.count; i++) {

        MMMessage *message = [self.orginMessageListArray objectAtIndex:i];

        if ([message.message_id isEqualToString:msgId]) {

            findMessage = message;
            break;
        }

    }

    return findMessage;

}


#pragma mark - clear eary message

- (void)clearOverEarlyMessage {
    if (self.totalCount > 100) { //
        int deleteMsgCount = (int) self.totalCount - 50;
        [self.chatListArray removeObjectsInRange:NSMakeRange(0, deleteMsgCount)];
        self.isFinishLoadAllHistoryMsg = NO;
        [self resetFirstAndLastMsgId];
        if ([self.delegate respondsToSelector:@selector(dataSourceManagerSnapChatUpdateListTable:)]) {
            [self.delegate dataSourceManagerSnapChatUpdateListTable:self];
        }
    }
}


#pragma mark - formart message

- (GJGCChatFriendContentType)formateChatFriendContent:(GJGCChatFriendContentModel *)chatContentModel withMsgModel:(MMMessage *)message {
    return [LMMessageTool formateChatFriendContent:chatContentModel withMsgModel:message];
}

- (BOOL)sendMesssage:(GJGCChatFriendContentModel *)messageContent {
    if (messageContent.contentType == GJGCChatFriendContentTypeText || messageContent.contentType == GJGCChatFriendContentTypeGif) {
        if (self.lastSendMsgTime != 0) {
            NSTimeInterval now = [[NSDate date] timeIntervalSince1970] * 1000;
            if (now - self.lastSendMsgTime < self.sendTimeLimit) {
                return NO;
            }
        }
    }
    messageContent.isSnapChatMode = self.taklInfo.snapChatOutDataTime > 0;
    GJGCChatContentBaseModel *temModel = [GJGCChatContentBaseModel new];
    temModel.sendTime = messageContent.sendTime;
    GJGCChatContentBaseModel *timeConttentModel = [self updateTheNewMsgTimeString:temModel];
    if (timeConttentModel) {
        [self.chatListArray objectAddObject:timeConttentModel];
    }
    //judge height
    [self addChatContentModel:messageContent];
    dispatch_source_merge_data(_refreshListSource, 1);
    self.lastSendMsgTime = [[NSDate date] timeIntervalSince1970] * 1000;
    MMMessage *message = [LMMessageTool packSendMessageWithChatContent:messageContent snapTime:self.taklInfo.snapChatOutDataTime];
    if (message) {
        //add orgin message to array
        [self.orginMessageListArray addObject:message];
        messageContent.isSnapChatMode = self.taklInfo.snapChatOutDataTime > 0;
        messageContent.readState = GJGCChatFriendMessageReadStateReaded;
        if (![self.ignoreMessageTypes containsObject:@(messageContent.contentType)]) {
            NSString *snapTime = @"0";
            NSString *readTime = @"0";
            NSDictionary *ext = message.ext;
            if ([message.ext isKindOfClass:[NSString class]]) {
                ext = [message.ext dictionaryValue];
            } else if ([message.ext isKindOfClass:[NSDictionary class]]) {
                ext = message.ext;
            }
            if (ext) {
                if ([ext.allKeys containsObject:@"luck_delete"]) {
                    snapTime = [ext valueForKey:@"luck_delete"];
                }
                if ([ext.allKeys containsObject:@"read_time"]) {
                    readTime = [ext valueForKey:@"read_time"];
                }
            }
            //set snaptime
            messageContent.snapTime = [snapTime intValue];
            if (messageContent.snapTime > 0) {
                //readed message
                if ([readTime integerValue] > 0) {
                    messageContent.readTime = [readTime integerValue];
                    messageContent.readState = GJGCChatFriendMessageReadStateReaded;
                    [self openSnapMessageCounterState:messageContent];
                } else {
                    messageContent.readState = GJGCChatFriendMessageReadStateUnReaded;
                }
            }
        }
    }

    
    //update conversion
    [[LMConversionManager sharedManager] sendMessage:message type:self.taklInfo.talkType];
    
    //save message
    [LMMessageTool savaSendMessageToDB:message];
    
    //send message
    [[IMService instance] asyncSendMessage:message uploadFileFailBlock:^(GJCFFileUploadTask *task, NSError *error) {
        MMMessage *message = [task.userInfo valueForKey:@"message"];
        GJGCChatFriendContentModel *contentModel = (GJGCChatFriendContentModel *) [self contentModelByMsgId:message.message_id];
        contentModel.uploadSuccess = NO;
        contentModel.uploadProgress = 0.f;
        [self updateMessageState:message state:GJGCChatFriendSendMessageStatusFaild];
    } uploadCompletionBlock:^(GJCFFileUploadTask *task, FileData *fileData) {
        MMMessage *message = [task.userInfo valueForKey:@"message"];
        GJGCChatFriendContentModel *contentModel = (GJGCChatFriendContentModel *) [self contentModelByMsgId:message.message_id];
        contentModel.uploadSuccess = YES;
        contentModel.uploadProgress = 1.f;
        [self uploadSuccessWithUrlDict:fileData mmmessage:message messageContentModel:contentModel system:[task.userInfo valueForKey:@"system"]];
    } progressBlock:^(GJCFFileUploadTask *updateTask, CGFloat progressValue) {
        MMMessage *message = [updateTask.userInfo valueForKey:@"message"];
        GJGCChatFriendContentModel *contentModel = (GJGCChatFriendContentModel *) [self contentModelByMsgId:message.message_id];
        contentModel.uploadProgress = progressValue;
        NSInteger index = [self.chatListArray indexOfObject:contentModel];
        if ([self.delegate respondsToSelector:@selector(dataSourceManagerUpdateUploadprogress:progress:index:)]) {
            [self.delegate dataSourceManagerUpdateUploadprogress:self progress:progressValue index:index];
        }
    } chatEcdhKey:self.taklInfo.group_ecdhKey contentModel:messageContent sendMessageCompletion:^(MMMessage *messageInfo, NSError *error) {
        if (!messageInfo) {
            return;
        }
        if (messageInfo.type == 12) {
            DDLogInfo(@"Read receipt of the message of success！！！");
            return;
        }
        //update message send_status
        [self updateMessageState:messageInfo state:messageInfo.sendstatus];
        if (messageInfo.sendstatus == GJGCChatFriendSendMessageStatusSuccessUnArrive) { //show blocked tips
            [self showUnArriveMessageCell];
        } else if (messageInfo.sendstatus == GJGCChatFriendSendMessageStatusFailByNoRelationShip){ //show without relationcship tips
            [self showNoRelationShipTipMessageCell];
        } else if (messageInfo.sendstatus == GJGCChatFriendSendMessageStatusFailByNotInGroup) { //show you are not in group chat tips
            [self showNoInfoGroupMessageCell];
        }
        ChatMessageInfo *chatMessage = [[MessageDBManager sharedManager] getMessageInfoByMessageid:message.message_id messageOwer:self.taklInfo.chatIdendifier];
        chatMessage.message = messageInfo;
        chatMessage.sendstatus = messageInfo.sendstatus;
        [[MessageDBManager sharedManager] updataMessage:chatMessage];
    }];
    
    return YES;
}


/**
 *  upload message success callback
 *
 *  @param response
 *  @param message
 *  @param messageContent
 */
- (void)uploadSuccessWithUrlDict:(FileData *)fileData mmmessage:(MMMessage *)message messageContentModel:(GJGCChatFriendContentModel *)messageContent system:(BOOL)system {

    NSString *fileUrl = nil;
    if (system) {
        fileUrl = [NSString stringWithFormat:@"%@?token=%@", fileData.URL, fileData.token];
    } else {
        fileUrl = [NSString stringWithFormat:@"%@?pub_key=%@&token=%@", fileData.URL, messageContent.reciverPublicKey, fileData.token];
    }
    switch (messageContent.contentType) {
        case GJGCChatFriendContentTypeVideo:
        case GJGCChatFriendContentTypeImage: {
            if (system) {
                message.content = fileUrl;
            } else {
                message.content = [NSString stringWithFormat:@"%@/thumb?pub_key=%@&token=%@", fileData.URL, messageContent.reciverPublicKey, fileData.token];
                message.url = fileUrl;
            }
        }
            break;
        case GJGCChatFriendContentTypeMapLocation:
        case GJGCChatFriendContentTypeAudio: {
            message.content = fileUrl;
        }
            break;
        default:
            break;
    }

    [LMMessageTool updateSendMessageStatus:message];
    [self sendMessagePost:message];

    NSInteger index = NSNotFound;
    for (MMMessage *msg in self.orginMessageListArray) {
        if ([msg.message_id isEqualToString:message.message_id]) {
            index = [self.orginMessageListArray indexOfObject:msg];
            break;
        }
    }
    if (index != NSNotFound) {
        [self.orginMessageListArray removeObjectAtIndexCheck:index];
        [self.orginMessageListArray objectInsert:message atIndex:index];
    }
}

#pragma mark - resend message

- (void)reSendMesssage:(GJGCChatFriendContentModel *)messageContent {
    MMMessage *bmMessage = [self messageByMessageId:messageContent.localMsgId];
    if (!messageContent ||
        !bmMessage) {
        return;
    }
    if ([LMMessageTool checkRichtextUploadStatuts:bmMessage]) {
        [self sendMessagePost:bmMessage];
    } else {
        //send message
        [[IMService instance] asyncSendMessage:bmMessage uploadFileFailBlock:^(GJCFFileUploadTask *task, NSError *error) {
            MMMessage *message = [task.userInfo valueForKey:@"message"];
            GJGCChatFriendContentModel *contentModel = (GJGCChatFriendContentModel *) [self contentModelByMsgId:message.message_id];
            contentModel.uploadSuccess = NO;
            contentModel.uploadProgress = 0.f;
            [self updateMessageState:message state:GJGCChatFriendSendMessageStatusFaild];
        } uploadCompletionBlock:^(GJCFFileUploadTask *task, FileData *fileData) {
            MMMessage *message = [task.userInfo valueForKey:@"message"];
            GJGCChatFriendContentModel *contentModel = (GJGCChatFriendContentModel *) [self contentModelByMsgId:message.message_id];
            contentModel.uploadSuccess = YES;
            contentModel.uploadProgress = 1.f;
            [self uploadSuccessWithUrlDict:fileData mmmessage:message messageContentModel:contentModel system:[task.userInfo valueForKey:@"system"]];
        } progressBlock:^(GJCFFileUploadTask *updateTask, CGFloat progressValue) {
            MMMessage *message = [updateTask.userInfo valueForKey:@"message"];
            GJGCChatFriendContentModel *contentModel = (GJGCChatFriendContentModel *) [self contentModelByMsgId:message.message_id];
            contentModel.uploadProgress = progressValue;
            NSInteger index = [self.chatListArray indexOfObject:contentModel];
            if ([self.delegate respondsToSelector:@selector(dataSourceManagerUpdateUploadprogress:progress:index:)]) {
                [self.delegate dataSourceManagerUpdateUploadprogress:self progress:progressValue index:index];
            }
        } chatEcdhKey:self.taklInfo.group_ecdhKey contentModel:messageContent sendMessageCompletion:^(MMMessage *messageInfo, NSError *error) {
            if (!messageInfo) {
                return;
            }
            if (messageInfo.type == 12) {
                DDLogInfo(@"Read receipt of the message of success！！！");
                return;
            }
            //update message send_status
            [self updateMessageState:messageInfo state:messageInfo.sendstatus];
            if (messageInfo.sendstatus == GJGCChatFriendSendMessageStatusSuccessUnArrive) { //show blocked tips
                [self showUnArriveMessageCell];
            } else if (messageInfo.sendstatus == GJGCChatFriendSendMessageStatusFailByNoRelationShip){ //show without relationcship tips
                [self showNoRelationShipTipMessageCell];
            } else if (messageInfo.sendstatus == GJGCChatFriendSendMessageStatusFailByNotInGroup) { //show you are not in group chat tips
                [self showNoInfoGroupMessageCell];
            }
            ChatMessageInfo *chatMessage = [[MessageDBManager sharedManager] getMessageInfoByMessageid:messageInfo.message_id messageOwer:self.taklInfo.chatIdendifier];
            chatMessage.message = messageInfo;
            chatMessage.sendstatus = messageInfo.sendstatus;
            [[MessageDBManager sharedManager] updataMessage:chatMessage];
        }];
    }
}

- (void)reSendUnSendingMessages {
    for (MMMessage *bmMessage in self.sendingMessages) {
        [self reSendMesssage:(GJGCChatFriendContentModel *) [self contentModelByMsgId:bmMessage.message_id]];
    }
}

#pragma mark - add message model
- (GJGCChatFriendContentModel *)addMMMessage:(ChatMessageInfo *)chatMessage {
    return nil;
}

#pragma mark - recive read ack message
- (void)getReadAckWithMessageID:(NSString *)messageId chatUserPublickey:(NSString *)publickey {
    if (![publickey isEqualToString:self.taklInfo.chatIdendifier]) {
        return;
    }
    [self handleSnapChatMessageWithMessageID:messageId];
}


#pragma mark - receive message

- (void)getBitchNewMessage:(NSArray *)messages {
    if (messages.count == 1) {
        [self getNewMessage:[messages lastObject]];
    } else {
        for (ChatMessageInfo *message in messages) {
            BOOL complete = message == [messages lastObject];
            if (![message.messageOwer isEqualToString:self.taklInfo.chatIdendifier]) {
                return;
            }
            //message de emphasis
            if (message.messageType != GJGCChatFriendContentTypeSnapChatReadedAck && [self contentModelByMsgId:message.messageId]) {
                return;
            }
            [self handleGetMessage:message isBitch:YES complete:complete];
        }
    }
}

- (void)getNewMessage:(ChatMessageInfo *)message {
    
    if (![message.messageOwer isEqualToString:self.taklInfo.chatIdendifier]) {
        return;
    }
    //message de emphasis
    if (message.messageType != GJGCChatFriendContentTypeSnapChatReadedAck && [self contentModelByMsgId:message.messageId]) {
        return;
    }
    [self handleGetMessage:message isBitch:NO complete:NO];
    
}

- (void)handleGetMessage:(ChatMessageInfo *)message isBitch:(BOOL)bitch complete:(BOOL)complete {

    if (message.messageType == GJGCChatFriendContentTypeSnapChat) {

        [self addMMMessage:message];
        self.taklInfo.snapChatOutDataTime = [message.message.content intValue];
        [GCDQueue executeInMainQueue:^{
            if (self.taklInfo.snapChatOutDataTime > 0) {
                if ([self.delegate respondsToSelector:@selector(dataSourceManagerEnterSnapChat:)]) {
                    [self.delegate dataSourceManagerEnterSnapChat:self];
                }
            } else {
                if ([self.delegate respondsToSelector:@selector(dataSourceManagerCloseSnapChat:)]) {
                    [self.delegate dataSourceManagerCloseSnapChat:self];
                }
            }
        }];
        for (GJGCChatContentBaseModel *model in self.chatListArray) {
            if (self.taklInfo.snapChatOutDataTime > 0) {
                model.isSnapChatMode = YES;
            } else {
                model.isSnapChatMode = NO;
            }
        }
        //reload daga
        [self dispatchOptimzeRefresh];
        return;
    }

    //remind
    [SystemTool showInstantMessageVoice];

    if (self.taklInfo.talkType != GJGCChatFriendTalkTypeGroup &&
            message.messageType != GJGCChatFriendContentTypeSnapChat) {
        //Check whether the message contains the contents of the burn after reading
        BOOL isSnapChatModel = NO;
        if (self.taklInfo.snapChatOutDataTime > 0) {
            isSnapChatModel = YES;
            if (message.messageType == GJGCChatFriendContentTypeText) {
                //[self sendMessageReadAck:message];
            }
        }
        if (message.snapTime > 0) {
            if (isSnapChatModel && message.snapTime != self.taklInfo.snapChatOutDataTime) {
                self.taklInfo.snapChatOutDataTime = (int) message.snapTime;
                [[RecentChatDBManager sharedManager] openOrCloseSnapChatWithTime:self.taklInfo.snapChatOutDataTime chatIdentifer:self.taklInfo.chatIdendifier];
                //Display a post burn time prompt message
                GJGCChatFriendContentModel *snapChatModel = [GJGCChatFriendContentModel timeSubModel];
                snapChatModel.baseMessageType = GJGCChatBaseMessageTypeChatMessage;
                snapChatModel.contentType = GJGCChatFriendContentTypeSnapChat;
                snapChatModel.snapChatTipString = [GJGCChatSystemNotiCellStyle formateOpensnapChatWithTime:self.taklInfo.snapChatOutDataTime isSendToMe:YES chatUserName:self.taklInfo.chatUser.normalShowName];
                snapChatModel.originTextMessage = snapChatModel.snapChatTipString.string;
                NSArray *contentHeightArray = [self heightForContentModel:snapChatModel];
                snapChatModel.contentHeight = [[contentHeightArray firstObject] floatValue];
                NSDate *sendTime = [NSDate date];
                snapChatModel.sendTime = [sendTime timeIntervalSince1970] * 1000;

                snapChatModel.localMsgId = [ConnectTool generateMessageId];
                [self addChatContentModel:snapChatModel];
                MMMessage *message = [[MMMessage alloc] init];
                message.content = [NSString stringWithFormat:@"%d", self.taklInfo.snapChatOutDataTime];
                message.type = GJGCChatFriendContentTypeSnapChat;
                message.message_id = snapChatModel.localMsgId;
                message.sendtime = snapChatModel.sendTime;
                message.publicKey = self.taklInfo.chatIdendifier;
                message.user_id = self.taklInfo.chatUser.address;
                message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;

                [LMMessageTool savaSendMessageToDB:message];
            }
            if (!isSnapChatModel) {

                if ([self.delegate respondsToSelector:@selector(dataSourceManagerEnterSnapChat:)]) {
                    [self.delegate dataSourceManagerEnterSnapChat:self];
                }
                //Display a post burn time prompt message
                self.taklInfo.snapChatOutDataTime = (int) message.snapTime;
                GJGCChatFriendContentModel *snapChatModel = [GJGCChatFriendContentModel timeSubModel];
                snapChatModel.baseMessageType = GJGCChatBaseMessageTypeChatMessage;
                snapChatModel.contentType = GJGCChatFriendContentTypeSnapChat;
                snapChatModel.snapChatTipString = [GJGCChatSystemNotiCellStyle formateOpensnapChatWithTime:self.taklInfo.snapChatOutDataTime isSendToMe:YES chatUserName:self.taklInfo.chatUser.normalShowName];
                snapChatModel.originTextMessage = snapChatModel.snapChatTipString.string;
                NSArray *contentHeightArray = [self heightForContentModel:snapChatModel];
                snapChatModel.contentHeight = [[contentHeightArray firstObject] floatValue];
                NSDate *sendTime = [NSDate date];
                snapChatModel.sendTime = [sendTime timeIntervalSince1970] * 1000;

                snapChatModel.localMsgId = [ConnectTool generateMessageId];

                [self addChatContentModel:snapChatModel];

                MMMessage *snapTipMessage = [[MMMessage alloc] init];
                snapTipMessage.content = [NSString stringWithFormat:@"%d", self.taklInfo.snapChatOutDataTime];
                snapTipMessage.type = GJGCChatFriendContentTypeSnapChat;
                snapTipMessage.message_id = snapChatModel.localMsgId;
                snapTipMessage.sendtime = snapChatModel.sendTime;
                snapTipMessage.publicKey = self.taklInfo.chatIdendifier;
                snapTipMessage.user_id = self.taklInfo.chatUser.address;
                snapTipMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;

                [LMMessageTool savaSendMessageToDB:snapTipMessage];
                //Read ack
                [self sendMessageReadAck:message];

                [[RecentChatDBManager sharedManager] openOrCloseSnapChatWithTime:self.taklInfo.snapChatOutDataTime chatIdentifer:self.taklInfo.chatIdendifier];

                for (GJGCChatContentBaseModel *model in self.chatListArray) {
                    model.isSnapChatMode = YES;
                }
            }
        } else {
            if (isSnapChatModel) {
                self.taklInfo.snapChatOutDataTime = 0;

                if ([self.delegate respondsToSelector:@selector(dataSourceManagerCloseSnapChat:)]) {
                    [self.delegate dataSourceManagerCloseSnapChat:self];
                }
                //Show off the burn after reading tips
                GJGCChatFriendContentModel *snapChatModel = [GJGCChatFriendContentModel timeSubModel];
                snapChatModel.baseMessageType = GJGCChatBaseMessageTypeChatMessage;
                snapChatModel.contentType = GJGCChatFriendContentTypeSnapChat;
                snapChatModel.snapChatTipString = [GJGCChatSystemNotiCellStyle formateOpensnapChatWithTime:0 isSendToMe:YES chatUserName:self.taklInfo.chatUser.normalShowName];
                snapChatModel.originTextMessage = snapChatModel.snapChatTipString.string;
                NSArray *contentHeightArray = [self heightForContentModel:snapChatModel];
                snapChatModel.contentHeight = [[contentHeightArray firstObject] floatValue];
                NSDate *sendTime = [NSDate date];
                snapChatModel.sendTime = (long long int) ([sendTime timeIntervalSince1970] * 1000);
                snapChatModel.localMsgId = [ConnectTool generateMessageId];
                [self addChatContentModel:snapChatModel];
                MMMessage *message = [[MMMessage alloc] init];
                message.content = @"0";
                message.type = GJGCChatFriendContentTypeSnapChat;
                message.message_id = snapChatModel.localMsgId;
                message.sendtime = snapChatModel.sendTime;
                message.publicKey = [[LKUserCenter shareCenter] currentLoginUser].pub_key;
                message.user_id = [[LKUserCenter shareCenter] currentLoginUser].address;
                message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;

                [LMMessageTool savaSendMessageToDB:message];

                [[RecentChatDBManager sharedManager] openOrCloseSnapChatWithTime:0 chatIdentifer:self.taklInfo.chatIdendifier];
                for (GJGCChatContentBaseModel *model in self.chatListArray) {
                    model.isSnapChatMode = NO;
                }
            }
        }
    }
    switch (message.messageType) {
        case GJGCChatFriendContentTypeGif:
        case GJGCChatFriendContentTypeText:
        case GJGCChatFriendContentTypeNameCard:
        case GJGCChatFriendContentTypeTransfer:
        case GJGCChatFriendContentTypePayReceipt:
        case GJGCChatFriendContentTypeStatusTip:
        case GJGCChatFriendContentTypeRedEnvelope:
        case GJGCChatFriendContentTypeAudio:
        case GJGCChatFriendContentTypeImage:
        case GJGCChatFriendContentTypeVideo:
        case GJGCChatInviteNewMemberTip:
        case GJGCChatSystemGonggao:
        case GJGCChatSystemShenhe:
        case GJGCChatInviteToGroup:
        case GJGCChatApplyToJoinGroup:
        case GJGCChatWalletLink:
        case GJGCChatFriendContentTypeMapLocation: {
            GJGCChatContentBaseModel *temModel = [GJGCChatContentBaseModel new];
            temModel.sendTime = message.message.sendtime;
            GJGCChatContentBaseModel *timeConttentModel = [self updateTheNewMsgTimeString:temModel];
            if (timeConttentModel) {
                [self.chatListArray addObject:timeConttentModel];
            }
            [self addMMMessage:message];
            if (bitch) {
                if (complete) {
                    [self dispatchOptimzeRefresh];
                }
            } else {
                dispatch_source_merge_data(_refreshListSource, 1);
            }
        }
            break;
        default:
            break;
    }

}

- (void)updateChatContentMessageCounterCricleAnimation:(GJGCChatFriendContentModel *)contentModel {
    if (contentModel.snapTime <= 0 || contentModel.readTime <= 0) {
        return;
    }
    if (![self.snapMessageContents containsObject:contentModel]) {
        [self.snapMessageContents addObject:contentModel];
    }
    if (self.snapMessageContents.count > 0) {
        self.snapChatDisplayLink.paused = NO;
    }
}


- (void)openSnapMessageCounterState:(GJGCChatFriendContentModel *)findContent {

    if (findContent.contentType == GJGCChatFriendContentTypeSnapChat) {
        return;
    }
    if (findContent) {
        findContent.readState = GJGCChatFriendMessageReadStateReaded;
        if (![self.snapMessageContents containsObject:findContent]) {
            [self.snapMessageContents addObject:findContent];
        }
        if (self.snapMessageContents.count > 0) {
            self.snapChatDisplayLink.paused = NO;
        }
    }
}


- (void)updateMessageState:(MMMessage *)theMessage state:(GJGCChatFriendSendMessageStatus)status {
    GJGCChatFriendContentModel *findContent = nil;
    NSInteger findIndex = NSNotFound;
    for (NSInteger index = 0; index < self.chatListArray.count; index++) {
        GJGCChatFriendContentModel *content = [self.chatListArray objectAtIndex:index];
        if ([content.localMsgId isEqualToString:theMessage.message_id]) {
            findContent = content;
            findIndex = index;
            break;
        }
    }
    if (findContent && findIndex != NSNotFound) {
        [GCDQueue executeInMainQueue:^{
            findContent.sendStatus = status;
            [self.chatListArray replaceObjectAtIndex:findIndex withObject:findContent];
            [self.delegate dataSourceManagerRequireUpdateListTable:self reloadForUpdateMsgStateAtIndex:findIndex];
        }];
    }
}


#pragma mark - Not in group tips

- (void)showNoInfoGroupMessageCell {
    GJGCChatFriendContentModel *statusTipModel = [[GJGCChatFriendContentModel alloc] init];
    statusTipModel.baseMessageType = GJGCChatBaseMessageTypeChatMessage;
    statusTipModel.contentType = GJGCChatFriendContentTypeStatusTip;

    NSString *tipMessage = LMLocalizedString(@"Message send fail not in group", nil);
    NSMutableAttributedString *tipMessageText = [[NSMutableAttributedString alloc] initWithString:tipMessage];
    [tipMessageText addAttribute:NSFontAttributeName
                           value:[UIFont systemFontOfSize:FONT_SIZE(22)]
                           range:NSMakeRange(0, tipMessage.length)];
    [tipMessageText addAttribute:NSForegroundColorAttributeName
                           value:LMAssociateTextColor
                           range:NSMakeRange(0, tipMessage.length)];
    statusTipModel.statusMessageString = tipMessageText;
    NSArray *contentHeightArray = [self heightForContentModel:statusTipModel];
    statusTipModel.contentHeight = [[contentHeightArray firstObject] floatValue];
    NSDate *sendTime = [NSDate date];
    statusTipModel.sendTime = [sendTime timeIntervalSince1970];
    statusTipModel.localMsgId = [ConnectTool generateMessageId];
    [self addChatContentModel:statusTipModel];
    dispatch_source_merge_data(_refreshListSource, 1);

    self.lastSendMsgTime = [[NSDate date] timeIntervalSince1970] * 1000;
}

#pragma mark - blolck tips

- (void)showUnArriveMessageCell {
    GJGCChatFriendContentModel *statusTipModel = [[GJGCChatFriendContentModel alloc] init];
    statusTipModel.baseMessageType = GJGCChatBaseMessageTypeChatMessage;
    statusTipModel.contentType = GJGCChatFriendContentTypeStatusTip;

    NSString *tipMessage = LMLocalizedString(@"Chat Add as a friend to chat", nil);
    NSMutableAttributedString *tipMessageText = [[NSMutableAttributedString alloc] initWithString:tipMessage];
    [tipMessageText addAttribute:NSFontAttributeName
                           value:[UIFont systemFontOfSize:FONT_SIZE(22)]
                           range:NSMakeRange(0, tipMessage.length)];
    [tipMessageText addAttribute:NSForegroundColorAttributeName
                           value:LMAssociateTextColor
                           range:NSMakeRange(0, tipMessage.length)];
    statusTipModel.statusMessageString = tipMessageText;
    NSArray *contentHeightArray = [self heightForContentModel:statusTipModel];
    statusTipModel.contentHeight = [[contentHeightArray firstObject] floatValue];
    NSDate *sendTime = [NSDate date];
    statusTipModel.sendTime = [sendTime timeIntervalSince1970];
    statusTipModel.localMsgId = [ConnectTool generateMessageId];
    [self addChatContentModel:statusTipModel];
    dispatch_source_merge_data(_refreshListSource, 1);

    self.lastSendMsgTime = [[NSDate date] timeIntervalSince1970] * 1000;
}

#pragma mark - no relationship tips

- (void)showNoRelationShipTipMessageCell {

    GJGCChatFriendContentModel *statusTipModel = [[GJGCChatFriendContentModel alloc] init];
    statusTipModel.baseMessageType = GJGCChatBaseMessageTypeChatMessage;
    statusTipModel.contentType = GJGCChatFriendContentTypeNoRelationShipTip;

    NSArray *contentHeightArray = [self heightForContentModel:statusTipModel];
    statusTipModel.contentHeight = [[contentHeightArray firstObject] floatValue];
    NSDate *sendTime = [NSDate date];
    statusTipModel.sendTime = [sendTime timeIntervalSince1970];
    statusTipModel.localMsgId = [ConnectTool generateMessageId];

    [self addChatContentModel:statusTipModel];
    dispatch_source_merge_data(_refreshListSource, 1);

    self.lastSendMsgTime = [[NSDate date] timeIntervalSince1970] * 1000;
}


#pragma mark - show securety chat tips

- (void)showfirstChatSecureTipWithTime:(long long)time {

    if (time == 0) {
        time = [[NSDate date] timeIntervalSince1970] * 1000;
    }
    GJGCChatFriendContentModel *statusTipModel = [[GJGCChatFriendContentModel alloc] init];
    statusTipModel.baseMessageType = GJGCChatBaseMessageTypeChatMessage;
    statusTipModel.contentType = GJGCChatFriendContentTypeSecureTip;
    NSArray *contentHeightArray = [self heightForContentModel:statusTipModel];
    statusTipModel.contentHeight = [[contentHeightArray firstObject] floatValue];
    statusTipModel.sendTime = time;
    statusTipModel.localMsgId = [ConnectTool generateMessageId];
    [self addChatContentModel:statusTipModel];

    self.lastSendMsgTime = time;
}

- (void)showGetRedBagMessageWithWithMessage:(MMMessage *)msg {
    NSString *operation = msg.content;
    NSArray *temA = [operation componentsSeparatedByString:@"/"];
    if (temA.count == 2) {
        NSString *senderAddress = [temA firstObject];
        NSString *reciverAddress = [temA lastObject];
        NSString *garbName = nil;
        NSString *senderName = nil;
        switch (self.taklInfo.talkType) {
            case GJGCChatFriendTalkTypePrivate: {
                //reciver is self
                if ([reciverAddress isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                    garbName = LMLocalizedString(@"Chat You", nil);
                    senderName = self.taklInfo.chatUser.normalShowName;
                }
                //send is self
                if ([senderAddress isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                    senderName = LMLocalizedString(@"Chat You", nil);
                    garbName = self.taklInfo.chatUser.normalShowName;
                }
            }
                break;
            case GJGCChatFriendTalkTypeGroup: {
                for (AccountInfo *groupMember in self.taklInfo.chatGroupInfo.groupMembers) {
                    //send is self
                    if ([senderAddress isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                        senderName = LMLocalizedString(@"Chat You", nil);
                    } else {
                        if ([groupMember.address isEqualToString:senderAddress]) {
                            senderName = groupMember.normalShowName;
                        }
                    }
                    //recive is self
                    if ([reciverAddress isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                        garbName = LMLocalizedString(@"Chat You", nil);
                    } else {
                        if ([groupMember.address isEqualToString:reciverAddress]) {
                            garbName = groupMember.normalShowName;
                        }
                    }
                }
            }
                break;
            case GJGCChatFriendTalkTypePostSystem: {
                garbName = LMLocalizedString(@"Chat You", nil);
                senderName = LMLocalizedString(@"Wallet Connect term", nil);
            }
                break;
            default:
                break;
        }

        GJGCChatFriendContentModel *statusTipModel = [[GJGCChatFriendContentModel alloc] init];
        statusTipModel.baseMessageType = GJGCChatBaseMessageTypeChatMessage;
        statusTipModel.contentType = GJGCChatFriendContentTypeStatusTip;
        statusTipModel.statusMessageString = [GJGCChatSystemNotiCellStyle formateRedbagTipWithSenderName:senderName garbName:garbName];
        statusTipModel.statusIcon = @"luckybag";
        NSArray *contentHeightArray = [self heightForContentModel:statusTipModel];
        statusTipModel.contentHeight = [[contentHeightArray firstObject] floatValue];
        statusTipModel.sendTime = msg.sendtime;
        statusTipModel.localMsgId = msg.message_id;
        [self addChatContentModel:statusTipModel];

        self.lastSendMsgTime = [[NSDate date] timeIntervalSince1970] * 1000;
        [GCDQueue executeInMainQueue:^{
            dispatch_source_merge_data(_refreshListSource, 1);
        }];
    }
}


- (void)showReceiptMessageMessageWithPayName:(NSString *)payName receiptName:(NSString *)receiptName isCrowd:(BOOL)isCrowd {

    GJGCChatFriendContentModel *statusTipModel = [[GJGCChatFriendContentModel alloc] init];
    statusTipModel.baseMessageType = GJGCChatBaseMessageTypeChatMessage;
    statusTipModel.contentType = GJGCChatFriendContentTypeStatusTip;
    statusTipModel.statusMessageString = [GJGCChatSystemNotiCellStyle formateReceiptTipWithPayName:payName receiptName:receiptName isCrowding:isCrowd];
    NSArray *contentHeightArray = [self heightForContentModel:statusTipModel];
    statusTipModel.contentHeight = [[contentHeightArray firstObject] floatValue];
    NSDate *sendTime = [NSDate date];
    statusTipModel.sendTime = [sendTime timeIntervalSince1970];
    statusTipModel.localMsgId = [ConnectTool generateMessageId];

    [self addChatContentModel:statusTipModel];
    dispatch_source_merge_data(_refreshListSource, 1);

    self.lastSendMsgTime = [[NSDate date] timeIntervalSince1970] * 1000;
}

- (void)showCrowdingCompleteMessage {

    GJGCChatFriendContentModel *statusTipModel = [[GJGCChatFriendContentModel alloc] init];
    statusTipModel.baseMessageType = GJGCChatBaseMessageTypeChatMessage;
    statusTipModel.contentType = GJGCChatFriendContentTypeStatusTip;
    statusTipModel.statusMessageString = [GJGCChatSystemNotiCellStyle formateCrowdingCompleteTipMessage];
    NSArray *contentHeightArray = [self heightForContentModel:statusTipModel];
    statusTipModel.contentHeight = [[contentHeightArray firstObject] floatValue];
    NSDate *sendTime = [NSDate date];
    statusTipModel.sendTime = [sendTime timeIntervalSince1970];
    statusTipModel.localMsgId = [ConnectTool generateMessageId];
    [self addChatContentModel:statusTipModel];
    dispatch_source_merge_data(_refreshListSource, 1);

    self.lastSendMsgTime = [[NSDate date] timeIntervalSince1970] * 1000;
}


/*
 *  Send read ack
 */
- (void)sendMessageReadAck:(ChatMessageInfo *)message {

    message.readTime = (long long int) ([[NSDate date] timeIntervalSince1970] * 1000);
    [[MessageDBManager sharedManager] updateMessageReadTimeWithMsgID:message.messageId messageOwer:self.taklInfo.chatIdendifier];
    if (![self.ignoreMessageTypes containsObject:@(message.messageType)]) {
        if (message.messageType == GJGCChatFriendContentTypeAudio || message.messageType == GJGCChatFriendContentTypeImage) {
            return;
        }
        if (self.ReadedMessageBlock) {
            self.ReadedMessageBlock(message.messageId);
        }
    }
}

- (void)showEcdhKeyUpdataMessageWithSuccess:(BOOL)success {

}


- (void)sendMessagePost:(MMMessage *)message {
    
    __weak __typeof(&*self) weakSelf = self;
    
    if (self.taklInfo.talkType == GJGCChatFriendTalkTypePrivate) {
        [[IMService instance] asyncSendMessageMessage:message onQueue:nil completion:^(MMMessage *messageInfo, NSError *error) {
            if (!messageInfo) {
                return;
            }
            if (messageInfo.type == 12) {
                DDLogInfo(@"Read receipt of the message of success！！！");
                return;
            }
            //update message send_status
            [weakSelf updateMessageState:messageInfo state:messageInfo.sendstatus];
            if (messageInfo.sendstatus == GJGCChatFriendSendMessageStatusSuccessUnArrive) { //show blocked tips
                [weakSelf showUnArriveMessageCell];
            } else if (messageInfo.sendstatus == GJGCChatFriendSendMessageStatusFailByNoRelationShip) //show without relationcship tips
            {
                [weakSelf showNoRelationShipTipMessageCell];
            }
            
            ChatMessageInfo *chatMessage = [[MessageDBManager sharedManager] getMessageInfoByMessageid:message.message_id messageOwer:weakSelf.taklInfo.chatIdendifier];
            chatMessage.message = messageInfo;
            chatMessage.sendstatus = messageInfo.sendstatus;
            
            [[MessageDBManager sharedManager] updataMessage:chatMessage];
            if (messageInfo.sendstatus == GJGCChatFriendSendMessageStatusSuccess) {
                
            }
            
        }                                     onQueue:nil];
        
    } else if (self.taklInfo.talkType == GJGCChatFriendTalkTypeGroup) {
        [[IMService instance] asyncSendGroupMessage:message withGroupEckhKey:self.taklInfo.group_ecdhKey onQueue:nil completion:^(MMMessage *messageInfo, NSError *error) {
            
            if (!messageInfo) {
                return;
            }
            [weakSelf updateMessageState:messageInfo state:messageInfo.sendstatus];
            
            if (messageInfo.sendstatus == GJGCChatFriendSendMessageStatusFailByNotInGroup) { //show you are not in group chat tips
                [weakSelf showNoInfoGroupMessageCell];
            }
            
            ChatMessageInfo *chatMessage = [[MessageDBManager sharedManager] getMessageInfoByMessageid:message.message_id messageOwer:weakSelf.taklInfo.chatIdendifier];
            chatMessage.message = messageInfo;
            chatMessage.sendstatus = messageInfo.sendstatus;
            
            [[MessageDBManager sharedManager] updataMessage:chatMessage];
            if (messageInfo.sendstatus == GJGCChatFriendSendMessageStatusSuccess) {
                
            }
        }                                   onQueue:nil];
    } else if (self.taklInfo.talkType == GJGCChatFriendTalkTypePostSystem) {
        [[IMService instance] asyncSendSystemMessage:message completion:^(MMMessage *messageInfo, NSError *error) {
            if (!messageInfo) {
                return;
            }
            [weakSelf updateMessageState:messageInfo state:messageInfo.sendstatus];
            ChatMessageInfo *chatMessage = [[MessageDBManager sharedManager] getMessageInfoByMessageid:message.message_id messageOwer:weakSelf.taklInfo.chatIdendifier];
            chatMessage.message = messageInfo;
            chatMessage.sendstatus = messageInfo.sendstatus;
            
            [[MessageDBManager sharedManager] updataMessage:chatMessage];
            
            if (messageInfo.sendstatus == GJGCChatFriendSendMessageStatusSuccess) {
                
            }
        }];
    }
}

@end
