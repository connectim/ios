//
//  GJGCChatFriendVideoCell.m
//  Connect
//
//  Created by MoHuilin on 16/7/4.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "GJGCChatFriendVideoCell.h"
#import "UIImage+Color.h"
#import "UIImage+YYAdd.h"
#import "UAProgressView.h"

@interface GJGCChatFriendVideoCell ()

@property(nonatomic, strong) UIButton *playButton;

@property(nonatomic, strong) UILabel *videoTimeLabel;

@property(nonatomic, strong) UILabel *videoSizeLabel;

@property(nonatomic, strong) CALayer *contentLayer;
@property(nonatomic, strong) CAShapeLayer *maskLayer;

@property(nonatomic, strong) UAProgressView *cirProgressView;
@property(nonatomic, strong) UIImageView *imageDefaultView;

@property(nonatomic, strong) UIImage *videoCoverImage;

@property(nonatomic, strong) UIView *customMaskView;

@end

@implementation GJGCChatFriendVideoCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {

        self.contentImageView = [[UIImageView alloc] init];
        self.contentImageView.image = GJCFImageStrecth([UIImage imageNamed:@"IM聊天页-占位图-BG.png"], 2, 2);
        self.contentImageView.gjcf_size = (CGSize) {160, 160};
        self.contentSize = self.contentImageView.size;

        [self.bubbleBackImageView addSubview:self.contentImageView];

        self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.playButton setImage:[UIImage imageNamed:@"message_download_cancel"] forState:UIControlStateSelected];

        [self.playButton addTarget:self action:@selector(tapOnContentImageView) forControlEvents:UIControlEventTouchUpInside];

        self.blankImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"IM聊天页-占位图"]];
        [self.contentImageView addSubview:self.blankImageView];
        self.blankImageView.gjcf_centerX = self.contentImageView.gjcf_width / 2;
        self.blankImageView.gjcf_centerY = self.contentImageView.gjcf_height / 2;

        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        self.maskLayer = maskLayer;
        maskLayer.fillColor = [UIColor blackColor].CGColor;
        maskLayer.strokeColor = [UIColor clearColor].CGColor;
        maskLayer.contentsCenter = CGRectMake(0.5, 0.8, 0.1, 0.1);
        maskLayer.contentsScale = [UIScreen mainScreen].scale;

        CALayer *contentLayer = [CALayer layer];
        self.contentLayer = contentLayer;
        contentLayer.mask = maskLayer;
        [self.contentImageView.layer addSublayer:contentLayer];

        self.cirProgressView = [[UAProgressView alloc] initWithFrame:CGRectMake(0, 0, 40.0f, 40.0f)];
        self.cirProgressView.tintColor = [UIColor whiteColor];
        [self.contentImageView addSubview:self.cirProgressView];
        self.playButton.size = self.cirProgressView.size;
        self.cirProgressView.centralView = self.playButton;
        self.imageDefaultView = [[UIImageView alloc] init];
        [self.contentImageView addSubview:self.imageDefaultView];
        self.imageDefaultView.image = [UIImage imageNamed:@"upload_Video_image"];
        self.imageDefaultView.size = AUTO_SIZE(69, 50);
        self.contentImageView.userInteractionEnabled = YES;


        self.customMaskView = [UIView new];
        [self.contentLayer addSublayer:self.customMaskView.layer];
        self.customMaskView.height = AUTO_HEIGHT(30);
        self.customMaskView.width = self.contentImageView.width;
        self.customMaskView.bottom = self.contentImageView.height;
        self.customMaskView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.8];


        self.videoTimeLabel = [UILabel new];
        self.videoSizeLabel.textAlignment = NSTextAlignmentLeft;
        self.videoTimeLabel.font = [UIFont systemFontOfSize:FONT_SIZE(17)];
        self.videoTimeLabel.textColor = [UIColor whiteColor];
        [self.customMaskView addSubview:self.videoTimeLabel];


        self.videoSizeLabel = [UILabel new];
        self.videoSizeLabel.textAlignment = NSTextAlignmentRight;
        self.videoSizeLabel.font = [UIFont systemFontOfSize:FONT_SIZE(17)];
        self.videoSizeLabel.textColor = [UIColor whiteColor];
        [self.customMaskView addSubview:self.videoSizeLabel];
    }
    return self;
}

