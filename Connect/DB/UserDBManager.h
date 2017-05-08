//
//  UserDBManager.h
//  Connect
//
//  Created by MoHuilin on 16/7/29.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseDB.h"
#import "AccountInfo.h"

@interface UserDBManager : BaseDB


+ (UserDBManager *)sharedManager;

+ (void)tearDown;

/**
 * save user
 * @param user
 */
- (void)saveUser:(AccountInfo *)user;

/**
 * batch save users
 * @param users
 */
- (void)batchSaveUsers:(NSArray *)users;

/**
 * delete user
 * @param pubKey
 */
- (void)deleteUserBypubkey:(NSString *)pubKey;

/**
 * delete user
 * @param address
 */
- (void)deleteUserByAddress:(NSString *)address;

/**
 * upadate user avatar and username
 * @param user
 */
- (void)updateUserNameAndAvatar:(AccountInfo *)user;

/**
 * update contact remark or common
 * @param commonContact
 * @param remark
 * @param address
 */
- (void)setUserCommonContact:(BOOL)commonContact AndSetNewRemark:(NSString *)remark withAddress:(NSString *)address;

/**
 * query user
 * @param publickey
 * @return
 */
- (AccountInfo *)getUserByPublickey:(NSString *)publickey;

/**
 * query user
 * @param address
 * @return
 */
- (AccountInfo *)getUserByAddress:(NSString *)address;


/**
 * query user pubkey
 * @param address
 * @return
 */
- (NSString *)getUserPubkeyByAddress:(NSString *)address;

/**
 * query all users
 * @return
 */
- (NSArray *)getAllUsers;

/**
 * async query all users
 * @param complete
 */
- (void)getAllUsersWithComplete:(void (^)(NSArray *))complete;


/**
 * async query all users not comtain system contact
 * @param complete
 */
- (void)getAllUsersNoConnectWithComplete:(void (^)(NSArray *))complete;


/**
 * check is my friend
 * @param address
 * @return
 */
- (BOOL)isFriendByAddress:(NSString *)address;


/**
 * get request tips
 * @param publickey
 * @return
 */
- (NSString *)getRequestTipsByUserPublickey:(NSString *)publickey;

/**
 * get friend request status
 * @param address
 * @return
 */
- (RequestFriendStatus)getFriendRequestStatusByAddress:(NSString *)address;

/**
 * get request create time
 * @param publickey
 * @return
 */
- (long int)getRequestTimeByUserPublickey:(NSString *)publickey;

/**
 * get all new friend request
 * @return
 */
- (NSArray *)getAllNewFirendRequest;

/**
 * get friend request
 * @param address
 * @return
 */
- (AccountInfo *)getFriendRequestBy:(NSString *)address;

/**
 * delete friend request
 * @param address
 */
- (void)deleteRequestUserByAddress:(NSString *)address;

/**
 * save new friend request
 * @param user
 */
- (void)saveNewFriend:(AccountInfo *)user;

/**
 * update friend request status
 * @param address
 * @param status
 */
- (void)updateNewFriendStatusAddress:(NSString *)address withStatus:(int)status;

/**
 * get user tags
 * @param address
 * @return
 */
- (NSArray *)getUserTags:(NSString *)address;

/**
 * get all user under tag
 * @param tag
 * @return
 */
- (NSArray *)getTagUsers:(NSString *)tag;

/**
 * query login user all tags
 * @return
 */
- (NSArray *)tagList;

/**
 * add tag
 * @param tag
 * @return
 */
- (BOOL)saveTag:(NSString *)tag;

/**
 * remove login user tag
 * @param tag
 * @return
 */
- (BOOL)removeTag:(NSString *)tag;

/**
 * set user to tag
 * @param address
 * @param tag
 * @return
 */
- (BOOL)saveAddress:(NSString *)address toTag:(NSString *)tag;

/**
 * remove user from tag
 * @param address
 * @param tag
 * @return
 */
- (BOOL)removeAddress:(NSString *)address fromTag:(NSString *)tag;

/**
 * get blocked list
 * @return
 */
- (NSArray *)blackManList;

/**
 * add user to blocked list
 * @param address
 */
- (void)addUserToBlackListWithAddress:(NSString *)address;

/**
 * remove user from blocked list
 * @param address
 */
- (void)removeUserFromBlackList:(NSString *)address;

/**
 * check user is blocked
 * @param address
 * @return
 */
- (BOOL)userIsInBlackList:(NSString *)address;


@end
