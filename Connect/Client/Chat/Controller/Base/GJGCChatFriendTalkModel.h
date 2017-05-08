//
//  GJGCChatFriendTalkModel.h
//  Connect
//
//  Created by KivenLin on 14-11-24.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GJGCChatFriendContentModel.h"
#import "LMTransferInfo.h"
#import "RecentChatModel.h"
#import "LMGroupInfo.h"

@interface GJGCChatFriendTalkModel : NSObject

@property(nonatomic, strong) NSString *headUrl;

@property(nonatomic, strong) NSString *name;

@property(nonatomic, strong) NSString *chatIdendifier;

//chat object model user/group
@property(nonatomic, strong) AccountInfo *chatUser;
@property(nonatomic, strong) LMGroupInfo *chatGroupInfo;

//group ecdh
@property(nonatomic, copy) NSString *group_ecdhKey;

@property(nonatomic, assign) GJGCChatFriendTalkType talkType;

@property(nonatomic, assign) int snapChatOutDataTime;

//path of rich message file user:address group:groupid
@property (nonatomic ,copy) NSString *fileDocumentName;

+ (NSString *)talkTypeString:(GJGCChatFriendTalkType)talkType;

@end
