//
//  GJGCChatFirendBaseCell.h
//  Connect
//
//  Created by KivenLin on 14-11-10.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJGCChatBaseCell.h"
#import "GJGCChatFriendContentModel.h"
#import "DACircularProgressView.h"

#define simpleContentDiffHeight 8
#define simpleContentDiffWidth 7

#define BubbleLeftRight AUTO_WIDTH(18)
#define BubbleContentBottomMargin (GJCFSystemiPhone5?AUTO_HEIGHT(10):AUTO_HEIGHT(2))
#define BubbleLeftRightMargin AUTO_WIDTH(20)
#define ImageIconInnerMargin AUTO_WIDTH(20)


@interface GJGCChatFriendBaseCell : GJGCChatBaseCell

@property(nonatomic, strong) GJGCCommonHeadView *headView;

@property(nonatomic, strong) UIImageView *bubbleBackImageView;

@property(nonatomic, strong) GJCFCoreTextContentView *timeLabel;

@property(nonatomic, strong) GJCFCoreTextContentView *nameLabel;

@property(nonatomic, assign) CGFloat contentBordMargin;

@property(nonatomic, assign) BOOL isFromSelf;

@property(nonatomic, strong) UIButton *statusButton;
@property(nonatomic, strong) UIActivityIndicatorView *indicatorView;

@property(nonatomic, assign) GJGCChatFriendSendMessageStatus sendStatus;

@property(nonatomic, assign) CGFloat statusButtonOffsetAudioDuration;

@property(nonatomic, assign) BOOL isGroupChat;

@property(nonatomic, assign) NSInteger faildType;

@property(nonatomic, strong) NSString *faildReason;

@property(nonatomic, assign) GJGCChatFriendTalkType talkType;

@property(nonatomic, assign) GJGCChatFriendContentType contentType;

@property(nonatomic, assign) BOOL isSnapChatMode;

@property(nonatomic, assign) GJGCChatFriendMessageReadState readState;

@property(nonatomic, strong) UIImageView *sexIconView;

@property(nonatomic, strong) DACircularProgressView *snapChatTimeoutProgressView;

@property(nonatomic, strong) GJGCChatContentBaseModel *contentModel;


- (void)adjustContent;

- (NSArray *)myAudioPlayIndicatorImages;

- (NSArray *)otherAudioPlayIndicatorImages;

- (void)startSendingAnimation;

- (void)successSendingAnimation;

- (void)faildSendingAnimation;

- (void)faildWithType:(NSInteger)faildType andReason:(NSString *)reason;

- (void)goToShowLongPressMenu:(UILongPressGestureRecognizer *)sender;

- (void)copyContent:(UIMenuItem *)item;

- (void)deleteMessage:(UIMenuItem *)item;

- (void)retweetMessage:(UIMenuItem *)item;

- (void)reSendMessage;

- (void)snapMessageTimeCount:(NSTimer *)sender;

- (void)setUploadProgress:(float)progress;

- (void)downloadProgress:(float)progress;

- (void)updateMessageUploadStatus;

- (void)updateSnapChatProgress;

@end
