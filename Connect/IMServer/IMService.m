/*
  Copyright (c) 2016-2016, Connect
    All rights reserved.
*/
#import "IMService.h"
#import "MessageDBManager.h"
#import "UserDBManager.h"
#import "StringTool.h"
#import "ConnectTool.h"
#import "PeerMessageHandler.h"
#import "GroupMessageHandler.h"
#import "AppDelegate.h"
#import "SystemMessageHandler.h"
#import "SystemTool.h"
#import "LMHistoryCacheManager.h"
#import "LMUUID.h"
#import "LMCommandAdapter.h"
#import "LMMessageAdapter.h"
#import "LMMessageSendManager.h"

@implementation UploadChatCookieModel

@end

@interface IMService ()

@property(nonatomic, strong) dispatch_queue_t commondQueue;
@property(nonatomic, strong) dispatch_queue_t delaySendCommondQueue;
@property(nonatomic, assign) BOOL delaySendIsSuspend;
@property(nonatomic, strong) dispatch_queue_t messageSendQueue;
@property(nonatomic, assign) BOOL messageSendIsSuspend;
@property(nonatomic, copy) BOOL (^HeartBeatBlock)();
//frist connect
@property(nonatomic, strong) NSData *sendSalt;
@property(nonatomic, copy) NSString *randomPrivkey;
@property(nonatomic, copy) NSString *randomPublickey;

@end

@implementation IMService

- (dispatch_queue_t)messageSendQueue {

    if (!_messageSendQueue) {
        _messageSendQueue = dispatch_queue_create("_imserver_message_sender_queue", DISPATCH_QUEUE_SERIAL);
    }
    return _messageSendQueue;
}

- (dispatch_queue_t)commondQueue{
    if (!_commondQueue) {
        _commondQueue = dispatch_queue_create("_commond_send_handle_queue", DISPATCH_QUEUE_CONCURRENT);
    }
    return _commondQueue;
}

