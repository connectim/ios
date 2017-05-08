//
//  GJGCChatInputExpandMenuPanel.m
//  Connect
//
//  Created by KivenLin QQ:1003081775 on 14-10-28.
//  Copyright (c) 2014年 ConnectSoft. All rights reserved.
//

#import "GJGCChatInputExpandMenuPanel.h"

@interface GJGCChatInputExpandMenuPanel () <UIScrollViewDelegate>

@property(nonatomic, strong) UIScrollView *contentScrollView;

@property(nonatomic, strong) UIPageControl *pageControl;

@property(nonatomic, assign) NSInteger totalItemCount;

@property(nonatomic, assign) CGFloat itemToPanelMargin;
@property(nonatomic, assign) CGFloat itemMargin;
@property(nonatomic, assign) CGFloat itemWidth;
@property(nonatomic, assign) CGFloat itemHeight;

@property(nonatomic, assign) CGFloat pageCount;

@end

@implementation GJGCChatInputExpandMenuPanel

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {

        [self initSubViews];

    }
    return self;
}

- (void)loadBarItems {
    NSArray *subViews = self.contentScrollView.subviews;

    NSInteger pageItemCount = self.rowCount * self.columnCount;

    NSMutableArray *pagesArray = [NSMutableArray array];

    self.pageCount = subViews.count % pageItemCount == 0 ? subViews.count / pageItemCount : subViews.count / pageItemCount + 1;
    self.pageControl.numberOfPages = self.pageCount;
    NSInteger pageLastCount = subViews.count % pageItemCount;
    if (self.pageCount == 1) {
        if (subViews.count < 8) {
            pageLastCount = subViews.count;
        } else {
            pageLastCount = pageItemCount;
        }
    }

    for (int i = 0; i < self.pageCount; i++) {

        NSMutableArray *pageItemArray = [NSMutableArray array];
        if (i != self.pageCount - 1) {
            [pageItemArray addObjectsFromArray:[subViews subarrayWithRange:NSMakeRange(i * pageItemCount, pageItemCount)]];
        } else {
            [pageItemArray addObjectsFromArray:[subViews subarrayWithRange:NSMakeRange(i * pageItemCount, pageLastCount)]];
        }

        [pagesArray objectAddObject:pageItemArray];
    }

    for (int i = 0; i < pagesArray.count; i++) {
        NSArray *pageItems = pagesArray[i];
        [pageItems enumerateObjectsUsingBlock:^(UIView *subView, NSUInteger idx, BOOL *stop) {

            if ([subView.class isSubclassOfClass:[GJGCChatInputExpandMenuPanelItem class]]) {
                GJGCChatInputExpandMenuPanelItem *item = (GJGCChatInputExpandMenuPanelItem *) subView;

                NSInteger rowIndex = idx / self.columnCount;
                NSInteger cloumnIndex = idx % self.columnCount;

                item.gjcf_left = (cloumnIndex + 1) * self.itemMargin + cloumnIndex * self.itemWidth + GJCFSystemScreenWidth * i;
                item.gjcf_top = rowIndex * self.itemHeight;
                item.gjcf_width = self.itemWidth;
                item.gjcf_height = self.itemHeight;
            }
        }];
    }
    self.contentScrollView.contentSize = CGSizeMake(self.pageCount * GJCFSystemScreenWidth, self.contentScrollView.gjcf_height);

}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.contentScrollView.frame = self.bounds;


    [self loadBarItems];
}

- (void)initSubViews {

    self.contentScrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    self.contentScrollView.pagingEnabled = YES;
    self.contentScrollView.showsVerticalScrollIndicator = NO;
    self.contentScrollView.showsHorizontalScrollIndicator = NO;
    self.contentScrollView.delegate = self;
    [self addSubview:self.contentScrollView];

    self.contentScrollView.backgroundColor = XCColor(205, 208, 212);


    self.pageControl = [[UIPageControl alloc] init];
    self.pageControl.hidesForSinglePage = YES;
    self.pageControl.frame = CGRectMake(0, 0, 80, 20);
    self.pageControl.pageIndicatorTintColor = GJCFQuickHexColor(@"cccccc");
    self.pageControl.currentPageIndicatorTintColor = GJCFQuickHexColor(@"b3b3b3");
    [self addSubview:self.pageControl];
    self.pageControl.currentPage = 0;
    [self.pageControl addTarget:self action:@selector(pageIndexChange:) forControlEvents:UIControlEventValueChanged];
    self.pageControl.gjcf_bottom = self.contentScrollView.gjcf_bottom;
    self.pageControl.gjcf_centerX = self.contentScrollView.gjcf_width / 2;

    self.totalItemCount = 0;
    self.rowCount = 2;
    self.columnCount = 4;
    self.itemToPanelMargin = 22;
    self.itemWidth = self.contentScrollView.gjcf_width / 4.f;
    self.itemHeight = self.contentScrollView.gjcf_height / 2.f;
    self.itemMargin = (GJCFSystemScreenWidth - (self.itemWidth * self.columnCount)) / (self.columnCount - 1 + 2);

    [self initMenuItems];

}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSInteger page = (scrollView.contentOffset.x + scrollView.gjcf_width / 2.f) / scrollView.gjcf_width;
    self.pageControl.currentPage = page;
}

