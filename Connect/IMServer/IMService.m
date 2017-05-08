/*
  Copyright (c) 2016-2016, Connect
    All rights reserved.
*/
#import "IMService.h"
#import "MessageDBManager.h"
#import "LMMessageExtendManager.h"
#import "UserDBManager.h"
#import "GroupDBManager.h"
#import "StringTool.h"
#import "ConnectTool.h"
#import "CommandOutTimeTool.h"
#import "PeerMessageHandler.h"
#import "GroupMessageHandler.h"
#import "AppDelegate.h"
#import "NSString+DictionaryValue.h"
#import "SystemMessageHandler.h"
#import "NSData+Gzip.h"
#import "CIImageCacheManager.h"
#import "SystemTool.h"
#import "YYImageCache.h"
#import "LMHistoryCacheManager.h"


#define kMaxSendOutTime (30)


#define SENDFAIL_NO_NETWORT 10000
#define SENDFAIL_OUTTIME 10001

typedef void (^SendMessageCompleteBlock)(MMMessage *message, NSError *error);

@interface SendMessageCallbackModel : NSObject

@property(nonatomic, copy) SendMessageCompleteBlock sendMessageCallbackBlock;

@end

@implementation SendMessageCallbackModel

@end

@interface IMService ()

@property(nonatomic) int seq;
@property(nonatomic) NSMutableDictionary *peerMessages;
@property(nonatomic) NSMutableDictionary *groupMessages;
@property(nonatomic, strong) NSMutableArray *sendFailMessages;
@property(nonatomic, strong) NSMutableArray *havedNotifiMessages;
@property(nonatomic, strong) dispatch_queue_t messageSendStatusQueue;
@property(nonatomic, strong) dispatch_queue_t offlineMessageHandleQueue;
@property(nonatomic, strong) dispatch_queue_t commondQueue;
@property(nonatomic, strong) dispatch_queue_t delaySendCommondQueue;
@property(nonatomic, assign) BOOL delaySendIsSuspend;
@property(nonatomic, strong) dispatch_queue_t messageAutoReSendStatusQueue;
@property(nonatomic, strong) dispatch_queue_t messageSendQueue;
@property(nonatomic, assign) BOOL messageSendIsSuspend;
@property(nonatomic, strong) dispatch_queue_t offLineMessageQueue;
@property(nonatomic, strong) dispatch_source_t reflashSendStatusSource;
@property(nonatomic, assign) BOOL reflashSendStatusSourceActive;
@property(nonatomic, copy) BOOL (^HeartBeatBlock)();
@property(nonatomic, strong) NSTimer *messageTimeoutTimer;
@property(nonatomic, strong) NSData *sendSalt;
@property(nonatomic, copy) NSString *randomPrivkey;
@property(nonatomic, copy) NSString *randomPublickey;
@property(nonatomic, copy) void (^UnBindDeviceTokenComplete)(NSError *erro);
@property(nonatomic, copy) NSString *uprikey;
@property(nonatomic, copy) NSString *uaddress;
@property(nonatomic, copy) NSString *upublickey;
@property(nonatomic, copy) NSString *serverPublicKey;
@property(nonatomic, strong) NSData *extensionPass;

@end

@implementation IMService


#pragma mark - inner properT

- (id <IMPeerMessageHandler>)peerMessageHandler {
    if (!_peerMessageHandler) {
        _peerMessageHandler = [PeerMessageHandler instance];
    }
    return _peerMessageHandler;
}

- (id <IMGroupMessageHandler>)groupMessageHandler {
    if (!_groupMessageHandler) {
        _groupMessageHandler = [GroupMessageHandler instance];
    }
    return _groupMessageHandler;
}

- (dispatch_queue_t)messageSendStatusQueue {
    if (!_messageSendStatusQueue) {
        _messageSendStatusQueue = dispatch_queue_create("_imserver_message_sender_status_queue", DISPATCH_QUEUE_SERIAL);
    }
    return _messageSendStatusQueue;
}

- (dispatch_queue_t)messageSendQueue {

    if (!_messageSendQueue) {
        _messageSendQueue = dispatch_queue_create("_imserver_message_sender_queue", DISPATCH_QUEUE_SERIAL);
    }
    return _messageSendQueue;
}

- (dispatch_queue_t)offlineMessageHandleQueue {
    if (!_offlineMessageHandleQueue) {
        _offlineMessageHandleQueue = dispatch_queue_create("_offlinemessage_queue", DISPATCH_QUEUE_SERIAL);
    }
    return _offlineMessageHandleQueue;
}

- (NSString *)uprikey {
    if (!_uprikey) {
        _uprikey = [LKUserCenter shareCenter].currentLoginUser.prikey;
    }
    return _uprikey;
}

- (NSString *)uaddress {
    if (!_uaddress) {
        _uaddress = [LKUserCenter shareCenter].currentLoginUser.address;
    }
    return _uaddress;
}


- (NSString *)upublickey {
    if (!_upublickey) {
        _upublickey = [LKUserCenter shareCenter].currentLoginUser.pub_key;
    }
    return _upublickey;
}


- (NSString *)serverPublicKey {
    if (!_serverPublicKey) {
        _serverPublicKey = [[ServerCenter shareCenter] getCurrentServer].data.pub_key;
    }
    return _serverPublicKey;
}

static IMService *im;
static dispatch_once_t onceToken;

+ (IMService *)instance {
    dispatch_once(&onceToken, ^{
        if (!im) {
            im = [[IMService alloc] init];
        }
    });
    return im;
}

- (id)init {
    self = [super init];
    if (self) {
        self.sendFailMessages = [NSMutableArray array];
        self.havedNotifiMessages = [NSMutableArray array];

        self.peerMessages = [NSMutableDictionary dictionary];
        self.groupMessages = [NSMutableDictionary dictionary];

        if (!self.messageAutoReSendStatusQueue) {
            self.messageAutoReSendStatusQueue = dispatch_queue_create("_message_autoresend_queue", DISPATCH_QUEUE_SERIAL);
        }

        if (!self.messageSendQueue) {
            self.messageSendQueue = dispatch_queue_create("_message_sendmessage_queue", DISPATCH_QUEUE_SERIAL);
        }

        if (!self.messageSendStatusQueue) {
            self.messageSendStatusQueue = dispatch_queue_create("_message_sendmessageStatus_queue", DISPATCH_QUEUE_SERIAL);
        }

        if (!self.commondQueue) {
            self.commondQueue = dispatch_queue_create("_commond_send_handle_queue", DISPATCH_QUEUE_CONCURRENT);
        }

    }
    return self;
}

#pragma mark - ACK

- (void)handleACK:(Message *)msg {
    IMTransferData *transerData = (IMTransferData *) msg.body;
    BOOL sign = [ConnectTool vertifyWithData:transerData.cipherData.data sign:transerData.sign];
    if (sign) {
        NSData *decodeData = [ConnectTool decodeGcmDataWithEcdhKey:self.extensionPass GcmData:transerData.cipherData];
        if (!decodeData) {
            DDLogError(@"decode message failed");
            return;
        }
        Ack *ack = [Ack parseFromData:decodeData error:nil];

        NSDictionary *dict = [self.peerMessages valueForKey:ack.msgId];
        MMMessage *message = [dict valueForKey:@"message"];
        SendMessageCallbackModel *callBackBlock = [dict valueForKey:@"callBackBlock"];

        [self messageSendSuccess:message];

        [GCDQueue executeInQueue:self.messageSendStatusQueue block:^{
            if (dict) {
                ChatMessageInfo *chatMessage = [[MessageDBManager sharedManager] getMessageInfoByMessageid:message.message_id messageOwer:message.publicKey];
                if (chatMessage.message.sendstatus == GJGCChatFriendSendMessageStatusSuccessUnArrive || chatMessage.message.sendstatus == GJGCChatFriendSendMessageStatusFailByNotInGroup) {
                    //blocked
                } else if (chatMessage.message.sendstatus == GJGCChatFriendSendMessageStatusFailByNoRelationShip && ![[UserDBManager sharedManager] isFriendByAddress:[KeyHandle getAddressByPubkey:message.publicKey]]) {
                    //no relationship
                } else {
                    message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                    chatMessage.message.sendstatus = message.sendstatus;
                    //update status
                    [[MessageDBManager sharedManager] updateMessageSendStatus:GJGCChatFriendSendMessageStatusSuccess withMessageId:message.message_id messageOwer:message.publicKey];
                    if (callBackBlock.sendMessageCallbackBlock) {
                        callBackBlock.sendMessageCallbackBlock(message, nil);
                    }
                    [GCDQueue executeInMainQueue:^{
                        SendNotify(ConnnectSendMessageSuccessNotification, chatMessage.messageOwer);
                    }];
                }
            }
        }];
        if ([self.peerMessages valueForKey:ack.msgId]) {
            [self.peerMessages removeObjectForKey:ack.msgId];
        }
    }
}

- (void)handleCommandACK:(Message *)msg {
    IMTransferData *transerData = (IMTransferData *) msg.body;

    BOOL sign = [ConnectTool vertifyWithData:transerData.cipherData.data sign:transerData.sign];

    if (sign) {
        NSData *decodeData = [ConnectTool decodeGcmDataWithEcdhKey:self.extensionPass GcmData:transerData.cipherData];

        if (!decodeData) {
            DDLogError(@"decode message failed");
            return;
        }
        NSError *error = nil;
        Command *command = [Command parseFromData:decodeData error:&error];
        if (error) {
            return;
        }
        Message *oriMsg = [[CommandOutTimeTool sharedManager] getMessageByIdentifer:command.msgId];
        if (!oriMsg) {
            return;
        }
        CommandCallbackModel *callBack = [[CommandOutTimeTool sharedManager].concurrentMsgCompleteBlockDict valueForKey:oriMsg.msgIdentifer];
        if (callBack.completeBlock) {
            callBack.completeBlock(nil, nil);
        }
        [[CommandOutTimeTool sharedManager] removeSuccessMessage:oriMsg];

        [self handldDetailCommandWihtCommand:command message:oriMsg decodeData:decodeData];
        [self sendIMBackAck:command.msgId];
    }
}

- (void)sendAck:(NSString *)messageid type:(int)type {

    Ack *ack = [[Ack alloc] init];
    ack.msgId = messageid;
    ack.type = type;
    IMTransferData *request = [ConnectTool createTransferWithEcdhKey:self.extensionPass data:ack.data aad:nil];

    Message *ackMsg = [[Message alloc] init];
    ackMsg.typechar = BM_ACK_TYPE;
    ackMsg.extension = BM_ACK_OFFLIE_BACK_EXT;
    ackMsg.body = [request data];
    ackMsg.len = (int) [request data].length;

    [self sendMessage:ackMsg];
}

#pragma mark -Message-friend

- (void)handleIMMessage:(Message *)msg {

    MessagePost *post = (MessagePost *) msg.body;
    DDLogError(@"get peer im message %@", post.msgData.msgId);
    BOOL isSign = [ConnectTool vertifyWithData:post.msgData.data sign:post.sign publickey:post.pubKey];
    if (!isSign) {
        [self sendIMBackAck:post.msgData.msgId];
        return;
    }
    [self.peerMessageHandler handleMessage:post];

    [self sendIMBackAck:post.msgData.msgId];
}

- (void)handleReadAckMessage:(Message *)msg {
    MessagePost *post = (MessagePost *) msg.body;
    DDLogError(@"get ReadAck im message %@", post.msgData.msgId);
    [self handleIMMessage:msg];
}


#pragma mark -Message-group

- (void)handleInviteGroupMessage:(Message *)msg {
    MessagePost *post = (MessagePost *) msg.body;
    BOOL isSign = [ConnectTool vertifyWithData:post.msgData.data sign:post.sign publickey:post.pubKey];
    if (!isSign) {
        return;
    }
    [self.groupMessageHandler handleGroupInviteMessage:post];
    //send ack
    [self sendIMBackAck:post.msgData.msgId];
}

- (void)handleGroupIMMessage:(Message *)msg {
    MessagePost *post = (MessagePost *) msg.body;
    BOOL isSign = [ConnectTool vertifyWithData:post.msgData.data sign:post.sign publickey:post.pubKey];
    if (!isSign) {
        return;
    }
    [self.groupMessageHandler handleMessage:post];
    DDLogError(@"get groupim message %@", post.msgData.msgId);
    [self sendIMBackAck:post.msgData.msgId];
}


#pragma mark -Message-rejected