- (dispatch_queue_t)delaySendCommondQueue{
    if (!_delaySendCommondQueue) {
        _delaySendCommondQueue = dispatch_queue_create("delaysendqueue", DISPATCH_QUEUE_CONCURRENT);
    }
    return _delaySendCommondQueue;
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


#pragma mark - ACK
- (void)handleACK:(Message *)msg {
    Ack *ack = [Ack parseFromData:msg.body error:nil];
    //send success
    [[LMMessageSendManager sharedManager] messageSendSuccessMessageId:ack.msgId];
}

- (void)sendOfflineAck:(NSString *)messageid type:(int)type {

    Ack *ack = [[Ack alloc] init];
    ack.msgId = messageid;
    ack.type = type;
    IMTransferData *request = [ConnectTool createTransferWithEcdhKey:[ServerCenter shareCenter].extensionPass data:ack.data aad:nil];

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
    if (isSign) {
        [[PeerMessageHandler instance] handleMessage:post];
    }
    [self sendIMBackAck:post.msgData.msgId];
}

#pragma mark -Message-group

- (void)handleInviteGroupMessage:(Message *)msg {
    MessagePost *post = (MessagePost *) msg.body;
    BOOL isSign = [ConnectTool vertifyWithData:post.msgData.data sign:post.sign publickey:post.pubKey];
    if (isSign) {
        [[GroupMessageHandler instance] handleGroupInviteMessage:post];
    }
    //send ack
    [self sendIMBackAck:post.msgData.msgId];
}

- (void)handleGroupIMMessage:(Message *)msg {
    MessagePost *post = (MessagePost *) msg.body;
    BOOL isSign = [ConnectTool vertifyWithData:post.msgData.data sign:post.sign publickey:post.pubKey];
    if (isSign) {
        [[GroupMessageHandler instance] handleMessage:post];
    }
    [self sendIMBackAck:post.msgData.msgId];
}


#pragma mark -Message-rejected

- (void)handleBlackUnArrive:(Message *)msg {
    [[LMMessageSendManager sharedManager] messageRejectedMessage:msg.body];
}

#pragma mark -Message-sys temmessage

- (void)handleSystemMessage:(Message *)msg {
    MSMessage *sysMsg = msg.body;
    [[SystemMessageHandler instance] handleMessage:sysMsg];
    //send ack
    [self sendIMBackAck:sysMsg.msgId];
}


#pragma mark -Message-IMAck

- (void)sendIMBackAck:(NSString *)msgID {
    [self sendOnlineBackAck:msgID type:0];
}

- (void)sendOnlineBackAck:(NSString *)msgID type:(int)type {

    Ack *ack = [[Ack alloc] init];
    ack.msgId = msgID;
    ack.type = type;

    IMTransferData *request = [ConnectTool createTransferWithEcdhKey:[ServerCenter shareCenter].extensionPass data:ack.data aad:nil];

    Message *ackMsg = [[Message alloc] init];
    ackMsg.typechar = BM_ACK_TYPE;
    ackMsg.extension = BM_ACK_BACK_EXT;
    ackMsg.body = [request data];
    ackMsg.len = (int) [request data].length;

    [self sendMessage:ackMsg];

}

#pragma mark - Socket-handshake

- (void)handleAuthStatus:(Message *)msg {
    IMResponse *response = (IMResponse *) msg.body;
    GcmData *gcmData = response.cipherData;
    NSData *password = [KeyHandle getECDHkeyWithPrivkey:[LKUserCenter shareCenter].currentLoginUser.prikey publicKey:[[ServerCenter shareCenter] getCurrentServer].data.pub_key];
    password = [KeyHandle getAes256KeyByECDHKeyAndSalt:password salt:[ConnectTool get64ZeroData]];
    NSData *handAckData = [ConnectTool decodeGcmDataWithEcdhKey:password GcmData:gcmData];
    if (!handAckData || handAckData.length <= 0) {
        return;
    }
    NewConnection *conn = [NewConnection parseFromData:handAckData error:nil];

    NSData *saltData = [StringTool DataXOR1:self.sendSalt DataXOR2:conn.salt];

    NSData *passwordTem = [KeyHandle getECDHkeyWithPrivkey:self.randomPrivkey publicKey:[StringTool hexStringFromData:conn.pubKey]];
    NSData *extensionPass = [KeyHandle getAes256KeyByECDHKeyAndSalt:passwordTem salt:saltData];
    [ServerCenter shareCenter].extensionPass = extensionPass;

    //upload device info
    NSUUID *uuid = [[UIDevice currentDevice] identifierForVendor];
    DeviceInfo *deviceId = [[DeviceInfo alloc] init];
    deviceId.deviceId = uuid.UUIDString;
    deviceId.deviceName = [UIDevice currentDevice].name;
    deviceId.locale = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
    deviceId.uuid = [LMUUID uuid];
    // channel
    if ([SystemTool isNationChannel]) {
        deviceId.cv = 1;
    }
    ChatCookieData *cacheData = [[LMHistoryCacheManager sharedManager] getLeastChatCookie];
    deviceId.chatCookieData = cacheData;
    IMTransferData *request = [ConnectTool createTransferWithEcdhKey:extensionPass data:deviceId.data aad:[ServerCenter shareCenter].defineAad];
    Message *m = [[Message alloc] init];
    m.typechar = BM_HANDSHAKE_TYPE;
    m.extension = BM_HANDSHAKEACK_EXT;
    m.len = (int) request.data.length;
    m.body = request.data;
    [self sendMessage:m];

    //upload version
    [self uploadAppInfoWhenVersionChange];

    //init loginUserChatCookie
    if (![SessionManager sharedManager].loginUserChatCookie && cacheData) {
        [SessionManager sharedManager].loginUserChatCookie = [[LMHistoryCacheManager sharedManager] getChatCookieWithSaltVer:cacheData.salt];
    }
}

- (void)authSussecc:(Message *)msg {
    //send unsend message
    if (self.messageSendIsSuspend) {
        dispatch_resume(self.messageSendQueue);
        self.messageSendIsSuspend = NO;
    }
    self.connectState = STATE_CONNECTED;
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
    if (self.HeartBeatBlock)
        return self.HeartBeatBlock();
    return NO;
}


#pragma mark - Command-offline messages

- (void)getOffLineMessages {
    [self publishConnectState:STATE_GETOFFLINE];
    
    Message *msg = [LMCommandAdapter sendAdapterWithExtension:BM_GETOFFLINE_EXT sendData:nil];
    [self sendCommandWithDelay:NO callBlock:^(IMService *imserverSelf) {
        [imserverSelf sendCommandWith:msg comlete:nil];
    }];
}


#pragma mark - Command-upload login user chat cookie

- (void)uploadCookieDuetoLocalChatCookieNotMatchServerChatCookieWithMessageCallModel:(SendMessageModel *)callModel {
    
    ChatCacheCookie *chatCookie = [ChatCacheCookie new];
    ChatCookieData *cookieData = [ChatCookieData new];
    chatCookie.chatPrivkey = [KeyHandle creatNewPrivkey];
    chatCookie.chatPubKey = [KeyHandle createPubkeyByPrikey:chatCookie.chatPrivkey];
    chatCookie.salt = [KeyHandle createRandom512bits];
    cookieData.expired = [[NSDate date] timeIntervalSince1970] + 24 * 60 * 60;
    
    cookieData.chatPubKey = chatCookie.chatPubKey;
    cookieData.salt = chatCookie.salt;
    
    ChatCookie *cookie = [ChatCookie new];
    cookie.data_p = cookieData;
    cookie.sign = [ConnectTool signWithData:cookieData.data];
    
    Message *m = [LMCommandAdapter sendAdapterWithExtension:BM_UPLOAD_CHAT_COOKIE_EXT sendData:cookie];
    
    UploadChatCookieModel *uploadChatModel = [UploadChatCookieModel new];
    uploadChatModel.chatCookie = chatCookie;
    uploadChatModel.chatCookieData = cookieData;
    uploadChatModel.sendMessageModel = callModel;
    m.sendOriginInfo = uploadChatModel;
    [self sendCommandWithDelay:NO callBlock:^(IMService *imserverSelf) {
        [imserverSelf sendCommandWith:m comlete:nil];
    }];
}



#pragma mark - Command-Get the latest Cookie for the session user

- (void)getUserCookieWihtChatUser:(AccountInfo *)chatUser complete:(SendCommandCallback)complete {
    if (GJCFStringIsNull(chatUser.address)) {
        complete = nil;
        return;
    }
    
    FriendChatCookie *chatInfoAddress = [FriendChatCookie new];
    chatInfoAddress.address = chatUser.address;
    
    Message *m = [LMCommandAdapter sendAdapterWithExtension:BM_FRIEND_CHAT_COOKIE_EXT sendData:chatInfoAddress];
    m.sendOriginInfo = chatUser;
    [self sendCommandWithDelay:YES callBlock:^(IMService *imserverSelf) {
        [imserverSelf sendCommandWith:m comlete:complete];
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
        
        Message *m = [LMCommandAdapter sendAdapterWithExtension:BM_UPLOAD_APPINFO_EXT sendData:appInfo];
        [self sendCommandWithDelay:YES callBlock:^(IMService *imserverSelf) {
            [imserverSelf sendCommandWith:m comlete:nil];
        }];
    }
}

#pragma mark - Command-create session

- (void)addNewSessionWithAddress:(NSString *)address complete:(SendCommandCallback)complete {
    
    ManageSession *session = [[ManageSession alloc] init];
    session.address = address;
    
    Message *m = [LMCommandAdapter sendAdapterWithExtension:BM_CREATE_SESSION sendData:session];
    [self sendCommandWithDelay:YES callBlock:^(IMService *imserverSelf) {
        [imserverSelf sendCommandWith:m comlete:complete];
    }];
}


- (void)reciveMoneyWihtToken:(NSString *)token complete:(SendCommandCallback)complete {
    
    ExternalBillingToken *billingToken = [[ExternalBillingToken alloc] init];
    billingToken.token = token;
    
    Message *m = [LMCommandAdapter sendAdapterWithExtension:BM_OUTER_TRANSFER_EXT sendData:billingToken];
    [self sendCommandWithDelay:YES callBlock:^(IMService *imserverSelf) {
        [imserverSelf sendCommandWith:m comlete:complete];
    }];
}

#pragma mark - Command-not interet someone

- (void)setRecommandUserNoInterestAdress:(NSString *)address
                                 comlete:(SendCommandCallback)complete {
    
    NOInterest *notInterest = [[NOInterest alloc] init];
    notInterest.address = address;

    Message *m = [LMCommandAdapter sendAdapterWithExtension:BM_RECOMMADN_NOTINTEREST_EXT sendData:notInterest];
    m.sendOriginInfo = address;
    [self sendCommandWithDelay:YES callBlock:^(IMService *imserverSelf) {
        [imserverSelf sendCommandWith:m comlete:complete];
    }];

}

- (void)openRedPacketWihtToken:(NSString *)token complete:(SendCommandCallback)complete {

    RedPackageToken *luckyToken = [[RedPackageToken alloc] init];
    luckyToken.token = token;
    
    Message *m = [LMCommandAdapter sendAdapterWithExtension:BM_OUTER_REDPACKET_EXT sendData:luckyToken];
    [self sendCommandWithDelay:YES callBlock:^(IMService *imserverSelf) {
        [imserverSelf sendCommandWith:m comlete:complete];
    }];
}

#pragma mark - Command-update session

- (void)openOrCloseSesionMuteWithAddress:(NSString *)address mute:(BOOL)mute complete:(SendCommandCallback)complete {

    UpdateSession *updateSession = [[UpdateSession alloc] init];
    updateSession.address = address;
    updateSession.flag = mute;
    
    Message *m = [LMCommandAdapter sendAdapterWithExtension:BM_SETMUTE_SESSION sendData:updateSession];
    [self sendCommandWithDelay:YES callBlock:^(IMService *imserverSelf) {
        [imserverSelf sendCommandWith:m comlete:complete];
    }];
}

#pragma mark - Command-delete session

- (void)deleteSessionWithAddress:(NSString *)address complete:(SendCommandCallback)complete {
    
    ManageSession *manageSession = [[ManageSession alloc] init];
    manageSession.address = address;
    
    Message *m = [LMCommandAdapter sendAdapterWithExtension:BM_DELETE_SESSION sendData:manageSession];
    [self sendCommandWithDelay:YES callBlock:^(IMService *imserverSelf) {
        [imserverSelf sendCommandWith:m comlete:complete];
    }];
}

#pragma mark - Command-add new friend

- (void)addNewFiendWithInviteUser:(AccountInfo *)inviteUser tips:(NSString *)tips source:(int)source comlete:(SendCommandCallback)complete {
    if (GJCFStringIsNull(tips)) {
        tips = LMLocalizedString(@"Link Hello", nil);
    }
    tips = [StringTool filterStr:tips];
    inviteUser.message = tips;
    inviteUser.source = source;
    inviteUser.status = RequestFriendStatusVerfing;
    AddFriendRequest *addReuqest = [[AddFriendRequest alloc] init];
    
    //encrypt tips
    GcmData *tipGcmData = [ConnectTool createGcmWithData:tips publickey:inviteUser.pub_key];
    addReuqest.address = inviteUser.address;
    addReuqest.tips = tipGcmData;
    addReuqest.source = source;

    Message *m = [LMCommandAdapter sendAdapterWithExtension:BM_NEWFRIEND_EXT sendData:addReuqest];
    m.sendOriginInfo = inviteUser.address;
    [self sendCommandWithDelay:YES callBlock:^(IMService *imserverSelf) {
        [imserverSelf sendCommandWith:m comlete:complete];
    }];

    //save request user
    [[UserDBManager sharedManager] saveNewFriend:inviteUser];
}

#pragma mark - Command-get contacts

- (void)getFriendsWithVersion:(NSString *)version comlete:(SendCommandCallback)complete {

    if ([version isEqualToString:@""]) { //login on new device
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showMessage:LMLocalizedString(@"数据同步中...", nil) toView:[UIApplication sharedApplication].keyWindow.rootViewController.view];
        }];
        version = @"0";
    }

    SyncRelationship *relation = [[SyncRelationship alloc] init];
    relation.version = version;

    Message *m = [LMCommandAdapter sendAdapterWithExtension:BM_FRIENDLIST_EXT sendData:relation];
    [self sendCommandWithDelay:YES callBlock:^(IMService *imserverSelf) {
        [imserverSelf sendCommandWith:m comlete:complete];
    }];
}