- (void)tapOnContentImageView {
    self.imageDefaultView.image = nil;
    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) self.contentModel;
    if (chatContentModel.videoIsDownload) {
        self.cirProgressView.center = self.contentImageView.center;
        if (self.delegate && [self.delegate respondsToSelector:@selector(videoMessageCellDidTap:)]) {
            [self.delegate videoMessageCellDidTap:self];
        }
    } else {
        if (self.playButton.selected) {
            self.cirProgressView.progress = 0.f;
            if (self.delegate && [self.delegate respondsToSelector:@selector(videoMessageCancelDownload:)]) {
                [self.delegate videoMessageCancelDownload:self];
            }
        } else {
            if (self.delegate && [self.delegate respondsToSelector:@selector(videoMessageCellDidTap:)]) {
                [self.delegate videoMessageCellDidTap:self];
            }
        }
        self.playButton.selected = !self.playButton.selected;
    }
}


- (void)startDownloadVideoAction {

}

- (void)resetState {

}

- (void)resetStateWithPrepareSize:(CGSize)pSize {
    self.contentImageView.gjcf_size = pSize;
    self.contentImageView.image = GJCFImageStrecth([UIImage imageNamed:@"IM聊天页-占位图-BG.png"], 2, 2);
    [self resetMaxBlankImageViewSize];
    self.blankImageView.gjcf_centerX = self.contentImageView.gjcf_width / 2;
    self.blankImageView.gjcf_centerY = self.contentImageView.gjcf_height / 2;
    self.blankImageView.hidden = NO;
    self.cirProgressView.progress = 0.f;
}

- (void)resetMaxBlankImageViewSize {
    CGFloat blankToBord = 8.f;

    CGFloat minSide = MIN(self.contentImageView.gjcf_width, self.contentImageView.gjcf_height);

    CGFloat blankWidth = minSide - 2 * blankToBord;

    self.blankImageView.gjcf_size = CGSizeMake(blankWidth, blankWidth);
}

- (void)removePrepareState {
    self.blankImageView.hidden = YES;
}

