//
//  GJGCChatDetailDataSourceManager.h
//  Connect
//
//  Created by KivenLin on 14-11-3.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GJGCChatBaseConstans.h"
#import "GJGCChatBaseCell.h"
#import "GJGCChatSystemNotiModel.h"
#import "GJGCChatFriendConstans.h"
#import "GJGCChatFriendContentModel.h"
#import "GJGCChatContentBaseModel.h"
#import "GJGCChatSystemNotiCellStyle.h"
#import "GJGCChatFriendCellStyle.h"
#import "GJGCChatFriendContentModel.h"
#import "GJGCChatFriendTalkModel.h"
#import "MessageDBManager.h"
#import "UserDBManager.h"
#import "GroupDBManager.h"
#import "MMMessage.h"


@class GJGCChatDetailDataSourceManager;

@protocol GJGCChatDetailDataSourceManagerDelegate <NSObject>

@optional

- (void)dataSourceManagerInsertNewMessagesReloadTableView:(GJGCChatDetailDataSourceManager *)dataManager;

- (void)dataSourceManagerSnapChatUpdateListTable:(GJGCChatDetailDataSourceManager *)dataManager;

- (void)dataSourceManagerSnapChatUpdateListTable:(GJGCChatDetailDataSourceManager *)dataManager scrollToBottom:(BOOL)scrollToBottom;

- (void)dataSourceManagerRequireUpdateListTable:(GJGCChatDetailDataSourceManager *)dataManager;

- (void)dataSourceManagerEnterSnapChat:(GJGCChatDetailDataSourceManager *)dataManager;

- (void)dataSourceManagerCloseSnapChat:(GJGCChatDetailDataSourceManager *)dataManager;

- (void)dataSourceManagerRequireUpdateListTable:(GJGCChatDetailDataSourceManager *)dataManager reloadAtIndex:(NSInteger)index;

- (void)dataSourceManagerRequireUpdateListTable:(GJGCChatDetailDataSourceManager *)dataManager reloadIndexPaths:(NSArray *)indexPaths;


- (void)dataSourceManagerRequireUpdateListTable:(GJGCChatDetailDataSourceManager *)dataManager reloadForUpdateMsgStateAtIndex:(NSInteger)index;

- (void)dataSourceManagerRequireUpdateListTable:(GJGCChatDetailDataSourceManager *)dataManager insertWithIndex:(NSInteger)index;

- (void)dataSourceManagerRequireTriggleLoadMore:(GJGCChatDetailDataSourceManager *)dataManager;

- (void)dataSourceManagerRequireFinishLoadMore:(GJGCChatDetailDataSourceManager *)dataManager;

- (void)dataSourceManagerRequireFinishRefresh:(GJGCChatDetailDataSourceManager *)dataManager;

- (void)dataSourceManagerUpdateUploadprogress:(GJGCChatDetailDataSourceManager *)dataManager progress:(float)progress index:(NSInteger)index;

- (void)dataSourceManagerRequireDeleteMessages:(GJGCChatDetailDataSourceManager *)dataManager deletePaths:(NSArray *)paths;

- (void)dataSourceManagerRequireDeleteMessages:(GJGCChatDetailDataSourceManager *)dataManager deletePaths:(NSArray *)paths deleteModels:(NSArray *)models;

- (void)dataSourceManagerRequireDeleteMessages:(GJGCChatDetailDataSourceManager *)dataManager deleteIndex:(NSInteger)index;

- (void)dataSourceManagerRequireDeleteMessages:(GJGCChatDetailDataSourceManager *)dataManager dict:(NSDictionary *)dict;

- (void)dataSourceManagerRequireUpdateListTable:(GJGCChatDetailDataSourceManager *)dataManager insertIndexPaths:(NSArray *)indexPaths;

- (void):(GJGCChatDetailDataSourceManager *)dataManager

state: (BOOL)enable;

- (void)dataSourceManagerRequireAutoPlayNextAudioAtIndex:(NSInteger)index;

- (void)dataSourceManagerDidRecievedChatContent:(GJGCChatFriendContentModel *)chatContent;

@end

@interface GJGCChatDetailDataSourceManager : NSObject

@property(nonatomic, strong) dispatch_queue_t insertIndexPathsQueue; //message indexpath queue

@property(nonatomic, readonly) NSString *uniqueIdentifier;

@property(nonatomic, weak) id <GJGCChatDetailDataSourceManagerDelegate> delegate;

@property(nonatomic, strong) NSString *title;

@property(nonatomic, strong) NSMutableArray *chatListArray;

@property(nonatomic, strong) NSMutableArray *orginMessageListArray; //Message array for communication between users

@property(nonatomic, strong) NSMutableArray *timeShowSubArray;

@property(nonatomic, readonly) GJGCChatFriendTalkModel *taklInfo;

@property(nonatomic, assign) BOOL isFinishFirstHistoryLoad;

@property(nonatomic, assign) BOOL isFinishLoadAllHistoryMsg;

@property(nonatomic, assign) BOOL isLoadingMore; //Are you loading more data? Stop countdown refresh: open refresh


@property(nonatomic, copy) void (^ReadedMessageBlock)(NSString *messageid);

@property(nonatomic, strong) dispatch_queue_t updateMessageInfoQueue;

@property(nonatomic, strong) NSArray *ignoreMessageTypes; //Need to ignore the type of burn after reading

@property(nonatomic, strong) CADisplayLink *snapChatDisplayLink;
@property(nonatomic, strong) NSMutableArray *snapMessageContents;//Burn the message array

/**
 *  Security tips for the first session
 */
- (void)showfirstChatSecureTipWithTime:(long long)time;

/*
   lucky packge tips
 */
- (void)showGetRedBagMessageWithWithMessage:(MMMessage *)msg;