#pragma mark - Command-sync contacts

- (void)syncFriendsWithComlete:(SendCommandCallback)complete {

    SyncRelationship *relation = [[SyncRelationship alloc] init];
    relation.version = @"0";
    
    //sync contact
    Message *m = [LMCommandAdapter sendAdapterWithExtension:BM_FRIENDLIST_EXT sendData:relation];
    m.sendOriginInfo = @"syncfriend";
    [self sendCommandWithDelay:YES callBlock:^(IMService *imserverSelf) {
        [imserverSelf sendCommandWith:m comlete:complete];
    }];
}

#pragma mark - Command-accept friend request

- (void)acceptAddRequestWithAddress:(NSString *)address source:(int)source comlete:(SendCommandCallback)complete {

    AcceptFriendRequest *acceptRequest = [[AcceptFriendRequest alloc] init];
    acceptRequest.address = address;
    acceptRequest.source = source;
    
    Message *m = [LMCommandAdapter sendAdapterWithExtension:BM_ACCEPT_NEWFRIEND_EXT sendData:acceptRequest];
    m.sendOriginInfo = address;
    [self sendCommandWithDelay:YES callBlock:^(IMService *imserverSelf) {
        [imserverSelf sendCommandWith:m comlete:complete];
    }];
}

#pragma mark - Comand-delete contact

