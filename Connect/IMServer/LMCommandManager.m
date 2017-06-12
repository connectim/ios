//
//  LMCommandManager.m
//  Connect
//
//  Created by MoHuilin on 2017/5/17.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMCommandManager.h"
#import "MessageDBManager.h"
#import "LMMessageExtendManager.h"
#import "UserDBManager.h"
#import "GroupDBManager.h"
#import "StringTool.h"
#import "ConnectTool.h"
#import "PeerMessageHandler.h"
#import "GroupMessageHandler.h"
#import "SystemMessageHandler.h"
#import "NSData+Gzip.h"
#import "YYImageCache.h"
#import "LMHistoryCacheManager.h"
#import "LMMessageSendManager.h"

@implementation SendCommandModel

@end


@interface LMCommandManager ()

@property(nonatomic, strong) dispatch_queue_t commandSendStatusQueue;
@property(nonatomic, strong) NSMutableDictionary *sendingCommands;


//check message outtime
@property(nonatomic, strong) dispatch_source_t reflashSendStatusSource;
@property(nonatomic, assign) BOOL reflashSendStatusSourceActive;

@end

@implementation LMCommandManager

CREATE_SHARED_MANAGER(LMCommandManager)

- (instancetype)init {
    if (self = [super init]) {
        _sendingCommands = [NSMutableDictionary dictionary];

        _commandSendStatusQueue = dispatch_queue_create("_imserver_message_sendstatus_queue", DISPATCH_QUEUE_SERIAL);

        //relash source
        __weak __typeof(&*self) weakSelf = self;
        _reflashSendStatusSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _commandSendStatusQueue);
        dispatch_source_set_timer(_reflashSendStatusSource, dispatch_walltime(NULL, 0), 3 * NSEC_PER_SEC, 0);
        dispatch_source_set_event_handler(_reflashSendStatusSource, ^{
            if (weakSelf.sendingCommands.allKeys.count <= 0) {
                dispatch_suspend(_reflashSendStatusSource);
                weakSelf.reflashSendStatusSourceActive = NO;
            }
            NSArray *sendMessageModels = weakSelf.sendingCommands.allValues.copy;
            for (SendCommandModel *sendComModel in sendMessageModels) {
                int long long currentTime = (long long int) [[NSDate date] timeIntervalSince1970];
                int long long sendDuration = currentTime - sendComModel.sendTime;
                if (sendDuration >= SOCKET_TIME_OUT) {
                    if (sendComModel.callBack) {
                        DDLogError(@"Command send overtime: extension:%d",sendComModel.sendMsg.extension);
                        sendComModel.callBack([NSError errorWithDomain:@"over_time" code:OVER_TIME_CODE userInfo:nil], nil);
                    }
                    [weakSelf.sendingCommands removeObjectForKey:sendComModel.sendMsg.msgIdentifer];
                }
            }
        });
        dispatch_resume(_reflashSendStatusSource);
        _reflashSendStatusSourceActive = YES;
    }
    return self;
}

- (void)addSendingMessage:(Message *)commandMsg callBack:(SendCommandCallback)callBack {
    if (commandMsg.extension != BM_UPLOAD_APPINFO_EXT) {
        SendCommandModel *sendComModel = [SendCommandModel new];
        sendComModel.sendMsg = commandMsg;
        sendComModel.sendTime = (long long int) [[NSDate date] timeIntervalSince1970];
        sendComModel.callBack = callBack;
        
        //save to send queue
        [self.sendingCommands setValue:sendComModel forKey:commandMsg.msgIdentifer];
        
        //open reflash
        if (!self.reflashSendStatusSourceActive) {
            dispatch_resume(self.reflashSendStatusSource);
            self.reflashSendStatusSourceActive = YES;
        }
    }
}


- (void)sendCommandSuccessWithCallbackMsg:(Message *)callBackMsg {
    [GCDQueue executeInQueue:self.commandSendStatusQueue block:^{
        Command *command = nil;
        if (callBackMsg.extension != BM_GETOFFLINE_EXT) {
            NSError *error = nil;
            command = [Command parseFromData:callBackMsg.body error:&error];
            if (error) {
                return;
            }
        }
        switch (callBackMsg.extension) {
            case BM_GETOFFLINE_EXT: {
                [self handleOfflineMessage:callBackMsg];
            }
                break;
            case BM_UNBINDDEVICETOKEN_EXT: {
                [self deviceTokenUnbind:command];
            }
                break;
            case BM_BINDDEVICETOKEN_EXT: {
                [self deviceTokenBind:command];
            }
                break;
            case BM_NEWFRIEND_EXT: {
                [self newFriendRequestDetailHandle:command];
            }
                break;
            case BM_FRIENDLIST_EXT: {
                [self handleFriendslist:command];
            }
                break;
            case BM_ACCEPT_NEWFRIEND_EXT: {
                [self acceptRequestSuccessDetail:command];
            }
                break;
            case BM_DELETE_FRIEND_EXT: {
                [self handleHandleDeleteUser:command];
            }
                break;
            case BM_SET_FRIENDINFO_EXT: {
                [self handleSetUserInfo:command];
            }
                break;
            case BM_GROUPINFO_CHANGE_EXT: {
                [self handleGroupInfoChangeWithData:command];
            }
                break;
            case BM_SYNCBADGENUMBER_EXT: {
                [self handldSyncBadgeNumber:command];
            }
                break;
            case BM_CREATE_SESSION: {
                [self handldSessionBackCall:command];
            }
                break;
            case BM_SETMUTE_SESSION: {
                [self handldSessionBackCall:command];
            }
                break;
            case BM_DELETE_SESSION: {
                [self handldSessionBackCall:command];
            }
                break;
            case BM_OUTER_TRANSFER_EXT: {
                [self handldOuterTransfer:command];
            }
                break;
            case BM_OUTER_REDPACKET_EXT: {
                [self handldOuterRedpacket:command];
            }
                break;
            case BM_RECOMMADN_NOTINTEREST_EXT: {
                [self handleRcommandNointeret:command];
            }
                break;
            case BM_UPLOAD_CHAT_COOKIE_EXT: {
                [self uploadCookieAck:command];
            }
                break;
            case BM_FRIEND_CHAT_COOKIE_EXT:
                [self chatUserCookie:command];
                break;
            case BM_FROCEUODATA_CHAT_COOKIE_EXT:{
                [self loginOnNewPhoneUploadChatCookie:command];
            }
                break;
            default:
                break;
        }
        if (command) {
            //remove command
            [self.sendingCommands removeObjectForKey:command.msgId];
            //ack
            [[IMService instance] sendIMBackAck:command.msgId];
        }
    }];
}

