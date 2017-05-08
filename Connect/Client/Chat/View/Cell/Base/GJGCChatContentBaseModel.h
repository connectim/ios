//
//  GJGCChatContentBaseModel.h
//  Connect
//
//  Created by KivenLin on 14-11-3.
//  Copyright (c) 2014年 ConnectSoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GJGCChatBaseConstans.h"

typedef NS_ENUM(NSUInteger, GJGCChatFriendSendMessageStatus) {

    GJGCChatFriendSendMessageStatusFaild = 0,
    GJGCChatFriendSendMessageStatusSuccess = 1,
    GJGCChatFriendSendMessageStatusSending = 2,
    GJGCChatFriendSendMessageStatusSuccessUnArrive = 3,
    GJGCChatFriendSendMessageStatusFailByNoRelationShip = 4,
    GJGCChatFriendSendMessageStatusFailByNotInGroup = 5,

};

typedef NS_ENUM(NSUInteger, GJGCChatFriendTalkType) {

    GJGCChatFriendTalkTypePrivate = 0,
    GJGCChatFriendTalkTypeGroup,
    GJGCChatFriendTalkTypePostSystem,
};

typedef NS_ENUM(NSUInteger, GJGCChatFriendMessageReadState) {

    GJGCChatFriendMessageReadStateUnReaded = 0,
    GJGCChatFriendMessageReadStateReaded,
    GJGCChatFriendMessageReadStatePlayCompleted,//audio message read complete
};

@interface GJGCChatContentBaseModel : NSObject

@property(nonatomic, readonly) NSString *uniqueIdentifier;

@property(nonatomic, readwrite) NSInteger contentSourceIndex;

@property(nonatomic, assign) long long sendTime;

@property(nonatomic, assign) NSInteger autoMsgid;

@property(nonatomic, assign) BOOL isSnapChatMode;

@property(nonatomic, assign) long long snapTime;

@property(nonatomic, assign) GJGCChatFriendMessageReadState readState;

@property(nonatomic, assign) int long long readTime;

@property(nonatomic, assign) CGFloat snapProgress;

@property(nonatomic, assign) BOOL isReadedAck;

@property(nonatomic, assign) BOOL otherSnapHandAck;


@property(nonatomic, assign) BOOL isTimeSubModel;

@property(nonatomic, strong) NSString *timeSubIdentifier;

@property(nonatomic, assign) NSInteger timeSubMsgCount;

@property(nonatomic, strong) NSAttributedString *timeString;

@property(nonatomic, strong) NSAttributedString *snapChatTipString;

@property(nonatomic, strong) NSString *faildReason;

@property(nonatomic, assign) NSInteger faildType;

@property(nonatomic, assign) GJGCChatFriendTalkType talkType;

@property(nonatomic, copy) NSString *toId;

@property(nonatomic, strong) NSString *userName;

@property(nonatomic, strong) NSString *toAddress;

@property(nonatomic, copy) NSString *publicKey;

@property(nonatomic, strong) NSString *senderId;

@property(nonatomic, strong) NSString *sessionId;

@property(nonatomic, assign) GJGCChatBaseMessageType baseMessageType;

@property(nonatomic, assign) CGFloat contentHeight;

@property(nonatomic, assign) CGSize contentSize;

@property(nonatomic, strong) NSString *localMsgId;

@property(nonatomic, assign) GJGCChatFriendSendMessageStatus sendStatus;


@property(nonatomic, strong) NSAttributedString *statusMessageString;
@property(nonatomic, copy) NSString *statusIcon;

- (NSComparisonResult)compareContent:(GJGCChatContentBaseModel *)contentModel;

@end
