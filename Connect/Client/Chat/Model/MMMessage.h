//
//  MMMessage.h
//  Connect
//
//  Created by MoHuilin on 16/6/23.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GJGCChatFriendConstans.h"
#import "BaseInfo.h"
#import "GJGCChatContentBaseModel.h"


@interface MMMessage :BaseInfo


/*!
 @property
 @brief message type
 */
@property (nonatomic ,assign) GJGCChatFriendContentType type;

@property (nonatomic ,assign) BOOL isRead;

@property (nonatomic ,strong) id senderInfoExt;

/*!
 @property
 @brief accept message
 */
@property (nonatomic, copy) NSString *user_name; // should be username for now
@property (nonatomic ,copy) NSString *user_id;


/**
 * Image message width and height
 *
 *  @return
 */

@property (nonatomic ,assign) CGFloat imageOriginWidth;
@property (nonatomic ,assign) CGFloat imageOriginHeight;

/**
 *  Image message width and height
 */
@property (nonatomic ,copy) NSString *publicKey;

/*!
 @property
 @brief message id
 */
@property (nonatomic, copy) NSString *message_id;

/**
 *  message content
 */
@property (nonatomic ,copy) NSString *content;

/**
 *  photo url
 */
@property (nonatomic ,copy) NSString *url;


/*!
 @property
 @brief The time the message was sent or received
 */
@property (nonatomic) long long sendtime;


@property (nonatomic ,assign) int  size;

/*!
 @property
 @brief The chatter of the conversation object
 */
@property (nonatomic, strong) NSString *conversationChatter;

@property (nonatomic, assign) GJGCChatFriendSendMessageStatus sendstatus;

@property (nonatomic ,strong) id ext;

@property (nonatomic ,strong) id ext1;

@property (nonatomic ,strong) id locationExt;


@end
