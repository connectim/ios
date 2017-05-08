//
//  GJGCChatInputExpandEmojiPanelMenuBar.m
//  Connect
//
//  Created by KivenLin on 15/6/4.
//  Copyright (c) 2015年 Connect. All rights reserved.
//

#import "GJGCChatInputExpandEmojiPanelMenuBar.h"

@implementation GJGCChatInputExpandEmojiPanelMenuBarItem

- (instancetype)initWithIconName:(NSString *)iconName selectedIconName:(NSString *)selectedIcon {
    if (self = [super init]) {

        self.gjcf_width = AUTO_WIDTH(120);
        self.gjcf_height = AUTO_HEIGHT(80);

        self.backImgView = [[UIImageView alloc] init];
        self.backImgView.gjcf_size = self.gjcf_size;
        [self addSubview:self.backImgView];

        self.iconImgView = [[UIButton alloc] init];
        self.iconImgView.userInteractionEnabled = NO;
        self.iconImgView.gjcf_size = (CGSize) {AUTO_WIDTH(60), AUTO_HEIGHT(60)};
        self.iconImgView.gjcf_centerX = self.gjcf_width / 2;
        self.iconImgView.gjcf_centerY = self.gjcf_height / 2;
        self.iconImgView.backgroundColor = [UIColor clearColor];
        [self addSubview:self.iconImgView];
        [self.iconImgView setImage:[UIImage imageNamed:iconName] forState:UIControlStateNormal];
        [self.iconImgView setImage:[UIImage imageNamed:selectedIcon] forState:UIControlStateSelected];

        self.rightSeprateLine = [[UIImageView alloc] init];
        self.rightSeprateLine.gjcf_size = CGSizeMake(0.9, self.gjcf_height * 0.6);
        self.rightSeprateLine.backgroundColor = [GJGCChatInputPanelStyle mainSeprateLineColor];
        self.rightSeprateLine.gjcf_right = self.gjcf_width;

        self.rightSeprateLine.centerY = self.centerY;

        [self addSubview:self.rightSeprateLine];
        self.rightSeprateLine.hidden = YES;

        [self switchToNormal];
    }
    return self;
}

- (instancetype)initWithIconName:(NSString *)iconName selectedIconName:(NSString *)selectedIcon height:(CGFloat)height {
    if (self = [super init]) {

        self.gjcf_width = AUTO_WIDTH(120);
        self.gjcf_height = height;

        self.backImgView = [[UIImageView alloc] init];
        self.backImgView.gjcf_size = self.gjcf_size;
        [self addSubview:self.backImgView];

        self.iconImgView = [[UIButton alloc] init];
        self.iconImgView.userInteractionEnabled = NO;
        self.iconImgView.gjcf_size = (CGSize) {AUTO_WIDTH(60), AUTO_HEIGHT(60)};
        self.iconImgView.gjcf_centerX = self.gjcf_width / 2;
        self.iconImgView.gjcf_centerY = self.gjcf_height / 2;
        self.iconImgView.backgroundColor = [UIColor clearColor];
        [self addSubview:self.iconImgView];
        [self.iconImgView setImage:[UIImage imageNamed:iconName] forState:UIControlStateNormal];
        [self.iconImgView setImage:[UIImage imageNamed:selectedIcon] forState:UIControlStateSelected];

        self.rightSeprateLine = [[UIImageView alloc] init];
        self.rightSeprateLine.gjcf_size = CGSizeMake(0.9, self.gjcf_height * 0.6);
        self.rightSeprateLine.backgroundColor = [GJGCChatInputPanelStyle mainSeprateLineColor];
        self.rightSeprateLine.gjcf_right = self.gjcf_width;

        self.rightSeprateLine.centerY = self.centerY;

        [self addSubview:self.rightSeprateLine];
        self.rightSeprateLine.hidden = YES;

        [self switchToNormal];
    }
    return self;
}

- (void)setSeprateLineShow:(BOOL)state {
    self.rightSeprateLine.hidden = !state;
}

- (void)switchToSelected {
    self.backImgView.backgroundColor = GJCFQuickHexColor(@"FF6C5A"); //GJCFQuickHexColor(@"dadada");
    [self.iconImgView setSelected:YES];
}

- (void)switchToNormal {
    self.backImgView.backgroundColor = GJCFQuickHexColor(@"CDD0D4");
    [self.iconImgView setSelected:NO];
}

@end


#define GJGCChatInputExpandEmojiPanelMenuBarItemBaseTag 3355678

@interface GJGCChatInputExpandEmojiPanelMenuBar ()

@property(nonatomic, strong) UIScrollView *itemScrolView;

@end

@implementation GJGCChatInputExpandEmojiPanelMenuBar

- (instancetype)initWithDelegate:(id <GJGCChatInputExpandEmojiPanelMenuBarDelegate>)aDelegate {
    if (self = [super init]) {

        self.itemScrolView = [[UIScrollView alloc] init];
        self.itemScrolView.showsVerticalScrollIndicator = NO;
        self.itemScrolView.showsHorizontalScrollIndicator = NO;
        [self addSubview:_itemScrolView];

        self.itemSourceArray = [GJGCChatInputExpandEmojiPanelMenuBarDataSource menuBarItems];
        self.delegate = aDelegate;

        self.gjcf_width = DEVICE_SIZE.width;
        self.gjcf_height = AUTO_HEIGHT(80);
        self.itemScrolView.height = AUTO_HEIGHT(80);
        self.itemScrolView.width = self.gjcf_width;

        self.itemScrolView.contentSize = CGSizeMake(AUTO_WIDTH(120) * self.itemSourceArray.count, self.itemScrolView.height);

        self.itemScrolView.contentInset = UIEdgeInsetsMake(0, 0, 0, AUTO_WIDTH(140));

        [self setupSubViewsWithSourceArray:self.itemSourceArray];
    }
    return self;
}