- (void)sendCommandFailedWithMsgId:(NSString *)messageId {
    [GCDQueue executeInQueue:self.commandSendStatusQueue block:^{
        SendCommandModel *sendComModel = [self.sendingCommands valueForKey:messageId];
        if (sendComModel.sendMsg.extension != BM_UNBINDDEVICETOKEN_EXT) {
            if (sendComModel.callBack) {
                NSError *error = [NSError errorWithDomain:@"imserver_error" code:-1 userInfo:nil];
                sendComModel.callBack(error, nil);
            }
            //send message when local chatcookie not match server chatcookie ,upload chatcookie failed 
            if (sendComModel.sendMsg.extension == BM_UPLOAD_CHAT_COOKIE_EXT) {
                UploadChatCookieModel *uploadChatCookie = sendComModel.sendMsg.sendOriginInfo;
                SendMessageModel *sendModel = uploadChatCookie.sendMessageModel;
                if (sendModel) {
                    if (sendModel.callBack) {
                        NSError *error = [NSError errorWithDomain:@"imserver" code:-1 userInfo:nil];
                        sendModel.callBack(sendModel.sendMsg, error);
                    }
                }
            }
            //remove
            [self.sendingCommands removeObjectForKey:messageId];
        }
    }];
}


#pragma mark - privket method

- (void)handleOfflineMessage:(Message *)msg {
    NSData *offlineData = [msg.body gunzippedData];
    OfflineMsgs *offlinemsg = [OfflineMsgs parseFromData:offlineData error:nil];
    NSMutableArray *offLineNomarlMessages = [NSMutableArray array];
    NSMutableArray *offLineCreateGroupMessages = [NSMutableArray array];
    NSMutableArray *offLinGroupMessages = [NSMutableArray array];
    NSMutableArray *offLineRoobtMessages = [NSMutableArray array];
    for (OfflineMsg *messageDetail in offlinemsg.offlineMsgsArray) {
        int type = messageDetail.body.type;
        int extension = messageDetail.body.ext;
        if (messageDetail.body.data_p.length == 0) {
            continue;
        }
        switch (type) {
            case BM_IM_TYPE: {
                if (extension == BM_SERVER_NOTE_EXT) {
                    Message *noteMsg = [[Message alloc] init];
                    noteMsg.body = [NoticeMessage parseFromData:messageDetail.body.data_p error:nil];
                    [self transactionStatusChangeNoti:noteMsg];
                } else {
                    if (extension == BM_IM_ROBOT_EXT) {
                        MSMessage *sysMsg = [MSMessage parseFromData:messageDetail.body.data_p error:nil];
                        [offLineRoobtMessages objectAddObject:sysMsg];
                    } else {
                        MessagePost *post = [MessagePost parseFromData:messageDetail.body.data_p error:nil];
                        BOOL isSign = [ConnectTool vertifyWithData:post.msgData.data sign:post.sign publickey:post.pubKey];
                        if (!isSign) {
                            continue;
                        }
                        switch (extension) {
                            case BM_IM_MESSAGE_ACK_EXT: //message read ack
                            case BM_IM_EXT: //friend message
                            {
                                [offLineNomarlMessages objectAddObject:post];
                            }
                                break;

                            case BM_IM_SEND_GROUPINFO_EXT: //group create
                            {
                                [offLineCreateGroupMessages objectAddObject:post];
                            }
                                break;

                            case BM_IM_GROUPMESSAGE_EXT: //group message
                            {
                                [offLinGroupMessages objectAddObject:post];
                            }
                                break;
                            default:
                                return;
                                break;
                        }
                    }
                }
            }
                break;
            case BM_COMMAND_TYPE: {
                [self handldOfflineCmdData:messageDetail.body.data_p cmdType:extension];
            }
                break;
            default:
                break;
        }
    }

    [[GroupMessageHandler instance] handleBatchGroupInviteMessage:offLineCreateGroupMessages];

    [[PeerMessageHandler instance] handleBatchMessages:offLineNomarlMessages];

    [[GroupMessageHandler instance] handleBatchGroupMessage:offLinGroupMessages];

    [[SystemMessageHandler instance] handleBatchMessages:offLineRoobtMessages];

    for (OfflineMsg *messageDetail in offlinemsg.offlineMsgsArray) {
        int type = messageDetail.body.type;
        [[IMService instance] sendOfflineAck:messageDetail.msgId type:type];
    }
    if (offlinemsg.completed) {
        [GCDQueue executeInMainQueue:^{
            [[IMService instance] publishConnectState:STATE_CONNECTED];
        }];
    }
}