- (void)setContentModel:(GJGCChatContentBaseModel *)contentModel {
    if (!contentModel) {
        return;
    }
    [super setContentModel:contentModel];

    UIImage *buImage = nil;
    if (self.isFromSelf) {
        buImage = [UIImage imageNamed:@"sender_message_blue"];
    } else {
        buImage = [UIImage imageNamed:@"reciver_message_white"];
    }
    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) contentModel;
    CGSize imageSize = CGSizeMake(chatContentModel.originImageWidth, chatContentModel.originImageHeight);
    UIImage *cacheImage = chatContentModel.messageContentImage;
    if (!cacheImage) {
        cacheImage = [UIImage imageWithColor:GJCFQuickHexColor(@"EAEBEE") withSize:self.contentSize];
        self.imageDefaultView.hidden = NO;
    } else {
        self.imageDefaultView.hidden = YES;
    }

    if (self.contentModel.isSnapChatMode || !chatContentModel.videoIsDownload) {
        cacheImage = [cacheImage imageByBlurRadius:30 tintColor:nil tintMode:0 saturation:1 maskImage:nil];
    }

    if (CGSizeEqualToSize(imageSize, CGSizeZero)) {
        imageSize = cacheImage.size;
        chatContentModel.originImageWidth = imageSize.width;
        chatContentModel.originImageHeight = imageSize.height;
    }
    CGFloat maxWidth = AUTO_WIDTH(340);
    CGFloat maxHeight = AUTO_WIDTH(340);
    self.contentSize = CGSizeMake(maxWidth, maxHeight);

    if (!CGSizeEqualToSize(imageSize, CGSizeZero)) {
        CGSize thumbSize = [GJGCImageResizeHelper getCutImageSize:imageSize maxSize:CGSizeMake(imageSize.width * 0.2, imageSize.height * 0.2)];
        if (thumbSize.width > thumbSize.height) {
            thumbSize.width = maxWidth;
            thumbSize.height = (thumbSize.width / chatContentModel.originImageWidth) * chatContentModel.originImageHeight;
        } else {
            thumbSize.height = maxHeight;
            thumbSize.width = (thumbSize.height / chatContentModel.originImageHeight) * chatContentModel.originImageWidth;
        }
        if (thumbSize.height < buImage.size.height) {
            thumbSize.height = buImage.size.height + 2;
        }
        if (thumbSize.width < buImage.size.width) {
            thumbSize.width = buImage.size.width + 2;
        }
        self.contentSize = thumbSize;
    }
    NSString *videoTimeString = [NSString stringWithFormat:@"00:%02ld", (long) chatContentModel.videoDuration];
    if (chatContentModel.videoDuration > 60 && chatContentModel.videoDuration <= 60 * 60) {
        videoTimeString = [NSString stringWithFormat:@"%02ld:%02ld", (long) chatContentModel.videoDuration / 60, (long) chatContentModel.videoDuration % 60];
    } else if (chatContentModel.videoDuration > 60 * 60) {
        videoTimeString = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long) chatContentModel.videoDuration / 60 / 60, (long) chatContentModel.videoDuration % (60 * 60) / 60, (long) chatContentModel.videoDuration % 60 % 60];
    }
    self.isFromSelf = chatContentModel.isFromSelf;
    self.videoTimeLabel.text = videoTimeString;
    self.videoSizeLabel.text = [NSString stringWithFormat:@"%@", chatContentModel.videoSize];

    self.videoCoverImage = cacheImage;


    if (chatContentModel.videoIsDownload) {
        [self.playButton setImage:[UIImage imageNamed:@"message_video_play"] forState:UIControlStateNormal];
        self.cirProgressView.progress = 1;
    } else {
        self.cirProgressView.progress = 0.f;
        [self.playButton setImage:[UIImage imageNamed:@"message_download"] forState:UIControlStateNormal];
        cacheImage = [cacheImage imageByBlurRadius:13.f tintColor:nil tintMode:0 saturation:1 maskImage:nil];
    }
    self.imageDefaultView.image = nil;
    if (!self.isFromSelf) {
        if (chatContentModel.videoIsDownload) {
            self.playButton.selected = NO;
            [self.playButton setImage:[UIImage imageNamed:@"message_video_play"] forState:UIControlStateNormal];
            self.cirProgressView.progress = 1;
        } else if (chatContentModel.isDownloading) {
            self.cirProgressView.progress = .3f;
            self.playButton.selected = YES;
            [self.playButton setImage:[UIImage imageNamed:@"message_download"] forState:UIControlStateNormal];
        } else {
            self.playButton.selected = NO;
            self.cirProgressView.progress = 0.f;
            [self.playButton setImage:[UIImage imageNamed:@"message_download"] forState:UIControlStateNormal];
        }
    } else {
        self.playButton.selected = NO;
        [self.playButton setImage:[UIImage imageNamed:@"message_video_play"] forState:UIControlStateNormal];
        self.cirProgressView.progress = 1.f;
    }


    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.maskLayer.contents = (id) buImage.CGImage;
    self.contentImageView.gjcf_size = self.contentSize;
    self.maskLayer.frame = self.contentImageView.bounds;
    self.contentLayer.frame = self.contentImageView.bounds;
    self.contentLayer.contents = (id) cacheImage.CGImage;
    [CATransaction commit];

    if (GJCFSystemiPhone6Plus) {
        UIImage *image = self.bubbleBackImageView.image;
        self.bubbleBackImageView.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.bubbleBackImageView setTintColor:[UIColor clearColor]];
    }
    self.bubbleBackImageView.gjcf_size = self.contentImageView.gjcf_size;
    [self adjustContent];

    self.contentImageView.gjcf_top = 0;
    if (self.isFromSelf) {
        self.contentImageView.gjcf_left = 0;
    } else {
        self.contentImageView.gjcf_right = self.bubbleBackImageView.gjcf_width;
    }
    self.imageDefaultView.center = self.contentImageView.center;


    self.customMaskView.width = self.contentImageView.width;
    self.customMaskView.bottom = self.contentImageView.height;

    if (self.isFromSelf) {

        self.cirProgressView.centerY = self.contentImageView.centerY;
        self.cirProgressView.centerX = self.contentImageView.centerX - AUTO_WIDTH(10);

        self.videoTimeLabel.height = self.customMaskView.height;
        self.videoTimeLabel.width = self.customMaskView.width / 2;
        self.videoTimeLabel.left = self.customMaskView.left + AUTO_WIDTH(10);

        self.videoSizeLabel.height = self.customMaskView.height;
        self.videoSizeLabel.width = self.customMaskView.width / 2;
        self.videoSizeLabel.right = self.customMaskView.right - AUTO_WIDTH(30);
    } else {

        self.cirProgressView.centerY = self.contentImageView.centerY;
        self.cirProgressView.centerX = self.contentImageView.centerX + AUTO_WIDTH(10);

        self.videoTimeLabel.height = self.customMaskView.height;
        self.videoTimeLabel.width = self.customMaskView.width / 2;
        self.videoTimeLabel.left = self.customMaskView.left + AUTO_WIDTH(30);

        self.videoSizeLabel.height = self.customMaskView.height;
        self.videoSizeLabel.width = self.customMaskView.width / 2;
        self.videoSizeLabel.right = self.customMaskView.right - AUTO_WIDTH(10);
    }

    if (self.isFromSelf) {
        if (chatContentModel.videoIsDownload) {
            if (!chatContentModel.uploadSuccess) {

                [self setUploadProgress:chatContentModel.uploadProgress];
                [self.playButton setImage:[UIImage imageNamed:@"upload_icon"] forState:UIControlStateNormal];
            } else {
                [self.cirProgressView setProgress:1.f animated:NO];
                [self.playButton setImage:[UIImage imageNamed:@"message_video_play"] forState:UIControlStateNormal];
            }
        } else {

            [self downloadProgress:chatContentModel.downloadProgress];
        }
    } else {
        if (!chatContentModel.videoIsDownload) {

            [self downloadProgress:chatContentModel.downloadProgress];
        } else {
            [self.cirProgressView setProgress:1.f animated:NO];
        }
    }
}

