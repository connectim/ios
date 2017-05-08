//
//  LMMessageTool.m
//  Connect
//
//  Created by MoHuilin on 2017/3/29.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMMessageTool.h"
#import "ConnectTool.h"
#import "GJGCChatFriendCellStyle.h"
#import "GJGCChatContentEmojiParser.h"
#import "LMGroupInfo.h"
#import "GJGCChatSystemNotiCellStyle.h"
#import "LMOtherModel.h"
#import "LMMessageExtendManager.h"
#import "SessionManager.h"
#import "MessageDBManager.h"
#import "GroupDBManager.h"

@implementation LMMessageTool


+ (void)savaSendMessageToDB:(MMMessage *)message {
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
    messageInfo.messageOwer = [SessionManager sharedManager].chatSession;
    messageInfo.sendstatus = GJGCChatFriendSendMessageStatusSending;
    messageInfo.message = message;
    messageInfo.snapTime = snapTime;
    messageInfo.readTime = 0;
    [[MessageDBManager sharedManager] saveMessage:messageInfo];
}

+ (void)updateSendMessageStatus:(MMMessage *)message {
    ChatMessageInfo *messageInfo = [[MessageDBManager sharedManager] getMessageInfoByMessageid:message.message_id messageOwer:[SessionManager sharedManager].chatSession];
    messageInfo.message = message;
    [[MessageDBManager sharedManager] updataMessage:messageInfo];
}

+ (NSData *)formateVideoLoacalPath:(GJGCChatFriendContentModel *)messageContent {
    
    AccountInfo *user = nil;
    LMGroupInfo *group = nil;
    if ([[SessionManager sharedManager].chatObject isKindOfClass:[AccountInfo class]]) {
        user = (AccountInfo *)[SessionManager sharedManager].chatObject;
    } else if ([[SessionManager sharedManager].chatObject isKindOfClass:[LMGroupInfo class]]){
        group = (LMGroupInfo *)[SessionManager sharedManager].chatObject;
    }

    //amr
    NSData *date = [NSData dataWithContentsOfFile:messageContent.audioModel.tempEncodeFilePath];
    if (date) {
        NSString *cacheDirectory = [[GJCFCachePathManager shareManager] mainAudioCacheDirectory];
        cacheDirectory = [[cacheDirectory stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].address]
                          stringByAppendingPathComponent:group?group.groupIdentifer:user.address];
        
        if (!GJCFFileDirectoryIsExist(cacheDirectory)) {
            GJCFFileProtectCompleteDirectoryCreate(cacheDirectory);
        }
        NSString *temWavName = [NSString stringWithFormat:@"%@.wav", messageContent.localMsgId];
        NSString *temWavPath = [cacheDirectory stringByAppendingPathComponent:temWavName];
        GJCFFileCopyFileIsRemove(messageContent.audioModel.localStorePath, temWavPath, YES);
        
        NSString *downloadencodeFileName = [NSString stringWithFormat:@"%@.encode", messageContent.localMsgId];
        NSString *downloadEncodeCachePath = [cacheDirectory stringByAppendingPathComponent:downloadencodeFileName];
        
        NSString *amrFileName = [NSString stringWithFormat:@"%@.amr", messageContent.localMsgId];
        NSString *amrFilePath = [cacheDirectory stringByAppendingPathComponent:amrFileName];
        GJCFFileCopyFileIsRemove(messageContent.audioModel.tempEncodeFilePath, amrFilePath, YES);
        messageContent.audioModel.localAMRStorePath = amrFilePath;
        messageContent.audioModel.downloadEncodeCachePath = downloadEncodeCachePath;
        messageContent.audioModel.tempWamFilePath = temWavPath;
    } else {
        date = [NSData dataWithContentsOfFile:messageContent.audioModel.localAMRStorePath];
    }
    
    return date;
}

