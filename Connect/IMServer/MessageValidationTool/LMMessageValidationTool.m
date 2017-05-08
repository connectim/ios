//
//  LMMessageValidationTool.m
//  Connect
//
//  Created by MoHuilin on 2016/12/29.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import "LMMessageValidationTool.h"
#import "MMMessage.h"

@implementation LMMessageValidationTool

+ (BOOL)checkMessageValidata:(MMMessage *)message messageType:(MessageType)msgType {

    if (!message) {
        return NO;
    }

    //General property check
    if (GJCFStringIsNull(message.message_id)) {
        return NO;
    }

    if (GJCFStringIsNull(message.publicKey)) {
        return NO;
    }

    if (GJCFStringIsNull(message.user_id)) {
        return NO;
    }


    if (message.ext && [message.ext isKindOfClass:[NSString class]]) {
        message.ext = [message.ext mj_JSONObject];
        if ([[message.ext allKeys] containsObject:@"luck_delete"]) {
            NSInteger snapChatTime = [[message.ext valueForKey:@"luck_delete"] integerValue];
            if (snapChatTime < 0) {
                return NO;
            }
        }
    }

    switch (msgType) {
        case MessageTypeGroup: {
            if ([message.senderInfoExt isKindOfClass:[NSString class]]) {
                message.senderInfoExt = [message.senderInfoExt mj_JSONObject];
            }

            if (![message.senderInfoExt isKindOfClass:[NSDictionary class]]) {
                return NO;
            }

            if (![[message.senderInfoExt allKeys] containsObject:@"username"] ||
                    ![[message.senderInfoExt allKeys] containsObject:@"avatar"] ||
                    ![[message.senderInfoExt allKeys] containsObject:@"address"]) {
                return NO;
            }
        }
            break;
        case MessageTypeSystem:
            return [self checkSystemMessage:message];
            break;
        default:
            break;
    }

    switch (message.type) {
        case GJGCChatFriendContentTypeGif:
        case GJGCChatFriendContentTypeText: {
            if (GJCFStringIsNull(message.content)) {
                return NO;
            }
            return YES;
        }
            break;
        case GJGCChatFriendContentTypeAudio: {
            if (message.size <= 0) {
                return NO;
            }
            if (GJCFStringIsNull(message.content)) {
                return NO;
            }

            return YES;
        }
            break;

        case GJGCChatFriendContentTypeImage: {
            if (message.imageOriginWidth <= 0 || message.imageOriginHeight <= 0) {
                return NO;
            }

            if (GJCFStringIsNull(message.content) || GJCFStringIsNull(message.url)) {
                return NO;
            }
            return YES;
        }
            break;

        case GJGCChatFriendContentTypeVideo: {

            if (GJCFStringIsNull(message.ext1)) { //video size
                return NO;
            }
            if (message.size <= 0) {
                return NO;
            }

            if (message.imageOriginWidth <= 0 || message.imageOriginHeight <= 0) {
                return NO;
            }

            if (GJCFStringIsNull(message.content) || GJCFStringIsNull(message.url)) {
                return NO;
            }

            return YES;
        }
            break;

        case GJGCChatFriendContentTypeSnapChat: {
            if ([message.content integerValue] < 0) {
                return NO;
            }
            return YES;
        }
            break;

        case GJGCChatFriendContentTypeSnapChatReadedAck: {
            if (GJCFStringIsNull(message.content)) {
                return NO;
            }
            return YES;
        }
            break;

        case GJGCChatFriendContentTypePayReceipt: {
            if (!message.ext1) {
                return NO;
            }

            if ([message.ext1 isKindOfClass:[NSString class]]) {
                message.ext1 = [message.ext1 mj_JSONObject];
            }
            if (![message.ext1 isKindOfClass:[NSDictionary class]]) {
                return NO;
            }

            if (![[message.ext1 allKeys] containsObject:@"totalMember"]) {
                return NO;
            }

            if (![[message.ext1 allKeys] containsObject:@"isCrowdfundRceipt"]) {
                return NO;
            }

            if ([[message.ext1 valueForKey:@"amount"] integerValue] <= 0) {
                return NO;
            }

            if (GJCFStringIsNull(message.content)) {
                return NO;
            }

            return YES;
        }
            break;

        case GJGCChatFriendContentTypeTransfer: {
            if ([message.ext1 isKindOfClass:[NSString class]]) {
                message.ext1 = [message.ext1 mj_JSONObject];
            }

            if (![message.ext1 isKindOfClass:[NSDictionary class]]) {
                return NO;
            }

            if ([[message.ext1 valueForKey:@"amount"] integerValue] <= 0) {
                return NO;
            }

            return YES;
        }
            break;

        case GJGCChatFriendContentTypeRedEnvelope: {
            if (GJCFStringIsNull(message.content)) { //not contain luckypackage hashid
                return NO;
            }
            if ([message.ext1 isKindOfClass:[NSString class]]) {
                id obj = [message.ext1 mj_JSONObject];
                if (obj) {
                    message.ext1 = obj;
                }
            }
            return YES;
        }
            break;

        case GJGCChatFriendContentTypeMapLocation: {
            if (GJCFStringIsNull(message.content)) {
                return NO;
            }

            if ([message.locationExt isKindOfClass:[NSString class]]) {
                message.locationExt = [message.locationExt mj_JSONObject];;
            }

            if (![[message.locationExt allKeys] containsObject:@"locationLongitude"] ||
                    ![[message.locationExt allKeys] containsObject:@"locationLatitude"] ||
                    ![[message.locationExt allKeys] containsObject:@"address"]) {
                return NO;
            }

            return YES;
        }
            break;
        case GJGCChatFriendContentTypeNameCard: {
            if ([message.ext1 isKindOfClass:[NSString class]]) {
                message.ext1 = [message.ext1 mj_JSONObject];
            }

            if (![message.ext1 isKindOfClass:[NSDictionary class]]) {
                return NO;
            }

            if (![[message.ext1 allKeys] containsObject:@"username"] ||
                    ![[message.ext1 allKeys] containsObject:@"avatar"] ||
                    ![[message.ext1 allKeys] containsObject:@"pub_key"] ||
                    ![[message.ext1 allKeys] containsObject:@"address"]) {
                return NO;
            }

            return YES;
        }
            break;
        case GJGCChatFriendContentTypeStatusTip: {
            if (GJCFStringIsNull(message.content) && !message.ext1) {
                return NO;
            }
            return YES;
        }
            break;

        case GJGCChatInviteToGroup: {
            if ([message.ext1 isKindOfClass:[NSString class]]) {
                message.ext1 = [message.ext1 mj_JSONObject];
            }

            if (![message.ext1 isKindOfClass:[NSDictionary class]]) {
                return NO;
            }

            if (![[message.ext1 allKeys] containsObject:@"avatar"] ||
                    ![[message.ext1 allKeys] containsObject:@"groupname"] ||
                    ![[message.ext1 allKeys] containsObject:@"inviteToken"] ||
                    ![[message.ext1 allKeys] containsObject:@"groupidentifier"]) {
                return NO;
            }

            return YES;
        }
            break;
        case GJGCChatApplyToJoinGroup: {
            if ([message.ext1 isKindOfClass:[NSString class]]) {
                message.ext1 = [message.ext1 mj_JSONObject];
            }

            if (![message.ext1 isKindOfClass:[NSDictionary class]]) {
                return NO;
            }

            if (![[message.ext1 allKeys] containsObject:@"username"] ||
                    ![[message.ext1 allKeys] containsObject:@"groupname"] ||
                    ![[message.ext1 allKeys] containsObject:@"groupidentifier"] ||
                    ![[message.ext1 allKeys] containsObject:@"verificationCode"] ||
                    ![[message.ext1 allKeys] containsObject:@"source"] ||
                    ![[message.ext1 allKeys] containsObject:@"username"] ||
                    ![[message.ext1 allKeys] containsObject:@"identifier"] ||
                    ![[message.ext1 allKeys] containsObject:@"avatar"] ||
                    ![[message.ext1 allKeys] containsObject:@"tips"]) {
                return NO;
            }
            return YES;
        }

        case GJGCChatInviteNewMemberTip: {
            if ([message.ext1 isKindOfClass:[NSString class]]) {
                message.ext1 = [message.ext1 mj_JSONObject];
            }

            if (![message.ext1 isKindOfClass:[NSDictionary class]]) {
                return NO;
            }

            if (![[message.ext1 allKeys] containsObject:@"inviter"] ||
                    ![[message.ext1 allKeys] containsObject:@"message"]) {
                return NO;
            }

            return YES;
        }
            break;
        case GJGCChatWalletLink: {
            if ([message.ext1 isKindOfClass:[NSString class]]) {
                message.ext1 = [message.ext1 mj_JSONObject];
            }

            if (![message.ext1 isKindOfClass:[NSDictionary class]]) {
                return NO;
            }

            if (GJCFStringIsNull(message.content)) {
                return NO;
            }

            if (![[message.ext1 allKeys] containsObject:@"linkTitle"] ||
                    ![[message.ext1 allKeys] containsObject:@"linkSubtitle"]) {
                return NO;
            }

            return YES;
        }
            break;

        default: //cant parse message
        {
            message.content = LMLocalizedString(@"Chat Message not parse upgrade version", nil);
            message.type = GJGCChatFriendContentTypeText;
            return YES;
        }
            break;
    }
    return NO;
}


