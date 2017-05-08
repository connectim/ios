//
//  GJGCChatInputExpandMenuPanelItem.m
//  Connect
//
//  Created by KivenLin on 14-10-28.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJGCChatInputExpandMenuPanelItem.h"
#import "UIImage+Color.h"
#import "TopImageBottomTitleButton.h"

@interface GJGCChatInputExpandMenuPanelItem ()

@property(nonatomic, strong) TopImageBottomTitleButton *iconButton;

@property(nonatomic, strong) UILabel *titleLabel;

@property(nonatomic, copy) GJGCChatInputExpandMenuPanelItemDidTapedBlock didTapBlock;

@end

@implementation GJGCChatInputExpandMenuPanelItem

- (instancetype)init {
    if (self = [super init]) {

        [self initSubViews];

        self.backgroundColor = GJCFQuickHexColor(@"CDD0D4");
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {

        [self initSubViews];
    }
    return self;
}

+ (GJGCChatInputExpandMenuPanelItem *)itemWithTitle:(NSString *)title
                                withIconImageNormal:(UIImage *)iconImageNormal
                             withIconImageHighlight:(UIImage *)iconImageHighlight
                                     withActionType:(GJGCChatInputMenuPanelActionType)actionType
                                       withTapBlock:(GJGCChatInputExpandMenuPanelItemDidTapedBlock)tapBlock {
    GJGCChatInputExpandMenuPanelItem *item = [[self alloc] init];

    [item.iconButton setImage:iconImageNormal forState:UIControlStateNormal];
    [item.iconButton setTitle:title forState:UIControlStateNormal];
    [item.iconButton setBackgroundImage:[UIImage imageWithColor:GJCFQuickHexColor(@"CDD0D4")] forState:UIControlStateNormal];
    [item.iconButton setBackgroundImage:[UIImage imageWithColor:GJCFQuickHexColor(@"D8DADE")] forState:UIControlStateHighlighted];

    item.iconButton.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
    [item.iconButton setTitleColor:GJCFQuickHexColor(@"767A82") forState:UIControlStateNormal];
    item.actionType = actionType;
    item.didTapBlock = tapBlock;
    return item;
}

+ (GJGCChatInputExpandMenuPanelItem *)itemWithTitle:(NSString *)title withIconImageNormal:(UIImage *)iconImageNormal withIconImageHighlight:(UIImage *)iconImageHighlight withActionType:(GJGCChatInputMenuPanelActionType)actionType withTapBlock:(GJGCChatInputExpandMenuPanelItemDidTapedBlock)tapBlock showTitle:(BOOL)isShowTitle {
    GJGCChatInputExpandMenuPanelItem *item = [[self alloc] init];
    //    [item.iconButton setBackgroundImage:iconImageNormal forState:UIControlStateNormal];
    //    [item.iconButton setBackgroundImage:iconImageHighlight forState:UIControlStateHighlighted];
    [item.iconButton setImage:iconImageNormal forState:UIControlStateNormal];
    [item.iconButton setTitle:title forState:UIControlStateNormal];
    [item.iconButton setBackgroundImage:[UIImage imageWithColor:GJCFQuickHexColor(@"CDD0D4")] forState:UIControlStateNormal];
    [item.iconButton setBackgroundImage:[UIImage imageWithColor:GJCFQuickHexColor(@"D8DADE")] forState:UIControlStateHighlighted];
    item.iconButton.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
    [item.iconButton setTitleColor:GJCFQuickHexColor(@"767A82") forState:UIControlStateNormal];

    item.actionType = actionType;
    item.didTapBlock = tapBlock;
    return item;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.iconButton.frame = self.bounds;

    CALayer *bottomBorder = [CALayer layer];
    CGFloat boderWidth = 0.5f;
    float height = self.iconButton.frame.size.height - boderWidth;
    float width = self.iconButton.frame.size.width;
    bottomBorder.frame = CGRectMake(0.0f, height, width, boderWidth);
    bottomBorder.backgroundColor = [UIColor colorWithWhite:0.7f alpha:1.0f].CGColor;
    [self.iconButton.layer addSublayer:bottomBorder];

    CALayer *leftBorder = [CALayer layer];
    height = self.iconButton.frame.size.height;
    width = self.iconButton.frame.size.width - boderWidth;
    leftBorder.frame = CGRectMake(width, 0, boderWidth, height);
    leftBorder.backgroundColor = [UIColor colorWithWhite:0.7f alpha:1.0f].CGColor;
    [self.iconButton.layer addSublayer:leftBorder];

}


- (void)initSubViews {
    self.iconButton = [TopImageBottomTitleButton buttonWithType:UIButtonTypeCustom];
    [self addSubview:self.iconButton];
    [self addTarget:self action:@selector(tapOnSelf) forControlEvents:UIControlEventTouchUpInside];
    [self.iconButton addTarget:self action:@selector(tapOnSelf) forControlEvents:UIControlEventTouchUpInside];
}

- (void)tapOnSelf {
    if (self.didTapBlock) {
        self.didTapBlock(self);
    }
}
@end