+ (MMMessage *)packSendMessageWithChatContent:(GJGCChatFriendContentModel *)messageContent snapTime:(int)snapTime{
    
    AccountInfo *user = nil;
    LMGroupInfo *group = nil;
    if ([[SessionManager sharedManager].chatObject isKindOfClass:[AccountInfo class]]) {
        user = (AccountInfo *)[SessionManager sharedManager].chatObject;
    } else if ([[SessionManager sharedManager].chatObject isKindOfClass:[LMGroupInfo class]]){
        group = (LMGroupInfo *)[SessionManager sharedManager].chatObject;
    }
    if (!group && !user) {
        return nil;
    }

    MMMessage *message = [[MMMessage alloc] init];
    message.user_name = messageContent.reciverName;
    message.type = messageContent.contentType;
    message.sendtime = messageContent.sendTime;
    message.message_id = messageContent.localMsgId;
    message.publicKey = messageContent.reciverPublicKey;
    message.user_id = messageContent.reciverAddress;
    message.sendstatus = GJGCChatFriendSendMessageStatusSending;
    message.senderInfoExt = @{@"username": [[LKUserCenter shareCenter] currentLoginUser].username,
                              @"address": [[LKUserCenter shareCenter] currentLoginUser].address,
                              @"publickey": [[LKUserCenter shareCenter] currentLoginUser].pub_key,
                              @"avatar": [[LKUserCenter shareCenter] currentLoginUser].avatar};
    
    if ([SessionManager sharedManager].talkType == GJGCChatFriendTalkTypeGroup) {
        message.publicKey = group.groupIdentifer;
        message.user_id = group.groupIdentifer;
        //set @ membser address
        if (messageContent.contentType == GJGCChatFriendContentTypeText) {
            message.ext1 = messageContent.noteGroupMemberAddresses;
        }
    }
    
    if (snapTime > 0) {
        message.ext = @{@"luck_delete": [NSString stringWithFormat:@"%d", snapTime]};
    } else {
        message.ext = nil;
    }
    switch (messageContent.contentType) {
        case GJGCChatWalletLink: {
            /*
             if (![[message.ext1 allKeys] containsObject:@"linkTitle"] ||
             ![[message.ext1 allKeys] containsObject:@"linkSubtitle"]) {
             */
            message.content = messageContent.originTextMessage;
            switch (messageContent.walletLinkType) {
                case LMWalletlinkTypeOuterTransfer: {
                    message.ext1 = @{@"linkTitle": LMLocalizedString(@"Wallet Wallet Out Send Share", nil),
                                     @"linkSubtitle": LMLocalizedString(@"Wallet Click to recive payment", nil)};
                }
                    break;
                case LMWalletlinkTypeOuterPacket: {
                    message.ext1 = @{@"linkTitle": LMLocalizedString(@"Wallet Send a lucky packet", nil),
                                     @"linkSubtitle": LMLocalizedString(@"Wallet Click to open lucky packet", nil)};
                }
                    break;
                case LMWalletlinkTypeOuterCollection: {
                    message.ext1 = @{@"linkTitle": LMLocalizedString(@"Wallet Send the payment connection", nil),
                                     @"linkSubtitle": LMLocalizedString(@"Wallet Click to transfer bitcoin", nil)};
                }
                    break;
                default:
                    break;
            }
        }
            break;
        case GJGCChatFriendContentTypeText: {
            message.content = messageContent.originTextMessage;
        }
            break;
        case GJGCChatFriendContentTypeAudio:
        case GJGCChatFriendContentTypeImage:
        case GJGCChatFriendContentTypeVideo:
            return nil;
            break;
        case GJGCChatFriendContentTypeMapLocation: {
            if ([SessionManager sharedManager].talkType == GJGCChatFriendTalkTypePostSystem) {
                message.locationExt = @{@"locationLatitude": @(messageContent.locationLatitude),
                                        @"locationLongitude": @(messageContent.locationLongitude),
                                        @"address": messageContent.originTextMessage};
                return message;
            } else {
                return nil;
            }
        }
            break;
        case GJGCChatFriendContentTypeGif: {
            message.content = messageContent.gifLocalId;
        }
            break;
            
        case GJGCChatFriendContentTypePayReceipt:
        case GJGCChatFriendContentTypeTransfer:
        case GJGCChatFriendContentTypeRedEnvelope: {
            message.content = messageContent.hashID;
            if (messageContent.contentType == GJGCChatFriendContentTypePayReceipt) {
                message.ext1 = @{@"amount": @(messageContent.amount),
                                 @"totalMember": @(messageContent.memberCount),
                                 @"isCrowdfundRceipt": @(messageContent.isCrowdfundRceipt),
                                 @"note": messageContent.tipNote};
            } else if (messageContent.contentType == GJGCChatFriendContentTypeTransfer) {
                message.ext1 = @{@"amount": @(messageContent.amount),
                                 @"tips": messageContent.tipNote ? messageContent.tipNote : @""};
            } else {
                if (![messageContent.tipNote isEqualToString:LMLocalizedString(@"Chat Send a Luck Packet Click to view", nil)]) {
                    message.ext1 = @{@"amount": @(messageContent.amount),
                                     @"tips": messageContent.tipNote ? messageContent.tipNote : @"",
                                     @"type": @(0)};
                }
            }
        }
            break;
        case GJGCChatFriendContentTypeNameCard: {
            message.ext1 = @{@"username": messageContent.contactName.string,
                             @"avatar": messageContent.contactAvatar,
                             @"pub_key": messageContent.contactPublickey,
                             @"address": messageContent.contactAddress};
            
        }
            break;
        default:
            break;
    }
    return message;
}


