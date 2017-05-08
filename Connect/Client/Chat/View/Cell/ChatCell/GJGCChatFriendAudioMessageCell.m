//
//  GJGCChatFriendAudioMessageCell.m
//  Connect
//
//  Created by KivenLin on 14-11-5.
//  Copyright (c) 2014年 ConnectSoft. All rights reserved.
//

#import "GJGCChatFriendAudioMessageCell.h"

@interface GJGCChatFriendAudioMessageCell ()

@property(nonatomic, strong) UIActivityIndicatorView *downLoadIndicatorView;

@end

@implementation GJGCChatFriendAudioMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {

        self.contentInnerMargin = 5.f;

        self.audioPlayIndicatorView = [[UIImageView alloc] init];
        self.audioPlayIndicatorView.gjcf_width = 17;
        self.audioPlayIndicatorView.gjcf_height = 19;
        [self.bubbleBackImageView addSubview:self.audioPlayIndicatorView];

        self.downLoadIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.downLoadIndicatorView.size = CGSizeMake(17, 17);
        self.downLoadIndicatorView.hidesWhenStopped = YES;
        [self.bubbleBackImageView addSubview:self.downLoadIndicatorView];

        self.audioTimeLabel = [[GJCFCoreTextContentView alloc] init];
        self.audioTimeLabel.gjcf_width = 100;
        self.audioTimeLabel.gjcf_height = 15;
        self.audioTimeLabel.contentBaseWidth = self.audioTimeLabel.gjcf_width;
        self.audioTimeLabel.contentBaseHeight = self.audioTimeLabel.gjcf_height;
        self.audioTimeLabel.backgroundColor = [UIColor clearColor];
        [self.bubbleBackImageView addSubview:self.audioTimeLabel];

        self.isAudioPlayTagView = [[UIImageView alloc] init];
        self.isAudioPlayTagView.gjcf_width = AUTO_WIDTH(18);
        self.isAudioPlayTagView.gjcf_height = AUTO_WIDTH(18);
        self.isAudioPlayTagView.image = GJCFQuickImage(@"audio_message_unread");
        [self.contentView addSubview:self.isAudioPlayTagView];
        self.isAudioPlayTagView.hidden = YES;


        //tap
        UITapGestureRecognizer *tapR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnSelf)];
        tapR.numberOfTapsRequired = 1;
        [self.bubbleBackImageView addGestureRecognizer:tapR];

        self.bubbleBackImageView.width = AUTO_WIDTH(200);
        self.bubbleBackImageView.height = AUTO_WIDTH(80);

    }
    return self;
}

- (void)setContentModel:(GJGCChatContentBaseModel *)contentModel {
    if (!contentModel) {
        return;
    }
    [super setContentModel:contentModel];

    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) contentModel;
    self.isFromSelf = chatContentModel.isFromSelf;

    self.audioTimeLabel.contentAttributedString = chatContentModel.audioDuration;
    self.audioTimeLabel.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:chatContentModel.audioDuration forBaseContentSize:self.audioTimeLabel.contentBaseSize];

    if (chatContentModel.isPlayingAudio) {
        [self playAudioAction];
    } else {
        [self finishPlayAudioAction];
    }

    if (chatContentModel.isDownloading) {
        [self startDownloadAction];
    } else if (chatContentModel.audioIsDownload) {
        [self successDownloadAction];
    } else {
        [self faildDownloadAction];
    }

    [self adjustContent];

    if (chatContentModel.isRead || self.isFromSelf) {
        self.isAudioPlayTagView.hidden = YES;
    } else {
        self.isAudioPlayTagView.hidden = NO;
    }

    self.audioTimeLabel.gjcf_rightToSuper = 20;
    self.statusButton.gjcf_right = self.bubbleBackImageView.gjcf_left - 5;
    self.audioPlayIndicatorView.image = GJCFQuickImage(@"audio_play");
    self.audioPlayIndicatorView.gjcf_centerY = self.bubbleBackImageView.gjcf_height / 2;
    self.audioTimeLabel.gjcf_centerY = self.bubbleBackImageView.gjcf_height / 2;
    self.audioPlayIndicatorView.gjcf_right = self.audioTimeLabel.gjcf_left - 10;
    self.statusButtonOffsetAudioDuration = self.audioTimeLabel.gjcf_width;
    self.statusButton.gjcf_centerY = self.audioTimeLabel.gjcf_centerY;

    self.isAudioPlayTagView.top = self.bubbleBackImageView.top + AUTO_HEIGHT(8);
    self.isAudioPlayTagView.right = self.bubbleBackImageView.right - AUTO_HEIGHT(8);

    self.downLoadIndicatorView.center = self.audioPlayIndicatorView.center;
}

