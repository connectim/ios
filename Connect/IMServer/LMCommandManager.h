//
//  LMCommandManager.h
//  Connect
//
//  Created by MoHuilin on 2017/5/17.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.h"

typedef void (^SendCommandCallback)(NSError *error, id data);

@interface SendCommandModel : NSObject

@property(nonatomic, strong) Message *sendMsg;
@property(nonatomic, assign) long long sendTime;
@property(nonatomic, copy) SendCommandCallback callBack;

@end

@interface LMCommandManager : NSObject

+ (instancetype)sharedManager;

/**
 * add sending command message to queue
 * @param commandMsg
 * @param callBack
 */
- (void)addSendingMessage:(Message *)commandMsg callBack:(SendCommandCallback)callBack;

/**
 * get command ack,server handled and send ack back
 * @param callBackMsg
 */
- (void)sendCommandSuccessWithCallbackMsg:(Message *)callBackMsg;

/**
 * command send failed ,remove comand and callback
 * @param msgId
 */
- (void)sendCommandFailedWithMsgId:(NSString *)msgId;

/**
 * transaction statue change
 * like transaction confirm , stranger transfer ,payment etc...
 * @param msg
 */
- (void)transactionStatusChangeNoti:(Message *)msg;

@end
