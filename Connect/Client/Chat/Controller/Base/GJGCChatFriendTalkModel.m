//
//  GJGCChatFriendTalkModel.m
//  Connect
//
//  Created by KivenLin on 14-11-24.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJGCChatFriendTalkModel.h"

@implementation GJGCChatFriendTalkModel

- (NSString *)fileDocumentName {
    if (self.talkType == GJGCChatFriendTalkTypeGroup) {
        _fileDocumentName = self.chatIdendifier;
    } else {
        _fileDocumentName = self.chatUser.address;
    }
    return _fileDocumentName;
}

- (NSString *)group_ecdhKey {
    if (!_group_ecdhKey) {
        _group_ecdhKey = self.chatGroupInfo.groupEcdhKey;
    }
    return _group_ecdhKey;
}

@end