- (void)transactionStatusChangeNoti:(Message *)msg {
    NoticeMessage *notice = (NoticeMessage *) msg.body;
    NSString *hashId = nil;
    NSString *operation = @"";
    Crowdfunding *crowdfunding;
    NSString *identifier = nil;
    ChatMessageInfo *chatMessage = [ChatMessageInfo new];
    switch (notice.category) {
        case 0: //stringer transfer
        {
            NSError *error = nil;
            TransferNotice *transfer = [TransferNotice parseFromData:notice.body error:&error];
            if (!error) {
                [self createChatWithHashId:transfer.hashId sender:transfer.sender reciver:transfer.receiver Amount:transfer.amount isOutTransfer:NO];
            }
        }
            break;
        case 1: //transfer confirm
        {
            NSError *error = nil;
            TransactionNotice *traction = [TransactionNotice parseFromData:notice.body error:&error];
            identifier = [[UserDBManager sharedManager] getUserPubkeyByAddress:traction.identifer];
            if (!error) {
                hashId = traction.hashId;
                [[LMMessageExtendManager sharedManager] updateMessageExtendStatus:traction.status withHashId:traction.hashId];
            }
        }
            break;
        case 2: //someone garb your luckypackage
        {
            NSError *error = nil;
            RedPackageNotice *redNotice = [RedPackageNotice parseFromData:notice.body error:&error];
            if (!error) {
                operation = [NSString stringWithFormat:@"%@/%@", redNotice.sender, redNotice.receiver];
                hashId = redNotice.hashId;

                chatMessage = [[ChatMessageInfo alloc] init];
                chatMessage.messageId = [ConnectTool generateMessageId];
                if (redNotice.category == 1) {
                    identifier = redNotice.identifer;
                } else {
                    identifier = [[UserDBManager sharedManager] getUserPubkeyByAddress:redNotice.receiver];
                }
                chatMessage.messageOwer = identifier;//transaction.idetifier;
                chatMessage.messageType = GJGCChatFriendContentTypeStatusTip;
                chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                chatMessage.createTime = (NSInteger) (long long) ([[NSDate date] timeIntervalSince1970] * 1000);
                MMMessage *message = [[MMMessage alloc] init];
                message.type = GJGCChatFriendContentTypeStatusTip;
                message.content = operation;
                message.ext1 = @(notice.category);
                message.sendtime = (long long int) ([[NSDate date] timeIntervalSince1970] * 1000);
                message.message_id = chatMessage.messageId;
                message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                chatMessage.message = message;
                [[MessageDBManager sharedManager] saveMessage:chatMessage];
            }
        }
            break;
        case 3: //receipt payed by friend
        case 5: {
            NSError *error = nil;
            BillNotice *bill = [BillNotice parseFromData:notice.body error:&error];
            if (!error) {
                operation = [NSString stringWithFormat:@"%@/%@", bill.receiver, bill.sender];
                hashId = bill.hashId;

                chatMessage = [[ChatMessageInfo alloc] init];
                chatMessage.messageId = [ConnectTool generateMessageId];
                identifier = [[UserDBManager sharedManager] getUserPubkeyByAddress:bill.sender]; //sender  payer
                if (GJCFStringIsNull(identifier)) {
                    DDLogError(@"case 3 5 : //bill payed note? server error bill.sender:%@", bill.sender);
                    return;
                }
                chatMessage.messageOwer = identifier;
                chatMessage.messageType = GJGCChatFriendContentTypeStatusTip;
                chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                chatMessage.createTime = (NSInteger) ([[NSDate date] timeIntervalSince1970] * 1000);
                MMMessage *message = [[MMMessage alloc] init];
                message.type = GJGCChatFriendContentTypeStatusTip;
                message.content = operation;
                message.ext1 = @(notice.category);
                message.sendtime = (long long int) ([[NSDate date] timeIntervalSince1970] * 1000);
                message.message_id = chatMessage.messageId;
                message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                chatMessage.message = message;
                [[MessageDBManager sharedManager] saveMessage:chatMessage];
                //updata trancation status
                [[LMMessageExtendManager sharedManager] updateMessageExtendStatus:bill.status withHashId:hashId];
            }
        }
            break;
        case 4: //outer transfer
        {
            NSError *error = nil;
            TransferNotice *transfer = [TransferNotice parseFromData:notice.body error:&error];
            if (!error) {
                [self createChatWithHashId:transfer.hashId sender:transfer.sender reciver:transfer.receiver Amount:transfer.amount isOutTransfer:YES];
            }
        }
            break;
        case 6: //crowding payed
        {
            NSError *error = nil;
            CrowdfundingNotice *bill = [CrowdfundingNotice parseFromData:notice.body error:&error]; //receiver 支付者 sender 发起者
            if (!error) {
                operation = [NSString stringWithFormat:@"%@/%@", bill.sender, bill.receiver];
                hashId = bill.hashId;
                identifier = bill.groupId;

                chatMessage = [[ChatMessageInfo alloc] init];
                chatMessage.messageId = [ConnectTool generateMessageId];
                chatMessage.messageOwer = bill.groupId;
                chatMessage.messageType = GJGCChatFriendContentTypeStatusTip;
                chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                chatMessage.createTime = (NSInteger) ([[NSDate date] timeIntervalSince1970] * 1000);
                MMMessage *message = [[MMMessage alloc] init];
                message.type = GJGCChatFriendContentTypeStatusTip;
                message.content = operation;
                message.ext1 = @(notice.category);
                message.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
                message.message_id = chatMessage.messageId;
                message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                chatMessage.message = message;
                [[MessageDBManager sharedManager] saveMessage:chatMessage];

                [[LMMessageExtendManager sharedManager] updateMessageExtendPayCount:(int) (bill.crowdfunding.size - bill.crowdfunding.remainSize) status:(int) bill.crowdfunding.status withHashId:bill.crowdfunding.hashId];

                if (bill.crowdfunding.remainSize == 0) { //crowding complete
                    crowdfunding = bill.crowdfunding;
                    ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
                    chatMessage.messageId = [ConnectTool generateMessageId];
                    chatMessage.messageOwer = bill.groupId;
                    chatMessage.messageType = GJGCChatFriendContentTypeStatusTip;
                    chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                    chatMessage.createTime = (long long) ([[NSDate date] timeIntervalSince1970] * 1000);
                    MMMessage *message = [[MMMessage alloc] init];
                    message.type = GJGCChatFriendContentTypeStatusTip;
                    message.content = LMLocalizedString(@"Chat Founded complete", nil);
                    message.sendtime = chatMessage.createTime;
                    message.message_id = chatMessage.messageId;
                    message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                    chatMessage.message = message;
                    [[MessageDBManager sharedManager] saveMessage:chatMessage];
                }
            }
        }
            break;
        default:
            break;
    }
    if (hashId) {

        NSMutableDictionary *noteDict = [NSMutableDictionary dictionary];
        [noteDict setObject:hashId forKey:@"hashId"];
        [noteDict setObject:chatMessage forKey:@"chatMessage"];
        if (crowdfunding) {
            [noteDict setObject:crowdfunding forKey:@"crowdfunding"];
        }
        [noteDict setObject:notice forKey:@"notice"];
        [noteDict setObject:identifier forKey:@"identifier"];
        SendNotify(TransactionStatusChangeNotification, (noteDict));
    }

    //send ack
    [[IMService instance] sendOnlineBackAck:notice.msgId type:msg.typechar];
}

- (void)handldOfflineCmdData:(NSData *)data cmdType:(int)cmdType {
    
    NSError *error = nil;
    Command *command = [Command parseFromData:data error:&error];
    if (error) {
        return;
    }
    switch (cmdType) {
        case BM_ACCEPT_NEWFRIEND_EXT: {
            [self acceptRequestSuccessDetail:command];
        }
            break;
        case BM_NEWFRIEND_EXT:
            [self newFriendRequestDetailHandle:command];
            break;
        case BM_GROUPINFO_CHANGE_EXT:
            [self handleGroupInfoChangeWithData:command];
            break;
        default:
            break;
    }
}

- (void)newFriendRequestDetailHandle:(Command *)command {
    SendCommandModel *sendComModel = [self.sendingCommands valueForKey:command.msgId];
    Message *oriMsg = sendComModel.sendMsg;
    if (!oriMsg) {
        NSError *error = nil;
        ReceiveFriendRequest *receveRequest = [ReceiveFriendRequest parseFromData:command.detail error:&error];
        if (error) {
            return;
        }
        NSString *tips = [ConnectTool decodeGcmData:receveRequest.tips publickey:receveRequest.sender.pubKey];
        if (GJCFStringIsNull(receveRequest.sender.address)) {
            return;
        }

        AccountInfo *newFriend = [[AccountInfo alloc] init];
        newFriend.username = receveRequest.sender.username;
        newFriend.avatar = receveRequest.sender.avatar;
        newFriend.pub_key = receveRequest.sender.pubKey;
        newFriend.address = receveRequest.sender.address;
        newFriend.message = tips;
        newFriend.source = receveRequest.source;
        newFriend.status = RequestFriendStatusAccept;

        [[UserDBManager sharedManager] saveNewFriend:newFriend];
        [GCDQueue executeInMainQueue:^{
            SendNotify(kNewFriendRequestNotification, newFriend);
        }];
    } else {
        
        switch (command.errNo) {
            case 3:
            case 1:
            {
                if (sendComModel.callBack) {
                    sendComModel.callBack([NSError errorWithDomain:@"" code:command.errNo userInfo:nil], nil);
                }
            }
                break;
            default:
                if (sendComModel.callBack) {
                    sendComModel.callBack(nil, oriMsg.sendOriginInfo);
                }
                break;
        }
    }
}

