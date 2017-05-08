//
//  LMCollectionEmojiTip.m
//  Connect
//
//  Created by MoHuilin on 2017/1/11.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMCollectionEmojiTip.h"
#import "GJGCChatContentEmojiParser.h"
#import "YYImage.h"
#import "GJGCGIFLoadManager.h"
#import "YYImageCache.h"

@interface LMCollectionEmojiTip ()

@property(nonatomic) UIImageView *backgroundImageView;

@property(nonatomic) UIImageView *imageView;

@property(nonatomic) UILabel *label;

@end


@implementation LMCollectionEmojiTip

+ (instancetype)sharedTip {
    static LMCollectionEmojiTip *tip;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^() {
        tip = [[LMCollectionEmojiTip alloc] initWithFrame:CGRectMake(0, 0, 64, 92)];
    });

    return tip;
}


- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"emoticon_keyboard_magnifier"]];
        [self addSubview:self.backgroundImageView];

        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake((CGRectGetWidth(self.frame) - 42) / 2, 4, 42, 42)];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:self.imageView];

        self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, 42, CGRectGetWidth(self.frame) * 0.9, 20)];
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.font = [UIFont systemFontOfSize:FONT_SIZE(20)];
        self.label.textColor = LMBasicDarkGray;
        [self addSubview:self.label];

        self.label.centerX = self.centerX;
    }

    return self;
}


- (void)showTipOnCell:(LMCollectionEmojiCell *)cell {
    if (cell == _cell) return;
    _cell = cell;

    if (!_cell) {
        [self removeFromSuperview];
    } else {
        UIView *superView = _cell.superview.superview;
        [superView addSubview:self];

        CGPoint point = [_cell convertPoint:_cell.tipFloatPoint toView:superView];
        CGRect frame = self.frame;
        frame.origin.x = point.x - CGRectGetWidth(frame) / 2;
        frame.origin.y = point.y - CGRectGetHeight(frame);
        self.frame = frame;
        self.imageView.image = [[GJGCChatContentEmojiParser sharedParser] imageForEmotionPNGName:_cell.emotionModel.imagePNG];
        NSString *text = [_cell.emotionModel.localText stringByReplacingOccurrencesOfString:@"[" withString:@""];
        text = [text stringByReplacingOccurrencesOfString:@"]" withString:@""];
        self.label.text = text;
    }
}

@end


#pragma mark - GIF Tip

#define SIDE_BAR_WIDTH 30
#define MIDDLE_BAR_WIDTH 20
#define TOTAL_BAR_SIZE 148
#define ARROW_HEIGHT 10


typedef NS_ENUM(NSInteger, LLTipPositionType) {
    kLLTipPositionTypeLeft = 1,
    kLLTipPositionTypeMiddle,
    kLLTipPositionTypeRight
};


@interface LMCollectionGifTip ()

@property(nonatomic) UIImageView *leftBackgroundImageView;
@property(nonatomic) UIImageView *middleBackgroundImageView;
@property(nonatomic) UIImageView *rightBackgroundImageView;

@property(nonatomic) LLTipPositionType type;

@property(nonatomic) YYAnimatedImageView *gifImageView;

@end


@implementation LMCollectionGifTip

+ (instancetype)sharedTip {
    static LMCollectionGifTip *tip;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^() {
        tip = [[LMCollectionGifTip alloc] initWithFrame:CGRectMake(0, 0, TOTAL_BAR_SIZE, TOTAL_BAR_SIZE + ARROW_HEIGHT)];
    });

    return tip;
}


- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.leftBackgroundImageView = [self imageWithResizbleImage:@"EmoticonBigTipsLeft"];
        self.middleBackgroundImageView = [self imageWithResizbleImage:@"EmoticonBigTipsMiddle"];
        self.rightBackgroundImageView = [self imageWithResizbleImage:@"EmoticonBigTipsRight"];

        _type = 0;

        CGFloat gap = 0.1 * TOTAL_BAR_SIZE;
        CGFloat gifWidth = 0.8 * TOTAL_BAR_SIZE;
        self.gifImageView = [[YYAnimatedImageView alloc] initWithFrame:CGRectMake(gap, gap, gifWidth, gifWidth)];
        self.gifImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:self.gifImageView];
    }

    return self;
}

- (UIImageView *)imageWithResizbleImage:(NSString *)imageName {
    UIImage *image = [self resizableImage:[UIImage imageNamed:imageName]];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];

    [self addSubview:imageView];

    return imageView;
}

- (UIImage *)resizableImage:(UIImage *)image {
    CGFloat capWidth = floorf(image.size.width / 2);
    CGFloat capHeight = floorf(image.size.height / 2);
    UIImage *capImage = [image resizableImageWithCapInsets:
            UIEdgeInsetsMake(capHeight, capWidth, capHeight, capWidth)];

    return capImage;
}


