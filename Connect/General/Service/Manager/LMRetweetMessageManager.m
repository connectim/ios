//
//  LMRetweetMessageManager.m
//  Connect
//
//  Created by MoHuilin on 2017/1/20.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMRetweetMessageManager.h"
#import "ReconmandChatListPage.h"
#import "GJCFFileUploadManager.h"
#import "MessageDBManager.h"
#import "LMGroupInfo.h"
#import "RecentChatDBManager.h"
#import "IMService.h"
#import "LMConversionManager.h"
#import "StringTool.h"

@interface LMRetweetMessageManager ()

@property (copy ,nonatomic) void (^RetweetComplete)(NSError *error,float progress);

@end

@implementation LMRetweetMessageManager


CREATE_SHARED_MANAGER(LMRetweetMessageManager)

- (instancetype)init{
    if (self = [super init]) {
        [self configUploadManager];
    }
    return self;
}

- (void)configUploadManager{
    
    [[GJCFFileUploadManager shareUploadManager] setProgressBlock:^(GJCFFileUploadTask *updateTask, CGFloat progressValue) {
        self.RetweetComplete(nil,progressValue);
    } forObserver:self];
    
    [[GJCFFileUploadManager shareUploadManager] setFaildBlock:^(GJCFFileUploadTask *task, NSError *error) {
        self.RetweetComplete(error,0);
    } forObserver:self];
    [[GJCFFileUploadManager shareUploadManager] setCompletionBlock:^(GJCFFileUploadTask *task, FileData *fileData) {
        MMMessage *message = [task.userInfo valueForKey:@"message"];
        id toFriend = [task.userInfo valueForKey:@"toFriend"];
        [self uploadSuccessWithUrlDict:fileData mmmessage:message chatType:[[task.userInfo valueForKey:@"chatType"] integerValue] toFriend:toFriend];
    } forObserver:self];
    
    [[GJCFFileUploadManager shareUploadManager] setDefaultHostUrl:UPLOAD_FILE_SERVER_URL];
}