- (void)handleBlackUnArrive:(Message *)msg {
    RejectMessage *rejectMsg = (RejectMessage *) msg.body;
    /**
     "NOT_EXISTED": 1,
     "NOT_FRIEND":    2,
     "BLACK_LIST":    3,
     "NOT_IN_GROUP":    4,
     "CHATINFO_EMPTY": 5,
     "GET_CHATINFO_ERROR": 6,
     "CHATINFO_NOT_MATCH": 7,
     "CHATINFO_EXPIRE": 8, //The other side is not more than a day on the line, ChatCookie expired, open a single random
     }
     */
    ChatMessageInfo *chatMessage = nil;
    NSString *identifier = nil;
    if (rejectMsg.status == 8) {
        identifier = [[UserDBManager sharedManager] getUserPubkeyByAddress:rejectMsg.receiverAddress];

        [[SessionManager sharedManager] removeChatCookieWithChatSession:identifier];

        NSDictionary *dict = [self.peerMessages valueForKey:rejectMsg.msgId];
        MMMessage *msg = [dict valueForKey:@"message"];
        SendMessageCallbackModel *callBackBlock = [dict valueForKey:@"callBackBlock"];
        [[SessionManager sharedManager] chatCookie:YES chatSession:identifier];
        [self asyncSendMessageMessage:msg onQueue:nil completion:callBackBlock.sendMessageCallbackBlock onQueue:nil];
    } else if (rejectMsg.status == 7) {
        /*
         NSDictionary *temD = @{@"sendTime":sendTime,
         @"message":message,
         @"callBackBlock":callBackBlock};
        */
        NSDictionary *dict = [self.peerMessages valueForKey:rejectMsg.msgId];
        MMMessage *msg = [dict valueForKey:@"message"];

        ChatCookie *chatCookie = [ChatCookie parseFromData:rejectMsg.data_p error:nil];
        identifier = [[UserDBManager sharedManager] getUserPubkeyByAddress:rejectMsg.receiverAddress];

        if ([ConnectTool vertifyWithData:chatCookie.data_p.data sign:chatCookie.sign publickey:identifier]) {
            ChatCookieData *chatInfo = chatCookie.data_p;
            [[SessionManager sharedManager] setChatCookie:chatInfo chatSession:identifier];
            SendMessageCallbackModel *callBackBlock = [dict valueForKey:@"callBackBlock"];

            [self asyncSendMessageMessage:msg onQueue:nil completion:callBackBlock.sendMessageCallbackBlock onQueue:nil];
        } else {
            chatMessage = [[MessageDBManager sharedManager] getMessageInfoByMessageid:rejectMsg.msgId messageOwer:identifier];
            if (!chatMessage) {
                return;
            }
            GJGCChatFriendSendMessageStatus sendStatus = GJGCChatFriendSendMessageStatusFaild;
            if (rejectMsg.status == 2) {
                sendStatus = GJGCChatFriendSendMessageStatusFailByNoRelationShip;

                [[MessageDBManager sharedManager] updateMessageSendStatus:GJGCChatFriendSendMessageStatusFailByNoRelationShip withMessageId:rejectMsg.msgId messageOwer:identifier];

                ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
                chatMessage.messageId = [ConnectTool generateMessageId];
                chatMessage.messageOwer = identifier;
                chatMessage.messageType = GJGCChatFriendContentTypeNoRelationShipTip;
                chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                chatMessage.createTime = (long long) ([[NSDate date] timeIntervalSince1970] * 1000);
                MMMessage *message = [[MMMessage alloc] init];
                message.type = GJGCChatFriendContentTypeNoRelationShipTip;
                message.content = @"";
                message.sendtime = chatMessage.createTime;
                message.message_id = chatMessage.messageId;
                message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                chatMessage.message = message;
                [[MessageDBManager sharedManager] saveMessage:chatMessage];
            } else if (rejectMsg.status == 3) {
                sendStatus = GJGCChatFriendSendMessageStatusSuccessUnArrive;
                [[MessageDBManager sharedManager] updateMessageSendStatus:GJGCChatFriendSendMessageStatusSuccessUnArrive withMessageId:rejectMsg.msgId messageOwer:identifier];

                ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
                chatMessage.messageId = [ConnectTool generateMessageId];
                chatMessage.messageOwer = identifier;
                chatMessage.messageType = GJGCChatFriendContentTypeStatusTip;
                chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                chatMessage.createTime = (long long) ([[NSDate date] timeIntervalSince1970] * 1000);
                MMMessage *message = [[MMMessage alloc] init];
                message.type = GJGCChatFriendContentTypeStatusTip;
                message.content = LMLocalizedString(@"Link Message has been sent the other rejected", nil);
                message.sendtime = chatMessage.createTime;
                message.message_id = chatMessage.messageId;
                message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                chatMessage.message = message;
                [[MessageDBManager sharedManager] saveMessage:chatMessage];
            } else if (rejectMsg.status == 4) {
                sendStatus = GJGCChatFriendSendMessageStatusFailByNotInGroup;
                [[MessageDBManager sharedManager] updateMessageSendStatus:GJGCChatFriendSendMessageStatusFailByNotInGroup withMessageId:rejectMsg.msgId messageOwer:identifier];

                ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
                chatMessage.messageId = [ConnectTool generateMessageId];
                chatMessage.messageOwer = identifier;
                chatMessage.messageType = GJGCChatFriendContentTypeStatusTip;
                chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                chatMessage.createTime = (long long) ([[NSDate date] timeIntervalSince1970] * 1000);
                MMMessage *message = [[MMMessage alloc] init];
                message.type = GJGCChatFriendContentTypeStatusTip;
                message.content = LMLocalizedString(@"Message send fail not in group", nil);
                message.sendtime = chatMessage.createTime;
                message.message_id = chatMessage.messageId;
                message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                chatMessage.message = message;
                [[MessageDBManager sharedManager] saveMessage:chatMessage];
            }
            NSDictionary *dict = [self.peerMessages valueForKey:rejectMsg.msgId];
            SendMessageCallbackModel *callBackBlock = [dict valueForKey:@"callBackBlock"];
            if (callBackBlock) {
                [GCDQueue executeInQueue:self.messageSendStatusQueue block:^{
                    MMMessage *message = chatMessage.message;
                    message.sendstatus = sendStatus;
                    if (callBackBlock.sendMessageCallbackBlock) {
                        callBackBlock.sendMessageCallbackBlock(message, nil);
                    }
                }];
            }
        }
    } else {
        if (rejectMsg.status == 4) {
            identifier = rejectMsg.receiverAddress;
            chatMessage = [[MessageDBManager sharedManager] getMessageInfoByMessageid:rejectMsg.msgId messageOwer:rejectMsg.receiverAddress];
        } else {
            identifier = [[UserDBManager sharedManager] getUserPubkeyByAddress:rejectMsg.receiverAddress];
            chatMessage = [[MessageDBManager sharedManager] getMessageInfoByMessageid:rejectMsg.msgId messageOwer:identifier];
        }
        if (!chatMessage) {
            return;
        }
        GJGCChatFriendSendMessageStatus sendStatus = GJGCChatFriendSendMessageStatusFaild;
        if (rejectMsg.status == 2) {
            sendStatus = GJGCChatFriendSendMessageStatusFailByNoRelationShip;

            [[MessageDBManager sharedManager] updateMessageSendStatus:GJGCChatFriendSendMessageStatusFailByNoRelationShip withMessageId:rejectMsg.msgId messageOwer:identifier];

            ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
            chatMessage.messageId = [ConnectTool generateMessageId];
            chatMessage.messageOwer = identifier;
            chatMessage.messageType = GJGCChatFriendContentTypeNoRelationShipTip;
            chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
            chatMessage.createTime = (long long) ([[NSDate date] timeIntervalSince1970] * 1000);
            MMMessage *message = [[MMMessage alloc] init];
            message.type = GJGCChatFriendContentTypeNoRelationShipTip;
            message.content = @"";
            message.sendtime = chatMessage.createTime;
            message.message_id = chatMessage.messageId;
            message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
            chatMessage.message = message;
            [[MessageDBManager sharedManager] saveMessage:chatMessage];
        } else if (rejectMsg.status == 3) {
            sendStatus = GJGCChatFriendSendMessageStatusSuccessUnArrive;
            [[MessageDBManager sharedManager] updateMessageSendStatus:GJGCChatFriendSendMessageStatusSuccessUnArrive withMessageId:rejectMsg.msgId messageOwer:identifier];

            ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
            chatMessage.messageId = [ConnectTool generateMessageId];
            chatMessage.messageOwer = identifier;
            chatMessage.messageType = GJGCChatFriendContentTypeStatusTip;
            chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
            chatMessage.createTime = (long long) ([[NSDate date] timeIntervalSince1970] * 1000);
            MMMessage *message = [[MMMessage alloc] init];
            message.type = GJGCChatFriendContentTypeStatusTip;
            message.content = LMLocalizedString(@"Link Message has been sent the other rejected", nil);
            message.sendtime = chatMessage.createTime;
            message.message_id = chatMessage.messageId;
            message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
            chatMessage.message = message;
            [[MessageDBManager sharedManager] saveMessage:chatMessage];
        } else if (rejectMsg.status == 4) {
            sendStatus = GJGCChatFriendSendMessageStatusFailByNotInGroup;
            [[MessageDBManager sharedManager] updateMessageSendStatus:GJGCChatFriendSendMessageStatusFailByNotInGroup withMessageId:rejectMsg.msgId messageOwer:identifier];

            ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
            chatMessage.messageId = [ConnectTool generateMessageId];
            chatMessage.messageOwer = identifier;
            chatMessage.messageType = GJGCChatFriendContentTypeStatusTip;
            chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
            chatMessage.createTime = (long long) ([[NSDate date] timeIntervalSince1970] * 1000);
            MMMessage *message = [[MMMessage alloc] init];
            message.type = GJGCChatFriendContentTypeStatusTip;
            message.content = LMLocalizedString(@"Message send fail not in group", nil);
            message.sendtime = chatMessage.createTime;
            message.message_id = chatMessage.messageId;
            message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
            chatMessage.message = message;
            [[MessageDBManager sharedManager] saveMessage:chatMessage];
        }
        NSDictionary *dict = [self.peerMessages valueForKey:rejectMsg.msgId];
        SendMessageCallbackModel *callBackBlock = [dict valueForKey:@"callBackBlock"];
        if (callBackBlock) {
            [GCDQueue executeInQueue:self.messageSendStatusQueue block:^{
                MMMessage *message = chatMessage.message;
                message.sendstatus = sendStatus;
                if (callBackBlock.sendMessageCallbackBlock) {
                    callBackBlock.sendMessageCallbackBlock(message, nil);
                }
            }];
        }
    }
    //remove send queue message
    if ([self.peerMessages valueForKey:rejectMsg.msgId]) {
        [self.peerMessages removeObjectForKey:rejectMsg.msgId];
    }
}


#pragma mark -Message-transactionstatus

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
                chatMessage.createTime = (long long) ([[NSDate date] timeIntervalSince1970] * 1000);
                MMMessage *message = [[MMMessage alloc] init];
                message.type = GJGCChatFriendContentTypeStatusTip;
                message.content = operation;
                message.ext1 = @(notice.category);
                message.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
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
                chatMessage.createTime = ([[NSDate date] timeIntervalSince1970] * 1000);
                MMMessage *message = [[MMMessage alloc] init];
                message.type = GJGCChatFriendContentTypeStatusTip;
                message.content = operation;
                message.ext1 = @(notice.category);
                message.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
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
                chatMessage.createTime = ([[NSDate date] timeIntervalSince1970] * 1000);
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
    [self sendOnlineBackAck:notice.msgId type:msg.typechar];
}

#pragma mark -Message-sys temmessage

- (void)handleSystemMessage:(Message *)msg {
    MSMessage *sysMsg = msg.body;

    //send ack
    [self sendIMBackAck:sysMsg.msgId];

    [[SystemMessageHandler instance] handleMessage:sysMsg];
}


#pragma mark -Message-IMAck

- (void)sendIMBackAck:(NSString *)msgID {

    Ack *ack = [[Ack alloc] init];
    ack.msgId = msgID;

    IMTransferData *request = [ConnectTool createTransferWithEcdhKey:self.extensionPass data:ack.data aad:nil];

    Message *ackMsg = [[Message alloc] init];
    ackMsg.typechar = BM_ACK_TYPE;
    ackMsg.extension = BM_ACK_BACK_EXT;
    ackMsg.body = [request data];
    ackMsg.len = (int) [request data].length;

    [self sendMessage:ackMsg];

}

- (void)sendOnlineBackAck:(NSString *)msgID type:(int)type {

    Ack *ack = [[Ack alloc] init];
    ack.msgId = msgID;
    ack.type = type;

    IMTransferData *request = [ConnectTool createTransferWithEcdhKey:self.extensionPass data:ack.data aad:nil];

    Message *ackMsg = [[Message alloc] init];
    ackMsg.typechar = BM_ACK_TYPE;
    ackMsg.extension = BM_ACK_BACK_EXT;
    ackMsg.body = [request data];
    ackMsg.len = (int) [request data].length;

    [self sendMessage:ackMsg];

}

- (void)handldDetailCommandWihtCommand:(Command *)command message:(Message *)oriMsg decodeData:(NSData *)decodeData {

    switch (oriMsg.extension) {

        case BM_NEWFRIEND_EXT: {
            AccountInfo *inviteUser = oriMsg.sendOriginInfo;
            CommandCallbackModel *callBack = [[CommandOutTimeTool sharedManager].concurrentMsgCompleteBlockDict valueForKey:oriMsg.msgIdentifer];
            if (callBack.completeBlock) {
                callBack.completeBlock(nil, inviteUser);
            }
        }
            break;

        default:
            break;
    }

}

#pragma mark - Socket-handshake

- (void)handleAuthStatus:(Message *)msg {
    IMResponse *response = (IMResponse *) msg.body;
    GcmData *gcmData = response.cipherData;
    NSData *password = [KeyHandle getECDHkeyWithPrivkey:self.uprikey publicKey:self.serverPublicKey];
    password = [KeyHandle getAes256KeyByECDHKeyAndSalt:password salt:[ConnectTool get64ZeroData]];
    NSData *handAckData = [ConnectTool decodeGcmDataWithEcdhKey:password GcmData:gcmData];
    if (!handAckData || handAckData.length <= 0) {
        return;
    }
    NewConnection *conn = [NewConnection parseFromData:handAckData error:nil];
    DDLogInfo(@"%@", conn);

    NSData *saltData = [StringTool DataXOR1:self.sendSalt DataXOR2:conn.salt];

    NSData *passwordTem = [KeyHandle getECDHkeyWithPrivkey:self.randomPrivkey publicKey:[StringTool hexStringFromData:conn.pubKey]];
    NSData *extensionPass = [KeyHandle getAes256KeyByECDHKeyAndSalt:passwordTem salt:saltData];
    self.extensionPass = extensionPass;

    [ServerCenter shareCenter].extensionPass = extensionPass;

    //upload device info
    NSUUID *uuid = [[UIDevice currentDevice] identifierForVendor];
    DeviceInfo *deviceId = [[DeviceInfo alloc] init];
    deviceId.deviceId = uuid.UUIDString;
    deviceId.deviceName = [UIDevice currentDevice].name;
    deviceId.locale = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
    // channel
    if ([SystemTool isNationChannel]) {
        deviceId.cv = 1;
    }
    IMTransferData *request = [ConnectTool createTransferWithEcdhKey:extensionPass data:deviceId.data aad:[ServerCenter shareCenter].defineAad];
    Message *m = [[Message alloc] init];
    m.typechar = BM_HANDSHAKE_TYPE;
    m.extension = BM_HANDSHAKEACK_EXT;
    m.len = (int) request.data.length;
    m.body = request.data;
    [self sendMessage:m];

    //upload version
    [self uploadAppInfoWhenVersionChange];
}