- (void)deleteFriendWithAddress:(NSString *)address comlete:(SendCommandCallback)complete {

    RemoveRelationship *removeFriend = [[RemoveRelationship alloc] init];
    removeFriend.address = address;

    Message *m = [LMCommandAdapter sendAdapterWithExtension:BM_DELETE_FRIEND_EXT sendData:removeFriend];
    m.sendOriginInfo = address;
    [self sendCommandWithDelay:YES callBlock:^(IMService *imserverSelf) {
        [imserverSelf sendCommandWith:m comlete:complete];
    }];
}

#pragma mark - Command-set user info

- (void)setFriendInfoWithAddress:(NSString *)address remark:(NSString *)remark commonContact:(BOOL)commonContact comlete:(SendCommandCallback)complete {
    SettingFriendInfo *setFriend = [[SettingFriendInfo alloc] init];
    setFriend.address = address;
    setFriend.common = commonContact;
    setFriend.remark = remark;

    Message *m = [LMCommandAdapter sendAdapterWithExtension:BM_SET_FRIENDINFO_EXT sendData:setFriend];
    [self sendCommandWithDelay:YES callBlock:^(IMService *imserverSelf) {
        [imserverSelf sendCommandWith:m comlete:complete];
    }];
}

#pragma mark - Command-sync badge number