- (void)retweetMessageWithModel:(LMRerweetModel *)retweetModel
                       complete:(void (^)(NSError *error,float progress))complete{
    
    
    self.RetweetComplete = complete;
    MMMessage *message = [self packSendMessageWithRetweetMessage:retweetModel.retweetMessage toFriend:retweetModel.toFriendModel];
    // save message
    [self savaMessageToDB:message];
    if (message.type == GJGCChatFriendContentTypeImage || message.type == GJGCChatFriendContentTypeVideo) {
        [self retweetFileWithFileOwer:message.user_id retweetModel:retweetModel message:message];
    }
    GJGCChatFriendTalkType chatType = GJGCChatFriendTalkTypePrivate;
    NSString *ecdhKey = nil;
    if ([retweetModel.toFriendModel isKindOfClass:[LMGroupInfo class]]) {
        chatType = GJGCChatFriendTalkTypeGroup;
        LMGroupInfo *group = (LMGroupInfo *)retweetModel.toFriendModel;
        ecdhKey = group.groupEcdhKey;
    } else if ([retweetModel.toFriendModel isKindOfClass:[AccountInfo class]]){
        AccountInfo *user = (AccountInfo *)retweetModel.toFriendModel;
        if ([[user.pub_key uppercaseString] isEqualToString:@"CONNECT"]) {
            chatType = GJGCChatFriendTalkTypePostSystem;
        } else{
            ecdhKey = [KeyHandle getECDHkeyUsePrivkey:[[LKUserCenter shareCenter] currentLoginUser].pub_key PublicKey:message.publicKey];
        }
    }
    
    if (message.type == GJGCChatFriendContentTypeImage ||
        message.type == GJGCChatFriendContentTypeVideo ) {
        switch (chatType) {
            case GJGCChatFriendTalkTypePostSystem:
            {
                switch (message.type) {
                    case GJGCChatFriendContentTypeImage:
                    {
                        // big image
                        NSData *uploadImageData = retweetModel.fileData;
                        RichMedia *richMedia = [[RichMedia alloc] init];
                        richMedia.entity = uploadImageData;
                        
                        NSString *taskIdentifier = nil;
                        GJCFFileUploadTask *uploadTaskImage = [GJCFFileUploadTask taskWithUploadData:richMedia.data taskObserver:nil getTaskUniqueIdentifier:&taskIdentifier];
                        uploadTaskImage.userInfo = @{@"message":message,
                                                     @"toFriend":retweetModel.toFriendModel,
                                                     @"chatType":@(chatType)};
                        uploadTaskImage.msgType = chatType;
                        [[GJCFFileUploadManager shareUploadManager] addTask:uploadTaskImage];
                        
                    }
                        break;
                        
                    case GJGCChatFriendContentTypeVideo:
                    {
                        
                        NSData *videoData = retweetModel.fileData;
                        NSData *videoCoverData = retweetModel.thumData;
                        RichMedia *richMedia = [[RichMedia alloc] init];
                        richMedia.entity = videoData;
                        richMedia.thumbnail = videoCoverData;
                        NSString *taskIdentifier = nil;
                        GJCFFileUploadTask *uploadTaskImage = [GJCFFileUploadTask taskWithUploadData:richMedia.data taskObserver:nil getTaskUniqueIdentifier:&taskIdentifier];
                        uploadTaskImage.userInfo = @{@"message":message,
                                                     @"toFriend":retweetModel.toFriendModel,
                                                     @"chatType":@(chatType)};
                        uploadTaskImage.msgType = chatType;
                        [[GJCFFileUploadManager shareUploadManager] addTask:uploadTaskImage];
                    }
                        break;
                        
                        
                    default:
                        break;
                }
            }
                break;
                
            default:{
                // send message
                [[LMConversionManager sharedManager] sendMessage:message type:chatType];
                switch (message.type) {
                    case GJGCChatFriendContentTypeImage:{
                        message.imageOriginWidth = retweetModel.retweetMessage.imageOriginWidth;
                        message.imageOriginHeight = retweetModel.retweetMessage.imageOriginHeight;
                        // small photo
                        NSData *uploadThumbData = retweetModel.thumData;
                        // big photo
                        NSData *uploadImageData = retweetModel.fileData;
                        NSData *ecdhkey = nil;
                        if (chatType == GJGCChatFriendTalkTypeGroup) {
                            ecdhkey = [StringTool hexStringToData:ecdhKey];
                        } else if(chatType == GJGCChatFriendTalkTypePrivate){
                            ecdhkey = [KeyHandle getECDHkeyWithPrivkey:[[LKUserCenter shareCenter] currentLoginUser].prikey
                                                             publicKey:message.publicKey];
                        }
                        ecdhkey = [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdhkey salt:[ConnectTool get64ZeroData]];
                        GcmData *thumbGcmdata = [ConnectTool createGcmDataWithStructDataEcdhkey:ecdhkey data:uploadThumbData aad:nil];
                        GcmData *iamgeGcmdata = [ConnectTool createGcmDataWithStructDataEcdhkey:ecdhkey data:uploadImageData aad:nil];
                        
                        RichMedia *richMedia = [[RichMedia alloc] init];
                        richMedia.thumbnail = thumbGcmdata.data;
                        richMedia.entity = iamgeGcmdata.data;
                        
                        NSString *taskIdentifier = nil;
                        GJCFFileUploadTask *uploadTaskImage = [GJCFFileUploadTask taskWithUploadData:richMedia.data taskObserver:self getTaskUniqueIdentifier:&taskIdentifier];
                        uploadTaskImage.userInfo = @{@"message":message,
                                                     @"toFriend":retweetModel.toFriendModel,
                                                     @"chatType":@(chatType)};
                        uploadTaskImage.msgType = chatType;
                        [[GJCFFileUploadManager shareUploadManager] addTask:uploadTaskImage];
                    }
                        break;
                    case GJGCChatFriendContentTypeVideo:{
                        message.ext1 = retweetModel.retweetMessage.ext1;
                        NSData *videoData = retweetModel.fileData;
                        NSData *videoCoverData = retweetModel.thumData;
                        message.size = retweetModel.retweetMessage.size;
                        message.imageOriginWidth = retweetModel.retweetMessage.imageOriginWidth;
                        message.imageOriginHeight = retweetModel.retweetMessage.imageOriginHeight;
                        
                        NSData *ecdhkey = nil;
                        if (chatType == GJGCChatFriendTalkTypeGroup) {
                            ecdhkey = [StringTool hexStringToData:ecdhKey];
                        } else if(chatType == GJGCChatFriendTalkTypePrivate){
                            ecdhkey = [KeyHandle getECDHkeyWithPrivkey:[[LKUserCenter shareCenter] currentLoginUser].prikey
                                                             publicKey:message.publicKey];
                        }
                        ecdhkey = [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdhkey salt:[ConnectTool get64ZeroData]];
                        GcmData *gcmData = [ConnectTool createGcmDataWithStructDataEcdhkey:ecdhkey data:videoCoverData aad:nil];
                        GcmData *videoGcmData = [ConnectTool createGcmDataWithStructDataEcdhkey:ecdhkey data:videoData aad:nil];
                        
                        RichMedia *richMedia = [[RichMedia alloc] init];
                        richMedia.thumbnail = gcmData.data;
                        richMedia.entity = videoGcmData.data;
                        
                        NSString *videoTaskIdentifier = nil;
                        GJCFFileUploadTask *uploadVideoTask = [GJCFFileUploadTask taskWithUploadData:richMedia.data taskObserver:self getTaskUniqueIdentifier:&videoTaskIdentifier];
                        
                        uploadVideoTask.userInfo = @{@"message":message,
                                                     @"toFriend":retweetModel.toFriendModel,
                                                     @"chatType":@(chatType)};
                        uploadVideoTask.msgType = chatType;
                        [[GJCFFileUploadManager shareUploadManager] addTask:uploadVideoTask];
                    }
                        break;
                    default:
                        break;
                }
            }
                break;
        }
    } else{
        // send message
        [[LMConversionManager sharedManager] sendMessage:message type:chatType];
        [self sendMessagePost:message withType:chatType toFriend:retweetModel.toFriendModel];
    }
}


