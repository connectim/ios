//
//  RecentChatDBManager.h
//  Connect
//
//  Created by MoHuilin on 16/8/2.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseDB.h"
#import "RecentChatModel.h"

#define RecentChatTable @"t_conversion"
#define RecentChatTableSetting @"t_conversion_setting"

@interface RecentChatDBManager : BaseDB

+ (RecentChatDBManager *)sharedManager;

+ (void)tearDown;

#pragma mark -会话公开方法

/**
 * acync get all unread count
 * @param complete
 */
- (void)getAllUnReadCountWithComplete:(void (^)(int count))complete;

/**
 * update recent chat last time
 * @param identifer
 */
- (void)updataRecentChatLastTimeByIdentifer:(NSString *)identifer;

/**
 * get all recent chat
 * @return
 */
- (NSArray *)getAllRecentChat;

/**
 * async get all recent chat
 * @return
 */
- (void)getAllRecentChatWithComplete:(void (^)(NSArray *recentChats))complete;

/**
 * save new recent chat
 * @param model
 */
- (void)save:(RecentChatModel *)model;

/**
 * delete recent chat
 * @param identifier
 */
- (void)deleteByIdentifier:(NSString *)identifier;

/**
 * update unread count
 * @param unreadCount
 * @param idetifier
 */
- (void)updataUnReadCount:(int)unreadCount idetifier:(NSString *)idetifier;

/**
 * updata stranger status
 * @param unreadCount
 * @param idetifier
 */
- (void)updataStrangerStatus:(BOOL)stranger idetifier:(NSString *)idetifier;

/**
 * clear unread count
 * @param idetifier
 */
- (void)clearUnReadCountWithIdetifier:(NSString *)idetifier;

/**
 * query recent model by id
 * @param identifier
 * @return
 */
- (RecentChatModel *)getRecentModelByIdentifier:(NSString *)identifier;

/**
 * top recent chat
 * @param publiKeyOrGroupid
 */
- (void)topChat:(NSString *)publiKeyOrGroupid;

/**
 * remove top status
 * @param publiKeyOrGroupid
 */
- (void)removeTopChat:(NSString *)publiKeyOrGroupid;

- (BOOL)isTopChat:(NSString *)identifier;


/**
 * updata recent chat draft
 * @param draft
 * @param identifier
 */
- (void)updateDraft:(NSString *)draft withIdentifier:(NSString *)identifier;

/**
 * clear draft
 * @param identifier
 */
- (void)removeDraftWithIdentifier:(NSString *)identifier;


/**
 * get recent chat draft
 * @param identifier
 * @return
 */
- (NSString *)getDraftWithIdentifier:(NSString *)identifier;

/**
 * recent chat is top status
 * @param publiKeyOrGroupid
 * @return
 */
- (BOOL)isTopChat:(NSString *)publiKeyOrGroupid;

/**
 * updata custum field value
 * @param fieldsValues
 * @param identifier
 */
- (void)customUpdateRecentChatTableWithFieldsValues:(NSDictionary *)fieldsValues withIdentifier:(NSString *)identifier;

/**
 * set group chat @ me
 * @param identifer
 */
- (void)setGroupNoteMyselfWithIdentifer:(NSString *)identifer;

/**
 * clear group chat @ me
 * @param identifer
 */
- (void)clearGroupNoteMyselfWithIdentifer:(NSString *)identifer;

/**
 * set recent chat snap chat time
 * @param snapTime
 * @param identifier
 */
- (void)openOrCloseSnapChatWithTime:(int)snapTime chatIdentifer:(NSString *)identifier;

/**
 * set recent chat snap chat time
 * @param snapTime
 * @param identifier
 */
- (void)openSnapChatWithIdentifier:(NSString *)identifier snapTime:(int)snapTime openOrCloseByMyself:(BOOL)flag;

/**
 * set recent chat mute
 * @param identifer
 */
- (void)setMuteWithIdentifer:(NSString *)identifer;

/**
 * clear recent chat mute
 * @param identifer
 */
- (void)removeMuteWithIdentifer:(NSString *)identifer;

/**
 * query mute staute
 * @param identifer
 * @return
 */
- (BOOL)getMuteStatusWithIdentifer:(NSString *)identifer;


/**
 * create new chat whih id
 * @param identifier
 * @param groupChat
 * @param lastContentShowType
 * @param content
 * @param ecdhKey
 * @param name
 */
- (void)createNewChatWithIdentifier:(NSString *)identifier groupChat:(BOOL)groupChat lastContentShowType:(int)lastContentShowType lastContent:(NSString *)content ecdhKey:(NSString *)ecdhKey talkName:(NSString *)name;

/**
 * create new chat
 * @param identifier
 * @param groupChat
 * @param lastContentShowType
 * @param content
 * @return
 */
- (RecentChatModel *)createNewChatWithIdentifier:(NSString *)identifier groupChat:(BOOL)groupChat lastContentShowType:(int)lastContentShowType lastContent:(NSString *)content;


/**
 * create connect frist message
 * welcome back
 */
- (void)createConnectTermWelcomebackChatAndMessage;

/**
 * create stranger chat
 * @param user
 */
- (void)createNewChatNoRelationShipWihtRegisterUser:(AccountInfo *)user;

@end