- (void)authSussecc:(Message *)msg {

    [[CommandOutTimeTool sharedManager] resume];

    //send unsend message
    if (self.messageSendIsSuspend) {
        dispatch_resume(self.messageSendQueue);
        self.messageSendIsSuspend = NO;
    }
    self.connectState = STATE_CONNECTED;
    [self resendFailMessageWhenConnect];
#if (TARGET_IPHONE_SIMULATOR)

#else

    if (!GJCFStringIsNull(self.deviceToken)) {
        AppDelegate *app = (AppDelegate *) [UIApplication sharedApplication].delegate;
        self.deviceToken = app.deviceToken;
        [self bindDeviceTokenWithDeviceToken:self.deviceToken];
    } else {
        __weak __typeof(&*self) weakSelf = self;
        self.RegisterDeviceTokenComplete = ^(NSString *deviceToken) {
            [weakSelf bindDeviceTokenWithDeviceToken:weakSelf.deviceToken];
        };
    }
#endif

    [self getOffLineMessages];

    NSString *contactVersion = [[MMAppSetting sharedSetting] getContactVersion];
    if ([contactVersion isEqualToString:@""]) {
        [self getFriendsWithVersion:contactVersion comlete:nil];
    }

    //Delayed command to receive commands sent to receive external envelopes or transfer
    if (self.delaySendCommondQueue && self.delaySendIsSuspend) {
        dispatch_resume(self.delaySendCommondQueue);
        self.delaySendIsSuspend = NO;
    }

    //Connect successfully send heartbeat information
    __weak __typeof(&*self) weakSelf = self;
    self.HeartBeatBlock = ^{
        Message *msg = [[Message alloc] init];
        msg.typechar = BM_HEARTBEAT_TYPE;
        msg.extension = BM_HEARTBEAT_EXT;
        msg.body = [NSData data];
        msg.len = 0;
        [weakSelf sendMessage:msg];
        return YES;
    };
}

#pragma mark - heartbeat

- (void)handlePong:(Message *)msg {
    [self pong];
}

- (BOOL)sendPing {
    //Check whether ChatCookie is expired
    [self uploadCookie];

    if (self.HeartBeatBlock)
        return self.HeartBeatBlock();
    return NO;
}

#pragma mark - Command-friends

- (void)handleFriendslist:(Message *)msg {
    IMTransferData *transerData = (IMTransferData *) msg.body;
    BOOL sign = [ConnectTool vertifyWithData:transerData.cipherData.data sign:transerData.sign];
    if (sign) {
        NSData *decodeData = [ConnectTool decodeGcmDataWithEcdhKey:self.extensionPass GcmData:transerData.cipherData];
        if (!decodeData) {
            DDLogError(@"decode message failed");
            return;
        }
        NSError *error = nil;
        Command *command = [Command parseFromData:decodeData error:&error];
        if (error) {
            return;
        }
        msg.msgIdentifer = command.msgId;
        NSString *version = @"";
        Message *oriMsg = [[CommandOutTimeTool sharedManager] getMessageByIdentifer:command.msgId];
        if ([oriMsg.sendOriginInfo isEqualToString:@"syncfriend"]) {
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
                    user.source = friend.source;
                    user.remarks = friend.remark;
                    if (![usersM containsObject:user]) {
                        [temA objectAddObject:user];
                    } else {
                        [usersM objectAddObject:user];
                    }
                }

                [[UserDBManager sharedManager] batchSaveUsers:temA];
                DDLogInfo(@"update contacts version success version:%@", friendList.version);
                CommandCallbackModel *callBack = [[CommandOutTimeTool sharedManager].concurrentMsgCompleteBlockDict valueForKey:oriMsg.msgIdentifer];
                if (callBack.completeBlock) {
                    callBack.completeBlock(nil, usersM);
                }

            }];
            version = friendList.version;
        } else {
            if ([[[MMAppSetting sharedSetting] getContactVersion] isEqualToString:@""] ||
                    [[[MMAppSetting sharedSetting] getContactVersion] isEqualToString:@"0"]) {
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
                        SendNotify(LoinOnNewDeviceStatusNotification, @(2));
                    }];
                } else {
                    for (AccountInfo *addUser in users) {
                        CommandCallbackModel *callBack = [[CommandOutTimeTool sharedManager].concurrentMsgCompleteBlockDict valueForKey:msg.msgIdentifer];
                        if (callBack.completeBlock) {
                            callBack.completeBlock(nil, addUser);
                        }
                    }
                }
                version = friendList.version;
            } else {
                error = nil;
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
                        CommandCallbackModel *callBack = [[CommandOutTimeTool sharedManager].concurrentMsgCompleteBlockDict valueForKey:msg.msgIdentifer];
                        if (callBack.completeBlock) {
                            callBack.completeBlock(nil, addUser);
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

        [self sendIMBackAck:command.msgId];
    }
    [[CommandOutTimeTool sharedManager] removeSuccessMessage:msg];

}

#pragma mark - Command-update user info

- (void)handleSetUserInfo:(Message *)msg {
    IMTransferData *transerData = (IMTransferData *) msg.body;

    BOOL sign = [ConnectTool vertifyWithData:transerData.cipherData.data sign:transerData.sign];

    if (sign) {
        NSData *decodeData = [ConnectTool decodeGcmDataWithEcdhKey:self.extensionPass GcmData:transerData.cipherData];

        if (!decodeData) {
            DDLogError(@"decode message failed");
            return;
        }
        NSError *error = nil;
        Command *command = [Command parseFromData:decodeData error:&error];
        if (error) {
            return;
        }
        msg.msgIdentifer = command.msgId;
        CommandCallbackModel *callBack = [[CommandOutTimeTool sharedManager].concurrentMsgCompleteBlockDict valueForKey:msg.msgIdentifer];
        if (callBack.completeBlock) {
            callBack.completeBlock(nil, nil);
        }
        [[CommandOutTimeTool sharedManager] removeSuccessMessage:msg];
        DDLogInfo(@"%@", command);

        [self sendIMBackAck:command.msgId];
    }
}

#pragma mark - Command-delete friend

- (void)handleHandleDeleteUser:(Message *)msg {
    IMTransferData *transerData = (IMTransferData *) msg.body;

    BOOL sign = [ConnectTool vertifyWithData:transerData.cipherData.data sign:transerData.sign];

    if (sign) {
        NSData *decodeData = [ConnectTool decodeGcmDataWithEcdhKey:self.extensionPass GcmData:transerData.cipherData];

        if (!decodeData) {
            DDLogError(@"decode message failed");
            return;
        }

        NSError *error = nil;
        Command *command = [Command parseFromData:decodeData error:&error];
        if (error) {
            return;
        }

        msg.msgIdentifer = command.msgId;

        Message *oriMsg = [[CommandOutTimeTool sharedManager] getMessageByIdentifer:command.msgId];
        AccountInfo *deleteUser = [[UserDBManager sharedManager] getUserByAddress:oriMsg.sendOriginInfo];

        [[CommandOutTimeTool sharedManager] removeSuccessMessage:oriMsg];

        //delete user
        [[UserDBManager sharedManager] deleteUserBypubkey:deleteUser.pub_key];

        [GCDQueue executeInMainQueue:^{
            SendNotify(ConnnectContactDidChangeDeleteUserNotification, deleteUser);
        }];

        if (command.errNo > 0) {

            CommandCallbackModel *callBack = [[CommandOutTimeTool sharedManager].concurrentMsgCompleteBlockDict valueForKey:oriMsg.msgIdentifer];
            if (callBack.completeBlock) {
                callBack.completeBlock([NSError errorWithDomain:command.msg code:command.errNo userInfo:nil], nil);
            }

            return;
        }
        CommandCallbackModel *callBack = [[CommandOutTimeTool sharedManager].concurrentMsgCompleteBlockDict valueForKey:oriMsg.msgIdentifer];
        if (callBack.completeBlock) {
            callBack.completeBlock(nil, oriMsg.sendOriginInfo);
        }

        [self getFriendsWithVersion:[[MMAppSetting sharedSetting] getContactVersion] comlete:^(NSError *erro, id data) {

        }];

        [self sendIMBackAck:command.msgId];
    }
}

#pragma mark - Command-handle new friend request

- (void)handleAcceptRequestSuccess:(Message *)msg {

    IMTransferData *transerData = (IMTransferData *) msg.body;

    BOOL sign = [ConnectTool vertifyWithData:transerData.cipherData.data sign:transerData.sign];

    if (sign) {
        NSData *decodeData = [ConnectTool decodeGcmDataWithEcdhKey:self.extensionPass GcmData:transerData.cipherData];

        if (!decodeData) {
            DDLogError(@"decode message failed");
            return;
        }

        [self acceptRequestSuccessDetail:decodeData];

    }
}

- (void)acceptRequestSuccessDetail:(NSData *)decodeData {
    if (!decodeData) {
        DDLogError(@"decode message failed");
        return;
    }

    NSError *error = nil;
    Command *command = [Command parseFromData:decodeData error:&error];
    if (error) {
        return;
    }

    Message *oriMsg = [[CommandOutTimeTool sharedManager] getMessageByIdentifer:command.msgId];
    [[CommandOutTimeTool sharedManager] removeSuccessMessage:oriMsg];

    switch (command.errNo) {
        case 1: //msg: "ACCEPT ERROR"
        {
            error = [NSError errorWithDomain:command.msg code:-1 userInfo:nil];
            CommandCallbackModel *callBack = [[CommandOutTimeTool sharedManager].concurrentMsgCompleteBlockDict valueForKey:oriMsg.msgIdentifer];
            if (callBack.completeBlock) {
                callBack.completeBlock(error, nil);
            }
            return;
        }
            break;
        default:

            break;
    }
    CommandCallbackModel *callBack = [[CommandOutTimeTool sharedManager].concurrentMsgCompleteBlockDict valueForKey:oriMsg.msgIdentifer];
    if (callBack.completeBlock) {
        callBack.completeBlock(nil, oriMsg.sendOriginInfo);
    }
    ReceiveAcceptFriendRequest *syncRalation = [ReceiveAcceptFriendRequest parseFromData:command.detail error:nil];

    DDLogInfo(@"accpet success");

    [[UserDBManager sharedManager] updateNewFriendStatusAddress:syncRalation.address withStatus:RequestFriendStatusAdded];
    [self getFriendsWithVersion:[[MMAppSetting sharedSetting] getContactVersion] comlete:^(NSError *erro, id data) {

        [GCDQueue executeInMainQueue:^{
            SendNotify(kAcceptNewFriendRequestNotification, data);
        }];
    }];

    [self sendIMBackAck:command.msgId];
}

#pragma mark - Command-friend request

- (void)newFriendRequest:(Message *)msg {
    IMTransferData *transerData = (IMTransferData *) msg.body;
    BOOL sign = [ConnectTool vertifyWithData:transerData.cipherData.data sign:transerData.sign];

    if (sign) {
        NSData *decodeData = [ConnectTool decodeGcmDataWithEcdhKey:self.extensionPass GcmData:transerData.cipherData];

        if (!decodeData) {
            DDLogError(@"decode message failed");
            return;
        }
        [self newFriendRequestDetailHandle:decodeData];
    }
}

- (void)newFriendRequestDetailHandle:(NSData *)decodeData {
    if (!decodeData) {
        DDLogError(@"decode message failed");
        return;
    }

    NSError *error = nil;

    Command *command = [Command parseFromData:decodeData error:&error];
    if (error) {
        return;
    }

    Message *oriMsg = [[CommandOutTimeTool sharedManager] getMessageByIdentifer:command.msgId];
    if (!oriMsg) {
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
        AccountInfo *inviteUser = oriMsg.sendOriginInfo;
        [[CommandOutTimeTool sharedManager] removeSuccessMessage:oriMsg];
        if (command.errNo == 1) { //add myself error
            CommandCallbackModel *callBack = [[CommandOutTimeTool sharedManager].concurrentMsgCompleteBlockDict valueForKey:oriMsg.msgIdentifer];
            if (callBack.completeBlock) {
                callBack.completeBlock([NSError errorWithDomain:@"" code:1 userInfo:nil], nil);
            }
            return;
        }
        CommandCallbackModel *callBack = [[CommandOutTimeTool sharedManager].concurrentMsgCompleteBlockDict valueForKey:oriMsg.msgIdentifer];
        if (callBack.completeBlock) {
            callBack.completeBlock(nil, inviteUser);
        }
    }

    [self sendIMBackAck:command.msgId];
}

#pragma mark - Command-offline messages

- (void)getOffLineMessages {
    self.connectState = STATE_GETOFFLINE;
    [GCDQueue executeInMainQueue:^{
        [self publishConnectState:self.connectState];
    }];

    Message *getofflineMessage = [[Message alloc] init];
    getofflineMessage.typechar = BM_COMMAND_TYPE;
    getofflineMessage.extension = BM_GETOFFLINE_EXT;
    getofflineMessage.body = [NSData data];
    getofflineMessage.len = 0;
    [self sendMessage:getofflineMessage];
}