- (instancetype)initWithDelegate:(id <GJGCChatInputExpandEmojiPanelMenuBarDelegate>)aDelegate height:(CGFloat)height {
    if (self = [super init]) {

        self.itemScrolView = [[UIScrollView alloc] init];
        self.itemScrolView.showsVerticalScrollIndicator = NO;
        self.itemScrolView.showsHorizontalScrollIndicator = NO;
        [self addSubview:_itemScrolView];

        self.itemSourceArray = [GJGCChatInputExpandEmojiPanelMenuBarDataSource menuBarItems];
        self.delegate = aDelegate;

        self.gjcf_width = DEVICE_SIZE.width;
        self.gjcf_height = height;
        self.itemScrolView.height = height;
        self.itemScrolView.width = self.gjcf_width;

        self.itemScrolView.contentSize = CGSizeMake(AUTO_WIDTH(120) * self.itemSourceArray.count, self.itemScrolView.height);

        self.itemScrolView.contentInset = UIEdgeInsetsMake(0, 0, 0, AUTO_WIDTH(140));

        [self setupSubViewsWithSourceArray:self.itemSourceArray];
    }
    return self;
}


- (instancetype)initWithDelegateForCommentBarStyle:(id <GJGCChatInputExpandEmojiPanelMenuBarDelegate>)aDelegate {
    if (self = [super init]) {
        self.itemScrolView = [[UIScrollView alloc] init];
        self.itemScrolView.showsVerticalScrollIndicator = NO;
        self.itemScrolView.showsHorizontalScrollIndicator = NO;
        [self addSubview:_itemScrolView];

        self.itemSourceArray = [GJGCChatInputExpandEmojiPanelMenuBarDataSource commentBarItems];
        self.delegate = aDelegate;

        self.gjcf_width = DEVICE_SIZE.width;
        self.gjcf_height = AUTO_HEIGHT(80);
        self.itemScrolView.height = AUTO_HEIGHT(80);
        self.itemScrolView.width = self.gjcf_width;


        self.itemScrolView.contentSize = CGSizeMake(AUTO_WIDTH(120) * self.itemSourceArray.count, self.itemScrolView.height);
        self.itemScrolView.contentInset = UIEdgeInsetsMake(0, 0, 0, AUTO_WIDTH(140));

        [self setupSubViewsWithSourceArray:self.itemSourceArray];
    }
    return self;
}

- (void)setupSubViewsWithSourceArray:(NSArray *)sourceArray {
    CGFloat itemWidth = AUTO_WIDTH(120);
    CGFloat itemHeight = self.itemScrolView.gjcf_height;
    for (NSInteger index = 0; index < sourceArray.count; index++) {

        CGFloat marginX = index * itemWidth;
        CGFloat marginY = 0;

        GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem *sourceItem = [sourceArray objectAtIndexCheck:index];

        GJGCChatInputExpandEmojiPanelMenuBarItem *item = [[GJGCChatInputExpandEmojiPanelMenuBarItem alloc] initWithIconName:sourceItem.faceEmojiIconName selectedIconName:sourceItem.faceEmojiSelectName height:self.gjcf_height];
        item.gjcf_left = marginX;
        item.gjcf_top = marginY;
        item.gjcf_width = itemWidth;
        item.gjcf_height = itemHeight;
        item.tag = GJGCChatInputExpandEmojiPanelMenuBarItemBaseTag + index;
        [item setSeprateLineShow:NO];//sourceItem.isNeedShowRightSideLine];

        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnBarItem:)];
        [item addGestureRecognizer:tapGesture];

        [self.itemScrolView addSubview:item];

        if (index == 0) {

            _selectedIndex = 0;
            [item switchToSelected];
        }
    }
}

- (void)selectItemIndex:(NSInteger)index {
    _selectedIndex = index;

    for (GJGCChatInputExpandEmojiPanelMenuBarItem *item in self.itemScrolView.subviews) {

        if (![item isKindOfClass:[GJGCChatInputExpandEmojiPanelMenuBarItem class]]) {
            continue;
        }

        if (item.tag - GJGCChatInputExpandEmojiPanelMenuBarItemBaseTag != index) {

            [item switchToNormal];

        } else {

            [item switchToSelected];
        }
    }
}

- (void)selectAtIndex:(NSInteger)index {
    [self selectItemIndex:index];
}

- (void)tapOnBarItem:(UITapGestureRecognizer *)tapR {
    UIView *tapView = tapR.view;

    NSInteger index = tapView.tag - GJGCChatInputExpandEmojiPanelMenuBarItemBaseTag;

    if (_selectedIndex == index) {
        return;
    }

    [self selectItemIndex:index];

    GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem *sourceItem = [self.itemSourceArray objectAtIndexCheck:index];

    if (self.delegate && [self.delegate respondsToSelector:@selector(emojiPanelMenuBar:didChoose:selectIndex:)]) {

        [self.delegate emojiPanelMenuBar:self didChoose:sourceItem selectIndex:index];
    }
}

@end
