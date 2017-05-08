//
//  GJGCChatFriendAndGroupConstans.h
//  Connect
//
//  Created by KivenLin on 14-11-5.
//  Copyright (c) 2014年 ConnectSoft. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, LMWalletlinkType) {
    LMWalletlinkTypeOuterPacket = 0,
    LMWalletlinkTypeOuterTransfer,
    LMWalletlinkTypeOuterCollection,
    LMWalletlinkTypeOuterOther,
};

/**
 *  Message type
 */
typedef NS_ENUM(NSUInteger, GJGCChatFriendContentType) {

    /**
     *  unknow
     */
            GJGCChatFriendContentTypeNotFound = 0,
    /**
     *  text
     */
            GJGCChatFriendContentTypeText = 1,
    /**
     *  audio
     */
            GJGCChatFriendContentTypeAudio = 2,
    /**
     *  photo
     */
            GJGCChatFriendContentTypeImage = 3,

    /**
     *  video
     */
            GJGCChatFriendContentTypeVideo = 4,
    /**
     *  gif
     */
            GJGCChatFriendContentTypeGif = 5,
    /**
     *  time cell
     */
            GJGCChatFriendContentTypeTime = 8,

    /**
     *  open or close snapchat
     */
            GJGCChatFriendContentTypeSnapChat = 11,

    /**
     *  read ack
     */
            GJGCChatFriendContentTypeSnapChatReadedAck = 12,

    /**
     *  receipt
     */
            GJGCChatFriendContentTypePayReceipt = 14,


    /**
     *  transfer
     */
            GJGCChatFriendContentTypeTransfer = 15,

    /**
     *  luckypackage
     */
            GJGCChatFriendContentTypeRedEnvelope = 16,

    /**
     *  location
     */
            GJGCChatFriendContentTypeMapLocation = 17,

    /**
     *  namecard
     */
            GJGCChatFriendContentTypeNameCard = 18,


    /**
     *  tip cell
     */
            GJGCChatFriendContentTypeStatusTip = 19,


    /**
     *  no relationship tip
     */
            GJGCChatFriendContentTypeNoRelationShipTip = 20,


    /**
     *  secure tip cell
     */
            GJGCChatFriendContentTypeSecureTip = 21,

    /**
     *  invite group member
     */
            GJGCChatInviteNewMemberTip = 22,


    /**
     *
     */
            GJGCChatInviteToGroup = 23,

    /**
     *  reviewd group
     */
            GJGCChatApplyToJoinGroup = 24,

    /**
     *  wallet link
     */
            GJGCChatWalletLink = 25,

    /**
     * Announcement
     */
            GJGCChatSystemGonggao = 101,
    GJGCChatSystemShenhe = 102,
};

#define GJGCContentTypeToString(contentType) [GJGCChatFriendConstans contentTypeToString:contentType]

@interface GJGCChatFriendConstans : NSObject

/**
 * Last content
 * @param type
 * @param textMessage
 * @return
 */
+ (NSString *)lastContentMessageWithType:(GJGCChatFriendContentType)type
                             textMessage:(NSString *)textMessage;

/**
 * last content
 * @param type
 * @param textMessage
 * @param senderUserName
 * @return
 */
+ (NSString *)lastContentMessageWithType:(GJGCChatFriendContentType)type
                             textMessage:(NSString *)textMessage
                          senderUserName:(NSString *)senderUserName;

+ (NSString *)identifierForContentType:(GJGCChatFriendContentType)contentType;

/**
 * get class by content type
 * @param contentType
 * @return
 */
+ (Class)classForContentType:(GJGCChatFriendContentType)contentType;

/**
 * message need notice
 * @param type
 * @return
 */
+ (BOOL)shouldNoticeWithType:(NSInteger)type;

@end
