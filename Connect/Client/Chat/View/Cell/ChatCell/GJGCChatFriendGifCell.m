//
//  GJGCChatFriendGifCell.m
//  Connect
//
//  Created by KivenLin on 15/6/3.
//  Copyright (c) 2015年 ConnectSoft. All rights reserved.
//

#import "GJGCChatFriendGifCell.h"
#import "GJGCGIFLoadManager.h"

#import "YYAnimatedImageView.h"
#import "YYImage.h"
#import "YYImageCache.h"

#define GIF_WIDTH_HEIGTH  AUTO_WIDTH(145)

@interface GJGCChatFriendGifCell ()

@property(nonatomic, strong) GJCUProgressView *progressView;

@property(nonatomic, strong) YYAnimatedImageView *gifImgView;

@property(nonatomic, strong) NSString *gifLocalId;

@end

@implementation GJGCChatFriendGifCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {

        self.gifImgView = [[YYAnimatedImageView alloc] init];

        self.gifImgView.gjcf_size = CGSizeMake(GIF_WIDTH_HEIGTH, GIF_WIDTH_HEIGTH);
        [self.bubbleBackImageView addSubview:self.gifImgView];

        self.progressView = [[GJCUProgressView alloc] init];
        self.progressView.frame = self.gifImgView.bounds;
        self.progressView.hidden = YES;
        [self.gifImgView addSubview:self.progressView];

    }
    return self;
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


- (void)setContentModel:(GJGCChatContentBaseModel *)contentModel {
    [super setContentModel:contentModel];

    self.progressView.progress = 0.f;
    self.progressView.hidden = YES;

    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) contentModel;

    self.gifLocalId = chatContentModel.gifLocalId;
    self.gifImgView.image = nil;

    [self setGifImageContent];

    self.bubbleBackImageView.gjcf_height = self.gifImgView.gjcf_height;
    self.bubbleBackImageView.gjcf_width = self.gifImgView.gjcf_width + 10;


    [self adjustContent];

    self.bubbleBackImageView.image = nil;
    self.bubbleBackImageView.highlightedImage = nil;
}

- (void)setGifImageContent {
    NSString *cacheKey = [[NSString stringWithFormat:@"local_%@", self.gifLocalId] sha1String];
    YYImage *gifImage = (YYImage *) [[YYImageCache sharedCache] getImageForKey:cacheKey];
    if (gifImage && [gifImage isKindOfClass:[YYImage class]]) {
        self.gifImgView.image = gifImage;
        self.gifImgView.size = CGSizeMake(gifImage.size.width * 0.66, gifImage.size.height * 0.66);
    } else {
        NSData *gifData = [GJGCGIFLoadManager getCachedGifDataById:self.gifLocalId];
        if (gifData) {
            YYImage *gifImage = [YYImage imageWithData:gifData];
            [[YYImageCache sharedCache] setImage:gifImage forKey:cacheKey];
            self.gifImgView.image = gifImage;
            self.gifImgView.size = CGSizeMake(gifImage.size.width * 0.66, gifImage.size.height * 0.66);
        } else {
            self.gifImgView.image = [UIImage imageNamed:@"大表情-gif占位图"];
        }
    }
}

- (void)pause {
    if (self.gifImgView.isAnimating) {

        [self.gifImgView stopAnimating];

    }
}

- (void)resume {
    if (!self.gifImgView.isAnimating) {

        [self.gifImgView startAnimating];

    }
}

- (void)setDownloadProgress:(CGFloat)downloadProgress {
    if (_downloadProgress == downloadProgress) {
        return;
    }
    self.progressView.hidden = NO;
    _downloadProgress = downloadProgress;
    self.progressView.progress = downloadProgress;
}

- (void)successDownloadGifFile:(NSData *)fileData {
    self.progressView.hidden = YES;

    if (!fileData) {
        return;
    }
    YYImage *gifImage = [YYImage imageWithData:fileData];
//    FLAnimatedImage *gifImage = [FLAnimatedImage animatedImageWithGIFData:fileData];

    self.gifImgView.image = gifImage;
}

- (void)faildDownloadGifFile {
    self.progressView.progress = 0.f;
    self.progressView.hidden = YES;
}

+ (CGFloat)cellHeightForContentModel:(GJGCChatContentBaseModel *)contentModel {

    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) contentModel;
    NSString *cacheKey = [[NSString stringWithFormat:@"local_%@", chatContentModel.gifLocalId] sha1String];
    YYImage *gifImage = (YYImage *) [[YYImageCache sharedCache] getImageForKey:cacheKey];
    if (!gifImage) {
        NSData *gifData = [GJGCGIFLoadManager getCachedGifDataById:chatContentModel.gifLocalId];
        if (gifData) {
            YYImage *gifImage = [YYImage imageWithData:gifData];
            [[YYImageCache sharedCache] setImage:gifImage forKey:cacheKey];
        } else {

        }
    }
    CGSize gifSize = CGSizeMake(gifImage.size.width * 0.66, gifImage.size.height * 0.66);
    if (gifSize.height < GIF_WIDTH_HEIGTH) {
        gifSize.height = GIF_WIDTH_HEIGTH;
    }

    CGSize nameSize = CGSizeZero;
    if (chatContentModel.isGroupChat && !chatContentModel.isFromSelf) {
        NSAttributedString *name = [[NSAttributedString alloc] initWithString:chatContentModel.senderName];
        nameSize = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:name forBaseContentSize:CGSizeMake(DEVICE_SIZE.width - AUTO_WIDTH(150), 25)];
        nameSize.height += 3;
    }

    return gifSize.height + BOTTOM_CELL_MARGIN + nameSize.height;
}

- (void)willDisplayCell {
}

- (void)didEndDisplayingCell {

}


@end