- (void)handleOfflineMessage:(Message *)msg {
    IMTransferData *response = (IMTransferData *) msg.body;
    if (response.cipherData) {
        GcmData *gcmData = response.cipherData;
        NSData *compressData = [ConnectTool decodeGcmDataWithEcdhKey:self.extensionPass GcmData:gcmData];
        NSData *offlineData = [compressData gunzippedData];
        OfflineMsgs *offlinemsg = [OfflineMsgs parseFromData:offlineData error:nil];

        [GCDQueue executeInQueue:self.offlineMessageHandleQueue block:^{
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
                                /**
                                 #define BM_IM_EXT 0x01
                                 #define BM_IM_MESSAGE_ACK_EXT 0x02
                                 #define BM_IM_SEND_GROUPINFO_EXT 0x03
                                 #define BM_IM_GROUPMESSAGE_EXT 0x04
                                 */
                                switch (extension) {
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

                                    case BM_IM_MESSAGE_ACK_EXT: //message read ack
                                    {
                                        Message *temMsg = [[Message alloc] init];
                                        temMsg.body = post;
                                        [self handleReadAckMessage:temMsg];
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

            [self.groupMessageHandler handleBatchGroupInviteMessage:offLineCreateGroupMessages];

            [self.peerMessageHandler handleBatchMessages:offLineNomarlMessages];

            [self.groupMessageHandler handleBatchGroupMessage:offLinGroupMessages];

            [[SystemMessageHandler instance] handleBatchMessages:offLineRoobtMessages];

            for (OfflineMsg *messageDetail in offlinemsg.offlineMsgsArray) {
                int type = messageDetail.body.type;
                [GCDQueue executeInQueue:self.messageSendQueue block:^{
                    [self sendAck:messageDetail.msgId type:type];
                }];
            }
        }];

        if (offlinemsg.completed) {
            DDLogError(@"%@", offlinemsg);
            self.connectState = STATE_CONNECTED;
            [GCDQueue executeInMainQueue:^{
                DDLogInfo(@"handleOfflineMessage publish %f", [[NSDate date] timeIntervalSince1970]);
                [self publishConnectState:self.connectState];
                if (offlinemsg.offlineMsgsArray.count) {
                    SendNotify(ConnectGetOfflieCompleteNotification, nil);
                }
            }];

            //upload Cookie
            [self uploadCookie];
        }
    }
}


#pragma mark - Command-upload login user chat cookie

- (void)uploadCookie {
    ChatCookieData *cacheData = [[LMHistoryCacheManager sharedManager] getLeastChatCookie];
    if (!cacheData ||
            cacheData.expired < [[NSDate date] timeIntervalSince1970]) {

        ChatCacheCookie *chatCookie = [ChatCacheCookie new];
        chatCookie.chatPrivkey = [KeyHandle creatNewPrivkey];
        chatCookie.chatPubKey = [KeyHandle createPubkeyByPrikey:chatCookie.chatPrivkey];
        chatCookie.salt = [KeyHandle createRandom512bits];
        [SessionManager sharedManager].loginUserChatCookie = chatCookie;

        ChatCookieData *cookieData = [ChatCookieData new];
        cookieData.chatPubKey = chatCookie.chatPubKey;
        cookieData.salt = chatCookie.salt;
        cookieData.expired = [[NSDate date] timeIntervalSince1970] + 24 * 60 * 60;

        ChatCookie *cookie = [ChatCookie new];
        cookie.data_p = cookieData;
        cookie.sign = [ConnectTool signWithData:cookieData.data];

        Command *command = [[Command alloc] init];
        command.msgId = [ConnectTool generateMessageId];
        command.detail = cookie.data;

        IMTransferData *request = [ConnectTool createTransferWithEcdhKey:self.extensionPass data:command.data aad:nil];
        Message *m = [[Message alloc] init];
        m.msgIdentifer = command.msgId;
        m.originData = command.data;
        m.sendOriginInfo = cookieData;
        m.typechar = BM_COMMAND_TYPE;
        m.extension = BM_UPLOAD_CHAT_COOKIE_EXT;
        m.len = (int) [request data].length;
        m.body = [request data];

        [self sendCommandWith:m comlete:nil];
    } else {
        if (![SessionManager sharedManager].loginUserChatCookie) {
            [SessionManager sharedManager].loginUserChatCookie = [[LMHistoryCacheManager sharedManager] getChatCookieWithSaltVer:cacheData.salt];
        }
    }
}

- (void)uploadCookieAck:(Message *)msg {
    IMTransferData *response = (IMTransferData *) msg.body;
    NSData *data = [ConnectTool decodeIMTransferData:response extensionEcdhKey:self.extensionPass];
    if (data) {
        Command *command = [Command parseFromData:data error:nil];

        Message *oriMsg = [[CommandOutTimeTool sharedManager] getMessageByIdentifer:command.msgId];
        msg.msgIdentifer = command.msgId;
        if (command.errNo == 0) {
            [[LMHistoryCacheManager sharedManager] cacheChatCookie:[SessionManager sharedManager].loginUserChatCookie];
            [[LMHistoryCacheManager sharedManager] cacheLeastChatCookie:oriMsg.sendOriginInfo];
        } else if (command.errNo == 4) { //time error
            //note ui ,time error
            [SessionManager sharedManager].loginUserChatCookie = nil;
        }
    }

    [[CommandOutTimeTool sharedManager] removeSuccessMessage:msg];
}

#pragma mark - Command-Get the latest Cookie for the session user

- (void)getUserCookieWihtChatUser:(AccountInfo *)chatUser complete:(SendCommandComplete)complete {
    if (GJCFStringIsNull(chatUser.address)) {
        complete = nil;
        return;
    }
    [self sendCommandWithDelayCallBlock:^(IMService *imserverSelf) {
        FriendChatCookie *chatInfoAddress = [FriendChatCookie new];
        chatInfoAddress.address = chatUser.address;

        Command *command = [[Command alloc] init];
        command.msgId = [ConnectTool generateMessageId];
        command.detail = chatInfoAddress.data;

        IMTransferData *request = [ConnectTool createTransferWithEcdhKey:self.extensionPass data:command.data aad:nil];
        Message *m = [[Message alloc] init];
        m.msgIdentifer = command.msgId;
        m.originData = command.data;
        m.sendOriginInfo = chatUser;
        m.typechar = BM_COMMAND_TYPE;
        m.extension = BM_FRIEND_CHAT_COOKIE_EXT;
        m.len = (int) [request data].length;
        m.body = [request data];
        [self sendCommandWith:m comlete:complete];
    }];
}

- (void)chatUserCookie:(Message *)msg {
    IMTransferData *response = (IMTransferData *) msg.body;
    NSData *data = [ConnectTool decodeIMTransferData:response extensionEcdhKey:self.extensionPass];
    if (data) {
        NSError *error = nil;
        Command *command = [Command parseFromData:data error:&error];
        msg.msgIdentifer = command.msgId;
        CommandCallbackModel *callBack = [[CommandOutTimeTool sharedManager].concurrentMsgCompleteBlockDict valueForKey:msg.msgIdentifer];
        if (command.errNo == 5) { //friend did not report Chatcookie
            if (callBack.completeBlock) {
                callBack.completeBlock(nil, nil);
            }
        } else {
            if (error) {
                if (callBack.completeBlock) {
                    callBack.completeBlock(error, nil);
                }
            } else {
                ChatCookie *chatCookie = [ChatCookie parseFromData:command.detail error:&error];
                Message *oriMsg = [[CommandOutTimeTool sharedManager] getMessageByIdentifer:command.msgId];
                AccountInfo *userInfo = (AccountInfo *) oriMsg.sendOriginInfo;
                if ([ConnectTool vertifyWithData:chatCookie.data_p.data sign:chatCookie.sign publickey:userInfo.pub_key]) {
                    ChatCookieData *chatInfo = chatCookie.data_p;
                    if (error) {
                        if (callBack.completeBlock) {
                            callBack.completeBlock(error, nil);
                        }
                    } else {
                        [[SessionManager sharedManager] setChatCookie:chatInfo chatSession:userInfo.pub_key];
                        if (callBack.completeBlock) {
                            callBack.completeBlock(nil, chatInfo);
                        }
                    }
                }
            }
        }
        [self sendIMBackAck:command.msgId];
        [[CommandOutTimeTool sharedManager] removeSuccessMessage:msg];
    }
}


#pragma mark - Command-unbind device token

- (void)deviceTokenUnbind:(Message *)msg {
    IMTransferData *response = (IMTransferData *) msg.body;
    NSData *data = [ConnectTool decodeIMTransferData:response extensionEcdhKey:self.extensionPass];
    if (data) {
        CommandStauts *status = [CommandStauts parseFromData:data error:nil];
        if (status.status != 0) {
            DDLogInfo(@"unbind device token success");
            if (self.UnBindDeviceTokenComplete) {
                self.UnBindDeviceTokenComplete(nil);
            }
        } else {
            DDLogError(@"unbind device token failed");
            if (self.UnBindDeviceTokenComplete) {
                self.UnBindDeviceTokenComplete([NSError errorWithDomain:@"Undingfail" code:-1 userInfo:nil]);
            }
        }
    }
}

#pragma mark - Comman-bind device token

- (void)deviceTokenBind:(Message *)msg {

    IMTransferData *response = (IMTransferData *) msg.body;
    NSData *data = [ConnectTool decodeIMTransferData:response extensionEcdhKey:self.extensionPass];
    NSError *error = nil;
    Command *command = [Command parseFromData:data error:&error];
    if (error) {
        return;
    }
    msg.msgIdentifer = command.msgId;
    [[CommandOutTimeTool sharedManager] removeSuccessMessage:msg];
    CommandStauts *status = [CommandStauts parseFromData:command.detail error:nil];
    if (status.status != 0) {
        DDLogInfo(@"bind success");
    } else {
        DDLogError(@"bind failed");
    }
    [self sendIMBackAck:command.msgId];
}

#pragma mark - Command-offlie command

- (void)handldOfflineCmdData:(NSData *)data cmdType:(int)cmdType {
    switch (cmdType) {
        case BM_ACCEPT_NEWFRIEND_EXT: {
            [self acceptRequestSuccessDetail:data];
        }
            break;
        case BM_NEWFRIEND_EXT:
            [self newFriendRequestDetailHandle:data];
            break;
        case BM_GROUPINFO_CHANGE_EXT:
            [self handleGroupInfoChangeOffLineCmdWithData:data];
            break;
        default:
            break;
    }
}

#pragma mark - Command-session

- (void)handldSessionBackCall:(Message *)msg {
    IMTransferData *transerData = (IMTransferData *) msg.body;

    BOOL sign = [ConnectTool vertifyWithData:transerData.cipherData.data sign:transerData.sign];
    NSData *decodeData = nil;
    Command *command = nil;
    if (sign) {
        decodeData = [ConnectTool decodeGcmDataWithEcdhKey:self.extensionPass GcmData:transerData.cipherData];
        NSError *error = nil;
        command = [Command parseFromData:decodeData error:&error];
        if (error) {
            DDLogError(@"can not parse data。。");
            return;
        }

        msg.msgIdentifer = command.msgId;

        CommandCallbackModel *callBack = [[CommandOutTimeTool sharedManager].concurrentMsgCompleteBlockDict valueForKey:msg.msgIdentifer];
        if (callBack.completeBlock) {
            callBack.completeBlock(nil, nil);
        }
        [[CommandOutTimeTool sharedManager] removeSuccessMessage:msg];
        [self sendIMBackAck:command.msgId];
    } else {
        DDLogError(@"verfy failed。。");
        return;
    }


    switch (msg.extension) {
        case BM_CREATE_SESSION: {

        }
            break;
        case BM_SETMUTE_SESSION: {

        }
            break;

        case BM_DELETE_SESSION: {

        }
            break;
        default:
            break;
    }
}

#pragma mark - Command-sync badge

- (void)handldSyncBadgeNumber:(Message *)msg {
    IMTransferData *transerData = (IMTransferData *) msg.body;
    BOOL sign = [ConnectTool vertifyWithData:transerData.cipherData.data sign:transerData.sign];
    if (sign) {
        NSData *decodeData = [ConnectTool decodeGcmDataWithEcdhKey:self.extensionPass GcmData:transerData.cipherData];

        if (!decodeData) {
            DDLogError(@"decode message failed");
            return;
        }
        NSError *error = nil;
        Command *command = [Command parseFromData:decodeData error:&error];
        if (error) {
            return;
        }

        msg.msgIdentifer = command.msgId;

        [[CommandOutTimeTool sharedManager] removeSuccessMessage:msg];

        [self sendIMBackAck:command.msgId];
    }
}

#pragma mark - Command-groupinfo change

- (void)handldGroupInfoChange:(Message *)msg {

    IMTransferData *transerData = (IMTransferData *) msg.body;

    BOOL sign = [ConnectTool vertifyWithData:transerData.cipherData.data sign:transerData.sign];

    if (sign) {
        NSData *decodeData = [ConnectTool decodeGcmDataWithEcdhKey:self.extensionPass GcmData:transerData.cipherData];
        [self handleGroupInfoChangeOffLineCmdWithData:decodeData];
    }
}

- (void)handleGroupInfoChangeOffLineCmdWithData:(NSData *)decodeData {
    if (!decodeData) {
        return;
    }

    NSError *error = nil;
    Command *command = [Command parseFromData:decodeData error:&error];
    if (error) {
        return;
    }

    GroupChange *groupChange = [GroupChange parseFromData:command.detail error:nil];

    [GCDQueue executeInGlobalQueue:^{
        [self handleGroupInfoDetailChange:groupChange messageId:command.msgId];
    }];
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

                        LMGroupInfo *lmGroupTem = [[GroupDBManager sharedManager] addMember:newUsers ToGroupChat:groupChange.identifier];

                        NSMutableArray *temA = [NSMutableArray arrayWithArray:lmGroupTem.groupMembers];
                        NSMutableArray *avatars = [NSMutableArray array];
                        for (AccountInfo *member in temA) {
                            [avatars objectAddObject:member.avatar];
                        }
                        [[CIImageCacheManager sharedInstance] uploadGroupAvatarWithGroupIdentifier:groupChange.identifier groupMembers:avatars];
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
                        LMGroupInfo *lmGroupTem = [[GroupDBManager sharedManager] addMember:newUsers ToGroupChat:groupChange.identifier];

                        NSMutableArray *temA = [NSMutableArray arrayWithArray:lmGroupTem.groupMembers];
                        NSMutableArray *avatars = [NSMutableArray array];
                        for (AccountInfo *member in temA) {
                            [avatars objectAddObject:member.avatar];
                        }
                        [[CIImageCacheManager sharedInstance] uploadGroupAvatarWithGroupIdentifier:groupChange.identifier groupMembers:avatars];
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

                        [[CIImageCacheManager sharedInstance] uploadGroupAvatarWithGroupIdentifier:groupChange.identifier groupMembers:avatars];

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


            [GCDQueue executeInQueue:self.messageSendQueue block:^{
                [self sendIMBackAck:msgId];
            }];

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

#pragma mark - Command-version change upload info to server

- (void)uploadAppInfoWhenVersionChange {
    BOOL neetUploadappVerinfo = [SystemTool neetUploadappVerinfo];
    if (neetUploadappVerinfo) {
        AppInfo *appInfo = [[AppInfo alloc] init];
        appInfo.platform = [UIDevice currentDevice].systemName;
        NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary]; //CFBundleIdentifier
        NSString *versionNum = [infoDict objectForKey:@"CFBundleShortVersionString"];
        appInfo.version = versionNum;

        appInfo.osVersion = [UIDevice currentDevice].systemVersion;

        appInfo.model = [MMGlobal getCurrentDeviceModel];

        Command *command = [[Command alloc] init];
        command.msgId = [ConnectTool generateMessageId];
        command.detail = appInfo.data;

        IMTransferData *request = [ConnectTool createTransferWithEcdhKey:self.extensionPass data:command.data aad:nil];
        Message *m = [[Message alloc] init];
        m.typechar = BM_COMMAND_TYPE;
        m.extension = BM_UPLOAD_APPINFO_EXT;
        m.len = (int) request.data.length;
        m.body = request.data;
        [self sendMessage:m];
    }
}

#pragma mark - Command-create session

- (void)addNewSessionWithAddress:(NSString *)address complete:(SendCommandComplete)complete {

    [self sendCommandWithDelayCallBlock:^(IMService *imserverSelf) {
        ManageSession *proto = [[ManageSession alloc] init];
        proto.address = address;
        Command *command = [[Command alloc] init];
        command.msgId = [ConnectTool generateMessageId];
        command.detail = proto.data;

        IMTransferData *request = [ConnectTool createTransferWithEcdhKey:imserverSelf.extensionPass data:command.data aad:nil];
        Message *m = [[Message alloc] init];
        m.msgIdentifer = command.msgId;
        m.originData = command.data;
        m.typechar = BM_COMMAND_TYPE;
        m.extension = BM_CREATE_SESSION;
        m.len = (int) [request data].length;
        m.body = [request data];

        [imserverSelf sendCommandWith:m comlete:complete];
    }];
}


#pragma mark -  Command outer transfer

- (void)handldOuterTransfer:(Message *)msg {
    IMTransferData *transerData = (IMTransferData *) msg.body;
    BOOL sign = [ConnectTool vertifyWithData:transerData.cipherData.data sign:transerData.sign];
    if (sign) {
        NSData *decodeData = [ConnectTool decodeGcmDataWithEcdhKey:self.extensionPass GcmData:transerData.cipherData];
        if (!decodeData) {
            DDLogError(@"decode failed！！！");
            return;
        }
        NSError *error = nil;
        Command *command = [Command parseFromData:decodeData error:&error];
        if (error) {
            return;
        }

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

        msg.msgIdentifer = command.msgId;

        [[CommandOutTimeTool sharedManager] removeSuccessMessage:msg];

        [self sendOnlineBackAck:command.msgId type:msg.typechar];
    }
}

- (void)reciveMoneyWihtToken:(NSString *)token complete:(SendCommandComplete)complete {

    [self sendCommandWithDelayCallBlock:^(IMService *imserverSelf) {
        ExternalBillingToken *proto = [[ExternalBillingToken alloc] init];
        proto.token = token;
        Command *command = [[Command alloc] init];
        command.msgId = [ConnectTool generateMessageId];
        command.detail = proto.data;
        IMTransferData *request = [ConnectTool createTransferWithEcdhKey:imserverSelf.extensionPass data:command.data aad:nil];
        Message *m = [[Message alloc] init];
        m.msgIdentifer = command.msgId;
        m.originData = command.data;
        m.typechar = BM_COMMAND_TYPE;
        m.extension = BM_OUTER_TRANSFER_EXT;
        m.len = (int) [request data].length;
        m.body = [request data];
        [imserverSelf sendCommandWith:m comlete:complete];
    }];
}

#pragma mark - Command-not interet someone

- (void)setRecommandUserNoInterestAdress:(NSString *)address
                                 comlete:(void (^)(NSError *erro, id data))complete {
    [self sendCommandWithDelayCallBlock:^(IMService *imserverSelf) {
        NOInterest *notInterest = [[NOInterest alloc] init];
        notInterest.address = address;
        Command *command = [[Command alloc] init];
        command.detail = notInterest.data;
        command.msgId = [ConnectTool generateMessageId];

        IMTransferData *request = [ConnectTool createTransferWithEcdhKey:imserverSelf.extensionPass data:command.data aad:nil];
        Message *m = [[Message alloc] init];
        m.msgIdentifer = command.msgId;
        m.originData = command.data;
        m.sendOriginInfo = address;
        m.typechar = BM_COMMAND_TYPE;
        m.extension = BM_RECOMMADN_NOTINTEREST_EXT;
        m.len = (int) [request data].length;
        m.body = [request data];
        [imserverSelf sendCommandWith:m comlete:complete];
    }];

}

- (void)handleRcommandNointeret:(Message *)msg {
    IMTransferData *transerData = (IMTransferData *) msg.body;
    BOOL sign = [ConnectTool vertifyWithData:transerData.cipherData.data sign:transerData.sign];
    if (sign) {
        NSData *decodeData = [ConnectTool decodeGcmDataWithEcdhKey:self.extensionPass GcmData:transerData.cipherData];
        if (!decodeData) {
            DDLogError(@"decode failed！！！");
            return;
        }
        NSError *error = nil;
        Command *command = [Command parseFromData:decodeData error:&error];
        if (error) {
            return;
        }

        Message *oriMsg = [[CommandOutTimeTool sharedManager] getMessageByIdentifer:command.msgId];
        CommandCallbackModel *callBack = [[CommandOutTimeTool sharedManager].concurrentMsgCompleteBlockDict valueForKey:oriMsg.msgIdentifer];
        if (callBack.completeBlock) {
            if (command.errNo > 0) {
                callBack.completeBlock([NSError errorWithDomain:command.msg code:command.errNo userInfo:nil], nil);
            } else {
                callBack.completeBlock(nil, oriMsg.sendOriginInfo);
            }
        }
        [[CommandOutTimeTool sharedManager] removeSuccessMessage:oriMsg];
    }
}

#pragma mark - Command-outer luckypackage

- (void)handldOuterRedpacket:(Message *)msg {
    IMTransferData *transerData = (IMTransferData *) msg.body;
    BOOL sign = [ConnectTool vertifyWithData:transerData.cipherData.data sign:transerData.sign];
    if (sign) {
        NSData *decodeData = [ConnectTool decodeGcmDataWithEcdhKey:self.extensionPass GcmData:transerData.cipherData];
        if (!decodeData) {
            DDLogError(@"decode message failed");
            return;
        }
        NSError *error = nil;
        Command *command = [Command parseFromData:decodeData error:&error];
        if (error) {
            return;
        }

        NSString *message = LMLocalizedString(@"Link Unknown error", nil);
        switch (command.errNo) {
            case 0: {
                message = LMLocalizedString(@"Chat You receive a red envelope", nil);
                ExternalRedPackageInfo *redPackgeinfo = [ExternalRedPackageInfo parseFromData:command.detail error:nil];
                if (redPackgeinfo.system) { //system package
                    UserInfo *system = [UserInfo new];
                    system.pubKey = @"connect";
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
        msg.msgIdentifer = command.msgId;

        [[CommandOutTimeTool sharedManager] removeSuccessMessage:msg];

        [self sendOnlineBackAck:command.msgId type:msg.typechar];
    }
}

- (void)openRedPacketWihtToken:(NSString *)token complete:(SendCommandComplete)complete {

    [self sendCommandWithDelayCallBlock:^(IMService *imserverSelf) {
        RedPackageToken *proto = [[RedPackageToken alloc] init];
        proto.token = token;
        Command *command = [[Command alloc] init];
        command.msgId = [ConnectTool generateMessageId];
        command.detail = proto.data;
        IMTransferData *request = [ConnectTool createTransferWithEcdhKey:imserverSelf.extensionPass data:command.data aad:nil];
        Message *m = [[Message alloc] init];
        m.msgIdentifer = command.msgId;
        m.originData = command.data;
        m.typechar = BM_COMMAND_TYPE;
        m.extension = BM_OUTER_REDPACKET_EXT;
        m.len = (int) [request data].length;
        m.body = [request data];
        [imserverSelf sendCommandWith:m comlete:complete];
    }];
}

#pragma mark - Command-update session

- (void)openOrCloseSesionMuteWithAddress:(NSString *)address mute:(BOOL)mute complete:(SendCommandComplete)complete {

    [self sendCommandWithDelayCallBlock:^(IMService *imserverSelf) {
        UpdateSession *proto = [[UpdateSession alloc] init];
        proto.address = address;
        proto.flag = mute;

        Command *command = [[Command alloc] init];
        command.msgId = [ConnectTool generateMessageId];
        command.detail = proto.data;
        IMTransferData *request = [ConnectTool createTransferWithEcdhKey:imserverSelf.extensionPass data:command.data aad:nil];
        Message *m = [[Message alloc] init];
        m.msgIdentifer = command.msgId;
        m.originData = command.data;
        m.typechar = BM_COMMAND_TYPE;
        m.extension = BM_SETMUTE_SESSION;
        m.len = (int) [request data].length;
        m.body = [request data];

        [imserverSelf sendCommandWith:m comlete:complete];
    }];

}

#pragma mark - Command-delete session

- (void)deleteSessionWithAddress:(NSString *)address complete:(SendCommandComplete)complete {
    [self sendCommandWithDelayCallBlock:^(IMService *imserverSelf) {
        ManageSession *proto = [[ManageSession alloc] init];
        proto.address = address;

        Command *command = [[Command alloc] init];
        command.msgId = [ConnectTool generateMessageId];
        command.detail = proto.data;

        IMTransferData *request = [ConnectTool createTransferWithEcdhKey:imserverSelf.extensionPass data:command.data aad:nil];
        Message *m = [[Message alloc] init];
        m.msgIdentifer = command.msgId;
        m.originData = command.data;
        m.typechar = BM_COMMAND_TYPE;
        m.extension = BM_DELETE_SESSION;
        m.len = (int) [request data].length;
        m.body = [request data];

        [imserverSelf sendCommandWith:m comlete:complete];
    }];
}

#pragma mark - Command-add new friend

- (void)addNewFiendWithInviteUser:(AccountInfo *)inviteUser tips:(NSString *)tips source:(int)source comlete:(void (^)(NSError *erro, id data))complete {
    if (GJCFStringIsNull(tips)) {
        tips = LMLocalizedString(@"Link Hello", nil);
    }
    tips = [StringTool filterStr:tips];
    inviteUser.message = tips;
    inviteUser.source = source;
    inviteUser.status = RequestFriendStatusVerfing;
    AddFriendRequest *addReuqest = [[AddFriendRequest alloc] init];
    GcmData *tipGcmData = [ConnectTool createGcmWithData:tips publickey:inviteUser.pub_key];
    addReuqest.address = inviteUser.address;
    addReuqest.tips = tipGcmData;
    addReuqest.source = source;

    Command *command = [[Command alloc] init];
    command.msgId = [ConnectTool generateMessageId];
    command.detail = addReuqest.data;

    IMTransferData *request = [ConnectTool createTransferWithEcdhKey:self.extensionPass data:command.data aad:nil];
    Message *m = [[Message alloc] init];
    m.msgIdentifer = command.msgId;
    m.originData = command.data;
    m.sendOriginInfo = inviteUser;
    m.typechar = BM_COMMAND_TYPE;
    m.extension = BM_NEWFRIEND_EXT;
    m.len = (int) [request data].length;
    m.body = [request data];
    [self sendCommandWith:m comlete:complete];

    [[UserDBManager sharedManager] saveNewFriend:inviteUser];
}

#pragma mark - Command-get contacts

- (void)getFriendsWithVersion:(NSString *)version comlete:(void (^)(NSError *erro, id data))complete {

    if ([version isEqualToString:@""]) { //login on new device
        [GCDQueue executeInMainQueue:^{
            SendNotify(LoinOnNewDeviceStatusNotification, @(1));
        }];
        version = @"0";
    }

    SyncRelationship *relation = [[SyncRelationship alloc] init];
    relation.version = version;

    Command *command = [[Command alloc] init];
    command.msgId = [ConnectTool generateMessageId];
    command.detail = relation.data;

    IMTransferData *request = [ConnectTool createTransferWithEcdhKey:self.extensionPass data:command.data aad:nil];
    Message *m = [[Message alloc] init];
    m.msgIdentifer = command.msgId;
    m.originData = command.data;
    m.typechar = BM_COMMAND_TYPE;
    m.extension = BM_FRIENDLIST_EXT;
    m.len = (int) [request data].length;
    m.body = [request data];

    [self sendCommandWith:m comlete:complete];

}

#pragma mark - Command-sync contacts

- (void)syncFriendsWithComlete:(void (^)(NSError *erro, id data))complete {

    SyncRelationship *relation = [[SyncRelationship alloc] init];
    relation.version = @"0";
    Command *command = [[Command alloc] init];
    command.msgId = [ConnectTool generateMessageId];
    command.detail = relation.data;

    IMTransferData *request = [ConnectTool createTransferWithEcdhKey:self.extensionPass data:command.data aad:nil];
    Message *m = [[Message alloc] init];
    m.msgIdentifer = command.msgId;
    m.originData = command.data;
    m.sendOriginInfo = @"syncfriend";
    m.typechar = BM_COMMAND_TYPE;
    m.extension = BM_FRIENDLIST_EXT;
    m.len = (int) [request data].length;
    m.body = [request data];
    [self sendCommandWith:m comlete:complete];
}

#pragma mark - Command-accept friend request

- (void)acceptAddRequestWithAddress:(NSString *)address source:(int)source comlete:(void (^)(NSError *erro, id data))complete {

    AcceptFriendRequest *acceptRequest = [[AcceptFriendRequest alloc] init];
    acceptRequest.address = address;
    acceptRequest.source = source;

    Command *command = [[Command alloc] init];
    command.msgId = [ConnectTool generateMessageId];
    command.detail = acceptRequest.data;

    IMTransferData *request = [ConnectTool createTransferWithEcdhKey:self.extensionPass data:command.data aad:nil];
    Message *m = [[Message alloc] init];
    m.msgIdentifer = command.msgId;
    m.originData = command.data;
    m.sendOriginInfo = address;
    m.typechar = BM_COMMAND_TYPE;
    m.extension = BM_ACCEPT_NEWFRIEND_EXT;
    m.len = (int) [request data].length;
    m.body = [request data];
    [self sendCommandWith:m comlete:complete];

}

#pragma mark - Comand-delete contact

- (void)deleteFriendWithAddress:(NSString *)address comlete:(void (^)(NSError *erro, id data))complete {

    RemoveRelationship *removeFriend = [[RemoveRelationship alloc] init];
    removeFriend.address = address;


    Command *command = [[Command alloc] init];
    command.msgId = [ConnectTool generateMessageId];
    command.detail = removeFriend.data;

    IMTransferData *request = [ConnectTool createTransferWithEcdhKey:self.extensionPass data:command.data aad:nil];

    Message *m = [[Message alloc] init];
    m.msgIdentifer = command.msgId;
    m.originData = command.data;
    m.sendOriginInfo = address;
    m.typechar = BM_COMMAND_TYPE;
    m.extension = BM_DELETE_FRIEND_EXT;
    m.len = (int) [request data].length;
    m.body = [request data];
    [self sendCommandWith:m comlete:complete];

}

#pragma mark - Command-set user info

- (void)setFriendInfoWithAddress:(NSString *)address remark:(NSString *)remark commonContact:(BOOL)commonContact comlete:(void (^)(NSError *erro, id data))complete {
    SettingFriendInfo *setFriend = [[SettingFriendInfo alloc] init];
    setFriend.address = address;
    setFriend.common = commonContact;
    setFriend.remark = remark;


    Command *command = [[Command alloc] init];
    command.msgId = [ConnectTool generateMessageId];
    command.detail = setFriend.data;

    IMTransferData *request = [ConnectTool createTransferWithEcdhKey:self.extensionPass data:command.data aad:nil];

    Message *m = [[Message alloc] init];
    m.msgIdentifer = command.msgId;
    m.originData = command.data;
    m.sendOriginInfo = address;
    m.typechar = BM_COMMAND_TYPE;
    m.extension = BM_SET_FRIENDINFO_EXT;
    m.len = (int) [request data].length;
    m.body = [request data];
    [self sendCommandWith:m comlete:complete];

}

#pragma mark - Command-sync badge number

- (void)syncBadgeNumber:(NSInteger)badgeNumber {
    if (badgeNumber < 0) {
        return;
    }
    [self sendCommandWithDelayCallBlock:^(IMService *imserverSelf) {
        SyncBadge *badge = [[SyncBadge alloc] init];
        badge.badge = (int) badgeNumber;
        Command *command = [[Command alloc] init];
        command.msgId = [ConnectTool generateMessageId];
        command.detail = badge.data;

        IMTransferData *request = [ConnectTool createTransferWithEcdhKey:self.extensionPass data:command.data aad:nil];

        Message *m = [[Message alloc] init];
        m.msgIdentifer = command.msgId;
        m.originData = command.data;
        m.sendOriginInfo = @(badgeNumber);
        m.typechar = BM_COMMAND_TYPE;
        m.extension = BM_SYNCBADGENUMBER_EXT;
        m.len = (int) [request data].length;
        m.body = [request data];
        [imserverSelf sendCommandWith:m comlete:nil];
    }];
}


#pragma mark - Command-send command base method

- (void)sendCommandWith:(Message *)msg comlete:(void (^)(NSError *erro, id data))complete {
    __weak __typeof(&*self) weakSelf = self;
    [[CommandOutTimeTool sharedManager] addToSendConcurrentQueue:msg complete:complete];
    [GCDQueue executeInQueue:self.commondQueue block:^{
        [weakSelf sendMessage:msg];
    }];
}

#pragma mark - Command-send command

- (void)sendCommandWithDelayCallBlock:(void (^)(IMService *imserverSelf))callBlock {
    if (self.connectState == STATE_CONNECTED || self.connectState == STATE_GETOFFLINE) {
        if (callBlock) {
            callBlock(self);
        }
    } else {
        if (!self.delaySendCommondQueue) {
            self.delaySendCommondQueue = dispatch_queue_create("delaysendqueue", DISPATCH_QUEUE_CONCURRENT);
        }
        if (!self.delaySendIsSuspend) {
            dispatch_suspend(self.delaySendCommondQueue);
            self.delaySendIsSuspend = YES;
        }
        dispatch_async(self.delaySendCommondQueue, ^{
            if (callBlock) {
                callBlock(self);
            }
        });
    }

}

#pragma mark - Command-bind device token

- (void)bindDeviceTokenWithDeviceToken:(NSString *)deviceToken {

    [self sendCommandWithDelayCallBlock:^(IMService *imserverSelf) {
        DeviceToken *deviceT = [[DeviceToken alloc] init];
        deviceT.apnsDeviceToken = deviceToken;
        deviceT.pushType = @"APNS";

        Command *command = [[Command alloc] init];
        command.msgId = [ConnectTool generateMessageId];
        command.detail = deviceT.data;

        IMTransferData *request = [ConnectTool createTransferWithEcdhKey:imserverSelf.extensionPass data:command.data aad:nil];

        Message *m = [[Message alloc] init];
        m.msgIdentifer = command.msgId;
        m.originData = command.data;
        m.sendOriginInfo = deviceToken;
        m.typechar = BM_COMMAND_TYPE;
        m.extension = BM_BINDDEVICETOKEN_EXT;
        m.len = (int) [request data].length;
        m.body = [request data];
        [imserverSelf sendCommandWith:m comlete:nil];
    }];
}

#pragma mark - Command-unbind device token

- (void)unBindDeviceTokenWithDeviceToken:(NSString *)deviceToken complete:(void (^)(NSError *error))complete {
    [self sendCommandWithDelayCallBlock:^(IMService *imserverSelf) {
        self.UnBindDeviceTokenComplete = complete;
        DeviceToken *deviceT = [[DeviceToken alloc] init];
        deviceT.apnsDeviceToken = deviceToken;
        deviceT.pushType = @"APNS";
        Command *command = [[Command alloc] init];
        command.msgId = [ConnectTool generateMessageId];
        command.detail = deviceT.data;

        IMTransferData *request = [ConnectTool createTransferWithEcdhKey:imserverSelf.extensionPass data:command.data aad:nil];
        Message *m = [[Message alloc] init];
        m.originData = command.data;
        m.sendOriginInfo = deviceToken;
        m.typechar = BM_COMMAND_TYPE;
        m.extension = BM_UNBINDDEVICETOKEN_EXT;
        m.len = (int) [request data].length;
        m.body = [request data];
        [imserverSelf sendCommandWith:m comlete:nil];
    }];
}

#pragma mark - Command-common group

- (void)handleGroupInfo:(Message *)msg {
    IMTransferData *response = (IMTransferData *) msg.body;

    GcmData *gcmData = response.cipherData;

    if ([ConnectTool vertifyWithData:gcmData.data sign:response.sign]) {

        NSData *data = [ConnectTool decodeGcmDataWithEcdhKey:self.extensionPass GcmData:gcmData];
        NSError *error = nil;
        UserCommonGroups *userGroups = [UserCommonGroups parseFromData:data error:&error];

        for (GroupInfo *groupInfo in userGroups.groupsArray) {
            NSDictionary *dict = [groupInfo.ecdh dictionaryValue];
            NSString *aad = [dict valueForKey:@"aad"];
            NSString *iv = [dict valueForKey:@"iv"];
            NSString *tag = [dict valueForKey:@"tag"];
            NSString *ciphertext = [dict valueForKey:@"ciphertext"];
            NSString *groupKey = nil;
            if (GJCFStringIsNull(aad) || GJCFStringIsNull(iv) || GJCFStringIsNull(tag) || GJCFStringIsNull(ciphertext)) {
                groupKey = [self getGroupFromBackup:groupInfo.backup];
            } else {
                groupKey = [KeyHandle xtalkDecodeAES_GCM:[[LKUserCenter shareCenter] getLocalGCDEcodePass] data:ciphertext aad:aad iv:iv tag:tag];
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
            if (groupInfo == [userGroups.groupsArray lastObject]) {
                [[MMAppSetting sharedSetting] haveSyncCommonGroup];
                [GCDQueue executeInMainQueue:^{
                    SendNotify(ConnnectDownAllCommonGroupCompleteNotification, @(userGroups.groupsArray.count));
                }];
            }
        }
        DDLogInfo(@"%@", userGroups);
    }
}

#pragma mark -  Parse Socket read data - handshake message

- (void)handleHandshakeWithMessage:(Message *)msg {
    switch (msg.extension) {
        case BM_HANDSHAKE_EXT: {
            [self handleAuthStatus:msg];
        }
            break;
        case BM_HANDSHAKEACK_EXT: {
            [self authSussecc:msg];
        }
            break;
        default:
            break;
    }
}

#pragma mark - Parse Socket read data -IM message

- (void)handleIMWithMessage:(Message *)msg {
    switch (msg.extension) {
        case BM_IM_EXT: {
            [self handleIMMessage:msg];
        }
            break;
        case BM_IM_MESSAGE_ACK_EXT: {
            [self handleReadAckMessage:msg];
        }
            break;
        case BM_IM_SEND_GROUPINFO_EXT: {
            [self handleInviteGroupMessage:msg];
        }
            break;
        case BM_IM_GROUPMESSAGE_EXT: {
            [self handleGroupIMMessage:msg];
        }
            break;
        case BM_IM_UNARRIVE_EXT:
        case BM_IM_NO_RALATIONSHIP_EXT: {
            [self handleBlackUnArrive:msg];
        }
            break;
        case BM_SERVER_NOTE_EXT: {
            [self transactionStatusChangeNoti:msg];
        }
            break;
        case BM_IM_ROBOT_EXT: {
            [self handleSystemMessage:msg];
        }
            break;
        default:
            break;
    }
}

#pragma mark - Parse Socket read data -ACK

- (void)handleAckWithMessage:(Message *)msg {
    switch (msg.extension) {
        case BM_ACK_EXT: {
            [self handleACK:msg];
        }
            break;
        case BM_GETOFFLINECMD_ACK_EXT: {
            [self handleCommandACK:msg];
        }
            break;
        default:
            break;
    }
}


#pragma mark - Parse Socket read data - command message

- (void)handleCommandWithMessage:(Message *)msg {
    switch (msg.extension) {
        case BM_GETOFFLINE_EXT: {
            [self handleOfflineMessage:msg];
        }
            break;
        case BM_UNBINDDEVICETOKEN_EXT: {
            [self deviceTokenUnbind:msg];
        }
            break;
        case BM_BINDDEVICETOKEN_EXT: {
            [self deviceTokenBind:msg];
        }
            break;
        case BM_NEWFRIEND_EXT: {
            [self newFriendRequest:msg];
        }
            break;
        case BM_FRIENDLIST_EXT: {
            [self handleFriendslist:msg];
        }
            break;
        case BM_ACCEPT_NEWFRIEND_EXT: {
            [self handleAcceptRequestSuccess:msg];
        }
            break;
        case BM_DELETE_FRIEND_EXT: {
            [self handleHandleDeleteUser:msg];
        }
            break;
        case BM_SET_FRIENDINFO_EXT: {
            [self handleSetUserInfo:msg];
        }
            break;
        case BM_COMMON_GROUP_EXT: {
            [self handleGroupInfo:msg];
        }
            break;
        case BM_GROUPINFO_CHANGE_EXT: {
            [self handldGroupInfoChange:msg];
        }
            break;
        case BM_SYNCBADGENUMBER_EXT: {
            [self handldSyncBadgeNumber:msg];
        }
            break;
        case BM_CREATE_SESSION: {
            [self handldSessionBackCall:msg];
        }
            break;
        case BM_SETMUTE_SESSION: {
            [self handldSessionBackCall:msg];
        }
            break;
        case BM_DELETE_SESSION: {
            [self handldSessionBackCall:msg];
        }
            break;
        case BM_OUTER_TRANSFER_EXT: {
            [self handldOuterTransfer:msg];
        }
            break;
        case BM_OUTER_REDPACKET_EXT: {
            [self handldOuterRedpacket:msg];
        }
            break;
        case BM_RECOMMADN_NOTINTEREST_EXT: {
            [self handleRcommandNointeret:msg];
        }
            break;
        case BM_UPLOAD_CHAT_COOKIE_EXT: {
            [self uploadCookieAck:msg];
        }
            break;
        case BM_FRIEND_CHAT_COOKIE_EXT:
            [self chatUserCookie:msg];
            break;
        default:
            break;
    }
}


#pragma mark - parse Socket read data - penetrating messages

- (void)handlePenetrateWithMessage:(Message *)msg {
    switch (msg.extension) {
        case BM_CUTOFFINE_CONNECT_EXT: {
            QuitMessage *quitMsg = msg.body;
            [[LKUserCenter shareCenter] loginOutByServerWithInfo:quitMsg.deviceName];
        }
            break;
        default:
            break;
    }
}

#pragma mark - parse the data read Socket - Socket layer received message classification processing

- (BOOL)handleData:(NSData *)data message:(Message *)msg {
    DDLogError(@"message type:%d  extension:%d", msg.typechar, msg.extension);
    switch (msg.typechar) {
        case BM_HANDSHAKE_TYPE:
            [self handleHandshakeWithMessage:msg];
            break;
        case BM_IM_TYPE:
            [self handleIMWithMessage:msg];
            break;
        case BM_ACK_TYPE:
            [self handleAckWithMessage:msg];
            break;
        case BM_COMMAND_TYPE:
            [self handleCommandWithMessage:msg];
            break;
        case BM_CUTOFFINE_CONNECT_TYPE:
            [self handlePenetrateWithMessage:msg];
            break;
        case BM_HEARTBEAT_TYPE:
            [self pong];
            break;
        default:
            break;
    }
    return YES;
}


#pragma mark - Method for transmitting data based on Socket layer

- (BOOL)sendPeerMessage:(MessagePost *)im {
    IMTransferData *imTransfer = [ConnectTool createTransferWithEcdhKey:self.extensionPass data:im.data aad:nil];
    Message *m = [[Message alloc] init];
    m.typechar = BM_IM_TYPE;
    m.extension = BM_IM_EXT;
    m.len = (int) [imTransfer data].length;
    m.body = [imTransfer data];
    BOOL r = [self sendMessage:m];
    return r;
}

- (BOOL)sendReadAckMessage:(MessagePost *)im {
    IMTransferData *imTransfer = [ConnectTool createTransferWithEcdhKey:self.extensionPass data:im.data aad:nil];
    Message *m = [[Message alloc] init];
    m.typechar = BM_IM_TYPE;
    m.extension = BM_IM_MESSAGE_ACK_EXT;
    m.len = (int) [imTransfer data].length;
    m.body = [imTransfer data];
    BOOL r = [self sendMessage:m];
    return r;
}


- (BOOL)sendGroupMessage:(MessagePost *)im {
    IMTransferData *imTransfer = [ConnectTool createTransferWithEcdhKey:self.extensionPass data:im.data aad:nil];
    Message *m = [[Message alloc] init];
    m.typechar = BM_IM_TYPE;
    m.extension = BM_IM_GROUPMESSAGE_EXT;
    m.len = (int) [imTransfer data].length;
    m.body = [imTransfer data];
    BOOL r = [self sendMessage:m];
    return r;
}


- (BOOL)sendSystemMessage:(IMTransferData *)imTransfer {
    Message *m = [[Message alloc] init];
    m.typechar = BM_IM_TYPE;
    m.extension = BM_IM_ROBOT_EXT;
    m.len = (int) [imTransfer data].length;
    m.body = [imTransfer data];
    BOOL r = [self sendMessage:m];
    return r;
}

- (BOOL)asyncSendGroupInfo:(MessagePost *)im {
    IMTransferData *imTransfer = [ConnectTool createTransferWithEcdhKey:self.extensionPass data:im.data aad:nil];
    Message *m = [[Message alloc] init];
    m.typechar = BM_IM_TYPE;
    m.extension = BM_IM_SEND_GROUPINFO_EXT;
    m.len = (int) [imTransfer data].length;
    m.body = [imTransfer data];
    BOOL r = [self sendMessage:m];
    if (r) {
        DDLogInfo(@"send success");
    }
    return YES;
}

- (BOOL)sendMessage:(Message *)msg {
    if (self.connectState == STATE_CONNECTED || self.connectState == STATE_AUTHING || self.connectState == STATE_GETOFFLINE) {
        self.seq = self.seq + 1;
        msg.seq = self.seq;
        DDLogError(@"typechar %d , extension %d", msg.typechar, msg.extension);
        NSData *data = [msg pack];
        if (!data) {
            DDLogInfo(@"message pack error");
            return NO;
        }
        [self write:data];
        return YES;
    } else {
        return NO;
    }
}


#pragma mark - Socket layer base send system message

- (void)asyncSendSystemMessage:(MMMessage *)message
                    completion:(void (^)(MMMessage *message,
                            NSError *error))completion {

    GPBMessage *msg = nil;
    switch (message.type) {
        case GJGCChatFriendContentTypeText: {
            TextMessage *textMsg = [[TextMessage alloc] init];
            textMsg.content = message.content;
            msg = textMsg;
        }
            break;
        case GJGCChatFriendContentTypeAudio: {
            Voice *voiceMsg = [[Voice alloc] init];
            voiceMsg.URL = message.content;
            voiceMsg.duration = message.size / 50;
            msg = voiceMsg;
        }
            break;

        case GJGCChatFriendContentTypeImage: {
            Image *image = [[Image alloc] init];
            image.URL = message.content;
            image.width = [NSString stringWithFormat:@"%f", message.imageOriginWidth];
            image.height = [NSString stringWithFormat:@"%f", message.imageOriginHeight];
            msg = image;
        }
            break;

        case GJGCChatFriendContentTypeMapLocation: {
            /*
             @{@"locationLatitude":@(messageContent.locationLatitude),
             @"locationLongitude":@(messageContent.locationLongitude),
             @"address":messageContent.originTextMessage};
             */
            Location *local = [[Location alloc] init];
            local.longitude = [[message.locationExt valueForKey:@"locationLongitude"] stringValue];
            local.latitude = [[message.locationExt valueForKey:@"locationLatitude"] stringValue];
            local.address = [message.locationExt valueForKey:@"address"];
            msg = local;
        }
            break;
        default:
            break;
    }

    MSMessage *msMessage = [[MSMessage alloc] init];
    msMessage.msgId = message.message_id;
    msMessage.body = msg.data;
    msMessage.category = message.type;

    IMTransferData *imTransferData = [ConnectTool createTransferWithEcdhKey:self.extensionPass data:msMessage.data aad:nil];
    __weak __typeof(&*self) weakSelf = self;
    [GCDQueue executeInQueue:self.messageSendQueue block:^{
        BOOL result = [weakSelf sendSystemMessage:imTransferData];

        NSString *sendTime = [NSString stringWithFormat:@"%lld", (int long long) [[NSDate date] timeIntervalSince1970]];
        SendMessageCallbackModel *callBackBlock = [[SendMessageCallbackModel alloc] init];
        callBackBlock.sendMessageCallbackBlock = completion;
        NSDictionary *temD = @{@"sendTime": sendTime,
                @"message": message,
                @"callBackBlock": callBackBlock};
        [self.peerMessages removeObjectForKey:message.message_id]; //resend
        [self.peerMessages setObject:temD forKey:message.message_id];

        if (!result) {
            [self messageSendFail:message];
            [GCDQueue executeInQueue:self.messageSendStatusQueue block:^{
                message.sendstatus = GJGCChatFriendSendMessageStatusFaild;
                if (completion) {
                    NSError *erro = [NSError errorWithDomain:@"imserver" code:SENDFAIL_NO_NETWORT userInfo:nil];
                    completion(message, erro);
                }
            }];
            [self.peerMessages removeObjectForKey:message.message_id];
        } else {

            if (!self.reflashSendStatusSource) {
                self.reflashSendStatusSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _messageSendStatusQueue);
                dispatch_source_set_timer(_reflashSendStatusSource, dispatch_walltime(NULL, 0), 3 * NSEC_PER_SEC, 0);
                dispatch_source_set_event_handler(_reflashSendStatusSource, ^{
                    if (weakSelf.peerMessages.allKeys.count <= 0) {
                        DDLogInfo(@"send all message success");
                        dispatch_suspend(_reflashSendStatusSource);
                        weakSelf.reflashSendStatusSourceActive = NO;
                    }
                    DDLogInfo(@"unsend messagees :%@", weakSelf.peerMessages);

                    for (MMMessage *message in weakSelf.sendFailMessages) {
                        DDLogInfo(@"message send failed");
                        [self messageSendFail:message];
                        message.sendstatus = GJGCChatFriendSendMessageStatusFaild;
                        [self.peerMessages removeObjectForKey:message.message_id];
                        [self.havedNotifiMessages objectAddObject:message];
                        [GCDQueue executeInQueue:_messageSendStatusQueue block:^{
                            NSError *erro = [NSError errorWithDomain:@"imserver" code:SENDFAIL_OUTTIME userInfo:nil];
                            if (completion) {
                                completion(message, erro);
                            }
                        }];
                    }

                    [weakSelf.sendFailMessages removeObjectsInArray:self.havedNotifiMessages];
                    [weakSelf.havedNotifiMessages removeAllObjects];
                    [weakSelf checkTimeOutMessage];
                });
            }
            if (!self.reflashSendStatusSourceActive) {
                dispatch_resume(self.reflashSendStatusSource);
                self.reflashSendStatusSourceActive = YES;
            }
        }

    }];

}

#pragma mark - Socket layer base send group message

- (MessagePost *)asyncSendGroupMessage:(MMMessage *)message
                      withGroupEckhKey:(NSString *)ecdhKey
                               onQueue:(dispatch_queue_t)sendMessageQueue
                            completion:(void (^)(MMMessage *message,
                                    NSError *error))completion
                               onQueue:(dispatch_queue_t)sendMessageStatusQueue {

    NSString *messageString = [message mj_JSONString];
    if (GJCFStringIsNull(ecdhKey)) {
        ecdhKey = [[GroupDBManager sharedManager] getGroupEcdhKeyByGroupIdentifier:message.publicKey];
        NSAssert(!GJCFStringIsNull(ecdhKey), @"group ecdh key should not be nil");
    }
    GcmData *userToUserData = [ConnectTool createGcmWithData:messageString ecdhKey:[StringTool hexStringToData:ecdhKey] needEmptySalt:NO];
    MessageData *messageData = [[MessageData alloc] init];
    messageData.cipherData = userToUserData;
    messageData.receiverAddress = message.publicKey;
    messageData.msgId = message.message_id;
    messageData.typ = message.type;


    NSString *sign = [ConnectTool signWithData:messageData.data];

    MessagePost *messagePost = [[MessagePost alloc] init];
    messagePost.sign = sign;
    messagePost.pubKey = self.upublickey;
    messagePost.msgData = messageData;
    __weak __typeof(&*self) weakSelf = self;
    [GCDQueue executeInQueue:self.messageSendQueue block:^{
        BOOL result = [weakSelf sendGroupMessage:messagePost];

        NSString *sendTime = [NSString stringWithFormat:@"%lld", (int long long) [[NSDate date] timeIntervalSince1970]];
        SendMessageCallbackModel *callBackBlock = [[SendMessageCallbackModel alloc] init];
        callBackBlock.sendMessageCallbackBlock = completion;
        NSDictionary *temD = @{@"sendTime": sendTime,
                @"message": message,
                @"callBackBlock": callBackBlock};

        [self.peerMessages removeObjectForKey:message.message_id];
        [self.peerMessages setObject:temD forKey:message.message_id];

        if (!result) {
            DDLogInfo(@"send message failed case of net not work");
            [self messageSendFail:message];
            [GCDQueue executeInQueue:self.messageSendStatusQueue block:^{
                message.sendstatus = GJGCChatFriendSendMessageStatusFaild;
                if (completion) {
                    NSError *erro = [NSError errorWithDomain:@"imserver" code:SENDFAIL_NO_NETWORT userInfo:nil];
                    completion(message, erro);
                }
            }];
            [self.peerMessages removeObjectForKey:messagePost.msgData.msgId];
        } else {

            if (!self.reflashSendStatusSource) {
                self.reflashSendStatusSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _messageSendStatusQueue);
                dispatch_source_set_timer(_reflashSendStatusSource, dispatch_walltime(NULL, 0), 3 * NSEC_PER_SEC, 0);
                dispatch_source_set_event_handler(_reflashSendStatusSource, ^{
                    if (weakSelf.peerMessages.allKeys.count <= 0) {
                        dispatch_suspend(_reflashSendStatusSource);
                        weakSelf.reflashSendStatusSourceActive = NO;
                    }
                    for (MMMessage *message in weakSelf.sendFailMessages) {
                        [self messageSendFail:message];
                        message.sendstatus = GJGCChatFriendSendMessageStatusFaild;
                        [self.peerMessages removeObjectForKey:message.message_id];
                        [self.havedNotifiMessages objectAddObject:message];
                        [GCDQueue executeInQueue:_messageSendStatusQueue block:^{
                            NSError *erro = [NSError errorWithDomain:@"imserver" code:SENDFAIL_OUTTIME userInfo:nil];
                            if (completion) {
                                completion(message, erro);
                            }
                        }];
                    }

                    [weakSelf.sendFailMessages removeObjectsInArray:self.havedNotifiMessages];
                    [weakSelf.havedNotifiMessages removeAllObjects];
                    [weakSelf checkTimeOutMessage];
                });
            }
            if (!self.reflashSendStatusSourceActive) {
                dispatch_resume(self.reflashSendStatusSource);
                self.reflashSendStatusSourceActive = YES;
            }
        }
    }];
    return messagePost;

}

#pragma mark - Socket layer foundation to send personal messages

- (MessagePost *)asyncSendMessageMessage:(MMMessage *)message
                                 onQueue:(dispatch_queue_t)sendMessageQueue
                              completion:(void (^)(MMMessage *message,
                                      NSError *error))completion
                                 onQueue:(dispatch_queue_t)sendMessageStatusQueue {

    if (!message) {
        return nil;
    }

    NSString *messageString = [message mj_JSONString];

    GcmData *userToUserData = nil;
    MessageData *messageData = [[MessageData alloc] init];
    messageData.receiverAddress = message.user_id;
    messageData.msgId = message.message_id;
    messageData.typ = message.type;
    ChatCookieData *reciverChatCookie = [[SessionManager sharedManager] getChatCookieWithChatSession:message.publicKey];
    BOOL chatCookieExpire = [[SessionManager sharedManager] chatCookieExpire:message.publicKey];
    if (reciverChatCookie && [SessionManager sharedManager].loginUserChatCookie) {
        messageData.chatPubKey = [SessionManager sharedManager].loginUserChatCookie.chatPubKey;
        messageData.salt = [SessionManager sharedManager].loginUserChatCookie.salt;
        messageData.ver = reciverChatCookie.salt;
        userToUserData = [ConnectTool createPeerIMGcmWithData:messageString chatPubkey:message.publicKey];
        DDLogInfo(@"messageData.salt %@ \n messageData.ver %@  messageData.chatPubKey %@", [StringTool hexStringFromData:messageData.salt],
                [StringTool hexStringFromData:messageData.ver],
                messageData.chatPubKey);
    } else if (!reciverChatCookie
            && [SessionManager sharedManager].loginUserChatCookie
            && chatCookieExpire) {
        messageData.chatPubKey = [SessionManager sharedManager].loginUserChatCookie.chatPubKey;
        messageData.salt = [SessionManager sharedManager].loginUserChatCookie.salt;
        userToUserData = [ConnectTool createHalfRandomPeerIMGcmWithData:messageString chatPubkey:message.publicKey];
    } else {
        userToUserData = [ConnectTool createGcmWithData:messageString publickey:message.publicKey needEmptySalt:YES];
    }
    messageData.cipherData = userToUserData;
    NSString *sign = [ConnectTool signWithData:messageData.data];
    MessagePost *messagePost = [[MessagePost alloc] init];
    messagePost.pubKey = self.upublickey;
    messagePost.msgData = messageData;
    messagePost.sign = sign;

    __weak __typeof(&*self) weakSelf = self;

    [GCDQueue executeInQueue:self.messageSendQueue block:^{
        BOOL result = [weakSelf sendPeerMessage:messagePost];

        NSString *sendTime = [NSString stringWithFormat:@"%lld", (int long long) [[NSDate date] timeIntervalSince1970]];
        SendMessageCallbackModel *callBackBlock = [[SendMessageCallbackModel alloc] init];
        callBackBlock.sendMessageCallbackBlock = completion;
        NSDictionary *temD = @{@"sendTime": sendTime,
                @"message": message,
                @"callBackBlock": callBackBlock};
        [self.peerMessages removeObjectForKey:message.message_id];
        [self.peerMessages setObject:temD forKey:message.message_id];

        if (!result) {
            DDLogInfo(@"send fail maybe net is not word");
            [self messageSendFail:message];
            [GCDQueue executeInQueue:self.messageSendStatusQueue block:^{
                message.sendstatus = GJGCChatFriendSendMessageStatusFaild;
                if (completion) {
                    NSError *erro = [NSError errorWithDomain:@"imserver" code:SENDFAIL_NO_NETWORT userInfo:nil];
                    completion(message, erro);
                }
            }];
            [self.peerMessages removeObjectForKey:messagePost.msgData.msgId];
        } else {

            if (!self.reflashSendStatusSource) {
                self.reflashSendStatusSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _messageSendStatusQueue);
                dispatch_source_set_timer(_reflashSendStatusSource, dispatch_walltime(NULL, 0), 3 * NSEC_PER_SEC, 0);
                dispatch_source_set_event_handler(_reflashSendStatusSource, ^{

                    if (weakSelf.peerMessages.allKeys.count <= 0) {
                        DDLogInfo(@"message send complete");
                        dispatch_suspend(_reflashSendStatusSource);
                        weakSelf.reflashSendStatusSourceActive = NO;
                    }
                    DDLogInfo(@"unsend message %@", weakSelf.peerMessages);
                    for (MMMessage *message in weakSelf.sendFailMessages) {
                        DDLogInfo(@"have message send fall");

                        [self messageSendFail:message];

                        message.sendstatus = GJGCChatFriendSendMessageStatusFaild;

                        ChatMessageInfo *chatMessage = [[MessageDBManager sharedManager] getMessageInfoByMessageid:message.message_id messageOwer:message.publicKey];

                        if (chatMessage.message.sendstatus == GJGCChatFriendSendMessageStatusSuccessUnArrive) {
                            message.sendstatus = GJGCChatFriendSendMessageStatusSuccessUnArrive;
                        }
                        if (chatMessage.message.sendstatus == GJGCChatFriendSendMessageStatusFailByNoRelationShip) {
                            message.sendstatus = GJGCChatFriendSendMessageStatusFailByNoRelationShip;
                        }
                        [self.peerMessages removeObjectForKey:message.message_id];
                        [self.havedNotifiMessages objectAddObject:message];
                        [GCDQueue executeInQueue:_messageSendStatusQueue block:^{
                            NSError *erro = [NSError errorWithDomain:@"imserver" code:SENDFAIL_OUTTIME userInfo:nil];
                            if (completion) {
                                completion(message, erro);
                            }
                        }];
                    }

                    [weakSelf.sendFailMessages removeObjectsInArray:self.havedNotifiMessages];
                    [weakSelf.havedNotifiMessages removeAllObjects];
                    [weakSelf checkTimeOutMessage];
                });
            }
            if (!self.reflashSendStatusSourceActive) {
                dispatch_resume(self.reflashSendStatusSource);
                self.reflashSendStatusSourceActive = YES;
            }
        }
    }];

    return messagePost;
}


#pragma mark - Socket layer based on the receipt of the burn after reading

- (MessagePost *)asyncSendMessageReadAck:(MMMessage *)message
                                 onQueue:(dispatch_queue_t)sendMessageQueue
                              completion:(void (^)(MMMessage *message,
                                      NSError *error))completion
                                 onQueue:(dispatch_queue_t)sendMessageStatusQueue {

    NSString *messageString = [message mj_JSONString];
    GcmData *userToUserData = [ConnectTool createGcmWithData:messageString publickey:message.publicKey needEmptySalt:YES];
    MessageData *messageData = [[MessageData alloc] init];
    messageData.cipherData = userToUserData;
    messageData.receiverAddress = message.user_id;
    messageData.msgId = message.message_id;
    messageData.typ = message.type;

    NSString *sign = [ConnectTool signWithData:messageData.data];
    MessagePost *messagePost = [[MessagePost alloc] init];
    messagePost.pubKey = self.upublickey;
    messagePost.msgData = messageData;
    messagePost.sign = sign;

    __weak __typeof(&*self) weakSelf = self;

    [GCDQueue executeInQueue:self.messageSendQueue block:^{
        BOOL result = [weakSelf sendReadAckMessage:messagePost];

        NSString *sendTime = [NSString stringWithFormat:@"%lld", (int long long) [[NSDate date] timeIntervalSince1970]];
        SendMessageCallbackModel *callBackBlock = [[SendMessageCallbackModel alloc] init];
        callBackBlock.sendMessageCallbackBlock = completion;
        NSDictionary *temD = @{@"sendTime": sendTime,
                @"message": message,
                @"callBackBlock": callBackBlock};

        [self.peerMessages setObject:temD forKey:message.message_id];
        if (!result) {
            DDLogInfo(@"send fail ,maybe net is not work");
            [self messageSendFail:message];
            [GCDQueue executeInQueue:self.messageSendStatusQueue block:^{
                message.sendstatus = GJGCChatFriendSendMessageStatusFaild;
                if (completion) {
                    NSError *erro = [NSError errorWithDomain:@"imserver" code:SENDFAIL_NO_NETWORT userInfo:nil];
                    completion(message, erro);
                }
            }];
            [self.peerMessages removeObjectForKey:messagePost.msgData.msgId];
        } else {

            if (!self.reflashSendStatusSource) {
                self.reflashSendStatusSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.messageSendStatusQueue);
                dispatch_source_set_timer(_reflashSendStatusSource, dispatch_walltime(NULL, 0), 3 * NSEC_PER_SEC, 0);
                dispatch_source_set_event_handler(_reflashSendStatusSource, ^{

                    if (weakSelf.peerMessages.allKeys.count <= 0) {
                        DDLogInfo(@"send message complete");
                        dispatch_suspend(_reflashSendStatusSource);
                        weakSelf.reflashSendStatusSourceActive = NO;
                    }
                    DDLogInfo(@"unsend message%@", weakSelf.peerMessages);
                    for (MMMessage *message in weakSelf.sendFailMessages) {
                        DDLogInfo(@"message send fail");
                        [self messageSendFail:message];
                        message.sendstatus = GJGCChatFriendSendMessageStatusFaild;
                        [self.peerMessages removeObjectForKey:message.message_id];
                        [self.havedNotifiMessages objectAddObject:message];

                        [GCDQueue executeInQueue:_messageSendQueue block:^{
                            NSError *erro = [NSError errorWithDomain:@"imserver" code:SENDFAIL_OUTTIME userInfo:nil];
                            if (completion) {
                                completion(message, erro);
                            }
                        }];
                    }

                    [weakSelf.sendFailMessages removeObjectsInArray:self.havedNotifiMessages];
                    [weakSelf.havedNotifiMessages removeAllObjects];
                    [weakSelf checkTimeOutMessage];
                });
            }
            if (!self.reflashSendStatusSourceActive) {
                dispatch_resume(self.reflashSendStatusSource);
                self.reflashSendStatusSourceActive = YES;
            }
        }
    }];

    return messagePost;

}


#pragma mark - Socket layer based message timeout method

- (dispatch_source_t)reflashSendStatusSource {
    if (!_reflashSendStatusSource) {
        __weak __typeof(&*self) weakSelf = self;
        _reflashSendStatusSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _messageSendStatusQueue);
        dispatch_source_set_timer(_reflashSendStatusSource, dispatch_walltime(NULL, 0), 3 * NSEC_PER_SEC, 0);
        dispatch_source_set_event_handler(_reflashSendStatusSource, ^{
            if (weakSelf.peerMessages.allKeys.count <= 0) {
                dispatch_suspend(_reflashSendStatusSource);
                weakSelf.reflashSendStatusSourceActive = NO;
            }
            for (MMMessage *message in weakSelf.sendFailMessages) {
                [self messageSendFail:message];
                DDLogInfo(@"message send failed");
                message.sendstatus = GJGCChatFriendSendMessageStatusFaild;
                [self.peerMessages removeObjectForKey:message.message_id];
                [self.havedNotifiMessages objectAddObject:message];
                [GCDQueue executeInQueue:_messageSendStatusQueue block:^{
                    NSError *erro = [NSError errorWithDomain:@"imserver" code:SENDFAIL_OUTTIME userInfo:nil];
                    DDLogInfo(@"erro %@", erro);
                }];
            }

            [self.sendFailMessages removeObjectsInArray:self.havedNotifiMessages];
            [self.havedNotifiMessages removeAllObjects];
            [weakSelf checkTimeOutMessage];
        });
        dispatch_resume(_reflashSendStatusSource);
        _reflashSendStatusSourceActive = YES;
    }
    return _reflashSendStatusSource;
}


- (void)checkTimeOutMessage {
    for (NSString *messageid in self.peerMessages.allKeys) {

        NSDictionary *temD = [self.peerMessages valueForKey:messageid];

        int long long sendTime = [[temD valueForKey:@"sendTime"] integerValue];

        int long long currentTime = [[NSDate date] timeIntervalSince1970];

        int long long time = currentTime - sendTime;

        if (time >= kMaxSendOutTime) {
            [self.sendFailMessages objectAddObject:[temD valueForKey:@"message"]];
        }
        DDLogInfo(@"check message send timeout time %lld", time);
    }
}

- (void)messageSendFail:(MMMessage *)message {


}

- (void)messageSendSuccess:(MMMessage *)message {

}

- (void)resendFailMessageWhenConnect {
}

#pragma mark - Socket- connect to server

- (void)onConnect {
    self.connectState = STATE_AUTHING;
    [GCDQueue executeInMainQueue:^{
        [self publishConnectState:self.connectState];
    }];

    if (GJCFStringIsNull(self.uprikey)) {
        [self close];
        return;
    }

    NewConnection *conn = [[NewConnection alloc] init];
    self.sendSalt = [KeyHandle createRandom512bits];
    conn.salt = self.sendSalt;


    self.randomPrivkey = [KeyHandle creatNewPrivkey];
    self.randomPublickey = [KeyHandle createPubkeyByPrikey:self.randomPrivkey];
    conn.pubKey = [StringTool hexStringToData:self.randomPublickey];

    NSData *password = [KeyHandle getECDHkeyWithPrivkey:self.uprikey publicKey:self.serverPublicKey];
    NSData *extensionPass = [KeyHandle getAes256KeyByECDHKeyAndSalt:password salt:[ConnectTool get64ZeroData]];
    IMRequest *request = [ConnectTool createRequestWithEcdhKey:extensionPass data:conn.data aad:[ServerCenter shareCenter].defineAad];
    Message *m = [[Message alloc] init];
    m.typechar = BM_HANDSHAKE_TYPE;
    m.extension = BM_HANDSHAKE_EXT;
    m.len = (int) [request data].length;
    m.body = [request data];
    [self sendMessage:m];
}

#pragma mark - quit user

- (void)quitUser {
    [super quitUser];
    [[CommandOutTimeTool sharedManager] revert];
    self.uprikey = nil;
    self.uaddress = nil;
    self.upublickey = nil;
    self.deviceToken = nil;
    self.extensionPass = nil;
    self.RegisterDeviceTokenComplete = nil;
}

#pragma mark - Close server connection

- (void)connecting {
    [[CommandOutTimeTool sharedManager] suspend];
}

- (void)onClose {
    [[CommandOutTimeTool sharedManager] suspend];

    [ServerCenter shareCenter].extensionPass = nil;

    self.connectState = STATE_UNCONNECTED;
    [GCDQueue executeInMainQueue:^{
        [self publishConnectState:self.connectState];
    }];

    self.HeartBeatBlock = nil;
    for (NSNumber *seq in self.peerMessages) {
        MessagePost *msg = [self.peerMessages objectForKey:seq];
        [self.peerMessageHandler handleMessageFailure:msg];
    }
    for (NSNumber *seq in self.groupMessages) {
        MessagePost *msg = [self.peerMessages objectForKey:seq];
        DDLogInfo(@"msg %@", msg.msgData.msgId);
    }
    [self.peerMessages removeAllObjects];
    [self.groupMessages removeAllObjects];
}

#pragma mark - privite method

- (NSString *)getGroupFromBackup:(NSString *)backup {
    NSArray *temA = [backup componentsSeparatedByString:@"/"];
    NSString *ecdh = @"";
    if (temA.count == 2) {
        NSString *pub = [temA objectAtIndexCheck:0];
        NSString *hex = [temA objectAtIndexCheck:1];
        NSData *data = [StringTool hexStringToData:hex];
        NSError *error = nil;
        GcmData *gcmData = [GcmData parseFromData:data error:&error];
        if (!error) {
            NSData *data = [ConnectTool decodeGcmDataWithGcmData:gcmData publickey:pub];
            CreateGroupMessage *backUpData = [CreateGroupMessage parseFromData:data error:&error];
            ecdh = backUpData.secretKey;
            if (!error) {
                [SetGlobalHandler uploadGroupEcdhKey:backUpData.secretKey groupIdentifier:backUpData.identifier];
            } else {
            }
        }
    }

    return ecdh;
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

@end
