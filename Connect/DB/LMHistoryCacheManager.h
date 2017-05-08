//
//  LMHistoryCacheManager.h
//  Connect
//
//  Created by MoHuilin on 2017/1/18.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMHistoryCacheManager : NSObject

+ (instancetype)sharedManager;

/**
 * contact register phone number
 * @param data
 */
- (void)cacheRegisterContacts:(NSData *)data;

- (NSData *)getRegisterContactsCache;

/**
 * luckypackage history
 * @param data
 */
- (void)cacheRedbagContacts:(NSData *)data;

- (NSData *)getRedbagContactsCache;

/**
 * transfer history
 * @param data
 */
- (void)cacheTransferContacts:(NSData *)data;

- (NSData *)getTransferContactsCache;

/**
 * persson transfer history
 * @param data
 */
- (void)cachePersonTransferContacts:(NSData *)data;

- (NSData *)getPersonTransferContactsCache;

/**
 * all transfer history
 * @param data
 */
- (void)cachePublicFinaincContacts:(NSData *)data;

- (NSData *)getPublicFinaincContactsCache;

/**
 *
 * @param data
 */
- (void)cacheOutContacts:(NSData *)data;

- (NSData *)getOutContactsCache;

/**
 * notification contacts
 * @param data
 */
- (void)cacheNotificatedContacts:(NSData *)data;

- (NSData *)getNotificatedContact;

/**
 * imserver ip
 * @param ip
 */
- (void)cacheIP:(NSString *)ip;

- (NSString *)getSocketIPCache;

/**
 * db pass
 * @return
 */
- (NSString *)cacheDBPassSaltData;

- (NSString *)getDBPassword;

/**
 * recent tranfer user address
 * @param address
 */
- (void)cacheTransferHistoryWith:(NSString *)address;

- (NSArray *)getTransferHistory;


/**
 * login user chatcookie 5 count
 * @param chatCookie
 */
- (void)cacheChatCookie:(ChatCacheCookie *)chatCookie;

- (ChatCacheCookie *)getChatCookieWithSaltVer:(NSData *)ver;

/**
 * cacheLeastChatCookie
 * @param chatCookie
 */
- (void)cacheLeastChatCookie:(ChatCookieData *)chatCookie;

- (ChatCookieData *)getLeastChatCookie;

@end