- (void)tapOnSelf {
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioMessageCellDidTap:)]) {
        [self.delegate audioMessageCellDidTap:self];
    }
}

- (void)startDownloadAction {
    self.statusButton.hidden = YES;
    self.audioPlayIndicatorView.hidden = YES;
    [self.downLoadIndicatorView startAnimating];
}

- (void)faildDownloadAction {
    [self.downLoadIndicatorView stopAnimating];
    self.downLoadIndicatorView.hidden = YES;
    self.audioPlayIndicatorView.hidden = NO;
}

- (void)successDownloadAction {
    [self.downLoadIndicatorView stopAnimating];
    self.downLoadIndicatorView.hidden = YES;
    self.audioPlayIndicatorView.hidden = NO;
}

- (void)playAudioAction {
    [self faildDownloadAction];
    self.audioPlayIndicatorView.animationDuration = 0.5;
    if (self.isFromSelf) {

        self.audioPlayIndicatorView.animationImages = [self myAudioPlayIndicatorImages];
        if (!self.audioPlayIndicatorView.isAnimating) {
            [self.audioPlayIndicatorView startAnimating];
        }

    } else {
        self.isAudioPlayTagView.hidden = YES;
        self.audioPlayIndicatorView.animationImages = [self otherAudioPlayIndicatorImages];
        if (!self.audioPlayIndicatorView.isAnimating) {
            [self.audioPlayIndicatorView startAnimating];
        }
    }
}

- (void)finishPlayAudioAction {
    [self faildDownloadAction];

    if (self.audioPlayIndicatorView.isAnimating) {
        [self.audioPlayIndicatorView stopAnimating];
    }
    self.audioPlayIndicatorView.animationImages = nil;
    if (self.isFromSelf) {
        self.audioPlayIndicatorView.image = GJCFQuickImage(@"chat_icon_video_green.png");
    } else {
        self.audioPlayIndicatorView.image = GJCFQuickImage(@"chat_icon_video_grey.png");
    }
}

- (CGFloat)getBubbleWidthByVoiceDuration:(CGFloat)mVoiceTime {
    if (mVoiceTime < 3) {
        return 132 / 2 - 6;
    } else if (mVoiceTime < 11) {
        return 132 / 2 - 6 + (mVoiceTime - 3) * (252 / 2 - 132 / 2 - 6) / 13;
    } else if (mVoiceTime < 60) {
        return 132 / 2 - 6 + (8 + ((NSInteger) ((mVoiceTime - 10) / 10))) * (252 / 2 - 132 / 2 - 6) / (13);
    }
    return 252 / 2 - 6;
}

- (void)goToShowLongPressMenu:(UILongPressGestureRecognizer *)sender {
    [super goToShowLongPressMenu:sender];
    if (sender.state == UIGestureRecognizerStateBegan) {
        //
        [self becomeFirstResponder];
        UIMenuController *popMenu = [UIMenuController sharedMenuController];
        UIMenuItem *item1 = [[UIMenuItem alloc] initWithTitle:LMLocalizedString(@"Link Delete", nil) action:@selector(deleteMessage:)];
        NSArray *menuItems = @[item1];
        [popMenu setMenuItems:menuItems];
        [popMenu setArrowDirection:UIMenuControllerArrowDown];

        [popMenu setTargetRect:self.bubbleBackImageView.frame inView:self];
        [popMenu setMenuVisible:YES animated:YES];

    }
}

+ (CGFloat)cellHeightForContentModel:(GJGCChatContentBaseModel *)contentModel {
    CGSize nameSize = CGSizeZero;
    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) contentModel;
    if (chatContentModel.isGroupChat && !chatContentModel.isFromSelf) {
        NSAttributedString *name = [[NSAttributedString alloc] initWithString:chatContentModel.senderName];
        nameSize = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:name forBaseContentSize:CGSizeMake(DEVICE_SIZE.width - AUTO_WIDTH(150), 25)];
        nameSize.height += 3;
    }
    return AUTO_WIDTH(80) + BOTTOM_CELL_MARGIN + nameSize.height;
}

@end