- (void)showTipOnCell:(LMCollectionGifCell *)cell {
    if (cell == _cell) return;
    _cell = cell;

    if (!_cell || !_cell.emotionModel.imageGIF) {
        self.gifImageView.image = nil;
        [self removeFromSuperview];
    } else {
        UIView *superView = _cell.superview.superview;
        [superView addSubview:self];

        CGPoint point = [_cell convertPoint:CGPointMake(CGRectGetWidth(_cell.frame) / 2, 0) toView:superView];
        LLTipPositionType type = kLLTipPositionTypeMiddle;
        CGRect frame = self.frame;
        frame.origin.y = point.y - TOTAL_BAR_SIZE - ARROW_HEIGHT + 4;

        CGFloat _x = point.x - TOTAL_BAR_SIZE / 2;
        if (_x < 0) {
            type = kLLTipPositionTypeLeft;
            point = [_cell convertPoint:CGPointMake(CGRectGetWidth(_cell.frame) * 0.45, 0) toView:superView];
            frame.origin.x = point.x - SIDE_BAR_WIDTH - MIDDLE_BAR_WIDTH / 2;

        } else if (TOTAL_BAR_SIZE + _x > DEVICE_SIZE.width) {
            type = kLLTipPositionTypeRight;
            point = [_cell convertPoint:CGPointMake(CGRectGetWidth(_cell.frame) * 0.55, 0) toView:superView];
            frame.origin.x = point.x + SIDE_BAR_WIDTH + MIDDLE_BAR_WIDTH / 2 - TOTAL_BAR_SIZE;

        } else {
            type = kLLTipPositionTypeMiddle;
            frame.origin.x = _x;
        }

        self.frame = frame;

        [self updateBackgroundWithType:type];


        NSString *cacheKey = [[NSString stringWithFormat:@"local_%@", _cell.emotionModel.imageGIF] sha1String];
        YYImage *gifImage = (YYImage *) [[YYImageCache sharedCache] getImageForKey:cacheKey];
        if (gifImage && [gifImage isKindOfClass:[YYImage class]]) {
            self.gifImageView.image = gifImage;
        } else {
            NSData *gifData = [GJGCGIFLoadManager getCachedGifDataById:_cell.emotionModel.imageGIF];
            if (gifData) {
                YYImage *gifImage = [YYImage imageWithData:gifData];

                [[YYImageCache sharedCache] setImage:gifImage forKey:cacheKey];
                self.gifImageView.image = gifImage;
            }
        }
    }
}

- (void)updateBackgroundWithType:(LLTipPositionType)type {
    if (_type == type) return;
    _type = type;

    if (_type == kLLTipPositionTypeLeft) {
        self.leftBackgroundImageView.frame = CGRectMake(0, 0, SIDE_BAR_WIDTH, TOTAL_BAR_SIZE + ARROW_HEIGHT);
        self.middleBackgroundImageView.frame = CGRectMake(SIDE_BAR_WIDTH, 0, MIDDLE_BAR_WIDTH,
                TOTAL_BAR_SIZE + ARROW_HEIGHT);
        self.rightBackgroundImageView.frame = CGRectMake(SIDE_BAR_WIDTH + MIDDLE_BAR_WIDTH, 0, (TOTAL_BAR_SIZE -
                SIDE_BAR_WIDTH - MIDDLE_BAR_WIDTH), TOTAL_BAR_SIZE + ARROW_HEIGHT);
    } else if (type == kLLTipPositionTypeMiddle) {
        CGFloat side = (TOTAL_BAR_SIZE - MIDDLE_BAR_WIDTH) / 2;
        self.leftBackgroundImageView.frame = CGRectMake(0, 0, side, TOTAL_BAR_SIZE + ARROW_HEIGHT);
        self.middleBackgroundImageView.frame = CGRectMake(side, 0, MIDDLE_BAR_WIDTH, TOTAL_BAR_SIZE + ARROW_HEIGHT);
        self.rightBackgroundImageView.frame = CGRectMake(TOTAL_BAR_SIZE - side, 0, side, TOTAL_BAR_SIZE + ARROW_HEIGHT);
    } else if (type == kLLTipPositionTypeRight) {
        CGFloat side = (TOTAL_BAR_SIZE - SIDE_BAR_WIDTH - MIDDLE_BAR_WIDTH);
        self.leftBackgroundImageView.frame = CGRectMake(0, 0, side, TOTAL_BAR_SIZE + ARROW_HEIGHT);
        self.middleBackgroundImageView.frame = CGRectMake(side, 0, MIDDLE_BAR_WIDTH, TOTAL_BAR_SIZE + ARROW_HEIGHT);
        self.rightBackgroundImageView.frame = CGRectMake(TOTAL_BAR_SIZE - SIDE_BAR_WIDTH, 0, SIDE_BAR_WIDTH,
                TOTAL_BAR_SIZE + ARROW_HEIGHT);
    }
}


@end