- (void)goToShowLongPressMenu:(UILongPressGestureRecognizer *)sender {
    [super goToShowLongPressMenu:sender];

    if (sender.state == UIGestureRecognizerStateBegan) {
        //
        [self becomeFirstResponder];
        UIMenuController *popMenu = [UIMenuController sharedMenuController];
        UIMenuItem *item1 = [[UIMenuItem alloc] initWithTitle:LMLocalizedString(@"Chat Retweet", nil) action:@selector(retweetMessage:)];
        UIMenuItem *item2 = [[UIMenuItem alloc] initWithTitle:LMLocalizedString(@"Link Delete", nil) action:@selector(deleteMessage:)];
        NSArray *menuItems = @[item1, item2];
        [popMenu setMenuItems:menuItems];
        [popMenu setArrowDirection:UIMenuControllerArrowDown];

        [popMenu setTargetRect:self.bubbleBackImageView.frame inView:self];
        [popMenu setMenuVisible:YES animated:YES];
    }
}

- (void)setPlayVideoState {
    [self.cirProgressView setProgress:1 animated:YES];
}

- (void)downloadProgress:(float)downloadProgress {
    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) self.contentModel;
    int count = (int) (downloadProgress * 10);
    if (count > chatContentModel.drawingCount && !chatContentModel.isSnapChatMode) {
        UIImage *cacheImage = [self.videoCoverImage imageByBlurRadius:13.f * (1 - downloadProgress) tintColor:nil tintMode:0 saturation:1 maskImage:nil];
        self.contentLayer.contents = (id) cacheImage.CGImage;
        chatContentModel.drawingCount = count;
    }
    chatContentModel.downloadProgress = downloadProgress;
    [self.cirProgressView setProgress:downloadProgress animated:YES];
}

- (void)faildCoverState {

}

- (void)faildVideoState {

}

