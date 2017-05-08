//
//  MessageDBManager.h
//  Connect
//
//  Created by MoHuilin on 16/7/29.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseDB.h"
#import "ChatMessageInfo.h"

#define MessageTable @"t_message"

@interface MessageDBManager : BaseDB

+ (MessageDBManager *)sharedManager;

+ (void)tearDown;

/**
 * delete all contact all messages
 * @param messageOwer
 */
- (void)deleteAllMessageByMessageOwer:(NSString *)messageOwer;

/**
 * delete all messages
 */
- (void)deleteAllMessages;

/**
 * save new message
 * @param messageInfo
 */
- (void)saveMessage:(ChatMessageInfo *)messageInfo;

/**
 * save batch messages
 * @param messages
 */
- (void)saveBitchMessage:(NSArray *)messages;

/**
 * create transaction messsage
 * @param user
 * @param hashId
 * @param money
 * @return
 */
- (MMMessage *)createTransactionMessageWithUserInfo:(AccountInfo *)user hashId:(NSString *)hashId monney:(NSString *)money;

/**
 * create transaction messsage
 * @param ower
 * @param hashId
 * @param money
 * @param isOutTransfer  is out transfer ?
 * @return
 */
- (MMMessage *)createSendtoOtherTransactionMessageWithMessageOwer:(AccountInfo *)ower hashId:(NSString *)hashId monney:(NSString *)money isOutTransfer:(BOOL)isOutTransfer;

/**
 * create transaction message
 * @param messageOwer
 * @param hashId
 * @param money
 * @param isOutTransfer
 * @return
 */
- (MMMessage *)createSendtoMyselfTransactionMessageWithMessageOwer:(AccountInfo *)messageOwer hashId:(NSString *)hashId monney:(NSString *)money isOutTransfer:(BOOL)isOutTransfer;

/**
 * get contact message count
 * @param messageOwer
 * @return
 */
- (long long int)messageCountWithMessageOwer:(NSString *)messageOwer;


/**
 * updata message send status
 * @param sendStatus
 * @param messageId
 * @param messageOwer
 */
- (void)updateMessageSendStatus:(GJGCChatFriendSendMessageStatus)sendStatus withMessageId:(NSString *)messageId messageOwer:(NSString *)messageOwer;

/**
 * delete message
 * @param messageId
 * @param messageOwer
 * @return
 */
- (BOOL)deleteMessageByMessageId:(NSString *)messageId messageOwer:(NSString *)messageOwer;

/**
 * delete snap chat message
 * @param messageOwer
 */
- (void)deleteSnapOutTimeMessageByMessageOwer:(NSString *)messageOwer;

/**
 * updatea message
 * @param messageInfo
 */
- (void)updataMessage:(ChatMessageInfo *)messageInfo;

/**
 * updatea message read time
 * @param messageId
 * @param messageOwer
 */
- (void)updateMessageReadTimeWithMsgID:(NSString *)messageId messageOwer:(NSString *)messageOwer;

/**
 * update audio message read state
 * @param messageId
 * @param messageOwer
 */
- (void)updateAudioMessageWithMsgID:(NSString *)messageId messageOwer:(NSString *)messageOwer;

/**
 * update audio message read state ,is readed complete
 * @param messageId
 * @param messageOwer
 */
- (void)updateAudioMessageReadCompleteWithMsgID:(NSString *)messageId messageOwer:(NSString *)messageOwer;

/**
 * query message read time
 * @param messageId
 * @param messageOwer
 * @return
 */
- (NSInteger)getReadTimeByMessageId:(NSString *)messageId messageOwer:(NSString *)messageOwer;

/**
 * get message
 * @param messageid
 * @param messageOwer
 * @return
 */
- (ChatMessageInfo *)getMessageInfoByMessageid:(NSString *)messageid messageOwer:(NSString *)messageOwer;

/**
 * get contact all message
 * @param messageOwer
 * @return
 */
- (NSArray *)getAllMessagesWithMessageOwer:(NSString *)messageOwer;

/**
 * query messages before time
 * @param messageOwer
 * @param limit
 * @param time
 * @param autoMsgid
 * @return
 */
- (NSArray *)getMessagesWithMessageOwer:(NSString *)messageOwer Limit:(int)limit beforeTime:(long long int)time messageAutoID:(NSInteger)autoMsgid;

/**
 * query messages before time
 * @param messageOwer
 * @param limit
 * @param time
 * @param autoMsgid
 * @return
 */
- (NSArray *)getMessagesWithMessageOwer:(NSString *)messageOwer Limit:(int)limit beforeTime:(long long int)time;

/**
 * check message si exists
 * @param messageId
 * @param messageOwer
 * @return
 */
- (BOOL)isMessageIsExistWithMessageId:(NSString *)messageId messageOwer:(NSString *)messageOwer;

/**
 * updata message time
 * @param ower
 * @param messageId
 */
- (void)updateMessageTimeWithMessageOwer:(NSString *)ower messageId:(NSString *)messageId;

@end
