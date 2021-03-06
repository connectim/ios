//
//  GJGCChatFriendReplyGroupCallCell.m
//  Connect
//
//  Created by KivenLin on 15/4/16.
//  Copyright (c) 2015年 Connect. All rights reserved.
//

#import "GJGCChatFriendAcceptGroupCallCell.h"

@interface GJGCChatFriendAcceptGroupCallCell ()

@property(nonatomic, strong) GJCFCoreTextContentView *titleLabel;

@property(nonatomic, assign) CGFloat contentInnerMargin;

@end

@implementation GJGCChatFriendAcceptGroupCallCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {

    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {

        self.contentInnerMargin = 11.f;
        CGFloat bubbleToBordMargin = 56;
        CGFloat maxTextContentWidth = GJCFSystemScreenWidth - bubbleToBordMargin - 40 - 3 - 5.5 - 13 - 2 * self.contentInnerMargin;

        self.titleLabel = [[GJCFCoreTextContentView alloc] init];
        self.titleLabel.gjcf_size = CGSizeMake(maxTextContentWidth, 20);
        self.titleLabel.gjcf_left = self.contentInnerMargin;
        self.titleLabel.contentBaseSize = self.titleLabel.gjcf_size;
        [self.bubbleBackImageView addSubview:self.titleLabel];

    }
    return self;
}

- (UIImage *)backgroundImage {
    UIImage *originImage = [UIImage imageNamed:@""];
    CGFloat centerX = originImage.size.width / 2;
    CGFloat centerY = originImage.size.height / 2;
    CGFloat top = centerY;
    CGFloat bottom = centerY;
    CGFloat left = centerX;
    CGFloat right = centerX;
    UIImage *stretchImage = GJCFImageResize(originImage, top, bottom, left, right);
    return stretchImage;
}

- (void)setContentModel:(GJGCChatContentBaseModel *)contentModel {
    if (!contentModel) {
        return;
    }
    [super setContentModel:contentModel];
    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) contentModel;
    self.titleLabel.contentAttributedString = nil;
    self.titleLabel.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:chatContentModel.acceptSummonTitle forBaseContentSize:self.titleLabel.contentBaseSize];
    self.titleLabel.contentAttributedString = chatContentModel.acceptSummonTitle;

    CGFloat textHeight = self.titleLabel.gjcf_height + 2 * self.contentInnerMargin;
    textHeight = MAX(textHeight, 40);
    self.bubbleBackImageView.gjcf_height = textHeight;
    self.bubbleBackImageView.gjcf_width = self.titleLabel.gjcf_width + 2 * self.contentInnerMargin;

    [self adjustContent];

    self.bubbleBackImageView.image = [self backgroundImage];
    self.bubbleBackImageView.highlightedImage = nil;

    if (chatContentModel.isFromSelf) {
        self.bubbleBackImageView.gjcf_right = self.bubbleBackImageView.gjcf_right - 3;
        self.nameLabel.gjcf_right = self.bubbleBackImageView.gjcf_right;
    } else {
        self.bubbleBackImageView.gjcf_left = self.bubbleBackImageView.gjcf_left + 3;
        self.nameLabel.gjcf_left = self.bubbleBackImageView.gjcf_left;
    }

    self.titleLabel.gjcf_centerY = self.bubbleBackImageView.gjcf_height / 2;
}

@end
