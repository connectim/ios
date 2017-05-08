//
//  GJGCChatFriendTalkModel.m
//  Connect
//
//  Created by KivenLin on 14-11-24.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJGCChatFriendTalkModel.h"

@implementation GJGCChatFriendTalkModel

- (NSString *)fileDocumentName{
    if (self.talkType == GJGCChatFriendTalkTypeGroup) {
        _fileDocumentName = self.chatIdendifier;
    } else {
        _fileDocumentName = self.chatUser.address;
    }
    return _fileDocumentName;
}

- (NSString *)group_ecdhKey{
    if (!_group_ecdhKey) {
        _group_ecdhKey = self.chatGroupInfo.groupEcdhKey;
    }
    return _group_ecdhKey;
}

+ (NSString *)talkTypeString:(GJGCChatFriendTalkType)talkType {
    NSString *msgType = nil;
    switch (talkType) {
        case GJGCChatFriendTalkTypeGroup: {
            msgType = @"group";
        }
            break;
        case GJGCChatFriendTalkTypePrivate: {
            msgType = @"private";
        }
            break;
        case GJGCChatFriendTalkTypePostSystem: {
            msgType = @"post_system";
        }
            break;
        default:
            break;
    }
    return msgType;
}

@end
