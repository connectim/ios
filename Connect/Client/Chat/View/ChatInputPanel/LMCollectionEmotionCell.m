//
//  LMCollectionEmotionCell.m
//  Connect
//
//  Created by MoHuilin on 2017/1/10.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMCollectionEmotionCell.h"
#import "GJGCChatContentEmojiParser.h"
#import "LMCollectionEmojiTip.h"

static CGPoint tipPoint;

@interface LMCollectionEmojiCell ()

@property(nonatomic) UIImageView *imageView;

@end

@implementation LMCollectionEmojiCell {

}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake((CGRectGetWidth(frame) - EMOJI_IMAGE_SIZE) / 2, (CGRectGetHeight(frame) - EMOJI_IMAGE_SIZE) / 2, EMOJI_IMAGE_SIZE, EMOJI_IMAGE_SIZE)];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;

        [self.contentView addSubview:self.imageView];

        self.userInteractionEnabled = NO;
    }

    return self;
}

- (void)setContent:(LMEmotionModel *)model {
    self.emotionModel = model;
    self.isDelete = NO;
    if (model)
        self.imageView.image = [[GJGCChatContentEmojiParser sharedParser] imageForEmotionPNGName:model.imagePNG];
}

- (void)setIsDelete:(BOOL)isDelete {
    _isDelete = isDelete;
    if (_isDelete) {
        self.emotionModel = nil;
        self.imageView.image = [UIImage imageNamed:@"delete_emoji"];
    } else {
        self.imageView.image = nil;
    }
}

- (CGPoint)tipFloatPoint {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tipPoint = CGPointMake(CGRectGetWidth(self.frame) / 2, CGRectGetMaxY(self.imageView.frame));
    });

    return tipPoint;
}

- (void)didClicked {

}


- (void)didMoveIn {
    if (!self.emotionModel) return;

    self.hidden = YES;
    [[LMCollectionEmojiTip sharedTip] showTipOnCell:self];
}

- (void)didMoveOut {
    if (!self.emotionModel) return;

    self.hidden = NO;
    [[LMCollectionEmojiTip sharedTip] showTipOnCell:nil];
}


@end


@interface LMCollectionGifCell ()

@property(nonatomic) UIImageView *imageView;

@property(nonatomic) UIImageView *highlightedBackgroundView;

@end


@implementation LMCollectionGifCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame))];
    if (self) {
        self.backgroundColor = [UIColor clearColor];

        self.highlightedBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"大表情-bg-预览"]];
        self.highlightedBackgroundView.frame = CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetWidth(frame));
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:self.highlightedBackgroundView];
        self.highlightedBackgroundView.hidden = YES;

        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetWidth(frame))];
        self.imageView.contentMode = UIViewContentModeCenter;
        [self.contentView addSubview:self.imageView];

        self.userInteractionEnabled = NO;
    }

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.highlightedBackgroundView.frame = self.contentView.bounds;
    self.imageView.frame = self.contentView.bounds;
}

- (void)setContent:(LMEmotionModel *)model {
    _emotionModel = model;
    if (!model) {
        self.imageView.image = nil;
    } else {
        self.imageView.image = [UIImage imageNamed:model.imageGIF];
    }
}

- (void)didClicked {


}

- (void)didMoveIn {
    if (!self.emotionModel) return;

    self.highlightedBackgroundView.hidden = NO;
    [[LMCollectionGifTip sharedTip] showTipOnCell:self];
}

- (void)didMoveOut {
    if (!self.emotionModel) return;

    self.highlightedBackgroundView.hidden = YES;
    [[LMCollectionGifTip sharedTip] showTipOnCell:nil];
}


@end