- (MMMessage *)packSendMessageWithRetweetMessage:(MMMessage *)retweetMessage toFriend:(id)toFriend{
    
    RecentChatModel *recent = nil;
    MMMessage *message = [[MMMessage alloc] init];
    message.type = retweetMessage.type;
    if ([toFriend isKindOfClass:[LMGroupInfo class]]) {
        LMGroupInfo *group = (LMGroupInfo *)toFriend;
        message.user_name = group.groupName;
        message.publicKey = group.groupIdentifer;
        message.user_id = group.groupIdentifer;
    } else if([toFriend isKindOfClass:[AccountInfo class]]){
        AccountInfo *user = (AccountInfo *)toFriend;
        message.user_name = user.username;
        message.publicKey = user.pub_key;
        message.user_id = user.address;
        recent = [[RecentChatDBManager sharedManager] getRecentModelByIdentifier:user.pub_key];
        if (recent.snapChatDeleteTime > 0) {
            message.ext = @{@"luck_delete":[NSString stringWithFormat:@"%d",recent.snapChatDeleteTime]};
        }
    }
    message.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
    
    message.message_id =  [ConnectTool generateMessageId];
    
    message.sendstatus = GJGCChatFriendSendMessageStatusSending;
    message.senderInfoExt = @{@"username":[[LKUserCenter shareCenter] currentLoginUser].username,
                              @"address":[[LKUserCenter shareCenter] currentLoginUser].address,
                              @"publickey":[[LKUserCenter shareCenter] currentLoginUser].pub_key,
                              @"avatar":[[LKUserCenter shareCenter] currentLoginUser].avatar};
    switch (retweetMessage.type) {
        case GJGCChatFriendContentTypeText:
        {
            message.content = retweetMessage.content;
        }
            break;
        case GJGCChatFriendContentTypeAudio:
            break;
        case GJGCChatFriendContentTypeImage:
        {
            // file mobile
            message.imageOriginWidth = retweetMessage.imageOriginWidth;
            message.imageOriginHeight = retweetMessage.imageOriginHeight;
        }
            return message;
            break;
        case GJGCChatFriendContentTypeVideo:
        {
            message.ext1 = retweetMessage.ext1;
            message.size = retweetMessage.size;
            message.imageOriginWidth = retweetMessage.imageOriginWidth;
            message.imageOriginHeight = retweetMessage.imageOriginHeight;
        }
            return message;
            break;
        case GJGCChatFriendContentTypeMapLocation:{
            if (recent.talkType == GJGCChatFriendTalkTypePostSystem) {
                message.locationExt = retweetMessage.locationExt;
                return message;
            } else{
                return nil;
            }
        }
            break;
        case GJGCChatFriendContentTypeGif:
        {
            message.content = retweetMessage.content;
        }
            break;
            
        case GJGCChatFriendContentTypePayReceipt:
        case GJGCChatFriendContentTypeTransfer:
        case GJGCChatFriendContentTypeRedEnvelope:
        {
            message.content = retweetMessage.content;
            if (retweetMessage.type == GJGCChatFriendContentTypePayReceipt) {
                message.ext1 = retweetMessage.ext1;
            } else if(retweetMessage.type == GJGCChatFriendContentTypeTransfer){
                message.ext1 = retweetMessage.ext1;
            }
        }
            break;
        
        case GJGCChatFriendContentTypeNameCard:
        {
            message.ext1 = retweetMessage.ext1;
            
        }
            break;
        case GJGCChatWalletLink:
        {
            message.ext1 = retweetMessage.ext1;
            message.content = retweetMessage.content;
        }
            break;
        default:
            break;
    }
    return message;
}

