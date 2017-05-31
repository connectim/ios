/*                                                                            
  Copyright (c) 2016-2016, Connect
    All rights reserved.
*/

#import <Foundation/Foundation.h>
#import "Message.h"
#import "TCPConnection.h"
#import "MMMessage.h"
#import "Protofile.pbobjc.h"
#import "LMSocketHandleDelegate.h"
#import "LMCommandManager.h"
#import "LMMessageSendManager.h"


@interface UploadChatCookieModel : NSObject

@property (nonatomic ,strong) ChatCookieData *chatCookieData;
@property (nonatomic ,strong) ChatCacheCookie *chatCookie;
@property (nonatomic ,strong) SendMessageModel *sendMessageModel;

@end

@interface IMService : TCPConnection

@property(nonatomic, copy) NSString *deviceToken;
@property(nonatomic, copy) void (^RegisterDeviceTokenComplete)(NSString *deviceToken);

+ (IMService *)instance;

/**
 * set friend info
 * @param address
 * @param remark
 * @param commonContact
 * @param complete
 */
- (void)setFriendInfoWithAddress:(NSString *)address remark:(NSString *)remark commonContact:(BOOL)commonContact comlete:(SendCommandCallback)complete;

/**
 * delete friend
 * @param address
 * @param complete
 */
- (void)deleteFriendWithAddress:(NSString *)address comlete:(SendCommandCallback)complete;

/**
 * add new friend
 * @param inviteUser
 * @param tips
 * @param source
 * @param complete
 */
- (void)addNewFiendWithInviteUser:(AccountInfo *)inviteUser tips:(NSString *)tips source:(int)source comlete:(SendCommandCallback)complete;


/**
 * recive outer transfer
 * @param token
 * @param complete
 */
- (void)reciveMoneyWihtToken:(NSString *)token complete:(SendCommandCallback)complete;

/**
 * open outer luckypackage
 * @param token
 * @param complete
 */
- (void)openRedPacketWihtToken:(NSString *)token complete:(SendCommandCallback)complete;

/**
 * Get all contacts from the server,
 * including common contacts and common group information
 * @param version
 * @param complete
 */
- (void)getFriendsWithVersion:(NSString *)version comlete:(SendCommandCallback)complete;

/**
 * sync contacts
 * @param complete
 */
- (void)syncFriendsWithComlete:(SendCommandCallback)complete;

/**
 * Accept an invitation for a new friend
 * @param address
 * @param source
 * @param complete
 */
- (void)acceptAddRequestWithAddress:(NSString *)address
                             source:(int)source
                            comlete:(SendCommandCallback)complete;

/**
 * get chat user random chat cookie ,Session encryption
 * @param chatUser
 * @param complete
 */
- (void)getUserCookieWihtChatUser:(AccountInfo *)chatUser complete:(SendCommandCallback)complete;

/**
 * sync number of unread messages
 * @param badgeNumber
 */
- (void)syncBadgeNumber:(NSInteger)badgeNumber;

/**
 * send create group info ,
 * When the group is created successfully, the group information is sent to each user
 * @param msg
 * @return
 */
- (BOOL)asyncSendGroupInfo:(MessagePost *)msg;

/**
 * Send messages asynchronously to friends
 * @param message
 * @param sendMessageQueue
 * @param completion
 * @param sendMessageStatusQueue
 * @return
 */
- (MessagePost *)asyncSendMessageMessage:(MMMessage *)message
                                 onQueue:(dispatch_queue_t)sendMessageQueue
                              completion:(void (^)(MMMessage *message,
                                      NSError *error))completion
                                 onQueue:(dispatch_queue_t)sendMessageStatusQueue;


/**
 * send message read ack
 * snap chat
 * @param message
 * @param sendMessageQueue
 * @param completion
 * @param sendMessageStatusQueue
 * @return
 */
- (MessagePost *)asyncSendMessageReadAck:(MMMessage *)message
                                 onQueue:(dispatch_queue_t)sendMessageQueue
                              completion:(void (^)(MMMessage *message,
                                      NSError *error))completion
                                 onQueue:(dispatch_queue_t)sendMessageStatusQueue;


/**
 * async send group message
 * @param message
 * @param ecdhKey
 * @param sendMessageQueue
 * @param completion
 * @param sendMessageStatusQueue
 * @return
 */
- (MessagePost *)asyncSendGroupMessage:(MMMessage *)message
                      withGroupEckhKey:(NSString *)ecdhKey
                               onQueue:(dispatch_queue_t)sendMessageQueue
                            completion:(void (^)(MMMessage *message,
                                    NSError *error))completion
                               onQueue:(dispatch_queue_t)sendMessageStatusQueue;


/**
 * async send system message
 * send message to Connect term
 * @param message
 * @param completion
 */
- (void)asyncSendSystemMessage:(MMMessage *)message
                    completion:(void (^)(MMMessage *message,
                            NSError *error))completion;


/**
 * set someone not interest
 * @param address
 * @param complete
 */
- (void)setRecommandUserNoInterestAdress:(NSString *)address
                                 comlete:(SendCommandCallback)complete;

/**
 * when user logout , you need unbind device token
 * @param deviceToken
 * @param complete
 */
- (void)unBindDeviceTokenWithDeviceToken:(NSString *)deviceToken complete:(SendCommandCallback)complete;

#pragma mark - Session

/**
 * add new session
 * @param address
 * @param complete
 */
- (void)addNewSessionWithAddress:(NSString *)address complete:(SendCommandCallback)complete;

/**
 * update session
 * @param address
 * @param mute
 * @param complete
 */
- (void)openOrCloseSesionMuteWithAddress:(NSString *)address mute:(BOOL)mute complete:(SendCommandCallback)complete;

/**
 * delete session
 * @param address
 * @param complete
 */
- (void)deleteSessionWithAddress:(NSString *)address complete:(SendCommandCallback)complete;

/**
 * upload login suer chat cookie
 */
- (void)uploadCookieDuetoLocalChatCookieNotMatchServerChatCookieWithMessageCallModel:(SendMessageModel *)callModel;

/**
 * send offlien message ack ,use when get offline message
 * @param messageid
 * @param type
 */
- (void)sendOfflineAck:(NSString *)messageid type:(int)type;

/**
 * send online ack
 * @param msgID
 * @param type
 */
- (void)sendOnlineBackAck:(NSString *)msgID type:(int)type;

/**
 * send online ack type:defalut 0
 * @param msgID
 */
- (void)sendIMBackAck:(NSString *)msgID;

@end

