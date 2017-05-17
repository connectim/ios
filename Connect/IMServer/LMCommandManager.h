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

- (void)addSendingMessage:(Message *)commandMsg callBack:(SendCommandCallback)callBack;

- (void)sendCommandSuccessWithCallbackMsg:(Message *)callBackMsg;

- (void)sendCommandFailedWithMsgId:(NSString *)msgId;

- (void)transactionStatusChangeNoti:(Message *)msg;

@end
