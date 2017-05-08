//
//  SetGlobalHandler.h
//  Connect
//
//  Created by MoHuilin on 16/7/26.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

@class LMGroupInfo;

@interface SetGlobalHandler : NSObject

/**
 *  Initialize the default settings
 */
+ (void)defaultSet;

/**
 *  add to blacklist
 */

+ (void)addToBlackListWithAddress:(NSString *)userAddress;

/**
 *  remove black list
 */
+ (void)removeBlackListWithAddress:(NSString *)userAddress;

/**
 *  Blacklist
 */

+ (void)blackListDownComplete:(void (^)(NSArray *blackList))complete;

/**
 *  Add a common contact
 */

+ (void)addToCommonContactListWithAddress:(NSString *)userAddress remark:(NSString *)remark;

/**
 *  Remove common contacts
 */
+ (void)removeCommonContactListWithAddress:(NSString *)userAddress remark:(NSString *)remark;;

/**
   * Add a new label
   *
   * @param tag
 */
+ (void)addNewTag:(NSString *)tag withAddress:(NSString*)address;

/**
   * Remove the label
   *
   * @param tag
 */
+ (void)removeTag:(NSString *)tag;

/**
   * Download the label
   *
   * @param complete
 */
+ (void)tagListDownCompelete:(void (^)(NSArray *tags))complete;

/**
   * Set friends to a label
   *
   * @param address
   * @param tag
 */
+ (void)setUserAddress:(NSString *)address ToTag:(NSString *)tag;

/**
   * Remove friends to a label
   *
   * @param address
   * @param tag
 */
+ (void)removeUserAddress:(NSString *)address formTag:(NSString *)tag;
/**
   * Remove a tag that has a friend already exists
   *
   * @param address
   * @param tag
 */
+ (void)removeUserHaveAddress:(NSString *)address formTag:(NSString *)tag;


/**
   * Tags under the user
   *
   * @param tag
   * @param complete
 */
+ (void)tag:(NSString *)tag downUsers:(void (^)(NSArray *users))complete;
/**
   * User under the label
   *
   * @param tag
   * @param complete
 */
+ (void)Userstag:(NSString *)address downTags:(void(^)(NSArray* tags))complete;
/**
   * Top chat
   *
   * @param chatIdentifer
 */
+ (void)topChatWithChatIdentifer:(NSString *)chatIdentifer;

/**
   * cancle Top chat
   *
   * @param chatIdentifer
 */
+ (void)CancelTopChatWithChatIdentifer:(NSString *)chatIdentifer;

/**
 *  Whether it is Zhiding
 *
 */
+ (BOOL)chatIsTop:(NSString *)chatIdentifer;



#pragma mark - Message scrambling

/**
 *  Message scrambling
 *
 *  @param publickey
 *
 *  @return
 */
+ (BOOL)friendChatMuteStatusWithPublickey:(NSString *)publickey;

+ (void)GroupChatSetMuteWithIdentifer:(NSString *)groupid mute:(BOOL)mute complete:(void (^)(NSError *erro))complete;

/**
   * Group personal nickname
   *
   * @param groupid group of groupid
 */
+ (void)updateGroupMynameWithIdentifer:(NSString *)groupid myName:(NSString *)myName complete:(void (^)(NSError *erro))complete;

/**
   * Do not disturb the state
   *
   * @param groupid group of groupid
   *
   * @return
 */
+ (BOOL)GroupChatMuteStatusWithIdentifer:(NSString *)groupid;

#pragma mark - group set

+ (void)downGroupEcdhKeyWithGroupIdentifier:(NSString *)groupid  complete:(void (^)(NSString *groupKey,NSError *error))complete;

+ (void)uploadGroupEcdhKey:(NSString *)groupEcdhKey groupIdentifier:(NSString *)groupid;

/**
   * Exit group
   *
   * @param groupid
   * @param complete
 */
+ (void)quitGroupWithIdentifer:(NSString *)groupid complete:(void (^)(NSError *erro))complete;

+ (void)downGroupInfoWithGroupIdentifer:(NSString *)identifer complete:(void (^)(NSError *error))complete;

+ (void)downBackupInfoWithGroupIdentifier:(NSString *)groupid  complete:(void (^)(NSString *groupKey,NSError *error))complete;

/**
   * Save your address book
   *
   * @param groupid
 */
+ (void)setCommonContactGroupWithIdentifer:(NSString *)groupid complete:(void (^)(NSError *error))complete;
/**
 *  Remove contacts
 *
 *  @param groupid
 */
+ (void)removeCommonContactGroupWithIdentifer:(NSString *)groupid complete:(void (^)(NSError *error))complete;

/**
   * privacy setting
   *
   * @param address is added via address
   * @param phone is added via phone number
   * @param verify whether you need to add validation
   * @param syncPhone whether to synchronize phone contacts
   * @param syncPhone whether to allow friends list to find me
 */
+ (void)privacySetAllowSearchAddress:(BOOL)address AllowSearchPhone:(BOOL)phone needVerify:(BOOL)verify syncPhonebook:(BOOL)syncPhone findMe:(BOOL)findMe;

/**
 *  Synchronize privacy settings
 */
+ (void)syncPrivacyComplete:(void(^)())complete;


/**
   * Synchronize user base information
   *
   * @param address
 */
+ (void)syncUserBaseInfoWithAddress:(NSString *)address complete:(void (^)(AccountInfo *user))complete;

/**
   * Payment settings
   *
   * @param nopass whether a password is required
   * @param payPass to pay the password
   * @ Param fee
 */
+ (void)setPaySetNoPass:(BOOL)nopass payPass:(NSString *)payPass fee:(long long)fee compete:(void(^)(BOOL result))complete;
+ (void)setpayPass:(NSString *)payPass compete:(void(^)(BOOL result))complete;
+ (void)syncPaypinversionWithComplete:(void(^)(NSString *password,NSError *error))complete;
+ (void)getPaySetComplete:(void (^)(NSError *erro))complete;


#pragma mark - user

/**
   * Synchronous address book
   *
   * @param contacts
   * @param complete
 */
+ (void)syncPhoneContactWithHashContact:(NSMutableArray *)contacts complete:(void (^)(NSTimeInterval time))complete;

+ (void)getGroupInfoWihtIdentifier:(NSString *)identifier complete:(void (^)(LMGroupInfo *groupInfo ,NSError *error))complete;

@end