- (void)loginOnNewPhoneUploadChatCookie:(Command *)command {
    DDLogInfo(@"command %@",command);
    [[IMService instance] uploadCookieDuetoLocalChatCookieNotMatchServerChatCookieWithMessageCallModel:nil];
}

- (void)handleGroupInfoChangeWithData:(Command *)command {
    GroupChange *groupChange = [GroupChange parseFromData:command.detail error:nil];
    [self handleGroupInfoDetailChange:groupChange messageId:command.msgId];
}

/**
 *  0: group info change,
 *  1: add new member,
 *  2: quit group
 *  3: group member info change
 *  4：group owner/adminer change
 *
 *  @param groupChange
 */
- (void)handleGroupInfoDetailChange:(GroupChange *)groupChange messageId:(NSString *)msgId {
    [SetGlobalHandler getGroupInfoWihtIdentifier:groupChange.identifier complete:^(LMGroupInfo *lmGroup, NSError *error) {
        if (lmGroup) {
            switch (groupChange.changeType) {
                case 0: {
                    NSError *error = nil;
                    Group *group = [Group parseFromData:groupChange.detail error:&error];
                    if (!error && group) {

                        if (!lmGroup) {
                            return;
                        }
                        if (group.public_p != lmGroup.isPublic) {
                            [[GroupDBManager sharedManager] updateGroupPublic:group.public_p groupId:group.identifier];
                        }
                        if (![group.summary isEqualToString:lmGroup.summary]) {
                            [[GroupDBManager sharedManager] addGroupSummary:group.summary withGroupId:group.identifier];
                        }
                        if (![group.name isEqualToString:lmGroup.groupName]) {
                            group.name = [StringTool filterStr:group.name];
                            [[GroupDBManager sharedManager] updateGroupName:group.name groupId:group.identifier];
                        }
                    }
                }
                    break;
                case 1: {
                    NSError *error = nil;
                    UsersInfo *usersInfo = [UsersInfo parseFromData:groupChange.detail error:&error];
                    if (lmGroup.groupMembers.count < 9) {
                        [[YYImageCache sharedCache] removeImageForKey:lmGroup.avatarUrl];
                    }

                    if (groupChange.inviteBy && groupChange.inviteBy.username) {
                        NSMutableArray *newUsers = [NSMutableArray array];
                        NSMutableString *welcomeTip = [NSMutableString string];
                        for (UserInfo *userInfo in usersInfo.usersArray) {
                            AccountInfo *newUser = [[AccountInfo alloc] init];
                            newUser.username = userInfo.username;
                            newUser.avatar = userInfo.avatar;
                            newUser.address = userInfo.address;
                            newUser.pub_key = userInfo.pubKey;
                            [newUsers objectAddObject:newUser];
                            if ([userInfo.address isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                                [welcomeTip appendString:LMLocalizedString(@"Chat You", nil)];
                            } else {
                                [welcomeTip appendString:userInfo.username];
                            }
                            if (userInfo != [usersInfo.usersArray lastObject]) {
                                [welcomeTip appendString:@"、"];
                            }
                        }

                        if ([groupChange.inviteBy.address isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                            groupChange.inviteBy.username = LMLocalizedString(@"Chat You", nil);
                        }

                        NSString *myChatTip = [NSString stringWithFormat:LMLocalizedString(@"Link invited to the group chat", nil), groupChange.inviteBy.username, welcomeTip];

                        ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
                        chatMessage.messageId = [ConnectTool generateMessageId];
                        chatMessage.messageOwer = groupChange.identifier;
                        chatMessage.messageType = GJGCChatFriendContentTypeStatusTip;
                        chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                        chatMessage.createTime = (long long) ([[NSDate date] timeIntervalSince1970] * 1000);
                        MMMessage *message = [[MMMessage alloc] init];
                        message.publicKey = groupChange.identifier;
                        message.user_id = groupChange.identifier;
                        message.type = GJGCChatFriendContentTypeStatusTip;
                        message.content = myChatTip;
                        message.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
                        message.message_id = chatMessage.messageId;
                        message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                        chatMessage.message = message;
                        [[MessageDBManager sharedManager] saveMessage:chatMessage];

                        [[RecentChatDBManager sharedManager] createNewChatWithIdentifier:groupChange.identifier groupChat:YES lastContentShowType:0 lastContent:[GJGCChatFriendConstans lastContentMessageWithType:message.type textMessage:message.content] ecdhKey:lmGroup.groupEcdhKey talkName:lmGroup.groupName];

                        if ([[SessionManager sharedManager].chatSession isEqualToString:groupChange.identifier]) {
                            SendNotify(GroupNewMemberEnterNotification, chatMessage);
                        }
                    } else {
                        NSMutableArray *newUsers = [NSMutableArray array];
                        for (UserInfo *userInfo in usersInfo.usersArray) {
                            AccountInfo *newUser = [[AccountInfo alloc] init];
                            newUser.username = userInfo.username;
                            newUser.avatar = userInfo.avatar;
                            newUser.address = userInfo.address;
                            newUser.pub_key = userInfo.pubKey;
                            [newUsers objectAddObject:newUser];

                            ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
                            chatMessage.messageId = [ConnectTool generateMessageId];
                            chatMessage.messageOwer = groupChange.identifier;
                            chatMessage.messageType = GJGCChatFriendContentTypeStatusTip;
                            chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                            chatMessage.createTime = (long long) ([[NSDate date] timeIntervalSince1970] * 1000);
                            MMMessage *message = [[MMMessage alloc] init];
                            message.publicKey = groupChange.identifier;
                            message.user_id = groupChange.identifier;
                            message.type = GJGCChatFriendContentTypeStatusTip;
                            message.content = [NSString stringWithFormat:LMLocalizedString(@"Link enter the group", nil), userInfo.username];
                            message.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
                            message.message_id = chatMessage.messageId;
                            message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                            chatMessage.message = message;
                            [[MessageDBManager sharedManager] saveMessage:chatMessage];

                            [[RecentChatDBManager sharedManager] createNewChatWithIdentifier:groupChange.identifier groupChat:YES lastContentShowType:0 lastContent:[GJGCChatFriendConstans lastContentMessageWithType:message.type textMessage:message.content] ecdhKey:lmGroup.groupEcdhKey talkName:lmGroup.groupName];

                            if ([[SessionManager sharedManager].chatSession isEqualToString:groupChange.identifier]) {
                                SendNotify(GroupNewMemberEnterNotification, chatMessage);
                            }
                        }
                    }
                }
                    break;

                case 2: {
                    NSError *error = nil;
                    QuitGroupUserAddress *quitAddresses = [QuitGroupUserAddress parseFromData:groupChange.detail error:&error];

                    if (lmGroup.groupMembers.count - quitAddresses.addressesArray.count < 9) {
                        [[YYImageCache sharedCache] removeImageForKey:lmGroup.avatarUrl];
                    }

                    if (!error) {
                        if (!lmGroup) {
                            return;
                        }
                        NSMutableArray *willDeleteMember = [NSMutableArray array];
                        NSMutableArray *avatars = [NSMutableArray array];
                        for (NSString *quitAddress in quitAddresses.addressesArray) {
                            for (AccountInfo *member in lmGroup.groupMembers) {
                                if ([member.address isEqualToString:quitAddress]) {
                                    [willDeleteMember objectAddObject:member];
                                    [[GroupDBManager sharedManager] removeMemberWithAddress:member.address groupId:groupChange.identifier];
                                } else {
                                    [avatars objectAddObject:member.avatar];
                                }
                            }
                        }
                        [lmGroup.groupMembers.mutableCopy removeObjectsInArray:willDeleteMember];

                        NSArray *groupArray = [[GroupDBManager sharedManager] getgroupMemberByGroupIdentifier:groupChange.identifier];
                        if (groupArray.count <= 1) {
                            [[GroupDBManager sharedManager] deletegroupWithGroupId:groupChange.identifier];
                        }
                    }
                }
                    break;

                case 3: {
                    NSError *error = nil;
                    ChangeGroupNick *changeNick = [ChangeGroupNick parseFromData:groupChange.detail error:&error];
                    if (!error) {
                        if (!lmGroup) {
                            return;
                        }
                        for (AccountInfo *member in lmGroup.groupMembers) {
                            if ([member.address isEqualToString:changeNick.address]) {
                                member.groupNickName = changeNick.nick;

                                [[GroupDBManager sharedManager] updateGroupMembserNick:changeNick.nick address:changeNick.address groupId:lmGroup.groupIdentifer];
                                break;
                            }
                        }

                    }
                }
                    break;
                case 4: {
                    NSError *error = nil;
                    GroupAttorn *attorn = [GroupAttorn parseFromData:groupChange.detail error:&error];
                    if (!error) {
                        if (!lmGroup) {
                            return;
                        }
                        for (AccountInfo *member in lmGroup.groupMembers) {
                            if ([member.address isEqualToString:attorn.address]) {

                                ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
                                chatMessage.messageId = [ConnectTool generateMessageId];
                                chatMessage.messageOwer = attorn.identifier;
                                chatMessage.messageType = GJGCChatFriendContentTypeStatusTip;
                                chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                                chatMessage.createTime = (long long) ([[NSDate date] timeIntervalSince1970] * 1000);
                                MMMessage *message = [[MMMessage alloc] init];
                                message.publicKey = attorn.identifier;
                                message.user_id = attorn.identifier;
                                message.type = GJGCChatFriendContentTypeStatusTip;
                                message.content = [NSString stringWithFormat:LMLocalizedString(@"Link become new group owner", nil), member.username];
                                message.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
                                message.message_id = chatMessage.messageId;
                                message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                                chatMessage.message = message;
                                [[MessageDBManager sharedManager] saveMessage:chatMessage];

                                [[RecentChatDBManager sharedManager] createNewChatWithIdentifier:groupChange.identifier groupChat:YES lastContentShowType:1 lastContent:message.content ecdhKey:lmGroup.groupEcdhKey talkName:lmGroup.groupName];
                                member.roleInGroup = 1;

                                [[GroupDBManager sharedManager] setGroupNewAdmin:member.address groupId:lmGroup.groupIdentifer];

                                if ([[SessionManager sharedManager].chatSession isEqualToString:attorn.identifier]) {
                                    SendNotify(GroupAdminChangeNotification, chatMessage);
                                }
                            } else {
                                member.roleInGroup = 0;
                            }
                        }
                    }
                }
                    break;
                default:
                    break;
            }

            if (lmGroup.groupMembers.count != groupChange.count) {
                [SetGlobalHandler downGroupInfoWithGroupIdentifer:groupChange.identifier complete:^(NSError *error) {
                    if (!error) {
                        if (groupChange.changeType != 4) {
                            [GCDQueue executeInMainQueue:^{
                                SendNotify(ConnnectGroupInfoDidChangeNotification, groupChange.identifier);
                            }];
                        }
                    }
                }];
            } else {
                if (groupChange.changeType != 4) {
                    [GCDQueue executeInMainQueue:^{
                        SendNotify(ConnnectGroupInfoDidChangeNotification, groupChange.identifier);
                    }];
                }
            }
        }
    }];
}

- (void)createChatWithHashId:(NSString *)hashId sender:(UserInfo *)sender reciver:(UserInfo *)reciver Amount:(long long)amount isOutTransfer:(BOOL)isOutTransfer {

    if (GJCFStringIsNull(hashId) || !reciver || !sender) {
        return;
    }
    MMMessage *message = nil;
    AccountInfo *reciverUser = [[AccountInfo alloc] init];
    reciverUser.address = reciver.address;
    reciverUser.pub_key = reciver.pubKey;
    reciverUser.avatar = reciver.avatar;
    reciverUser.username = reciver.username;

    AccountInfo *senderUser = [[AccountInfo alloc] init];
    senderUser.address = sender.address;
    senderUser.pub_key = sender.pubKey;
    senderUser.avatar = sender.avatar;
    senderUser.username = sender.username;

    if ([sender.address isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
        message = [[MessageDBManager sharedManager] createSendtoOtherTransactionMessageWithMessageOwer:reciverUser hashId:hashId monney:[PayTool getBtcStringWithAmount:amount] isOutTransfer:isOutTransfer];
        if ([[UserDBManager sharedManager] isFriendByAddress:reciverUser.address]) {
            RecentChatModel *model = [[RecentChatDBManager sharedManager] createNewChatWithIdentifier:reciverUser.pub_key groupChat:NO lastContentShowType:1 lastContent:[GJGCChatFriendConstans lastContentMessageWithType:message.type textMessage:nil]];
            [GCDQueue executeInMainQueue:^{
                SendNotify(ConnnectRecentChatChangeNotification, model);
            }];
        } else {
            [[RecentChatDBManager sharedManager] createNewChatNoRelationShipWihtRegisterUser:reciverUser];
        }

    } else {
        message = [[MessageDBManager sharedManager] createSendtoMyselfTransactionMessageWithMessageOwer:senderUser hashId:hashId monney:[PayTool getBtcStringWithAmount:amount] isOutTransfer:isOutTransfer];
        if ([[UserDBManager sharedManager] isFriendByAddress:senderUser.address]) {
            RecentChatModel *model = [[RecentChatDBManager sharedManager] createNewChatWithIdentifier:senderUser.pub_key groupChat:NO lastContentShowType:0 lastContent:[GJGCChatFriendConstans lastContentMessageWithType:message.type textMessage:nil]];
            [GCDQueue executeInMainQueue:^{
                SendNotify(ConnnectRecentChatChangeNotification, model);
            }];
        } else {
            [[RecentChatDBManager sharedManager] createNewChatNoRelationShipWihtRegisterUser:senderUser];
        }
    }
}

- (void)deviceTokenBind:(Command *)command{
    
}


- (void)handleFriendslist:(Command *)command {
    NSString *version = @"";
    SendCommandModel *sendComModel = [self.sendingCommands valueForKey:command.msgId];
    Message *oriMsg = sendComModel.sendMsg;

    if ([oriMsg.sendOriginInfo isKindOfClass:[NSString class]] &&
            [oriMsg.sendOriginInfo isEqualToString:@"syncfriend"]) {
        NSError *error = nil;
        SyncUserRelationship *syncRalation = [SyncUserRelationship parseFromData:command.detail error:&error];
        if (error) {
            return;
        }

        RelationShip *friendList = syncRalation.relationShip;
        if (error) {
            return;
        }
        [[UserDBManager sharedManager] getAllUsersNoConnectWithComplete:^(NSArray *users) {
            NSMutableArray *usersM = [NSMutableArray arrayWithArray:users];
            NSMutableArray *temA = @[].mutableCopy;
            for (FriendInfo *friend in friendList.friendsArray) {
                AccountInfo *user = [[AccountInfo alloc] init];
                user.username = friend.username;
                user.address = friend.address;
                user.pub_key = friend.pubKey;
                user.avatar = friend.avatar;
                user.isOffenContact = friend.common;
                user.source = (UserSourceType) friend.source;
                user.remarks = friend.remark;
                if (![usersM containsObject:user]) {
                    [temA objectAddObject:user];
                } else {
                    [usersM objectAddObject:user];
                }
            }

            [[UserDBManager sharedManager] batchSaveUsers:temA];

            if (sendComModel.callBack) {
                sendComModel.callBack(nil, usersM);
            }

        }];
        version = friendList.version;
    } else {
        if ([[[MMAppSetting sharedSetting] getContactVersion] isEqualToString:@""] ||
                [[[MMAppSetting sharedSetting] getContactVersion] isEqualToString:@"0"]) {
            NSError *error = nil;
            SyncUserRelationship *syncRalation = [SyncUserRelationship parseFromData:command.detail error:&error];
            if (error) {
                return;
            }
            //friend
            RelationShip *friendList = syncRalation.relationShip;
            //common group
            UserCommonGroups *userGroups = syncRalation.userCommonGroups;

            NSMutableArray *users = @[].mutableCopy;
            for (FriendInfo *friend in friendList.friendsArray) {
                AccountInfo *user = [[AccountInfo alloc] init];
                user.username = friend.username;
                user.address = friend.address;
                user.pub_key = friend.pubKey;
                user.avatar = friend.avatar;
                user.isOffenContact = friend.common;
                user.source = friend.source;
                user.remarks = friend.remark;
                [users objectAddObject:user];
            }
            if (users.count) {
                [[UserDBManager sharedManager] batchSaveUsers:users];
            }

            for (GroupInfo *groupInfo in userGroups.groupsArray) {
                NSString *groupKey = nil;
                if (!GJCFStringIsNull(groupInfo.ecdh)) {
                    NSArray *array = [groupInfo.ecdh componentsSeparatedByString:@"/"];
                    if (array.count == 2) {
                        NSString *randomPublickey = [array objectAtIndexCheck:0];
                        NSData *ecdhKey = [KeyHandle getECDHkeyWithPrivkey:[[LKUserCenter shareCenter] currentLoginUser].prikey publicKey:randomPublickey];
                        ecdhKey = [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdhKey salt:[ConnectTool get64ZeroData]];
                        GcmData *ecdhKeyGcmData = [GcmData parseFromData:[StringTool hexStringToData:[array objectAtIndexCheck:1]] error:nil];
                        NSData *ecdh = [ConnectTool decodeGcmDataWithEcdhKey:ecdhKey GcmData:ecdhKeyGcmData haveStructData:NO];
                        groupKey = [[NSString alloc] initWithData:ecdh encoding:NSUTF8StringEncoding];
                    }
                }

                if (GJCFStringIsNull(groupKey)) {
                    NSArray *temA = [groupInfo.backup componentsSeparatedByString:@"/"];
                    if (temA.count == 2) {
                        NSString *pub = [temA objectAtIndexCheck:0];
                        NSString *hex = [temA objectAtIndexCheck:1];
                        NSData *data = [StringTool hexStringToData:hex];
                        NSError *error = nil;
                        GcmData *gcmData = [GcmData parseFromData:data error:&error];
                        if (!error) {
                            NSData *data = [ConnectTool decodeGcmDataWithGcmData:gcmData publickey:pub needEmptySalt:YES];
                            CreateGroupMessage *createGroup = [CreateGroupMessage parseFromData:data error:&error];
                            groupKey = createGroup.secretKey;
                        }
                    }
                }
                if (GJCFStringIsNull(groupKey)) {
                    continue;
                }
                LMGroupInfo *lmGroup = [[LMGroupInfo alloc] init];
                lmGroup.groupName = groupInfo.group.name;
                lmGroup.groupIdentifer = groupInfo.group.identifier;
                lmGroup.groupEcdhKey = groupKey;
                lmGroup.isCommonGroup = YES;
                lmGroup.isPublic = groupInfo.group.public_p;
                lmGroup.isGroupVerify = groupInfo.group.reviewed;
                lmGroup.summary = groupInfo.group.summary;
                lmGroup.avatarUrl = groupInfo.group.avatar;

                NSMutableArray *AccoutInfoArray = [NSMutableArray array];
                for (GroupMember *member in groupInfo.membersArray) {
                    AccountInfo *accountInfo = [[AccountInfo alloc] init];
                    accountInfo.username = member.username;
                    accountInfo.avatar = member.avatar;
                    accountInfo.address = member.address;
                    accountInfo.roleInGroup = member.role;
                    accountInfo.groupNickName = member.nick;
                    accountInfo.pub_key = member.pubKey;
                    [AccoutInfoArray objectAddObject:accountInfo];
                }
                lmGroup.groupMembers = AccoutInfoArray;

                [[GroupDBManager sharedManager] savegroup:lmGroup];
            }
            if ([[[MMAppSetting sharedSetting] getContactVersion] isEqualToString:@""]) {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow.rootViewController.view];
                }];
                [[RecentChatDBManager sharedManager] createConnectTermWelcomebackChatAndMessage];
            } else {
                for (AccountInfo *addUser in users) {
                    if (sendComModel.callBack) {
                        sendComModel.callBack(nil, addUser);
                    }
                }
            }
            version = friendList.version;
        } else {
            NSError *error = nil;
            ChangeRecords *changes = [ChangeRecords parseFromData:command.detail error:&error];
            if (error) {
                return;
            }
            NSMutableArray *addUsers = [NSMutableArray array];

            for (ChangeRecord *record in changes.changeRecordsArray) {
                if ([record.category isEqualToString:@"del"]) {
                    [[UserDBManager sharedManager] deleteUserByAddress:record.address];
                } else if ([record.category isEqualToString:@"add"]) {
                    AccountInfo *addUser = [[AccountInfo alloc] init];
                    addUser.username = record.userInfo.username;
                    addUser.address = record.userInfo.address;
                    addUser.avatar = record.userInfo.avatar;
                    addUser.pub_key = record.userInfo.pubKey;
                    addUser.source = record.userInfo.source;
                    addUser.stranger = NO;
                    [addUsers objectAddObject:addUser];
                }
            }
            if (addUsers.count) {
                [[UserDBManager sharedManager] batchSaveUsers:addUsers];
                for (AccountInfo *addUser in addUsers) {
                    if (sendComModel.callBack) {
                        sendComModel.callBack(nil, addUser);
                    }
                }
            }
            version = changes.version;
        }
    }

    [[MMAppSetting sharedSetting] saveContactVersion:version];
    [GCDQueue executeInMainQueue:^{
        SendNotify(kFriendListChangeNotification, nil);
    }];
}


