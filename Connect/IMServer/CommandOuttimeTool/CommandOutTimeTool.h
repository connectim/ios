//
//  CommandOutTimeTool.h
//  Connect
//
//  Created by MoHuilin on 16/8/22.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.h"

typedef void (^CompleteBlock)(NSError *erro, id data);


@interface CommandCallbackModel : NSObject

@property(nonatomic, copy) CompleteBlock completeBlock;

@end

@interface CommandOutTimeTool : NSObject

+ (CommandOutTimeTool *)sharedManager;

- (void)resume;

- (void)suspend;

- (void)revert;

/**
 *  add command
 *
 *  @param msg
 */
- (void)addToSendConcurrentQueue:(Message *)msg complete:(CompleteBlock)coplete;

/**
 *  remove handled command
 *
 *  @param msg
 */
- (void)removeSuccessMessage:(Message *)msg;

/**
 *  get command
 *
 *  @param identifer
 *
 *  @return
 */
- (Message *)getMessageByIdentifer:(NSString *)identifer;

@property(nonatomic, strong) NSMutableDictionary *concurrentMsgCompleteBlockDict;

@end