+ (BOOL)checkSystemMessage:(MMMessage *)message {
    switch (message.type) {
        case GJGCChatFriendContentTypeText: {
            if (GJCFStringIsNull(message.content)) {
                return NO;
            }
            return YES;
        }
            break;
        case GJGCChatFriendContentTypeAudio: {
            if (message.size <= 0) {
                return NO;
            }
            if (GJCFStringIsNull(message.content)) {
                return NO;
            }

            return YES;
        }
            break;

        case GJGCChatFriendContentTypeImage: {
            if (message.imageOriginWidth <= 0 || message.imageOriginHeight <= 0) {
                return NO;
            }

            if (GJCFStringIsNull(message.content)) {
                return NO;
            }
            return YES;
        }
            break;

        case GJGCChatFriendContentTypeTransfer: {

            if ([message.ext1 isKindOfClass:[NSString class]]) {
                message.ext1 = [message.ext1 mj_JSONObject];
            }

            if (![message.ext1 isKindOfClass:[NSDictionary class]]) {
                return NO;
            }

            if ([[message.ext1 valueForKey:@"amount"] integerValue] <= 0) {
                return NO;
            }

            if (GJCFStringIsNull(message.content)) {
                return NO;
            }

            return YES;
        }
            break;

        case GJGCChatFriendContentTypeRedEnvelope: {
            if (GJCFStringIsNull(message.content)) {
                return NO;
            }
            return YES;
        }
            break;

        case GJGCChatFriendContentTypeStatusTip: {
            if (GJCFStringIsNull(message.content) && !message.ext1) {
                return NO;
            }
            return YES;
        }
            break;

        case GJGCChatApplyToJoinGroup: {
            if ([message.ext1 isKindOfClass:[NSString class]]) {
                message.ext1 = [message.ext1 mj_JSONObject];
            }

            if (![message.ext1 isKindOfClass:[NSDictionary class]]) {
                return NO;
            }

            if (![[message.ext1 allKeys] containsObject:@"username"] ||
                    ![[message.ext1 allKeys] containsObject:@"avatar"] ||
                    ![[message.ext1 allKeys] containsObject:@"pubKey"] ||
                    ![[message.ext1 allKeys] containsObject:@"identifier"] ||
                    ![[message.ext1 allKeys] containsObject:@"category"] ||
                    ![[message.ext1 allKeys] containsObject:@"tips"] ||
                    ![[message.ext1 allKeys] containsObject:@"verificationCode"] ||
                    ![[message.ext1 allKeys] containsObject:@"groupname"] ||
                    ![[message.ext1 allKeys] containsObject:@"source"]) {
                return NO;
            }

            return YES;
        }

        case 102: //annoncement
        {
            if ([message.ext1 isKindOfClass:[NSString class]]) {
                message.ext1 = [message.ext mj_JSONObject];
            }

            if (![message.ext1 isKindOfClass:[NSDictionary class]]) {
                return NO;
            }

            if (![[message.ext1 allKeys] containsObject:@"title"] ||
                    ![[message.ext1 allKeys] containsObject:@"content"] ||
                    ![[message.ext1 allKeys] containsObject:@"category"]) {
                return NO;
            }

            return YES;
        }
            break;

        default: {
            message.content = LMLocalizedString(@"Chat Message not parse upgrade version", nil);
            message.type = GJGCChatFriendContentTypeText;
            return YES;
        }
            break;
    }
    return NO;
}

@end