- (void)handleHandleDeleteUser:(Command *)command {

    SendCommandModel *sendComModel = [self.sendingCommands valueForKey:command.msgId];
    Message *oriMsg = sendComModel.sendMsg;
    
    AccountInfo *deleteUser = [[UserDBManager sharedManager] getUserByAddress:oriMsg.sendOriginInfo];

    //delete user
    [[UserDBManager sharedManager] deleteUserBypubkey:deleteUser.pub_key];

    [GCDQueue executeInMainQueue:^{
        SendNotify(ConnnectContactDidChangeDeleteUserNotification, deleteUser);
    }];

    if (command.errNo > 0) {
        if (sendComModel.callBack) {
            sendComModel.callBack([NSError errorWithDomain:command.msg code:command.errNo userInfo:nil], nil);
        }
    } else {
        if (sendComModel.callBack) {
            sendComModel.callBack(nil, oriMsg.sendOriginInfo);
        }
        [[IMService instance] getFriendsWithVersion:[[MMAppSetting sharedSetting] getContactVersion] comlete:^(NSError *erro, id data) {

        }];
    }
}

- (void)handleSetUserInfo:(Command *)command {
    SendCommandModel *sendComModel = [self.sendingCommands valueForKey:command.msgId];
    if (sendComModel.callBack) {
        sendComModel.callBack(nil, nil);
    }
}

