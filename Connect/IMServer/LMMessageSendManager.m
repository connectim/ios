//
//  LMMessageSendManager.m
//  Connect
//
//  Created by MoHuilin on 2017/5/16.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMMessageSendManager.h"
#import "MessageDBManager.h"
#import "UserDBManager.h"
#import "IMService.h"
#import "ConnectTool.h"



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
typedef NS_ENUM(NSInteger ,MessageRejectErrorType) {
    MessageRejectErrorTypeUnknow = 0,
    MessageRejectErrorTypeNotExisted,
    MessageRejectErrorTypeNotFriend,
    MessageRejectErrorTypeBlackList,
    MessageRejectErrorTypeNotInGroup,
    MessageRejectErrorTypeChatinfoEmpty,
    MessageRejectErrorTypeGetChatinfoError,
    MessageRejectErrorTypeChatinfoNotMatch,
    MessageRejectErrorTypeChatinfoExpire,
    MessageRejectErrorTypeMyChatCookieNotMatch,
};

@implementation SendMessageModel

@end


@interface LMMessageSendManager ()

@property(nonatomic, strong) dispatch_queue_t messageSendStatusQueue;
@property(nonatomic, strong) NSMutableDictionary *sendingMessages;


//check message outtime
@property(nonatomic, strong) dispatch_source_t reflashSendStatusSource;
@property(nonatomic, assign) BOOL reflashSendStatusSourceActive;

@end

@implementation LMMessageSendManager

- (instancetype)init {
    if (self = [super init]) {
        _sendingMessages = [NSMutableDictionary dictionary];

        _messageSendStatusQueue = dispatch_queue_create("_imserver_message_sendstatus_queue", DISPATCH_QUEUE_SERIAL);

        //relash source
        __weak __typeof(&*self) weakSelf = self;
        _reflashSendStatusSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _messageSendStatusQueue);
        dispatch_source_set_timer(_reflashSendStatusSource, dispatch_walltime(NULL, 0), 3 * NSEC_PER_SEC, 0);
        dispatch_source_set_event_handler(_reflashSendStatusSource, ^{
            if (weakSelf.sendingMessages.allKeys.count <= 0) {
                dispatch_suspend(_reflashSendStatusSource);
                weakSelf.reflashSendStatusSourceActive = NO;
            }
            NSArray *sendMessageModels = weakSelf.sendingMessages.allValues.copy;
            for (SendMessageModel *sendMessageModel in sendMessageModels) {
                int long long currentTime = [[NSDate date] timeIntervalSince1970];
                int long long sendDuration = currentTime - sendMessageModel.sendTime;
                if (sendDuration >= SOCKET_TIME_OUT) {
                    //update message send status
                    sendMessageModel.sendMsg.sendstatus = GJGCChatFriendSendMessageStatusFaild;

                    if (sendMessageModel.callBack) {
                        sendMessageModel.callBack(sendMessageModel.sendMsg, [NSError errorWithDomain:@"over_time" code:OVER_TIME_CODE userInfo:nil]);
                    }

                    
                    [weakSelf.sendingMessages removeObjectForKey:sendMessageModel.sendMsg.message_id];
                }
            }
        });
        dispatch_resume(_reflashSendStatusSource);
        _reflashSendStatusSourceActive = YES;
    }
    return self;
}

CREATE_SHARED_MANAGER(LMMessageSendManager)


- (void)addSendingMessage:(MMMessage *)message callBack:(SendMessageCallBlock)callBack {
    SendMessageModel *sendMessageModel = [SendMessageModel new];
    sendMessageModel.sendMsg = message;
    sendMessageModel.sendTime = [[NSDate date] timeIntervalSince1970];
    sendMessageModel.callBack = callBack;

    //save to send queue
    [self.sendingMessages setValue:sendMessageModel forKey:message.message_id];

    //open reflash
    if (!self.reflashSendStatusSourceActive) {
        dispatch_resume(self.reflashSendStatusSource);
        self.reflashSendStatusSourceActive = YES;
    }
}


- (void)messageSendSuccessMessageId:(NSString *)messageId {
    if (GJCFStringIsNull(messageId)) {
        return;
    }
    [GCDQueue executeInQueue:self.messageSendStatusQueue block:^{

        SendMessageModel *sendModel = [self.sendingMessages valueForKey:messageId];
        NSString *messageOwer = sendModel.sendMsg.publicKey;

        GJGCChatFriendSendMessageStatus sendStatus = [[MessageDBManager sharedManager] getMessageSendStatusByMessageid:messageId messageOwer:messageOwer];
        if (sendStatus == GJGCChatFriendSendMessageStatusSuccessUnArrive ||
                sendStatus == GJGCChatFriendSendMessageStatusFailByNotInGroup) {
            //blocked
        } else if (sendStatus == GJGCChatFriendSendMessageStatusFailByNoRelationShip && ![[UserDBManager sharedManager] isFriendByAddress:[KeyHandle getAddressByPubkey:messageOwer]]) {
            //no relationship
        } else {
            //update status
            [[MessageDBManager sharedManager] updateMessageSendStatus:GJGCChatFriendSendMessageStatusSuccess withMessageId:messageId messageOwer:messageOwer];
            sendModel.sendMsg.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
            if (sendModel.callBack) {
                sendModel.callBack(sendModel.sendMsg, nil);
            }
            //updatea recent chat cell status
            [GCDQueue executeInMainQueue:^{
                SendNotify(ConnnectSendMessageSuccessNotification, messageOwer);
            }];
        }

        [self.sendingMessages removeObjectForKey:messageId];
    }];
}

