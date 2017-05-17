//
//  LMMessageSendManager.h
//  Connect
//
//  Created by MoHuilin on 2017/5/16.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMMessage.h"
#import "Protofile.pbobjc.h"

typedef void(^SendMessageCallBlock)(MMMessage *message, NSError *error);

@interface SendMessageModel : NSObject

@property (nonatomic ,strong) MMMessage *sendMsg;
@property (nonatomic ,assign) long long sendTime;
@property (nonatomic ,copy) SendMessageCallBlock callBack;

@end

@interface LMMessageSendManager : NSObject

+ (instancetype)sharedManager;

- (void)addSendingMessage:(MMMessage *)message callBack:(SendMessageCallBlock)callBack;

- (void)messageSendSuccessMessageId:(NSString *)messageId;

- (void)messageSendFailedMessageId:(NSString *)messageId;

- (void)messageRejectedMessage:(RejectMessage *)rejectMsg;

@end
