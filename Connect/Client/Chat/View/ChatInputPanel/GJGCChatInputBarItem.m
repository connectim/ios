//
//  GJGCCommonInputBarControlItem.m
//  Connect
//
//  Created by KivenLin on 14-10-28.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJGCChatInputBarItem.h"
#import "GJGCIconSeprateButton.h"

@interface GJGCChatInputBarItem ()

@property(nonatomic, strong) GJGCIconSeprateButton *normalStateButton;

@property(nonatomic, strong) GJGCIconSeprateButton *selectedStateButton;

@property(nonatomic, copy) GJGCChatInputBarControlItemStateChangeEventBlock eventChangeBlock;

@property(nonatomic, copy) GJGCChatInputBarControlItemAuthorizedBlock authorizeBlock;

@end

@implementation GJGCChatInputBarItem

#pragma mark - life circle

- (instancetype)initWithSelectedIcon:(UIImage *)selectedIcon withNormalIcon:(UIImage *)normalIcon {
    if (self = [super init]) {
        self.normalStateButton = [[GJGCIconSeprateButton alloc] initWithFrame:self.bounds withSelectedIcon:selectedIcon withNormalIcon:normalIcon];
        self.normalStateButton.iconView.gjcf_size = CGSizeMake(AUTO_WIDTH(65), AUTO_WIDTH(65));
        GJCFWeakSelf weakSelf = self;
        [self.normalStateButton setTapBlock:^(GJGCIconSeprateButton *button) {
            [weakSelf tapOnButton:button];
        }];
        [self addSubview:self.normalStateButton];
        self.selected = NO;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.normalStateButton.frame = self.bounds;
}

- (void)setSelected:(BOOL)selected {
    [self.normalStateButton setSelected:selected];
}

- (BOOL)isSelected {
    return self.normalStateButton.selected;
}

- (void)tapOnButton:(GJGCIconSeprateButton *)button {
    BOOL canUse = YES;
    if (self.authorizeBlock) {
        canUse = self.authorizeBlock(self);
    }

    if (canUse) {

        self.selected = !self.selected;
        button.selected = self.selected;

        if (self.eventChangeBlock) {
            self.eventChangeBlock(self, self.selected);
        }

    }
}

#pragma mark - config
- (void)configStateChangeEventBlock:(GJGCChatInputBarControlItemStateChangeEventBlock)eventBlock {
    if (self.eventChangeBlock) {
        self.eventChangeBlock = nil;
    }
    self.eventChangeBlock = eventBlock;
}

- (void)configAuthorizeBlock:(GJGCChatInputBarControlItemAuthorizedBlock)authorizBlock {
    if (self.authorizeBlock) {
        self.authorizeBlock = nil;
    }
    self.authorizeBlock = authorizBlock;
}

@end
