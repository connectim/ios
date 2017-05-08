//
//  ChatMapCell.m
//  Connect
//
//  Created by MoHuilin on 16/7/27.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "ChatMapCell.h"
#import "UIImage+YYAdd.h"


@interface ChatMapCell ()

@property(nonatomic, strong) CALayer *contentLayer;
@property(nonatomic, strong) CAShapeLayer *maskLayer;
@property(nonatomic, strong) UIView *customMaskView;
@property(nonatomic, strong) GJCFCoreTextContentView *locationAddressView; //街道信息

@end

@implementation ChatMapCell

#pragma mark - init

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {

        self.contentImageView = [[UIImageView alloc] init];
        self.contentImageView.size = AUTO_SIZE(434, 208);

        self.contentSize = self.contentImageView.size;

        self.contentImageView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tapR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnContentImageView)];
        tapR.numberOfTapsRequired = 1;
        [self.bubbleBackImageView addGestureRecognizer:tapR];
        [self.bubbleBackImageView addSubview:self.contentImageView];
        self.bubbleBackImageView.size = self.contentSize;

        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        self.maskLayer = maskLayer;
        maskLayer.fillColor = [UIColor blackColor].CGColor;
        maskLayer.strokeColor = [UIColor clearColor].CGColor;
        maskLayer.contentsCenter = CGRectMake(0.5, 0.8, 0.1, 0.1);
        maskLayer.contentsScale = [UIScreen mainScreen].scale;//Set the effect of automatic stretch without deformation

        CALayer *contentLayer = [CALayer layer];
        self.contentLayer = contentLayer;
        self.contentLayer.masksToBounds = YES;
        contentLayer.mask = maskLayer;
        [self.contentImageView.layer addSublayer:contentLayer];
        self.contentImageView.clipsToBounds = YES;


        self.customMaskView = [UIView new];
        [self.contentLayer addSublayer:self.customMaskView.layer];
        self.customMaskView.height = AUTO_HEIGHT(61);
        self.customMaskView.width = self.contentImageView.width;
        self.customMaskView.bottom = self.contentImageView.height;
        self.customMaskView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.9];

        self.locationAddressView = [[GJCFCoreTextContentView alloc] init];
        self.locationAddressView.width = AUTO_WIDTH(400);
        self.locationAddressView.height = AUTO_HEIGHT(33);
        self.locationAddressView.contentBaseWidth = self.locationAddressView.width;
        self.locationAddressView.contentBaseHeight = self.locationAddressView.height;
        self.locationAddressView.backgroundColor = [UIColor clearColor];
        self.locationAddressView.bottom = self.customMaskView.height - BubbleContentBottomMargin * 1.2;
        [self.customMaskView addSubview:self.locationAddressView];


    }
    return self;
}

#pragma mark - tap iamge

- (void)tapOnContentImageView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(mapLocationMessageCellDidTap:)]) {
        [self.delegate mapLocationMessageCellDidTap:self];
    }
}

#pragma mark - set model

- (void)setContentModel:(GJGCChatContentBaseModel *)contentModel {
    if (!contentModel) {
        return;
    }

    [super setContentModel:contentModel];

    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) contentModel;

    self.locationAddressView.contentAttributedString = chatContentModel.locationMessage;
    self.locationAddressView.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:chatContentModel.locationMessage forBaseContentSize:self.locationAddressView.contentBaseSize];
    if (chatContentModel.isFromSelf) {
        self.locationAddressView.left = self.customMaskView.left + BubbleLeftRightMargin;
    } else {
        self.locationAddressView.left = self.customMaskView.left + BubbleLeftRightMargin + BubbleLeftRight;
    }

    UIImage *cacheImage = chatContentModel.messageContentImage;
    if (!cacheImage) {
        cacheImage = [UIImage imageNamed:@"image_message_placeholder"];
    }

    if (chatContentModel.isSnapChatMode) {
        cacheImage = [cacheImage imageByBlurRadius:30 tintColor:nil tintMode:0 saturation:1 maskImage:nil];
    } else {
        if (GJCFFileIsExist(chatContentModel.locationImageOriginDataCachePath)) {
            cacheImage = GJCFQuickImageByFilePath(chatContentModel.locationImageOriginDataCachePath);
        } else {
            cacheImage = [UIImage imageNamed:@"image_message_placeholder"];
        }
    }

    UIImage *buImage = nil;

    self.bubbleBackImageView.gjcf_size = self.contentSize;
    [self adjustContent];

    if (self.isFromSelf) {
        buImage = [UIImage imageNamed:@"message_box_map_sender"];
    } else {
        buImage = [UIImage imageNamed:@"message_box_map_other"];
    }

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.maskLayer.frame = self.contentImageView.bounds;
    self.contentLayer.frame = self.contentImageView.bounds;
    self.maskLayer.contents = (id) buImage.CGImage;
    self.contentLayer.contents = (id) cacheImage.CGImage;
    [CATransaction commit];

}

#pragma mark - long press

- (void)goToShowLongPressMenu:(UILongPressGestureRecognizer *)sender {
    [super goToShowLongPressMenu:sender];

    if (sender.state == UIGestureRecognizerStateBegan) {
        //
        [self becomeFirstResponder];
        UIMenuController *popMenu = [UIMenuController sharedMenuController];
        UIMenuItem *item2 = [[UIMenuItem alloc] initWithTitle:LMLocalizedString(@"Link Delete", nil) action:@selector(deleteMessage:)];
        NSArray *menuItems = @[item2];
        [popMenu setMenuItems:menuItems];
        [popMenu setArrowDirection:UIMenuControllerArrowDown];

        [popMenu setTargetRect:self.bubbleBackImageView.frame inView:self];
        [popMenu setMenuVisible:YES animated:YES];

    }

}

- (void)successDownloadWithImageData:(NSData *)imageData {
    if (imageData) {

        UIImage *cacheImage = [UIImage imageWithData:imageData];

        if (self.contentModel.isSnapChatMode) {
            cacheImage = [cacheImage imageByBlurRadius:30 tintColor:nil tintMode:0 saturation:1 maskImage:nil];
        }
        self.contentImageView.gjcf_size = self.contentSize;
        [self adjustContent];

        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        self.maskLayer.contents = (id) self.bubbleBackImageView.image.CGImage;
        self.maskLayer.frame = self.contentImageView.bounds;
        self.contentLayer.frame = self.contentImageView.bounds;
        self.contentLayer.contents = (id) cacheImage.CGImage;
        [CATransaction commit];


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

- (void)failDownloadState {

}

+ (CGFloat)cellHeightForContentModel:(GJGCChatContentBaseModel *)contentModel {
    CGSize nameSize = CGSizeZero;
    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) contentModel;
    if (chatContentModel.isGroupChat && !chatContentModel.isFromSelf) {
        NSAttributedString *name = [[NSAttributedString alloc] initWithString:chatContentModel.senderName];
        nameSize = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:name forBaseContentSize:CGSizeMake(DEVICE_SIZE.width - AUTO_WIDTH(150), 25)];
        nameSize.height += 3;
    }
    return AUTO_HEIGHT(208) + BOTTOM_CELL_MARGIN + nameSize.height;
}

- (void)willDisplayCell {
}

- (void)didEndDisplayingCell {
}


@end