- (void)updateMessageToDB:(MMMessage *)message{
    ChatMessageInfo *messageInfo = [[MessageDBManager sharedManager] getMessageInfoByMessageid:message.message_id messageOwer:message.publicKey];
    messageInfo.message = message;
    [[MessageDBManager sharedManager] updataMessage:messageInfo];
}


- (void)savaMessageToDB:(MMMessage *)message{
    NSInteger snapTime = 0;
    if (message.ext && [message.ext isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = message.ext;
        if ([dict.allKeys containsObject:@"luck_delete"]) {
            snapTime = [[dict valueForKey:@"luck_delete"] integerValue];
        }
    }
    ChatMessageInfo *messageInfo = [[ChatMessageInfo alloc] init];
    messageInfo.messageId = message.message_id;
    messageInfo.messageType = message.type;
    messageInfo.createTime = message.sendtime;
    messageInfo.messageOwer = message.publicKey;
    messageInfo.sendstatus = GJGCChatFriendSendMessageStatusSending;
    messageInfo.message = message;
    messageInfo.snapTime = snapTime;
    messageInfo.readTime = 0;
    [[MessageDBManager sharedManager] saveMessage:messageInfo];
    // send message
    [GCDQueue executeInMainQueue:^{
        SendNotify(RereweetMessageNotification, messageInfo);
    }];
}

- (void)sendMessagePost:(MMMessage *)sendMessage
               withType:(GJGCChatFriendTalkType)chatType
               toFriend:(id)toFriend{
    
    if (chatType == GJGCChatFriendTalkTypePrivate) {
        [[IMService instance] asyncSendMessageMessage:sendMessage onQueue:nil completion:^(MMMessage *messageInfo,NSError *error) {
            self.RetweetComplete(error,1.1);
            if (!messageInfo) {
                return;
            }
            if (messageInfo.type == 12) {
                DDLogInfo(@"Read receipt of the message of success！！！");
                return;
            }
            ChatMessageInfo *chatMessage = [[MessageDBManager sharedManager] getMessageInfoByMessageid:messageInfo.message_id messageOwer:messageInfo.publicKey];
            chatMessage.message = messageInfo;
            chatMessage.sendstatus = messageInfo.sendstatus;
            
            [[MessageDBManager sharedManager] updataMessage:chatMessage];
            if (messageInfo.sendstatus == GJGCChatFriendSendMessageStatusSuccess) {
            
            }
            
        } onQueue:nil];
        
    } else if (chatType == GJGCChatFriendTalkTypeGroup){
        LMGroupInfo *group = (LMGroupInfo *)toFriend;
        [[IMService instance] asyncSendGroupMessage:sendMessage withGroupEckhKey:group.groupEcdhKey onQueue:nil completion:^(MMMessage *messageInfo, NSError *error) {
            
            self.RetweetComplete(error,1.1);
            
            if (!messageInfo) {
                return;
            }
            
            ChatMessageInfo *chatMessage = [[MessageDBManager sharedManager] getMessageInfoByMessageid:messageInfo.message_id messageOwer:messageInfo.publicKey];
            chatMessage.message = messageInfo;
            chatMessage.sendstatus = messageInfo.sendstatus;
            
            [[MessageDBManager sharedManager] updataMessage:chatMessage];
            if (messageInfo.sendstatus == GJGCChatFriendSendMessageStatusSuccess) {
                
            }
        } onQueue:nil];
    } else if (chatType == GJGCChatFriendTalkTypePostSystem){
        [[IMService instance] asyncSendSystemMessage:sendMessage completion:^(MMMessage *messageInfo, NSError *error) {
            if (!messageInfo) {
                return;
            }
            
            self.RetweetComplete(error,1.1);
            
            // Update the database status
            [GCDQueue executeInBackgroundPriorityGlobalQueue:^{
                
                ChatMessageInfo *chatMessage = [[MessageDBManager sharedManager] getMessageInfoByMessageid:messageInfo.message_id messageOwer:messageInfo.publicKey];
                chatMessage.message = messageInfo;
                chatMessage.sendstatus = messageInfo.sendstatus;
                
                [[MessageDBManager sharedManager] updataMessage:chatMessage];
                
                if (messageInfo.sendstatus == GJGCChatFriendSendMessageStatusSuccess) {
                    // Update to the database
                    
                }
            }];
        }];
    }
}


- (void)uploadSuccessWithUrlDict:(FileData *)fileData mmmessage:(MMMessage *)message chatType:(GJGCChatFriendTalkType)chatType toFriend:(id)toFriend{
    
    NSString * fileUrl = nil;
    if (chatType == GJGCChatFriendTalkTypePostSystem) {
        fileUrl = [NSString stringWithFormat:@"%@?token=%@",fileData.URL,fileData.token];
    } else{
        fileUrl = [NSString stringWithFormat:@"%@?pub_key=%@&token=%@",fileData.URL,message.publicKey,fileData.token];
    }
    
    switch (message.type) {
        case GJGCChatFriendContentTypeVideo:
        case GJGCChatFriendContentTypeImage:
        {
            if (chatType == GJGCChatFriendTalkTypePostSystem) {
                message.content = fileUrl;
            } else{
                message.content = [NSString stringWithFormat:@"%@/thumb?pub_key=%@&token=%@",fileData.URL,message.publicKey,fileData.token];
                message.url = fileUrl;
            }
        }
            break;
        case GJGCChatFriendContentTypeMapLocation:
        case GJGCChatFriendContentTypeAudio:
        {
            message.content = fileUrl;
        }
            break;
        default:
            break;
    }

    
    [self updateMessageToDB:message];
    [self sendMessagePost:message withType:chatType toFriend:toFriend];
    
}

- (void)retweetFileWithFileOwer:(NSString *)ower
                  retweetModel:(LMRerweetModel *)retweetModel
                       message:(MMMessage *)message{
    NSString *cacheDirectory = [[GJCFCachePathManager shareManager] mainVideoCacheDirectory];
    cacheDirectory = [[cacheDirectory stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].address]
                      stringByAppendingPathComponent:ower];
    if (!GJCFFileDirectoryIsExist(cacheDirectory)) {
        GJCFFileProtectCompleteDirectoryCreate(cacheDirectory);
    }
    
    switch (message.type) {
        case GJGCChatFriendContentTypeVideo:
        {
            NSString *videoFileName = [NSString stringWithFormat:@"%@.mp4",message.message_id];
            NSString *videoFileCoverImageName = [NSString stringWithFormat:@"%@-coverimage.jpg",message.message_id];
            NSString *videoFileLocalPath = [cacheDirectory stringByAppendingPathComponent:videoFileName];
            NSString *videoFileCoverImageLocalPath = [cacheDirectory stringByAppendingPathComponent:videoFileCoverImageName];
            
            GJCFFileWrite(retweetModel.thumData, videoFileCoverImageLocalPath);
            GJCFFileWrite(retweetModel.fileData, videoFileLocalPath);
            
        }
            break;
        case GJGCChatFriendContentTypeImage:
        {
            // big image
            NSString *imageName = [NSString stringWithFormat:@"%@.jpg",message.message_id];
            GJCFFileWrite(retweetModel.fileData, [cacheDirectory stringByAppendingPathComponent:imageName]);
            NSString *thumbImageName = [NSString stringWithFormat:@"%@-thumb.jpg",message.message_id];
            // small image
            GJCFFileWrite(retweetModel.thumData, [cacheDirectory stringByAppendingPathComponent:thumbImageName]);
        }
            break;
            
        default:
            break;
    }
}


@end
