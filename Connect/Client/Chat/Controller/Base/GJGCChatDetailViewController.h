//
//  GJGCChatDetailViewController.h
//  Connect
//
//  Created by KivenLin on 14-10-17.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GJGCChatInputPanel.h"
#import "GJCFAudioPlayer.h"
#import "GJGCChatDetailDataSourceManager.h"
#import "GJGCChatBaseCellDelegate.h"
#import "GJCFFileDownloadManager.h"
#import "GJGCChatFriendTalkModel.h"
#import "GJGCRefreshHeaderView.h"
#import "GJGCRefreshFooterView.h"
#import "GJGCBaseViewController.h"
#import "UserDBManager.h"
#import "ChatPageTitleView.h"


@interface GJGCChatDetailViewController : GJGCBaseViewController <UITableViewDataSource, UITableViewDelegate, GJGCChatBaseCellDelegate, GJGCChatDetailDataSourceManagerDelegate, GJGCChatInputPanelDelegate> {
    UITextField *textField;
}

@property(nonatomic, strong) ChatPageTitleView *titleView;

@property(nonatomic, strong) GJGCRefreshHeaderView *refreshHeadView;

@property(nonatomic, strong) GJGCRefreshFooterView *refreshFootView;

@property(nonatomic, strong) GJGCChatInputPanel *inputPanel;

/**
  * display control
 */
@property(nonatomic, assign) BOOL willDisappear;
@property(nonatomic, assign) BOOL isKeyboardShowing;


@property(nonatomic, strong) GJCFAudioPlayer *audioPlayer;

@property(nonatomic, strong) GJGCChatDetailDataSourceManager *dataSourceManager;

@property(nonatomic, strong) UITableView *chatListTable;

@property(nonatomic, readonly) GJGCChatFriendTalkModel *taklInfo;

@property(nonatomic, strong) NSArray *visibleCells;

@property (nonatomic ,strong) NSMutableArray *noteGroupMembers;

//Downloading message array
@property(nonatomic, strong) NSMutableArray *downLoadingRichMessageIds;

- (instancetype)initWithTalkInfo:(GJGCChatFriendTalkModel *)talkModel;

/**
 *  reload data
 */
- (void)reloadData;

/**
 *  stop refresh
 */
- (void)stopRefresh;

/**
 *  stop load more
 */
- (void)stopLoadMore;

/**
 *  start refresh
 */
- (void)startRefresh;

/**
 *  stop load more
 */
- (void)startLoadMore;


- (void)triggleRefreshing;
- (void)triggleLoadingMore;

/*
 * stop audio paly
 */
- (void)stopPlayCurrentAudio;

#pragma mark - reserve keyboard

- (void)reserveChatInputPanelState;

#pragma mark - down rich message

/*
 * Preloading
 */
- (void)downloadRichtextWhenShowAtIndexPath:(NSIndexPath *)indexPath contentModel:(GJGCChatFriendContentModel *)contentModel;

/* 
 * rich_image
 */
- (void)downloadImageFile:(GJGCChatContentBaseModel *)contentModel forIndexPath:(NSIndexPath *)indexPath;

/*
 * cancle download
 */
- (void)cancelDownloadWithTaskIdentifier:(NSString *)taskIdentifier;

/**
 *  add download task
 *
 */
- (void)addDownloadTask:(GJCFFileDownloadTask *)task;

/**
 *  download complete
 *
 *  @param url
 *  @param fileData
 */
- (void)finishDownloadWithTask:(GJCFFileDownloadTask *)task withDownloadFileData:(NSData *)fileData localPath:(NSString *)localPath;

/**
 *  download progress
 *
 *  @param url
 *  @param progress
 */
- (void)downloadFileWithTask:(GJCFFileDownloadTask *)task progress:(CGFloat)progress;

/**
 *  download fail
 *
 *  @param url
 */
- (void)faildDownloadFileWithTask:(GJCFFileDownloadTask *)task;

/**
 *  init message data manager
 */
- (void)initDataManager;

/**
 *  claer early message
 */
- (void)clearAllEarlyMessage;

/**
 *  inpute text view text change callback
 */
- (void)inputTextChangeWithText:(NSString *)text;

@end
