//
//  LMMessageExtendManager.h
//  Connect
//
//  Created by Connect on 2017/4/14.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "BaseDB.h"

@interface LMMessageExtendManager : BaseDB

+ (LMMessageExtendManager *)sharedManager;

+ (void)tearDown;

/**
 * Save the message extension of the transaction, the array, the array inside the dictionary
 * @param array
 */
- (void)saveBitchMessageExtend:(NSArray *)array;

/**
 * Save message extension transactions, dictionary
 * @param dic
 */
- (void)saveBitchMessageExtendDict:(NSDictionary *)dic;

/**
 * To change the status of a transaction based on the message extension
 * @param status
 * @param hashId
 */
- (void)updateMessageExtendStatus:(int)status withHashId:(NSString *)hashId;

/**
 * According to the message extension transaction, to change the payCount
 * @param payCount
 * @param hashId
 */
- (void)updateMessageExtendPayCount:(int)payCount withHashId:(NSString *)hashId;

/**
 * Change the payCount and status according to the message extension transaction
 * @param payCount
 * @param status
 * @param hashId
 */
- (void)updateMessageExtendPayCount:(int)payCount status:(int)status withHashId:(NSString *)hashId;

/**
 * Judge the existence of transaction ID
 * @param hashId
 * @return
 */
- (BOOL)isExisetWithHashId:(NSString *)hashId;

/**
 * Judge transaction ID, get status
 * @param hashId
 * @return
 */
- (int)getStatus:(NSString *)hashId;

/**
 * According to the transaction ID, get payCount
 * @param hashId
 * @return
 */
- (int)getPayCount:(NSString *)hashId;

/**
 * get message id
 * @param hashId
 * @return
 */
- (NSString *)getMessageId:(NSString *)hashId;
@end