- (void)successDownloadWithImageData:(NSData *)imageData isVideo:(BOOL)isVideo {
    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) self.contentModel;
    if (isVideo) {
        chatContentModel.videoIsDownload = YES;
        self.playButton.selected = NO;
        [self.playButton setImage:[UIImage imageNamed:@"message_video_play"] forState:UIControlStateNormal];
    }
    if (imageData && !isVideo) {
        [self removePrepareState];
        UIImage *cacheImage = [UIImage imageWithData:imageData];
        self.videoCoverImage = cacheImage;
        self.imageDefaultView.hidden = YES;
        [self removePrepareState];
        if (self.contentModel.isSnapChatMode || !chatContentModel.videoIsDownload) {
            cacheImage = [cacheImage imageByBlurRadius:30 tintColor:nil tintMode:0 saturation:1 maskImage:nil];
        }

        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        self.maskLayer.contents = (id) self.bubbleBackImageView.image.CGImage;
        self.contentImageView.gjcf_size = self.contentSize;
        self.maskLayer.frame = self.contentImageView.bounds;
        self.contentLayer.frame = self.contentImageView.bounds;
        self.contentLayer.contents = (id) cacheImage.CGImage;
        [CATransaction commit];


        self.bubbleBackImageView.gjcf_size = self.contentImageView.gjcf_size;

        [self adjustContent];

        if (GJCFSystemiPhone6Plus) {
            UIImage *image = self.bubbleBackImageView.image;
            self.bubbleBackImageView.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [self.bubbleBackImageView setTintColor:[UIColor clearColor]];
        }

        self.contentImageView.gjcf_top = 0;
        if (self.isFromSelf) {
            self.contentImageView.gjcf_left = 0;
        } else {
            self.contentImageView.gjcf_right = self.bubbleBackImageView.gjcf_width;
        }
        self.contentLayer.contents = (id) cacheImage.CGImage;
    }
}


- (BOOL)canBecomeFirstResponder {
    return YES;
}


- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(deleteMessage:) ||
            action == @selector(reSendMessage) ||
            action == @selector(retweetMessage:)) {
        return YES;
    }
    return NO;
}

- (void)stopAction {

}

- (void)playAction {

}

- (void)setUploadProgress:(float)progress {
    if (progress >= 1.f) {
        [self.playButton setImage:[UIImage imageNamed:@"message_video_play"] forState:UIControlStateNormal];
    }
    self.cirProgressView.progress = progress;
}

+ (CGFloat)cellHeightForContentModel:(GJGCChatContentBaseModel *)contentModel {

    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) contentModel;

    UIImage *buImage = nil;
    if (chatContentModel.isFromSelf) {
        buImage = [UIImage imageNamed:@"sender_message_blue"];
    } else {
        buImage = [UIImage imageNamed:@"reciver_message_white"];
    }

    CGSize imageSize = CGSizeMake(chatContentModel.originImageWidth, chatContentModel.originImageHeight);
    UIImage *cacheImage = chatContentModel.messageContentImage;
    if (!cacheImage) {
        cacheImage = GJCFQuickImageByFilePath(chatContentModel.videoOriginCoverImageCachePath);
        chatContentModel.messageContentImage = cacheImage;
    }
    if (CGSizeEqualToSize(imageSize, CGSizeZero)) {
        imageSize = cacheImage.size;
        chatContentModel.originImageWidth = imageSize.width;
        chatContentModel.originImageHeight = imageSize.height;
    }
    CGFloat maxWidth = AUTO_WIDTH(340);
    CGFloat maxHeight = AUTO_WIDTH(340);

    CGSize contentSize = CGSizeZero;

    if (!CGSizeEqualToSize(imageSize, CGSizeZero)) {
        CGSize thumbSize = [GJGCImageResizeHelper getCutImageSize:imageSize maxSize:CGSizeMake(imageSize.width * 0.2, imageSize.height * 0.2)];
        if (thumbSize.width > thumbSize.height) {
            thumbSize.width = maxWidth;
            thumbSize.height = (thumbSize.width / chatContentModel.originImageWidth) * chatContentModel.originImageHeight;
        } else {
            thumbSize.height = maxHeight;
            thumbSize.width = (thumbSize.height / chatContentModel.originImageHeight) * chatContentModel.originImageWidth;
        }
        if (thumbSize.height < buImage.size.height) {
            thumbSize.height = buImage.size.height + 2;
        }
        if (thumbSize.width < buImage.size.width) {
            thumbSize.width = buImage.size.width + 2;
        }
        contentSize = thumbSize;
    }

    CGSize nameSize = CGSizeZero;
    if (chatContentModel.isGroupChat && !chatContentModel.isFromSelf) {
        NSAttributedString *name = [[NSAttributedString alloc] initWithString:chatContentModel.senderName];
        nameSize = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:name forBaseContentSize:CGSizeMake(DEVICE_SIZE.width - AUTO_WIDTH(150), 25)];
        nameSize.height += 3;
    }
    return contentSize.height + BOTTOM_CELL_MARGIN + nameSize.height;
}


- (void)willDisplayCell {

}

- (void)didEndDisplayingCell {

}


@end