/**
 * crowding complete tips
 */
- (void)showCrowdingCompleteMessage;

/** 
  Who pays for all your bills
 */
- (void)showReceiptMessageMessageWithPayName:(NSString *)payName receiptName:(NSString *)receiptName isCrowd:(BOOL)isCrowd;

/**
 *  Update countdown schedule
 */
- (void)updateMessageReadState:(MMMessage *)theMessage;

- (void)removeUpdateMessageReadState;

- (void)openSnapMessageCounterState:(GJGCChatFriendContentModel *)findContent;

- (void)readedMessageAndCountTime:(MMMessage *)message;

- (void)readedAckWithMessageid:(NSString *)message_id;

- (void)viewControllerWillDisMissToCheckSendingMessageSaveSendStateFail;

/**
 *  Time interval control of transmitting messages
 */
@property(nonatomic, assign) NSInteger sendTimeLimit;

/**
 *  Time of last message
 */
@property(nonatomic, assign) long long lastSendMsgTime;

/**
 *  The first message is msgId
 */
@property(nonatomic, copy) NSString *lastFirstLocalMsgId;

- (instancetype)initWithTalk:(GJGCChatFriendTalkModel *)talk withDelegate:(id <GJGCChatDetailDataSourceManagerDelegate>)aDelegate;

- (NSInteger)totalCount;

- (NSInteger)chatContentTotalCount;

- (Class)contentCellAtIndex:(NSInteger)index;

- (NSString *)contentCellIdentifierAtIndex:(NSInteger)index;

- (GJGCChatContentBaseModel *)contentModelAtIndex:(NSInteger)index;

- (NSInteger)getContentModelIndexByDownloadTaskIdentifier:(NSString *)downloadTaskIdentifier;

- (GJGCChatFriendContentModel *)getContentModelByDownloadTaskIdentifier:(NSString *)downloadTaskIdentifier;

- (NSArray *)heightForContentModel:(GJGCChatContentBaseModel *)contentModel;

- (CGFloat)rowHeightAtIndex:(NSInteger)index;

/**
 *  Update the data source object and affect the height of the data source
 *
 *  @param contentModel
 *  @param index
 */
- (NSNumber *)updateContentModel:(GJGCChatContentBaseModel *)contentModel atIndex:(NSInteger)index;

/**
 *  Updates some values of the data source object, but does not affect the height of the data source
 *
 *  @param contentModel
 *  @param index
 */
- (void)updateContentModelValuesNotEffectRowHeight:(GJGCChatContentBaseModel *)contentModel atIndex:(NSInteger)index;

/**
 *  Add a message model
 *
 *  @param contentModel
 *
 *  @return
 */
- (NSNumber *)addChatContentModel:(GJGCChatContentBaseModel *)contentModel;

- (void)removeChatContentModelAtIndex:(NSInteger)index;

- (void)resortAllChatContentBySendTime;

- (void)resortAllSystemNotiContentBySendTime;

- (void)resetFirstAndLastMsgId;

- (void)readLastMessagesFromDB;

- (void)updateAllMsgTimeShowString;

- (GJGCChatContentBaseModel *)updateTheNewMsgTimeString:(GJGCChatContentBaseModel *)contentModel;

- (NSString *)updateMsgContentTimeStringAtDeleteIndex:(NSInteger)index;

- (void)removeContentModelByIdentifier:(NSString *)identifier;

- (void)removeTimeSubByIdentifier:(NSString *)identifier;

- (NSInteger)getContentModelIndexByLocalMsgId:(NSString *)msgId;

- (GJGCChatContentBaseModel *)contentModelByMsgId:(NSString *)msgId;

- (MMMessage *)messageByMessageId:(NSString *)msgID;

- (NSArray *)deleteMessageAtIndex:(NSInteger)index;

- (void)trigglePullHistoryMsgForEarly;

@property(nonatomic, strong) NSMutableArray *sendingMessages; //正在发送的消息


- (void)pushAddMoreMsg:(NSArray *)array;

/**
 *  Update session last message
 *
 *  @param contentModel 
 */
- (void)updateLastMsg:(GJGCChatFriendContentModel *)contentModel;

- (void)updateLastMsgForRecentTalk;

- (void)updateLastSystemMessageForRecentTalk;

#pragma mark - Add data to the data monitoring process, requiring UI refresh

- (void)insertNewMessageWithStartIndex:(NSInteger)startIndex Count:(NSInteger)count;

/**
 *  Clear early history
 */
- (void)clearOverEarlyMessage;

/**
 *  take history messages
 *
 *  @return
 */
- (NSArray *)reTryGetLocalMessageWhileHistoryMessageIsSubMessagesOfLocalMessages;

- (GJGCChatFriendContentType)formateChatFriendContent:(GJGCChatFriendContentModel *)chatContentModel withMsgModel:(MMMessage *)msgModel;

- (GJGCChatFriendContentModel *)addMMMessage:(ChatMessageInfo *)aMessage;

- (BOOL)sendMesssage:(GJGCChatFriendContentModel *)messageContent;

- (void)sendMesssages:(NSArray *)messageContents;

/**
 *  Resend a message
 *
 *  @param theMessage
 */
- (void)reSendMesssage:(GJGCChatFriendContentModel *)messageContent;


/** 
 *  Resend the message being sent
 */
- (void)reSendUnSendingMessages;

/**
 *  Open burn after reading
 */
- (void)openSnapChatModeWithTime:(int)time;


- (void)enterSnapchatMode;

/**
 *  Burn after reading
 */
- (void)closeSnapChatMode;

/**
 *  Session ecdh updated successfully tips
 */
- (void)showEcdhKeyUpdataMessageWithSuccess:(BOOL)success;

@end
