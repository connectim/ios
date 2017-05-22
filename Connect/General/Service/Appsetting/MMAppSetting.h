//
//  MMAppSetting.h
//  XChat
//
//  Created by MoHuilin on 16/2/16.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AccountInfo.h"

@interface MMAppSetting : NSObject

@property (nonatomic ,copy) NSString *privkey;

+ (MMAppSetting *)sharedSetting;

- (void)deleteLocalUserWithAddress:(NSString *)address;

/**
 * Delete the login user information
 */
- (void)deleteLoginUser;
/**
 * Get the login user private key
 */
- (NSString *)getLoginUserPrivkey;
/**
 *  Save the user private key
 */
- (void)saveLoginUserPrivkey:(NSString *)privkey;

// Login user address access
- (NSString *)getLoginAddress;
- (BOOL)haveLoginAddress;
- (void )saveLoginAddress:(NSString *)address;
#pragma mark - A user's preference data
/**
 *  Save the address book number
 *
 *  @param
 */
- (void)saveContactVersion:(NSString *)version;
/**
 *  Get the address book version number
 *
 *  @return
 */
- (NSString *)getContactVersion;



#pragma mark - privacy setting
- (void)setAllowAddress;
- (void)setDelyAddress;
- (BOOL)isAllowAddress;

- (void)setAllowPhone;
- (void)setDelyPhone;
- (BOOL)isAllowPhone;

- (void)setNeedVerfiy;
- (void)setDelyVerfiy;
- (BOOL)isAllowVerfiy;

- (void)setAutoSysBook;
- (void)setNoAutoSysBook;
- (BOOL)isAutoSysBook;

- (NSTimeInterval)getLastSyncContactTime;
- (void)setLastSyncContactTime;
- (void)removeLastSyncContactTime;


#pragma mark - Save the login user to keychain

- (void)updataUserLashLoginTime:(NSString *)address;
- (AccountInfo *)getLoginChainUsersByEncodePri:(NSString *)encodePri;

- (AccountInfo *)getLoginChainUsersByKey:(NSString *)key;

- (void)saveUserAnduploadLoginTimeToKeyChain:(AccountInfo *)user;
- (void)saveUserToKeyChain:(AccountInfo *)user;

- (void)deleteKeyChainUser;

- (NSArray *)getKeyChainUsers;

- (void)deleteKeyChainUserWithUser:(AccountInfo *)user;

#pragma mark - gesture pass
- (void)openGesturePassWithPass:(NSString *)pass;
- (BOOL)haveGesturePass;
- (void)cancelGestursPass;
- (BOOL)vertifyGesturePass:(NSString *)pass;

- (void)setLastErroGestureTime:(NSTimeInterval)time;
- (NSTimeInterval)getLastErroGestureTime;
- (void)removeLastErroGestureTime;

#pragma mark - touch id pay
-(BOOL)isDeviceSupportFingerPay;
- (void)setFingerPay;
- (void)cacelFingerPay;
- (BOOL)needFingerPay;

#pragma mark - Free payment
- (void)setNoPassPay;
- (void)cacelNoPassPay;
- (BOOL)isCanNoPassPay;

#pragma mark - Transfer fee
- (void)setTransferFee:(NSString *)fee;
- (void)removeTransfer;
- (long long)getTranferFee;

- (void)setMaxTransferFee:(NSString *)fee;
- (void)removeMaxTransfer;
- (long long)getMaxTranferFee;

#pragma mark - pay pass
- (void)setPayPass:(NSString *)pass;
- (void)removePayPass;
- (NSString *)getPayPass;
- (void)setpaypassVersion:(NSString *)version;
- (NSString *)getpaypassVersion;


#pragma mark - Whether the user tags are synchronized
- (void)haveSyncUserTags;
- (BOOL)isHaveSyncUserTags;
#pragma mark - Whether to synchronize privacy settings
- (void)haveSyncPrivacy;
- (BOOL)isHaveSyncPrivacy;

#pragma mark - Whether or not a registered address book has been obtained
- (void)haveSyncPhoneContactRegister;
- (BOOL)isHavePhoneContactRegister;

#pragma mark - Whether to synchronize the blacklist
- (void)haveSyncBlickMan;
- (BOOL)isHaveSyncBlickMan;

#pragma mark - Whether the payment setup data is synchronized
- (void)haveSyncPaySet;
- (BOOL)isHaveSyncPaySet;

#pragma mark - Whether to synchronize frequently used groups
- (void)haveSyncCommonGroup;
- (BOOL)isHaveCommonGroup;

#pragma mark - Need to be prompted to read after the description
- (void)setDontShowSnapchatTip;
- (BOOL)isDontShowSnapchatTip;

#pragma mark - Whether to synchronize the address Bo
- (void)haveSyncAddressbook;
- (BOOL)isHaveAddressbook;

#pragma mark - Does you synchronize the address Bo?
- (void)openVoiceNoti;
- (void)closeVoiceNoti;
- (BOOL)canVoiceNoti;

- (void)openVibrateNoti;
- (void)closeVibrateNoti;
- (BOOL)canVibrateNoti;

#pragma mark - recomand
- (void)setAllowRecomand;
- (void)setDelyRecomand;
- (BOOL)isAllowRecomand;
#pragma mark - Whether or not the method of obtaining the old group was executed
- (void)setGroupExecuted;
- (BOOL)isGroupExecuted;

#pragma mark - currency
- (void)setcurrency:(NSString *)currency;
- (NSString *)getcurrency;


#pragma mark - money blance
- (void)saveBalance:(long long int)balance;
- (long long int)getBalance;

#pragma mark - rate
- (void)saveRate:(float)rate;
- (double)getRate;
- (void)saveEstimatefee:(NSString *)estimatefee;
- (double)getEstimatefee;
- (BOOL)needReCacheEstimatefee;

- (void)setAutoCalculateTransactionFee:(BOOL)autoCalculate;
- (BOOL)canAutoCalculateTransactionFee;

@end