- (void)syncBadgeNumber:(NSInteger)badgeNumber {
    if (badgeNumber < 0) {
        return;
    }
    SyncBadge *badge = [[SyncBadge alloc] init];
    badge.badge = (int) badgeNumber;
    
    Message *m = [LMCommandAdapter sendAdapterWithExtension:BM_SYNCBADGENUMBER_EXT sendData:badge];
    m.sendOriginInfo = @(badgeNumber);
    [self sendCommandWithDelay:NO callBlock:^(IMService *imserverSelf) {
        [imserverSelf sendCommandWith:m comlete:nil];
    }];
}


#pragma mark - Command-send command base method

- (void)sendCommandWith:(Message *)msg comlete:(SendCommandCallback)complete {
    BOOL result = [self sendMessage:msg];
    [[LMCommandManager sharedManager] addSendingMessage:msg callBack:complete];
    if (!result) {
        [[LMCommandManager sharedManager] sendCommandFailedWithMsgId:msg.msgIdentifer];
    }
}

#pragma mark - Command-send command

- (void)sendCommandWithDelay:(BOOL)delay callBlock:(void (^)(IMService *imserverSelf))callBlock {
    if (delay) {
        if (self.connectState == STATE_CONNECTED || self.connectState == STATE_GETOFFLINE) {
            if (callBlock) {
                callBlock(self);
            }
        } else {
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
    } else{
        [GCDQueue executeInQueue:self.commondQueue block:^{
            if (callBlock) {
                callBlock(self);
            }
        }];
    }
}

#pragma mark - Command-bind device token

- (void)bindDeviceTokenWithDeviceToken:(NSString *)deviceToken {
    DeviceToken *deviceT = [[DeviceToken alloc] init];
    deviceT.apnsDeviceToken = deviceToken;
    deviceT.pushType = @"APNS";
    Message *m = [LMCommandAdapter sendAdapterWithExtension:BM_BINDDEVICETOKEN_EXT sendData:deviceT];
    m.sendOriginInfo = deviceToken;
    [self sendCommandWithDelay:YES callBlock:^(IMService *imserverSelf) {
        [imserverSelf sendCommandWith:m comlete:nil];
    }];
}

#pragma mark - Command-unbind device token

- (void)unBindDeviceTokenWithDeviceToken:(NSString *)deviceToken complete:(SendCommandCallback)complete {
    
    DeviceToken *deviceT = [[DeviceToken alloc] init];
    deviceT.apnsDeviceToken = deviceToken;
    deviceT.pushType = @"APNS";
    
    Message *m = [LMCommandAdapter sendAdapterWithExtension:BM_UNBINDDEVICETOKEN_EXT sendData:deviceT];
    m.sendOriginInfo = deviceToken;
    [self sendCommandWithDelay:NO callBlock:^(IMService *imserverSelf) {
        [imserverSelf sendCommandWith:m comlete:complete];
    }];
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
        case BM_IM_MESSAGE_ACK_EXT:
        case BM_IM_EXT: {
            [self handleIMMessage:msg];
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
            [[LMCommandManager sharedManager] transactionStatusChangeNoti:msg];
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
            [[LMCommandManager sharedManager] sendCommandSuccessWithCallbackMsg:msg];
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

- (BOOL)sendDataWithMessage:(MessagePost *)im extension:(unsigned char)extension{
    IMTransferData *imTransfer = [ConnectTool createTransferWithEcdhKey:[ServerCenter shareCenter].extensionPass data:im.data aad:nil];
    Message *m = [[Message alloc] init];
    m.typechar = BM_IM_TYPE;
    m.extension = extension;
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

- (BOOL)sendPeerMessage:(MessagePost *)im {
    return [self sendDataWithMessage:im extension:BM_IM_EXT];
}

- (BOOL)sendReadAckMessage:(MessagePost *)im {
    return [self sendDataWithMessage:im extension:BM_IM_MESSAGE_ACK_EXT];
}


- (BOOL)sendGroupMessage:(MessagePost *)im {
    return [self sendDataWithMessage:im extension:BM_IM_GROUPMESSAGE_EXT];
}

- (BOOL)asyncSendGroupInfo:(MessagePost *)im {
    return [self sendDataWithMessage:im extension:BM_IM_SEND_GROUPINFO_EXT];
}

- (BOOL)sendMessage:(Message *)msg {
    if (self.connectState == STATE_CONNECTED || self.connectState == STATE_AUTHING || self.connectState == STATE_GETOFFLINE) {
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

    IMTransferData *imTransferData = (IMTransferData *)[LMMessageAdapter sendAdapterIMPostWithMessage:message talkType:GJGCChatFriendTalkTypePostSystem ecdhKey:nil];
    [GCDQueue executeInQueue:self.messageSendQueue block:^{
        BOOL result = [self sendSystemMessage:imTransferData];
        //aad sending message to queue
        [[LMMessageSendManager sharedManager] addSendingMessage:message callBack:completion];
        if (!result) {
            [[LMMessageSendManager sharedManager] messageSendFailedMessageId:message.message_id];
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
    MessagePost *messagePost = (MessagePost *)[LMMessageAdapter sendAdapterIMPostWithMessage:message talkType:GJGCChatFriendTalkTypeGroup ecdhKey:ecdhKey];
    [GCDQueue executeInQueue:self.messageSendQueue block:^{
        BOOL result = [self sendGroupMessage:messagePost];
        //aad sending message to queue
        [[LMMessageSendManager sharedManager] addSendingMessage:message callBack:completion];
        if (!result) {
            [[LMMessageSendManager sharedManager] messageSendFailedMessageId:message.message_id];
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

    MessagePost *messagePost = (MessagePost *)[LMMessageAdapter sendAdapterIMPostWithMessage:message talkType:GJGCChatFriendTalkTypePrivate ecdhKey:nil];
    [GCDQueue executeInQueue:self.messageSendQueue block:^{
        BOOL result = [self sendPeerMessage:messagePost];
        //aad sending message to queue
        [[LMMessageSendManager sharedManager] addSendingMessage:message callBack:completion];
        if (!result) {
            [[LMMessageSendManager sharedManager] messageSendFailedMessageId:message.message_id];
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
    MessagePost *messagePost = (MessagePost *)[LMMessageAdapter sendAdapterIMPostWithMessage:message talkType:GJGCChatFriendTalkTypePrivate ecdhKey:nil];
    [GCDQueue executeInQueue:self.messageSendQueue block:^{
        BOOL result = [self sendReadAckMessage:messagePost];
        //aad sending message to queue
        [[LMMessageSendManager sharedManager] addSendingMessage:message callBack:completion];
        if (!result) {
            [[LMMessageSendManager sharedManager] messageSendFailedMessageId:message.message_id];
        }
    }];
    return messagePost;
}

#pragma mark - Socket- connect to server

- (void)onConnect {
    self.connectState = STATE_AUTHING;
    [GCDQueue executeInMainQueue:^{
        [self publishConnectState:self.connectState];
    }];

    if (GJCFStringIsNull([LKUserCenter shareCenter].currentLoginUser.prikey)) {
        [self close];
        return;
    }

    NewConnection *conn = [[NewConnection alloc] init];
    self.sendSalt = [KeyHandle createRandom512bits];
    conn.salt = self.sendSalt;


    self.randomPrivkey = [KeyHandle creatNewPrivkey];
    self.randomPublickey = [KeyHandle createPubkeyByPrikey:self.randomPrivkey];
    conn.pubKey = [StringTool hexStringToData:self.randomPublickey];

    NSData *password = [KeyHandle getECDHkeyWithPrivkey:[LKUserCenter shareCenter].currentLoginUser.prikey publicKey:[[ServerCenter shareCenter] getCurrentServer].data.pub_key];
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
    self.deviceToken = nil;
    [ServerCenter shareCenter].extensionPass = nil;
    self.RegisterDeviceTokenComplete = nil;
}

#pragma mark - Close server connection
- (void)connecting {
    
}

- (void)onClose {
    [ServerCenter shareCenter].extensionPass = nil;

    self.connectState = STATE_UNCONNECTED;
    [GCDQueue executeInMainQueue:^{
        [self publishConnectState:self.connectState];
    }];
    self.HeartBeatBlock = nil;
}

@end