- (void)messageSendFailedMessageId:(NSString *)messageId {
    [GCDQueue executeInQueue:self.messageSendStatusQueue block:^{
        SendMessageModel *sendModel = [self.sendingMessages valueForKey:messageId];
        sendModel.sendMsg.sendstatus = GJGCChatFriendSendMessageStatusFaild;
        if (sendModel.callBack) {
            NSError *error = [NSError errorWithDomain:@"imserver" code:-1 userInfo:nil];
            sendModel.callBack(sendModel.sendMsg, error);
        }

        //remove
        [self.sendingMessages removeObjectForKey:messageId];
    }];
}

- (void)messageRejectedMessage:(RejectMessage *)rejectMsg {
    [GCDQueue executeInQueue:self.messageSendStatusQueue block:^{
        SendMessageModel *sendModel = [self.sendingMessages valueForKey:rejectMsg.msgId];

        MessageRejectErrorType rejectErrorType = (NSInteger)rejectMsg.status;
        switch (rejectErrorType) {
            case MessageRejectErrorTypeMyChatCookieNotMatch:{
                [[IMService instance] uploadCookieDuetoLocalChatCookieNotMatchServerChatCookieWithMessageCallModel:sendModel];
            }
                break;
            case MessageRejectErrorTypeChatinfoExpire:{
                NSString *identifier = [[UserDBManager sharedManager] getUserPubkeyByAddress:rejectMsg.receiverAddress];
                [[SessionManager sharedManager] removeChatCookieWithChatSession:identifier];
                [[SessionManager sharedManager] chatCookie:YES chatSession:identifier];
                [[IMService instance] asyncSendMessageMessage:sendModel.sendMsg onQueue:nil completion:sendModel.callBack onQueue:nil];
            }
                break;
            case MessageRejectErrorTypeChatinfoNotMatch:{
                ChatCookie *chatCookie = [ChatCookie parseFromData:rejectMsg.data_p error:nil];
                NSString *identifier = [[UserDBManager sharedManager] getUserPubkeyByAddress:rejectMsg.receiverAddress];
                if ([ConnectTool vertifyWithData:chatCookie.data_p.data sign:chatCookie.sign publickey:identifier]) {
                    ChatCookieData *chatInfo = chatCookie.data_p;
                    [[SessionManager sharedManager] setChatCookie:chatInfo chatSession:identifier];
                    [[IMService instance] asyncSendMessageMessage:sendModel.sendMsg onQueue:nil completion:sendModel.callBack onQueue:nil];
                } else{
                    if (sendModel.callBack) {
                        sendModel.sendMsg.sendstatus = GJGCChatFriendSendMessageStatusFaild;
                        NSError *error = [NSError errorWithDomain:@"imserver" code:-1 userInfo:nil];
                        sendModel.callBack(sendModel.sendMsg, error);
                    }
                }
            }
                break;
            case MessageRejectErrorTypeNotInGroup:{
                NSString *identifier = rejectMsg.receiverAddress;
                if (!GJCFStringIsNull(identifier)) {
                    //updata message sendstatus
                    [[MessageDBManager sharedManager] updateMessageSendStatus:GJGCChatFriendSendMessageStatusFailByNotInGroup withMessageId:rejectMsg.msgId messageOwer:identifier];
                    sendModel.sendMsg.sendstatus = GJGCChatFriendSendMessageStatusFailByNotInGroup;
                    //create tip message
                    [[MessageDBManager sharedManager] createTipMessageWithMessageOwer:identifier isnoRelationShipType:NO content:LMLocalizedString(@"Message send fail not in group", nil)];
                    if (sendModel.callBack) {
                        sendModel.callBack(sendModel.sendMsg, nil);
                    }
                }
            }
                break;
            case MessageRejectErrorTypeNotFriend:{
                NSString *identifier = [[UserDBManager sharedManager] getUserPubkeyByAddress:rejectMsg.receiverAddress];
                if (!GJCFStringIsNull(identifier)) {
                    [[MessageDBManager sharedManager] updateMessageSendStatus:GJGCChatFriendSendMessageStatusFailByNoRelationShip withMessageId:rejectMsg.msgId messageOwer:identifier];
                    
                    sendModel.sendMsg.sendstatus = GJGCChatFriendSendMessageStatusFailByNoRelationShip;
                    
                    //create tip message
                    [[MessageDBManager sharedManager] createTipMessageWithMessageOwer:identifier isnoRelationShipType:YES content:nil];
                    if (sendModel.callBack) {
                        sendModel.callBack(sendModel.sendMsg, nil);
                    }
                }
            }
                break;
                
            case MessageRejectErrorTypeBlackList:{
                
                NSString *identifier = [[UserDBManager sharedManager] getUserPubkeyByAddress:rejectMsg.receiverAddress];
                if (!GJCFStringIsNull(identifier)) {
                    [[MessageDBManager sharedManager] updateMessageSendStatus:GJGCChatFriendSendMessageStatusSuccessUnArrive withMessageId:rejectMsg.msgId messageOwer:identifier];
                    
                    sendModel.sendMsg.sendstatus = GJGCChatFriendSendMessageStatusSuccessUnArrive;
                    //create tip message
                    [[MessageDBManager sharedManager] createTipMessageWithMessageOwer:identifier isnoRelationShipType:NO content:LMLocalizedString(@"Link Message has been sent the other rejected", nil)];
                    if (sendModel.callBack) {
                        sendModel.callBack(sendModel.sendMsg, nil);
                    }
                }
            }
                break;
            default:
                break;
        }
        //remove send queue message
        [self.sendingMessages removeObjectForKey:rejectMsg.msgId];
    }];
}


@end
