//
//  GJGCChatFriendAudioMessageCell.h
//  Connect
//
//  Created by KivenLin on 14-11-5.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJGCChatFriendBaseCell.h"

@interface GJGCChatFriendAudioMessageCell : GJGCChatFriendBaseCell

@property(nonatomic, strong) UIImageView *audioPlayIndicatorView;

@property(nonatomic, strong) GJCFCoreTextContentView *audioTimeLabel;

@property(nonatomic, assign) CGFloat contentInnerMargin;

@property(nonatomic, strong) UIImageView *isAudioPlayTagView;

- (void)finishPlayAudioAction;

- (void)playAudioAction;

- (void)startDownloadAction;

- (void)faildDownloadAction;

- (void)successDownloadAction;


@end
