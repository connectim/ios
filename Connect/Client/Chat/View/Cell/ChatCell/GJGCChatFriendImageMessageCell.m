//
//  GJGCChatFriendImageMessageCell.m
//  ZYChat
//
//  Created by KivenLin on 14-11-5.
//  Copyright (c) 2014年 ConnectSoft. All rights reserved.
//

#import "GJGCChatFriendImageMessageCell.h"
#import "UIImage+Color.h"
#import "UIImage+YYAdd.h"

@interface GJGCChatFriendImageMessageCell ()

@property(nonatomic, strong) CALayer *contentLayer;
@property(nonatomic, strong) CAShapeLayer *maskLayer;
@property(nonatomic, strong) UIImageView *imageDefaultView;
@property(nonatomic, strong) UIImage *saveImage;
@property(nonatomic, strong) UIImageView *uploadImageView;

@end

@implementation GJGCChatFriendImageMessageCell


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {

        self.contentImageView = [[UIImageView alloc] init];
        self.contentImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.contentImageView.gjcf_size = (CGSize) {160, 160};
        self.contentImageView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tapR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnContentImageView)];
        tapR.numberOfTapsRequired = 1;
        [self.bubbleBackImageView addGestureRecognizer:tapR];
        [self.bubbleBackImageView addSubview:self.contentImageView];

        self.blankImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"IM聊天页-占位图"]];
        [self.contentImageView addSubview:self.blankImageView];
        self.blankImageView.gjcf_centerX = self.contentImageView.gjcf_width / 2;
        self.blankImageView.gjcf_centerY = self.contentImageView.gjcf_height / 2;

        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        self.maskLayer = maskLayer;
        maskLayer.fillColor = [UIColor clearColor].CGColor;
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
        self.cirProgressView.hidden = YES;


        self.imageDefaultView = [[UIImageView alloc] init];
        [self.contentImageView addSubview:self.imageDefaultView];
        self.imageDefaultView.image = [UIImage imageNamed:@"message_picture_default"];
        self.imageDefaultView.size = AUTO_SIZE(63, 51);
        self.uploadImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"upload_icon"]];
        [self.contentImageView addSubview:self.uploadImageView];

        self.uploadImageView.size = self.cirProgressView.size;
        self.cirProgressView.centralView = self.uploadImageView;

    }
    return self;
}

- (void)tapOnContentImageView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(imageMessageCellDidTap:)]) {
        [self.delegate imageMessageCellDidTap:self];
    }
}

- (void)resetState {

}

- (void)resetStateWithPrepareSize:(CGSize)pSize {
    self.contentImageView.gjcf_size = pSize;

    UIImage *buImage = nil;
    if (self.isFromSelf) {
        buImage = [UIImage imageNamed:@"sender_message_blue"];
    } else {
        buImage = [UIImage imageNamed:@"reciver_message_white"];
    }
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.maskLayer.contents = (id) buImage.CGImage;
    self.contentImageView.gjcf_size = pSize;
    self.maskLayer.frame = self.contentImageView.bounds;
    self.contentLayer.frame = self.contentImageView.bounds;
    self.contentLayer.contents = (id) [UIImage imageWithColor:[UIColor clearColor] withSize:self.contentSize].CGImage;
    [CATransaction commit];

    [self resetMaxBlankImageViewSize];
    self.blankImageView.gjcf_centerX = self.contentImageView.gjcf_width / 2;
    self.blankImageView.gjcf_centerY = self.contentImageView.gjcf_height / 2;
    self.blankImageView.hidden = NO;
    self.cirProgressView.progress = 0.2f;
    self.cirProgressView.hidden = YES;
}

- (void)resetMaxBlankImageViewSize {
    CGFloat blankToBord = 8.f;

    CGFloat minSide = MIN(self.contentImageView.gjcf_width, self.contentImageView.gjcf_height);

    CGFloat blankWidth = minSide - 2 * blankToBord;

    self.blankImageView.gjcf_size = CGSizeMake(blankWidth, blankWidth);
}

- (void)removePrepareState {
    self.blankImageView.hidden = YES;
    self.cirProgressView.hidden = YES;
}

- (void)setContentModel:(GJGCChatContentBaseModel *)contentModel {
    if (!contentModel) {
        return;
    }

    [super setContentModel:contentModel];

    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) contentModel;

    self.isFromSelf = chatContentModel.isFromSelf;

    UIImage *buImage = nil;
    if (self.isFromSelf) {
        buImage = [UIImage imageNamed:@"sender_message_blue"];
    } else {
        buImage = [UIImage imageNamed:@"reciver_message_white"];
    }

    CGSize imageSize = CGSizeMake(chatContentModel.originImageWidth, chatContentModel.originImageHeight);
    UIImage *cacheImage = chatContentModel.messageContentImage;

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
    if (!cacheImage) {
        [self resetStateWithPrepareSize:self.contentSize];
        cacheImage = [UIImage imageWithColor:GJCFQuickHexColor(@"EAEBEE") withSize:self.contentSize];
        self.imageDefaultView.hidden = NO;
    } else {
        self.imageDefaultView.hidden = YES;
    }

    if (chatContentModel.isSnapChatMode) {
        cacheImage = [cacheImage imageByBlurRadius:30 tintColor:nil tintMode:0 saturation:1 maskImage:nil];
    } else {
        if (!cacheImage) {
            cacheImage = GJCFQuickImageByFilePath(chatContentModel.thumbImageCachePath);
            cacheImage = [UIImage imageWithColor:GJCFQuickHexColor(@"EAEBEE") withSize:self.contentSize];
            self.imageDefaultView.hidden = NO;
            self.cirProgressView.hidden = NO;
        } else{
            self.imageDefaultView.hidden = YES;
            self.cirProgressView.hidden = YES;
        }
    }

    self.bubbleBackImageView.gjcf_size = self.contentSize;
    [self adjustContent];

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.maskLayer.contents = (id) self.bubbleBackImageView.image.CGImage;
    self.contentImageView.gjcf_size = self.contentSize;
    self.maskLayer.frame = self.contentImageView.bounds;
    self.contentLayer.frame = self.contentImageView.bounds;
    self.saveImage = cacheImage;
    self.contentLayer.contents = (id) cacheImage.CGImage;
    [CATransaction commit];

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
    self.cirProgressView.center = self.contentImageView.center;
    self.imageDefaultView.center = self.contentImageView.center;


    if (self.isFromSelf) {
        if (chatContentModel.messageContentImage) {
            if (chatContentModel.uploadSuccess) {
                self.cirProgressView.hidden = YES;
                self.uploadImageView.hidden = YES;
            } else {
                //upload progress
                self.cirProgressView.hidden = chatContentModel.uploadProgress >= 1.f;
                self.uploadImageView.hidden = chatContentModel.uploadProgress >= 1.f;
                [self.cirProgressView setProgress:chatContentModel.uploadProgress animated:NO];
            }
        } else {
            //download progress
            [self downloadProgress:chatContentModel.downloadProgress];
        }
    } else {
        if (chatContentModel.messageContentImage) {
            self.cirProgressView.hidden = YES;
        } else {
            //download progress
            [self downloadProgress:chatContentModel.downloadProgress];
        }
    }
}


