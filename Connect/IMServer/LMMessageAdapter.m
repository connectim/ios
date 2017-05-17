//
//  LMMessageAdapter.m
//  Connect
//
//  Created by MoHuilin on 2017/5/16.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMMessageAdapter.h"
#import "StringTool.h"
#import "ConnectTool.h"
#import "GroupDBManager.h"

@implementation LMMessageAdapter

+ (GPBMessage *)sendAdapterIMPostWithMessage:(MMMessage *)message talkType:(GJGCChatFriendTalkType)talkType ecdhKey:(NSString *)ecdhKey {
    if (!message) {
        return nil;
    }

    NSString *messageString = [message mj_JSONString];

    switch (talkType) {
        case GJGCChatFriendTalkTypePrivate: {
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
            messagePost.pubKey = [LKUserCenter shareCenter].currentLoginUser.pub_key;
            messagePost.msgData = messageData;
            messagePost.sign = sign;

            return messagePost;
        }
            break;

        case GJGCChatFriendTalkTypeGroup: {
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
            messagePost.pubKey = [LKUserCenter shareCenter].currentLoginUser.pub_key;
            messagePost.msgData = messageData;

            return messagePost;
        }
            break;

        case GJGCChatFriendTalkTypePostSystem: {
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

            IMTransferData *imTransferData = [ConnectTool createTransferWithEcdhKey:[ServerCenter shareCenter].extensionPass data:msMessage.data aad:nil];

            return imTransferData;
        }
            break;
        default:
            break;
    }

    return nil;
}

+ (MessagePost *)sendAdapterIMReadAckPostWithMessage:(MMMessage *)message {

    if (!message) {
        return nil;
    }

    NSString *messageString = [message mj_JSONString];
    GcmData *userToUserData = [ConnectTool createGcmWithData:messageString publickey:message.publicKey needEmptySalt:YES];
    MessageData *messageData = [[MessageData alloc] init];
    messageData.cipherData = userToUserData;
    messageData.receiverAddress = message.user_id;
    messageData.msgId = message.message_id;
    messageData.typ = message.type;

    NSString *sign = [ConnectTool signWithData:messageData.data];
    MessagePost *messagePost = [[MessagePost alloc] init];
    messagePost.pubKey = [LKUserCenter shareCenter].currentLoginUser.pub_key;
    messagePost.msgData = messageData;
    messagePost.sign = sign;

    return messagePost;
}

@end
