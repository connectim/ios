//
//  LMRecommandFriendManager.m
//  Connect
//
//  Created by Connect on 2017/4/13.
//  Copyright © 2017年 Connect. All rights reserved.


#import "BaseDB.h"

#define RecommandFriendTable @"t_recommand_friend"

@interface LMRecommandFriendManager : BaseDB

+ (LMRecommandFriendManager *)sharedManager;

+ (void)tearDown;

/**
 * delete all recomand data
 */
- (void)deleteAllRecommandFriend;

/**
 * delete recomand user by address
 * @param address
 */
- (void)deleteRecommandFriendWithAddress:(NSString *)address;

/**
 * save recomand users
 * @param friendArray
 */
- (void)saveRecommandFriend:(NSArray *)friendArray;

/**
 * Paging query
 * @param page
 * @return
 */
- (NSArray *)getRecommandFriendsWithPage:(int)page;

/**
 * check recommand user is saved
 * @param userInfo
 * @return
 */
- (BOOL)getUserInfoWith:(AccountInfo *)userInfo;

/**
 * check recommand user is saved
 * @param userInfo
 * @return
 */
- (BOOL)getUserInfoWithAddress:(NSString *)address;

/**
 * update recommand status
 * @param status
 * @param address
 */
- (void)updateRecommandFriendStatus:(int32_t)status withAddress:(NSString *)address;

/**
 * Paging query
 * @param page
 * @param status
 * @return
 */
- (NSArray *)getRecommandFriendsWithPage:(int)page withStatus:(int)status;

@end