+ (GJGCChatFriendContentType)formateChatFriendContent:(GJGCChatFriendContentModel *)chatContentModel withMsgModel:(MMMessage *)message{
    AccountInfo *user = nil;
    LMGroupInfo *group = nil;
    if ([[SessionManager sharedManager].chatObject isKindOfClass:[AccountInfo class]]) {
        user = (AccountInfo *)[SessionManager sharedManager].chatObject;
    } else if ([[SessionManager sharedManager].chatObject isKindOfClass:[LMGroupInfo class]]){
        group = (LMGroupInfo *)[SessionManager sharedManager].chatObject;
    }
    GJGCChatFriendContentType type = GJGCChatFriendContentTypeNotFound;
    if (!group && !user) {
        return type;
    }
    chatContentModel.localMsgId = message.message_id;
    
    switch (message.type) {
        case GJGCChatFriendContentTypeAudio:
        {
            chatContentModel.contentType = GJGCChatFriendContentTypeAudio;
            type = chatContentModel.contentType;
            
            chatContentModel.audioModel.remotePath = message.content;
            
            if (message.content && chatContentModel.isFromSelf) {
                chatContentModel.uploadSuccess = YES;
                chatContentModel.uploadProgress = 1.f;
            }
            
            NSString *cacheDirectory = [[GJCFCachePathManager shareManager] mainAudioCacheDirectory];
            cacheDirectory = [[cacheDirectory stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].address]
                              stringByAppendingPathComponent:group?group.groupIdentifer:user.address];
            
            if (!GJCFFileDirectoryIsExist(cacheDirectory)) {
                GJCFFileProtectCompleteDirectoryCreate(cacheDirectory);
            }
            
            NSString *temWavName = [NSString stringWithFormat:@"%@.wav", message.message_id];
            NSString *temWavPath = [cacheDirectory stringByAppendingPathComponent:temWavName];
            
            NSString *downloadencodeFileName = [NSString stringWithFormat:@"%@.encode", message.message_id];
            NSString *downloadEncodeCachePath = [cacheDirectory stringByAppendingPathComponent:downloadencodeFileName];
            
            NSString *amrFileName = [NSString stringWithFormat:@"%@.amr", message.message_id];
            NSString *amrFilePath = [cacheDirectory stringByAppendingPathComponent:amrFileName];
            chatContentModel.audioModel.localAMRStorePath = amrFilePath;
            chatContentModel.audioModel.downloadEncodeCachePath = downloadEncodeCachePath;
            chatContentModel.audioModel.tempWamFilePath = temWavPath;
            chatContentModel.audioModel.duration = message.size;
            chatContentModel.audioDuration = [GJGCChatFriendCellStyle formateAudioDuration:GJCFStringFromInt(chatContentModel.audioModel.duration)];
            
            if (GJCFFileIsExist(chatContentModel.audioModel.localAMRStorePath)) {
                chatContentModel.audioIsDownload = YES;
            }
        }
            break;
        case GJGCChatFriendContentTypeText:{
            chatContentModel.contentType = GJGCChatFriendContentTypeText;
            type = chatContentModel.contentType;
            
            if ([message.content isKindOfClass:[NSString class]]) {
                
                if (!GJCFNSCacheGetValue(message.content)) {
                    [GJGCChatFriendCellStyle formateSimpleTextMessage:message.content];
                }
                chatContentModel.originTextMessage = message.content;
                
            } else {
                type = GJGCChatFriendContentTypeNotFound;
            }
        }
            break;
        case GJGCChatWalletLink:{
            chatContentModel.contentType = GJGCChatWalletLink;
            type = chatContentModel.contentType;
            chatContentModel.originTextMessage = message.content;
            if ([[GJGCChatContentEmojiParser sharedParser] isWalletUrlString:chatContentModel.originTextMessage]) {
                chatContentModel.contentType = GJGCChatWalletLink;
                type = chatContentModel.contentType;
                if ([message.content containsString:@"transfer?"]) {
                    chatContentModel.walletLinkType = LMWalletlinkTypeOuterTransfer;
                } else if ([message.content containsString:@"packet?"]) {
                    chatContentModel.walletLinkType = LMWalletlinkTypeOuterPacket;
                } else if ([message.content containsString:@"pay?"]) {
                    chatContentModel.walletLinkType = LMWalletlinkTypeOuterCollection;
                }
                chatContentModel.originTextMessage = message.content;
            } else {
                chatContentModel.walletLinkType = LMWalletlinkTypeOuterOther;
                chatContentModel.linkTitle = [message.ext1 valueForKey:@"linkTitle"];
                chatContentModel.linkSubtitle = [message.ext1 valueForKey:@"linkSubtitle"];
                chatContentModel.linkImageUrl = [message.ext1 valueForKey:@"linkImageUrl"];
            }
        }
            break;
        case GJGCChatInviteToGroup:{
            chatContentModel.contentType = GJGCChatInviteToGroup;
            type = chatContentModel.contentType;
            
            NSDictionary *temD = message.ext1;
            if ([temD isKindOfClass:[NSString class]]) {
                temD = [temD mj_JSONObject];
            }
            if (temD) {
                chatContentModel.contactName = [GJGCChatSystemNotiCellStyle formatetGroupInviteGroupName:[temD valueForKey:@"groupname"] reciverName:nil isSystemMessage:NO isSendFromMySelf:chatContentModel.isFromSelf];
                chatContentModel.groupIdentifier = [temD valueForKey:@"groupidentifier"];
                chatContentModel.inviteToken = [temD valueForKey:@"inviteToken"];
                chatContentModel.contactSubTipMessage = [GJGCChatSystemNotiCellStyle formateCellLeftSubTipsWithType:GJGCChatInviteToGroup withNote:nil isCrowding:NO];
                chatContentModel.contactAvatar = [temD valueForKey:@"avatar"];
            } else {
                type = GJGCChatFriendContentTypeNotFound;
            }
        }
            break;
        case GJGCChatApplyToJoinGroup:{
            chatContentModel.contentType = GJGCChatApplyToJoinGroup;
            type = chatContentModel.contentType;
            
            NSDictionary *temD = message.ext1;
            if ([temD isKindOfClass:[NSString class]]) {
                temD = [temD mj_JSONObject];
            }
            if (temD) {
                chatContentModel.contactName = [GJGCChatSystemNotiCellStyle formatetGroupInviteGroupName:[temD valueForKey:@"groupname"] reciverName:[temD valueForKey:@"username"] isSystemMessage:YES isSendFromMySelf:chatContentModel.isFromSelf];
                chatContentModel.groupIdentifier = [temD valueForKey:@"groupidentifier"];
                chatContentModel.contactAvatar = [temD valueForKey:@"avatar"];
                chatContentModel.contactSubTipMessage = [GJGCChatSystemNotiCellStyle formateCellLeftSubTipsWithType:GJGCChatApplyToJoinGroup withNote:nil isCrowding:NO];
                LMOtherModel *model = [[LMOtherModel alloc] init];
                BOOL isNoted = [[temD valueForKey:@"newaccept"] boolValue];
                NSString *groupId = [temD valueForKey:@"identifier"];
                NSString *applyUserPubkey = [temD valueForKey:@"pubKey"];
                BOOL userIsInGroup = [[GroupDBManager sharedManager] userWithAddress:[KeyHandle getAddressByPubkey:applyUserPubkey] isinGroup:groupId];
                if (userIsInGroup) {
                    chatContentModel.statusMessageString = [GJGCChatSystemNotiCellStyle formateCellStatusWithHandle:YES refused:NO isNoted:isNoted];
                } else{
                    BOOL refused = [[temD valueForKey:@"refused"] boolValue];
                    if (refused) {
                        chatContentModel.statusMessageString = [GJGCChatSystemNotiCellStyle formateCellStatusWithHandle:YES refused:refused isNoted:isNoted];
                        model.handled = YES;
                        model.refused = refused;
                    } else {
                        chatContentModel.statusMessageString = [GJGCChatSystemNotiCellStyle formateCellStatusWithHandle:NO refused:NO isNoted:isNoted];
                    }
                }
                model.userIsinGroup = userIsInGroup;
                model.userName = [temD valueForKey:@"username"];
                model.headImageViewUrl = [temD valueForKey:@"avatar"];
                model.contentName = [temD valueForKey:@"tips"];
                model.sourceType = [[temD valueForKey:@"source"] intValue];
                model.verificationCode = [temD valueForKey:@"verificationCode"];
                model.publickey = applyUserPubkey;
                model.groupIdentifier = groupId;
                chatContentModel.contentModel = model;
            } else {
                type = GJGCChatFriendContentTypeNotFound;
            }
        }
            break;
        case GJGCChatFriendContentTypeNameCard:{
            chatContentModel.contentType = GJGCChatFriendContentTypeNameCard;
            type = chatContentModel.contentType;
            
            NSDictionary *temD = message.ext1;
            if ([temD isKindOfClass:[NSString class]]) {
                temD = [temD mj_JSONObject];
            }
            if (temD) {
                chatContentModel.contactAvatar = [temD valueForKey:@"avatar"];
                chatContentModel.contactPublickey = [temD valueForKey:@"pub_key"];
                chatContentModel.contactAddress = [temD valueForKey:@"address"];
                NSString *name = [temD valueForKey:@"username"];
                if (name != nil) {
                    NSMutableAttributedString *nameText = [[NSMutableAttributedString alloc] initWithString:name];
                    [nameText addAttribute:NSFontAttributeName
                                     value:[UIFont systemFontOfSize:FONT_SIZE(32)]
                                     range:NSMakeRange(0, name.length)];
                    [nameText addAttribute:NSForegroundColorAttributeName
                                     value:[UIColor whiteColor]
                                     range:NSMakeRange(0, name.length)];
                    
                    chatContentModel.contactName = nameText;
                }
                chatContentModel.contactSubTipMessage = [GJGCChatSystemNotiCellStyle formateNameCardSubTipsIsFromSelf:chatContentModel.isFromSelf];
            } else {
                type = GJGCChatFriendContentTypeNotFound;
            }
        }
            break;
        case GJGCChatFriendContentTypeTransfer:{
            chatContentModel.contentType = GJGCChatFriendContentTypeTransfer;
            type = chatContentModel.contentType;
            long long int amount = [[message.ext1 valueForKey:@"amount"] integerValue];
            int status = [[LMMessageExtendManager sharedManager] getStatus:message.content];
            chatContentModel.transferMessage = [GJGCChatSystemNotiCellStyle formateTransferWithAmount:amount isSendToMe:!chatContentModel.isFromSelf isOuterTransfer:[SessionManager sharedManager].talkType == GJGCChatFriendTalkTypePostSystem];
            chatContentModel.transferSubTipMessage = [GJGCChatSystemNotiCellStyle formateCellLeftSubTipsWithType:GJGCChatFriendContentTypeTransfer withNote:[message.ext1 valueForKey:@"tips"] isCrowding:NO];
            if ([SessionManager sharedManager].talkType != GJGCChatFriendTalkTypePostSystem) {
                chatContentModel.transferStatusMessage = [GJGCChatSystemNotiCellStyle formateRecieptSubTipsWithTotal:1 payCount:1 isCrowding:NO transStatus:status == 0 ? 1 : status];
            }
            chatContentModel.hashID = message.content;
            chatContentModel.amount = amount;
            chatContentModel.isOuterTransfer = [message.locationExt boolValue];
        }
            break;
        case GJGCChatFriendContentTypeRedEnvelope:{
            chatContentModel.contentType = GJGCChatFriendContentTypeRedEnvelope;
            type = chatContentModel.contentType;
            chatContentModel.redBagTipMessage = [GJGCChatSystemNotiCellStyle formateRedBagWithMessage:message.ext1 isOuterTransfer:NO];
            NSString *tips = nil;
            if ([message.ext1 isKindOfClass:[NSString class]]) {
                tips = message.ext1;
            } else {
                tips = [message.ext1 valueForKey:@"tips"];
            }
            chatContentModel.redBagSubTipMessage = [GJGCChatSystemNotiCellStyle formateCellLeftSubTipsWithType:GJGCChatFriendContentTypeRedEnvelope withNote:tips isCrowding:NO];
            chatContentModel.hashID = message.content;
        }
            break;
        case GJGCChatFriendContentTypePayReceipt:{
            chatContentModel.contentType = GJGCChatFriendContentTypePayReceipt;
            type = chatContentModel.contentType;
            
            if ([message.ext1 isKindOfClass:[NSString class]]) {
                message.ext1 = [message.ext1 mj_JSONObject];
            }
            NSAssert([message.ext1 isKindOfClass:[NSDictionary class]], @"message.ext1 is not a dictory");
            long long int amount = [[message.ext1 valueForKey:@"amount"] longValue];
            int totalMember = [[message.ext1 valueForKey:@"totalMember"] intValue];
            BOOL isCrowdfundRceipt = [[message.ext1 valueForKey:@"isCrowdfundRceipt"] intValue];
            NSString *note = [message.ext1 valueForKey:@"note"];
            int status = [[LMMessageExtendManager sharedManager] getStatus:message.content];
            int payCount = [[LMMessageExtendManager sharedManager] getPayCount:message.content];
            chatContentModel.payOrReceiptStatusMessage = [GJGCChatSystemNotiCellStyle formateRecieptSubTipsWithTotal:totalMember payCount:payCount isCrowding:isCrowdfundRceipt transStatus:status];
            chatContentModel.payOrReceiptMessage = [GJGCChatSystemNotiCellStyle formateRecieptWithAmount:amount isSendToMe:!chatContentModel.isFromSelf isCrowdfundRceipt:isCrowdfundRceipt withNote:note];
            chatContentModel.payOrReceiptSubTipMessage = [GJGCChatSystemNotiCellStyle formateCellLeftSubTipsWithType:GJGCChatFriendContentTypePayReceipt withNote:note isCrowding:isCrowdfundRceipt];
            chatContentModel.hashID = message.content;
            chatContentModel.amount = amount;
            chatContentModel.memberCount = totalMember;
            chatContentModel.isCrowdfundRceipt = isCrowdfundRceipt;
        }
            break;
        case GJGCChatFriendContentTypeSnapChat:{
            chatContentModel.contentType = GJGCChatFriendContentTypeSnapChat;
            type = chatContentModel.contentType;
            chatContentModel.snapChatTipString = [GJGCChatSystemNotiCellStyle formateOpensnapChatWithTime:(int) [message.content integerValue] isSendToMe:[message.user_id isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address] chatUserName:user.normalShowName];
        }
            break;
        case GJGCChatFriendContentTypeImage:{
            chatContentModel.contentType = GJGCChatFriendContentTypeImage;
            type = chatContentModel.contentType;
            
            chatContentModel.encodeFileUrl = message.url;
            chatContentModel.encodeThumbFileUrl = message.content;
            
            if ([SessionManager sharedManager].talkType == GJGCChatFriendTalkTypePostSystem) {
                if (message.content && chatContentModel.isFromSelf) {
                    chatContentModel.uploadSuccess = YES;
                    chatContentModel.uploadProgress = 1.f;
                }
            } else{
                if (message.content && message.url && chatContentModel.isFromSelf) {
                    chatContentModel.uploadSuccess = YES;
                    chatContentModel.uploadProgress = 1.f;
                }
            }
            
            NSString *cacheDirectory = [[GJCFCachePathManager shareManager] mainImageCacheDirectory];
            cacheDirectory = [[cacheDirectory stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].address]
                              stringByAppendingPathComponent:group?group.groupIdentifer:user.address];
            
            if (!GJCFFileDirectoryIsExist(cacheDirectory)) {
                GJCFFileProtectCompleteDirectoryCreate(cacheDirectory);
            }
            
            NSString *temOriginName = [NSString stringWithFormat:@"%@.jpg", message.message_id];
            NSString *thumbImageName = [NSString stringWithFormat:@"%@-thumb.jpg", message.message_id];
            NSString *temOriginPath = [cacheDirectory stringByAppendingPathComponent:temOriginName];
            NSString *thumbImageNamePath = [cacheDirectory stringByAppendingPathComponent:thumbImageName];
            
            NSString *downloadencodeFileName = [NSString stringWithFormat:@"%@.encode", message.message_id];
            NSString *downloadEncodeCachePath = [cacheDirectory stringByAppendingPathComponent:downloadencodeFileName];
            
            NSString *downloadThumbencodeFileName = [NSString stringWithFormat:@"%@-thumb.encode", message.message_id];
            NSString *downloadThumbEncodeCachePath = [cacheDirectory stringByAppendingPathComponent:downloadThumbencodeFileName];
            
            chatContentModel.imageOriginDataCachePath = temOriginPath;
            chatContentModel.downEncodeImageCachePath = downloadEncodeCachePath;
            chatContentModel.downThumbEncodeImageCachePath = downloadThumbEncodeCachePath;
            chatContentModel.thumbImageCachePath = thumbImageNamePath;
            chatContentModel.originImageHeight = message.imageOriginHeight;
            chatContentModel.originImageWidth = message.imageOriginWidth;

            if (GJCFFileIsExist(chatContentModel.thumbImageCachePath)) {
                chatContentModel.isDownloadThumbImage = YES;
                NSData *imageData = [NSData dataWithContentsOfFile:chatContentModel.thumbImageCachePath];
                chatContentModel.messageContentImage = [UIImage imageWithData:imageData];
            }
            if (GJCFFileIsExist(chatContentModel.imageOriginDataCachePath)) {
                chatContentModel.isDownloadImage = YES;
                if (!chatContentModel.messageContentImage) {
                    NSData *imageData = [NSData dataWithContentsOfFile:chatContentModel.imageOriginDataCachePath];
                    chatContentModel.messageContentImage = [UIImage imageWithData:imageData];
                }
            }
        }
            break;
        case GJGCChatFriendContentTypeMapLocation:{
            chatContentModel.contentType = GJGCChatFriendContentTypeMapLocation;
            type = chatContentModel.contentType;
            
            chatContentModel.encodeFileUrl = message.content;
            
            if (message.content && chatContentModel.isFromSelf) {
                chatContentModel.uploadSuccess = YES;
                chatContentModel.uploadProgress = 1.f;
            }
            
            NSString *cacheDirectory = [[GJCFCachePathManager shareManager] mainImageCacheDirectory];
            cacheDirectory = [[cacheDirectory stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].address]
                              stringByAppendingPathComponent:group?group.groupIdentifer:user.address];
            
            if (!GJCFFileDirectoryIsExist(cacheDirectory)) {
                GJCFFileProtectCompleteDirectoryCreate(cacheDirectory);
            }
            
            NSString *temOriginName = [NSString stringWithFormat:@"%@.jpg", message.message_id];
            NSString *temOriginPath = [cacheDirectory stringByAppendingPathComponent:temOriginName];
            
            NSString *downloadencodeFileName = [NSString stringWithFormat:@"%@.encode", message.message_id];
            NSString *downloadEncodeCachePath = [cacheDirectory stringByAppendingPathComponent:downloadencodeFileName];
            
            NSDictionary *temD = message.locationExt;
            if (temD) {
                chatContentModel.locationLongitude = [[temD valueForKey:@"locationLongitude"] doubleValue];
                chatContentModel.locationLatitude = [[temD valueForKey:@"locationLatitude"] doubleValue];
                chatContentModel.originTextMessage = [temD valueForKey:@"address"];
                chatContentModel.locationMessage = [GJGCChatSystemNotiCellStyle formatLocationMessage:chatContentModel.originTextMessage];
            }
            
            chatContentModel.locationImageOriginDataCachePath = temOriginPath;
            chatContentModel.locationImageDownPath = downloadEncodeCachePath;
            
            if (GJCFFileIsExist(chatContentModel.locationImageOriginDataCachePath)) {
                NSData *imageData = [NSData dataWithContentsOfFile:chatContentModel.locationImageOriginDataCachePath];
                chatContentModel.messageContentImage = [UIImage imageWithData:imageData];
            }
        }
            break;
        case GJGCChatFriendContentTypeVideo:{
            chatContentModel.contentType = GJGCChatFriendContentTypeVideo;
            type = chatContentModel.contentType;
            chatContentModel.videoDuration = message.size;
            chatContentModel.videoSize = message.ext1;
            chatContentModel.encodeFileUrl = message.content;
            chatContentModel.videoEncodeUrl = message.url;
            
            
            if ([SessionManager sharedManager].talkType == GJGCChatFriendTalkTypePostSystem) {
                if (message.content && chatContentModel.isFromSelf) {
                    chatContentModel.uploadSuccess = YES;
                    chatContentModel.uploadProgress = 1.f;
                }
            } else{
                if (message.content && message.url && chatContentModel.isFromSelf) {
                    chatContentModel.uploadSuccess = YES;
                    chatContentModel.uploadProgress = 1.f;
                }
            }
            
            chatContentModel.originImageHeight = message.imageOriginHeight;
            chatContentModel.originImageWidth = message.imageOriginWidth;
            
            NSString *cacheDirectory = [[GJCFCachePathManager shareManager] mainVideoCacheDirectory];
            cacheDirectory = [[cacheDirectory stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].address]
                              stringByAppendingPathComponent:group?group.groupIdentifer:user.address];
            
            if (!GJCFFileDirectoryIsExist(cacheDirectory)) {
                GJCFFileProtectCompleteDirectoryCreate(cacheDirectory);
            }

            chatContentModel.videoDownCoverEncodePath = [cacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-coverimage.decode", message.message_id]];
            chatContentModel.videoDownVideoEncodePath = [cacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.decode", message.message_id]];

            chatContentModel.videoOriginCoverImageCachePath = [cacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-coverimage.jpg", message.message_id]];
            chatContentModel.videoOriginDataPath = [cacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", message.message_id]];
            chatContentModel.videoIsDownload = GJCFFileRead(chatContentModel.videoOriginDataPath);
            
            if (GJCFFileIsExist(chatContentModel.videoOriginCoverImageCachePath)) {
                NSData *imageData = [NSData dataWithContentsOfFile:chatContentModel.videoOriginCoverImageCachePath];
                chatContentModel.messageContentImage = [UIImage imageWithData:imageData];
            }
        }
            break;
        case GJGCChatFriendContentTypeGif:{
            chatContentModel.contentType = GJGCChatFriendContentTypeGif;
            type = chatContentModel.contentType;
        }
            break;
        case GJGCChatFriendContentTypeStatusTip:{
            chatContentModel.contentType = GJGCChatFriendContentTypeStatusTip;
            type = chatContentModel.contentType;
            //        message.ext1 = @{@"type":@"redpackge",
            //                         @"hashid":repackNotict.hashid};
            if ([message.ext1 isKindOfClass:[NSDictionary class]]) {
                NSString *type = [message.ext1 valueForKey:@"type"];
                if ([type isEqualToString:@"redpackge"]) {
                    if (GJCFStringIsNull(message.content)) {
                        return GJGCChatFriendContentTypeNotFound;
                    }
                    NSString *tipMessage = message.content;
                    chatContentModel.typeString = @"redpackge";
                    chatContentModel.statusIcon = @"luckybag";
                    chatContentModel.statusMessageString = [GJGCChatSystemNotiCellStyle formateRedbagTipWithSenderName:[[LKUserCenter shareCenter] currentLoginUser].username garbName:tipMessage];
                    chatContentModel.hashID = [message.ext1 valueForKey:@"hashid"];
                } else if ([type isEqualToString:@"addressnotify"]) {
                    chatContentModel.typeString = @"addressnotify";
                    chatContentModel.statusMessageString = [GJGCChatSystemNotiCellStyle formateAddressNotify:[[message.ext1 valueForKey:@"amount"] longLongValue]];
                    chatContentModel.hashID = [message.ext1 valueForKey:@"txId"];
                } else if ([type isEqualToString:@"groupreviewed"] ||
                           [type isEqualToString:@"groupdismiss"]) {
                    chatContentModel.statusMessageString = [GJGCChatSystemNotiCellStyle formateTipStringWithTipMessage:[message.ext1 valueForKey:@"message"]];
                } else if ([type isEqualToString:@"phonebind"]) {
                    chatContentModel.statusMessageString = [GJGCChatSystemNotiCellStyle formateTipStringWithTipMessage:[NSString stringWithFormat:LMLocalizedString(@"Chat Your Connect ID will no longer be linked with mobile number", nil), message.content]];
                }
            } else {
                
                if (GJCFStringIsNull(message.content)) {
                    return GJGCChatFriendContentTypeNotFound;
                }
                NSString *tipMessage = message.content;
                int category = [message.ext1 intValue];
                switch (category) {
                    case 2: {
                        if ([SessionManager sharedManager].talkType == GJGCChatFriendTalkTypePostSystem) {
                            chatContentModel.statusMessageString = [GJGCChatSystemNotiCellStyle formateRedbagTipWithSenderName:LMLocalizedString(@"Wallet Connect term", nil) garbName:[[LKUserCenter shareCenter] currentLoginUser].normalShowName];
                            chatContentModel.statusIcon = @"luckybag";
                        } else {
                            NSArray *temA = [tipMessage componentsSeparatedByString:@"/"];
                            if (temA.count == 2) {
                                NSString *senderAddress = [temA firstObject];
                                NSString *reciverAddress = [temA lastObject];
                                NSString *garbName = nil;
                                NSString *senderName = nil;
                                switch ([SessionManager sharedManager].talkType) {
                                    case GJGCChatFriendTalkTypePrivate: {
                                        //reciver is self
                                        if ([reciverAddress isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                                            garbName = LMLocalizedString(@"Chat You", nil);
                                            senderName = user.normalShowName;
                                        }
                                        //sender is self
                                        if ([senderAddress isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                                            senderName = LMLocalizedString(@"Chat You", nil);
                                            garbName = user.normalShowName;
                                        }
                                    }
                                        break;
                                    case GJGCChatFriendTalkTypeGroup: {
                                        for (AccountInfo *groupMember in group.groupMembers) {
                                            //sender is self
                                            if ([senderAddress isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                                                senderName = LMLocalizedString(@"Chat You", nil);
                                            } else {
                                                if ([groupMember.address isEqualToString:senderAddress]) {
                                                    senderName = groupMember.normalShowName;
                                                }
                                            }
                                            //reciver is self
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
                                        senderName = LMLocalizedString(@"Connect term", nil);
                                    }
                                        break;
                                    default:
                                        break;
                                }
                                chatContentModel.statusMessageString = [GJGCChatSystemNotiCellStyle formateRedbagTipWithSenderName:senderName garbName:garbName];
                                chatContentModel.statusIcon = @"luckybag";
                            }
                        }
                    }
                        break;
                    case 3:
                    case 5:
                    case 6: {
                        NSArray *temA = [tipMessage componentsSeparatedByString:@"/"];
                        if (temA.count == 2) { //reference socket tpe:5 extension :9
                            NSString *payName = nil;
                            NSString *reciverName = nil;
                            NSString *payAddress = [temA lastObject];
                            NSString *reciverAddress = [temA firstObject];
                            switch ([SessionManager sharedManager].talkType) {
                                case GJGCChatFriendTalkTypePrivate: {

                                    if ([payAddress isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                                        payName = LMLocalizedString(@"Chat You", nil);
                                        reciverName = user.normalShowName;
                                    }

                                    if ([reciverAddress isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                                        reciverName = LMLocalizedString(@"Chat You", nil);
                                        payName = user.normalShowName;
                                    }
                                    chatContentModel.statusMessageString = [GJGCChatSystemNotiCellStyle formateReceiptTipWithPayName:payName receiptName:reciverName isCrowding:NO];
                                }
                                    break;
                                case GJGCChatFriendTalkTypeGroup: {
                                    for (AccountInfo *groupMember in group.groupMembers) {

                                        if ([payAddress isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                                            payName = LMLocalizedString(@"Chat You", nil);
                                        } else {
                                            if ([groupMember.address isEqualToString:payAddress]) {
                                                payName = groupMember.normalShowName;
                                            }
                                        }

                                        if ([reciverAddress isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                                            reciverName = LMLocalizedString(@"Chat You", nil);
                                        } else {
                                            if ([groupMember.address isEqualToString:reciverAddress]) {
                                                reciverName = groupMember.normalShowName;
                                            }
                                        }
                                    }
                                    chatContentModel.statusMessageString = [GJGCChatSystemNotiCellStyle formateReceiptTipWithPayName:payName receiptName:reciverName isCrowding:YES];
                                }
                                    break;
                                default:
                                    break;
                            }
                        } else {
                            NSMutableAttributedString *tipMessageText = [[NSMutableAttributedString alloc] initWithString:tipMessage];
                            [tipMessageText addAttribute:NSFontAttributeName
                                                   value:[UIFont systemFontOfSize:FONT_SIZE(22)]
                                                   range:NSMakeRange(0, tipMessage.length)];
                            [tipMessageText addAttribute:NSForegroundColorAttributeName
                                                   value:LMAssociateTextColor
                                                   range:NSMakeRange(0, tipMessage.length)];
                            chatContentModel.statusMessageString = tipMessageText;
                        }
                    }
                        break;
                        
                    default: {
                        NSMutableAttributedString *tipMessageText = [[NSMutableAttributedString alloc] initWithString:tipMessage];
                        [tipMessageText addAttribute:NSFontAttributeName
                                               value:[UIFont systemFontOfSize:FONT_SIZE(22)]
                                               range:NSMakeRange(0, tipMessage.length)];
                        [tipMessageText addAttribute:NSForegroundColorAttributeName
                                               value:LMAssociateTextColor
                                               range:NSMakeRange(0, tipMessage.length)];
                        chatContentModel.statusMessageString = tipMessageText;
                    }
                        break;
                }
            }
        }
            break;
        case GJGCChatInviteNewMemberTip:{
            chatContentModel.contentType = GJGCChatFriendContentTypeStatusTip;
            if (message.ext && [message.ext isKindOfClass:[NSDictionary class]]) {
                type = chatContentModel.contentType;
                NSString *inviter = [message.ext valueForKey:@"inviter"];
                NSString *welcomeTip = [message.ext valueForKey:@"message"];
                message.content = [NSString stringWithFormat:LMLocalizedString(@"Link invited to the group chat", nil), inviter, welcomeTip];
                NSString *tipMessage = message.content;
                NSMutableAttributedString *tipMessageText = [[NSMutableAttributedString alloc] initWithString:tipMessage];
                [tipMessageText addAttribute:NSFontAttributeName
                                       value:[UIFont systemFontOfSize:FONT_SIZE(22)]
                                       range:NSMakeRange(0, tipMessage.length)];
                [tipMessageText addAttribute:NSForegroundColorAttributeName
                                       value:LMAssociateTextColor
                                       range:NSMakeRange(0, tipMessage.length)];
                chatContentModel.statusMessageString = tipMessageText;
                chatContentModel.statusIcon = message.ext1;
            } else {
                type = GJGCChatFriendContentTypeNotFound;
            }
        }
            break;
        case GJGCChatFriendContentTypeNoRelationShipTip:{
            chatContentModel.contentType = GJGCChatFriendContentTypeNoRelationShipTip;
            type = chatContentModel.contentType;
        }
            break;
            
        default:
            break;
    }
    return type;
}

@end