- (void)handldSyncBadgeNumber:(Command *)command {
    
}

- (void)handldSessionBackCall:(Command *)command {
    SendCommandModel *sendComModel = [self.sendingCommands valueForKey:command.msgId];
    if (sendComModel.callBack) {
        sendComModel.callBack(nil, nil);
    }
}


- (void)handldOuterTransfer:(Command *)command {
    NSString *message = LMLocalizedString(@"Link Unknown error", nil);
    switch (command.errNo) {
        case 1://transfer not exists
        {
            message = LMLocalizedString(@"Chat Failed to get transfer", nil);
        }
            break;
        case 2://can not recive your transfer
        {
            message = LMLocalizedString(@"Wallet Could not get himself sent money transfer", nil);
        }
            break;
        case 0: {
            message = LMLocalizedString(@"Chat Accept success", nil);
        }

        default:
            break;
    }

    [GCDQueue executeInMainQueue:^{
        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        window.userInteractionEnabled = YES;
        [MBProgressHUD hideHUDForView:window animated:YES];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:window animated:YES];
        hud.mode = MBProgressHUDModeCustomView;
        hud.labelText = message;
        if (command.errNo == 0) {
            hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"top_success_icon"]];
        } else {
            hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"attention_message"]];
        }
        [hud hide:YES afterDelay:2.f];
    }];
}