- (void)pageIndexChange:(UIPageControl *)sender {
    CGRect visiableRect = CGRectMake(self.contentScrollView.gjcf_width * self.pageControl.currentPage, 0, self.contentScrollView.gjcf_width, self.contentScrollView.gjcf_height);
    [self.contentScrollView scrollRectToVisible:visiableRect animated:YES];
}

- (instancetype)initWithFrame:(CGRect)frame withDelegate:(id <GJGCChatInputExpandMenuPanelDelegate>)aDelegate; {
    if (self = [super initWithFrame:frame]) {

        self.delegate = aDelegate;

        [self initSubViews];
    }

    return self;
}

- (void)initMenuItems {
    if ([self.delegate respondsToSelector:@selector(menuPanelRequireCurrentConfigData:)] && self.delegate) {

        GJGCChatInputExpandMenuPanelConfigModel *configModel = [self.delegate menuPanelRequireCurrentConfigData:self];

        NSArray *dataSourceItems = [GJGCChatInputExpandMenuPanelDataSource menuItemDataSourceWithConfigModel:configModel];

        [dataSourceItems enumerateObjectsUsingBlock:^(NSDictionary *item, NSUInteger idx, BOOL *stop) {

            NSString *itemTitle = item[GJGCChatInputExpandMenuPanelDataSourceTitleKey];
            UIImage *iconImage = GJCFQuickImage(item[GJGCChatInputExpandMenuPanelDataSourceIconNormalKey]);
            UIImage *iconHighlightImage = GJCFQuickImage(item[GJGCChatInputExpandMenuPanelDataSourceIconHighlightKey]);
            GJGCChatInputMenuPanelActionType actionType = [item[GJGCChatInputExpandMenuPanelDataSourceActionTypeKey] intValue];

            GJCFWeakSelf weakSelf = self;
            GJGCChatInputExpandMenuPanelItem *panelItem = [GJGCChatInputExpandMenuPanelItem itemWithTitle:itemTitle withIconImageNormal:iconImage withIconImageHighlight:iconHighlightImage withActionType:actionType withTapBlock:^(GJGCChatInputExpandMenuPanelItem *item) {
                [weakSelf tapOnMenuPanelItem:item];
            }];
            [self appendMenuItem:panelItem];

        }];

        [self setNeedsLayout];

    }

}

- (void)tapOnMenuPanelItem:(GJGCChatInputExpandMenuPanelItem *)senderItem {
    if (self.delegate && [self.delegate respondsToSelector:@selector(menuPanel:didChooseAction:)]) {
        [self.delegate menuPanel:self didChooseAction:senderItem.actionType];
    }
}

- (BOOL)isLeftItem:(GJGCChatInputExpandMenuPanelItem *)item {
    return item.index % self.columnCount == 1;
}

- (BOOL)isTopItem:(GJGCChatInputExpandMenuPanelItem *)item {
    if (item.index > self.columnCount) {
        return item.index % self.columnCount == 1;
    }
    return YES;
}

- (BOOL)isBottomItem:(GJGCChatInputExpandMenuPanelItem *)item {
    return item.index % self.columnCount == self.rowCount - 1;
}

- (BOOL)isRightItem:(GJGCChatInputExpandMenuPanelItem *)item {
    return NO;
}

- (void)appendMenuItem:(GJGCChatInputExpandMenuPanelItem *)aItem {
    if (GJCFCheckObjectNull(aItem)) {
        return;
    }

    aItem.index = self.totalItemCount;
    self.totalItemCount++;
    [self.contentScrollView addSubview:aItem];
}


@end