- (void)downloadProgress:(float)downloadProgress {
    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) self.contentModel;
    if (chatContentModel.downloadProgress == downloadProgress) {
        return;
    }
    self.cirProgressView.hidden = downloadProgress >= 1.f;
    chatContentModel.downloadProgress = downloadProgress;
    [GCDQueue executeInMainQueue:^{
        [self.cirProgressView setProgress:downloadProgress animated:YES];
    }];
}


- (void)setUploadProgress:(float)progress {
    if (progress >= 1.f) {
        self.cirProgressView.hidden = YES;
        self.uploadImageView.hidden = YES;
    }
    [GCDQueue executeInMainQueue:^{
        [self.cirProgressView setProgress:progress animated:YES];
    }];
}

- (void)goToShowLongPressMenu:(UILongPressGestureRecognizer *)sender {
    [super goToShowLongPressMenu:sender];

    if (sender.state == UIGestureRecognizerStateBegan) {
        [self becomeFirstResponder];
        UIMenuController *popMenu = [UIMenuController sharedMenuController];
        UIMenuItem *item3 = [[UIMenuItem alloc] initWithTitle:LMLocalizedString(@"Chat Retweet", nil) action:@selector(retweetMessage:)];
        UIMenuItem *item1 = [[UIMenuItem alloc] initWithTitle:LMLocalizedString(@"Set Save Photo", nil) action:@selector(saveImage:)];
        UIMenuItem *item2 = [[UIMenuItem alloc] initWithTitle:LMLocalizedString(@"Link Delete", nil) action:@selector(deleteMessage:)];
        NSArray *menuItems = @[item3, item1, item2];
        [popMenu setMenuItems:menuItems];
        [popMenu setArrowDirection:UIMenuControllerArrowDown];

        [popMenu setTargetRect:self.bubbleBackImageView.frame inView:self];
        [popMenu setMenuVisible:YES animated:YES];

    }

}

- (void)faildState {
    CGSize thumbNoScaleSize = self.contentSize;
    self.contentImageView.gjcf_size = thumbNoScaleSize;
    self.contentImageView.image = [UIImage imageWithColor:[UIColor clearColor] withSize:thumbNoScaleSize];
    self.blankImageView.gjcf_centerX = self.contentImageView.gjcf_width / 2;
    self.blankImageView.gjcf_centerY = self.contentImageView.gjcf_height / 2;
    self.blankImageView.hidden = NO;
    self.cirProgressView.progress = 0.f;
    self.cirProgressView.hidden = YES;
}

- (void)successDownloadWithImageData:(NSData *)imageData {
    if (imageData) {
        self.cirProgressView.hidden = YES;
        self.imageDefaultView.hidden = YES;
        [self removePrepareState];
        UIImage *cacheImage = [UIImage imageWithData:imageData];
        if (self.contentModel.isSnapChatMode) {
            cacheImage = [cacheImage imageByBlurRadius:30 tintColor:nil tintMode:0 saturation:1 maskImage:nil];
        }

        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        self.maskLayer.contents = (id) self.bubbleBackImageView.image.CGImage;
        self.contentImageView.gjcf_size = self.contentSize;
        self.maskLayer.frame = self.contentImageView.bounds;
        self.contentLayer.frame = self.contentImageView.bounds;
        self.saveImage = cacheImage;
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
        self.saveImage = cacheImage;
        self.contentLayer.contents = (id) cacheImage.CGImage;
    }
}

/**
 *  save image
 *
 *  @param sender 
 */
- (void)saveImage:(UIMenuItem *)sender {
    UIImageWriteToSavedPhotosAlbum(self.saveImage, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {

}


- (BOOL)canBecomeFirstResponder {
    return YES;
}


- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(saveImage:) ||
            action == @selector(deleteMessage:) ||
            action == @selector(reSendMessage) ||
            action == @selector(retweetMessage:)) {
        return YES;
    }
    return NO;
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
        cacheImage = GJCFQuickImageByFilePath(chatContentModel.imageOriginDataCachePath);
        if (!cacheImage) {
            cacheImage = GJCFQuickImageByFilePath(chatContentModel.thumbImageCachePath);
        }
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

#pragma mark -

- (void)willDisplayCell {

}

- (void)didEndDisplayingCell {

}


@end