- (void)handldOuterRedpacket:(Command *)command {
    NSString *message = LMLocalizedString(@"Link Unknown error", nil);
    switch (command.errNo) {
        case 0: {
            message = LMLocalizedString(@"Chat You receive a red envelope", nil);
            ExternalRedPackageInfo *redPackgeinfo = [ExternalRedPackageInfo parseFromData:command.detail error:nil];
            if (redPackgeinfo.system) { //system package
                UserInfo *system = [UserInfo new];
                system.pubKey = kSystemIdendifier;
                system.address = @"Connect";
                system.avatar = @"connect_logo";
                system.username = @"Connect";
                redPackgeinfo.sender = system;
            }

            AccountInfo *senderUser = [[UserDBManager sharedManager] getUserByPublickey:redPackgeinfo.sender.pubKey];
            if (!senderUser) {
                senderUser = [[AccountInfo alloc] init];
            }
            senderUser.address = redPackgeinfo.sender.address;
            senderUser.pub_key = redPackgeinfo.sender.pubKey;
            senderUser.avatar = redPackgeinfo.sender.avatar;
            senderUser.username = redPackgeinfo.sender.username;
            if (![[MessageDBManager sharedManager] isMessageIsExistWithMessageId:redPackgeinfo.msgId messageOwer:redPackgeinfo.sender.pubKey]) {

                MMMessage *messageInfo = [[MMMessage alloc] init];
                messageInfo.message_id = redPackgeinfo.msgId;
                messageInfo.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
                messageInfo.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                messageInfo.user_id = [[LKUserCenter shareCenter] currentLoginUser].address;
                messageInfo.type = GJGCChatFriendContentTypeRedEnvelope;
                messageInfo.user_name = [[LKUserCenter shareCenter] currentLoginUser].username;
                messageInfo.publicKey = [[LKUserCenter shareCenter] currentLoginUser].pub_key;
                messageInfo.content = redPackgeinfo.hashId;
                ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
                chatMessage.messageId = messageInfo.message_id;
                chatMessage.createTime = messageInfo.sendtime;
                chatMessage.readTime = 0;
                chatMessage.message = messageInfo;
                chatMessage.messageOwer = senderUser.pub_key;
                chatMessage.messageType = messageInfo.type;
                chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                chatMessage.senderAddress = senderUser.address;
                [[MessageDBManager sharedManager] saveMessage:chatMessage];

                if (!senderUser.stranger) {
                    RecentChatModel *model = [[RecentChatDBManager sharedManager] createNewChatWithIdentifier:senderUser.pub_key groupChat:NO lastContentShowType:0 lastContent:[GJGCChatFriendConstans lastContentMessageWithType:messageInfo.type textMessage:nil]];
                    [GCDQueue executeInMainQueue:^{
                        SendNotify(ConnnectRecentChatChangeNotification, model);
                    }];
                } else {
                    [[RecentChatDBManager sharedManager] createNewChatNoRelationShipWihtRegisterUser:senderUser];
                }

                [GCDQueue executeInMainQueue:^{
                    SendNotify(ConnectGetOuterRedpackgeNotification, (@{@"senderUser": senderUser,
                            @"hashid": redPackgeinfo.hashId}));
                }];
            } else {

                [GCDQueue executeInMainQueue:^{
                    SendNotify(ConnectGetOuterRedpackgeNotification, (@{@"senderUser": senderUser,
                            @"hashid": redPackgeinfo.hashId}));
                }];
            }
        }
        case 1: //error luckypackage
        {
            message = LMLocalizedString(@"Chat Failed to get redpact", nil);
        }
            break;
        case 2: //you garbed this luckypackage
        {
            message = LMLocalizedString(@"Wallet You already open this luckypacket", nil);
        }
            break;
        default:
            break;
    }
    [GCDQueue executeInMainQueue:^{
        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        window.userInteractionEnabled = YES;
        [MBProgressHUD hideHUDForView:window animated:YES];
        if (command.errNo != 0) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:window animated:YES];
            hud.mode = MBProgressHUDModeCustomView;
            hud.labelText = message;
            hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"attention_message"]];
            [hud hide:YES afterDelay:2.f];
        }
    }];
}

- (void)handleRcommandNointeret:(Command *)command {
    SendCommandModel *sendComModel = [self.sendingCommands valueForKey:command.msgId];
    Message *oriMsg = sendComModel.sendMsg;
    if (sendComModel.callBack) {
        if (command.errNo > 0) {
            sendComModel.callBack([NSError errorWithDomain:command.msg code:command.errNo userInfo:nil], nil);
        } else {
            sendComModel.callBack(nil, oriMsg.sendOriginInfo);
        }
    }
}

- (void)uploadCookieAck:(Command *)command {
    DDLogInfo(@"command %@",command);
    SendCommandModel *sendComModel = [self.sendingCommands valueForKey:command.msgId];
    UploadChatCookieModel *uploadChatCookie = sendComModel.sendMsg.sendOriginInfo;
    SendMessageModel *sendModel = uploadChatCookie.sendMessageModel;
    if (command.errNo == 0) {
        ChatCookieData *cacheData = uploadChatCookie.chatCookieData;
        ChatCacheCookie *chatCookie = uploadChatCookie.chatCookie;
        [SessionManager sharedManager].loginUserChatCookie = chatCookie;
        [[LMHistoryCacheManager sharedManager] cacheChatCookie:[SessionManager sharedManager].loginUserChatCookie];
        [[LMHistoryCacheManager sharedManager] cacheLeastChatCookie:cacheData];
        DDLogInfo(@"update chatCookie success!");
        if (sendModel) {
            DDLogInfo(@"resend message....");
            [[IMService instance] asyncSendMessageMessage:sendModel.sendMsg onQueue:nil completion:sendModel.callBack onQueue:nil];
        }
    } else if (command.errNo == 4) { //time error
        //note ui ,time error
        [SessionManager sharedManager].loginUserChatCookie = nil;
        if (sendModel.callBack) {
            sendModel.sendMsg.sendstatus = GJGCChatFriendSendMessageStatusFaild;
            NSError *error = [NSError errorWithDomain:@"imserver" code:-1 userInfo:nil];
            sendModel.callBack(sendModel.sendMsg, error);
        }
    }
}

- (void)chatUserCookie:(Command *)command {
    SendCommandModel *sendComModel = [self.sendingCommands valueForKey:command.msgId];
    if (command.errNo == 5) { //friend did not report Chatcookie
        if (sendComModel.callBack) {
            sendComModel.callBack(nil, nil);
        }
    } else {
        NSError *error = nil;
        if (error) {
            if (sendComModel.callBack) {
                sendComModel.callBack(error, nil);
            }
        } else {
            ChatCookie *chatCookie = [ChatCookie parseFromData:command.detail error:&error];
            Message *oriMsg = sendComModel.sendMsg;
            AccountInfo *userInfo = (AccountInfo *) oriMsg.sendOriginInfo;
            if ([ConnectTool vertifyWithData:chatCookie.data_p.data sign:chatCookie.sign publickey:userInfo.pub_key]) {
                ChatCookieData *chatInfo = chatCookie.data_p;
                if (error) {
                    if (sendComModel.callBack) {
                        sendComModel.callBack(error, nil);
                    }
                } else {
                    [[SessionManager sharedManager] setChatCookie:chatInfo chatSession:userInfo.pub_key];
                    if (sendComModel.callBack) {
                        sendComModel.callBack(nil, chatInfo);
                    }
                }
            }
        }
    }
}

- (void)deviceTokenUnbind:(Command *)command {
    CommandStauts *status = [CommandStauts parseFromData:command.detail error:nil];
    SendCommandModel *sendComModel = [self.sendingCommands valueForKey:command.msgId];
    if (status.status != 0) {
        DDLogInfo(@"unbind device token success");
        if (sendComModel.callBack) {
            sendComModel.callBack(nil, nil);
        }
    } else {
        DDLogError(@"unbind device token failed");
        if (sendComModel.callBack) {
            sendComModel.callBack([NSError errorWithDomain:@"Undingfail" code:-1 userInfo:nil], nil);
        }
    }
}

- (void)acceptRequestSuccessDetail:(Command *)command {
    SendCommandModel *sendComModel = [self.sendingCommands valueForKey:command.msgId];
    Message *oriMsg = sendComModel.sendMsg;
    switch (command.errNo) {
        case 1: //msg: "ACCEPT ERROR"
        {
            NSError *error = [NSError errorWithDomain:command.msg code:command.errNo userInfo:nil];
            if (sendComModel.callBack) {
                sendComModel.callBack(error, nil);
            }
        }
            break;
            
        case 4: //OVER TIME
        {
            NSError *error = [NSError errorWithDomain:command.msg code:command.errNo userInfo:nil];
            if (sendComModel.callBack) {
                sendComModel.callBack(error, nil);
            }
        }
            break;
        default:{
            ReceiveAcceptFriendRequest *syncRalation = [ReceiveAcceptFriendRequest parseFromData:command.detail error:nil];
            [[UserDBManager sharedManager] updateNewFriendStatusAddress:syncRalation.address withStatus:RequestFriendStatusAdded];
            
            if (sendComModel.callBack) {
                sendComModel.callBack(nil, oriMsg.sendOriginInfo);
                [[IMService instance] getFriendsWithVersion:[[MMAppSetting sharedSetting] getContactVersion] comlete:^(NSError *error, id data) {
                    if (!error && [data isKindOfClass:[AccountInfo class]]) {
                        AccountInfo *addUser = (AccountInfo *)data;
                        addUser.message = [[UserDBManager sharedManager] getRequestTipsByUserPublickey:addUser.pub_key];
                        [GCDQueue executeInMainQueue:^{
                            SendNotify(kAcceptNewFriendRequestNotification, addUser);
                        }];
                    }
                }];
            } else {
                [[IMService instance] getFriendsWithVersion:[[MMAppSetting sharedSetting] getContactVersion] comlete:^(NSError *error, id data) {
                    if (!error && [data isKindOfClass:[AccountInfo class]]) {
                        [GCDQueue executeInMainQueue:^{
                            SendNotify(kAcceptNewFriendRequestNotification, data);
                        }];
                    }
                }];
            }
        }
            break;
    }
}

@end
