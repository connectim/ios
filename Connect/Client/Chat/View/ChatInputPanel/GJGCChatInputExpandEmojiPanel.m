//
//  GJGCChatInputExpandEmojiPanel.m
//  Connect
//
//  Created by KivenLin on 14-10-28.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJGCChatInputExpandEmojiPanel.h"
#import "GJGCChatInputExpandEmojiPanelMenuBar.h"
#import "LMCollectionEmotionCell.h"

#define ROWS_EMOJI 3
#define ROWS_GIF 2
#define GIF_CELL_SIZE 62

#define TOP_AREA_HEIGHT kMeunBarHeight - AUTO_HEIGHT(100)


static NSInteger number_per_line_emoji;
static NSInteger number_per_line_gif;

@interface LMSectionData : NSObject

@property(nonatomic) GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem *groupModel;

@property(nonatomic) NSInteger sectionIndex;

@property(nonatomic) NSInteger totalSections;

@property(nonatomic) NSInteger startSection;

@property(nonatomic) NSInteger pageNum;

@property(nonatomic) NSInteger totalItem;

@property(nonatomic) CGSize itemSize;

@property(nonatomic) UIEdgeInsets sectionInset;

@property(nonatomic) NSInteger minimumLineSpacing;

@property(nonatomic) NSInteger minimumInteritemSpacing;

@end


@implementation LMSectionData

- (instancetype)initWithEmotionGroupModel:(GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem *)model {
    self = [super init];
    if (self) {
        _groupModel = model;

        self.totalItem = _groupModel.emojiArrays.count;

        if (_groupModel.emojiType == GJGCChatInputExpandEmojiTypeSimple) { //3:2
            CGFloat itemWidth = DEVICE_SIZE.width / number_per_line_emoji;
            CGFloat itemHeight = AUTO_HEIGHT(260) / ROWS_EMOJI;

            self.itemSize = CGSizeMake(itemWidth, itemHeight);
            self.minimumLineSpacing = 0;
            self.minimumInteritemSpacing = 0;
            self.sectionInset = UIEdgeInsetsZero;
            self.pageNum = number_per_line_emoji * ROWS_EMOJI;
            self.totalItem = _groupModel.emojiArrays.count;
            self.totalSections = ceil((CGFloat) self.totalItem / (self.pageNum - 1));
        } else if (_groupModel.emojiType == GJGCChatInputExpandEmojiTypeGIF) { //2:1
            self.minimumLineSpacing = 0;
            self.itemSize = CGSizeMake(DEVICE_SIZE.width / number_per_line_gif, AUTO_HEIGHT(260) / ROWS_GIF);
            self.minimumInteritemSpacing = 0;
            self.sectionInset = UIEdgeInsetsZero;
            self.pageNum = number_per_line_gif * ROWS_GIF;
            self.totalItem = _groupModel.emojiArrays.count;
            self.totalSections = ceil((CGFloat) self.totalItem / self.pageNum);
        }
    }

    return self;
}

- (CGFloat)pixelAlignForFloat:(CGFloat)position {
    CGFloat scale = [UIScreen mainScreen].scale;
    return round(position * scale) / scale;
}


@end


#define GJGCChatInputExpandEmojiPanelPageTag 239400

@interface GJGCChatInputExpandEmojiPanel () <
        GJGCChatInputExpandEmojiPanelMenuBarDelegate,
        UICollectionViewDataSource,
        UICollectionViewDelegate>
@property(nonatomic) UICollectionView *collectionView;

@property(nonatomic) UICollectionViewFlowLayout *layout;

@property(nonatomic, strong) NSMutableArray *sectionDatas;

@property(nonatomic, strong) UIPageControl *pageControl;

@property(nonatomic, strong) UIButton *sendButton;

@property(nonatomic) id <LMEmotionTipDelegate> touchView;

@property(nonatomic, strong) GJGCChatInputExpandEmojiPanelMenuBar *menuBar;

@property(nonatomic, strong) NSString *panelIdentifier;

@end

@implementation GJGCChatInputExpandEmojiPanel

+ (instancetype)sharedInstance {
    static GJGCChatInputExpandEmojiPanel *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[GJGCChatInputExpandEmojiPanel alloc] initWithFrame:CGRectMake(0, 0, DEVICE_SIZE.width, kMeunBarHeight)];
    });

    return _instance;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupView];
    }
    return self;
}

- (void)dealloc {
    RemoveNofify;
}


- (void)removeEmojiOberverWithIdentifier:(NSString *)identifier {
    if (!identifier) {
        return;
    }
    NSString *formateNoti = [GJGCChatInputConst panelNoti:GJGCChatInputTextViewContentChangeNoti formateWithIdentifier:self.panelIdentifier];
    [GJCFNotificationCenter removeObserver:self name:formateNoti object:nil];
}

- (void)addEmojiOberverWithIdentifier:(NSString *)identifier {

    if (identifier && [identifier isEqualToString:_panelIdentifier]) {
        return;
    }

    _panelIdentifier = identifier;

    NSString *formateNoti = [GJGCChatInputConst panelNoti:GJGCChatInputTextViewContentChangeNoti formateWithIdentifier:self.panelIdentifier];
    [GJCFNotificationCenter addObserver:self selector:@selector(observeTextChange:) name:formateNoti object:nil];
}


- (void)observeTextChange:(NSNotification *)note {
    NSString *text = note.object;
    self.sendButton.enabled = text.length;
}

- (void)sendEmojiAction {
    self.sendButton.enabled = NO;
    NSString *formateNoti = [GJGCChatInputConst panelNoti:GJGCChatInputExpandEmojiPanelChooseSendNoti formateWithIdentifier:self.panelIdentifier];
    GJCFNotificationPost(formateNoti);
}

#pragma mark - menuBarDelegate

- (void)emojiPanelMenuBar:(GJGCChatInputExpandEmojiPanelMenuBar *)bar
                didChoose:(GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem *)emojiSourceItem
              selectIndex:(NSInteger)selectIndex {
    [self gotoSection:selectIndex];
}


#pragma mark - 修改

- (void)setupView {

    self.translatesAutoresizingMaskIntoConstraints = NO;

    number_per_line_emoji = 7;
    number_per_line_gif = 4;

    self.sectionDatas = [[NSMutableArray alloc] init];
    NSInteger index = 0;
    NSArray *items = [[GJGCChatContentEmojiParser sharedParser] getEmojiGroups];
    for (int i = 0; i < items.count; i++) {
        GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem *model = items[i];
        LMSectionData *sectionData = [[LMSectionData alloc] initWithEmotionGroupModel:model];
        sectionData.startSection = index;
        index += sectionData.totalSections;
        sectionData.sectionIndex = i;
        [self.sectionDatas objectAddObject:sectionData];
    }

    self.layout = [[UICollectionViewFlowLayout alloc] init];
    self.layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;

    self.collectionView = [[UICollectionView alloc]
            initWithFrame:CGRectMake(0, 0, DEVICE_SIZE.width, TOP_AREA_HEIGHT) collectionViewLayout:self.layout];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.pagingEnabled = YES;

    [self addSubview:_collectionView];

    [self.collectionView registerClass:[LMCollectionEmojiCell class] forCellWithReuseIdentifier:@"LMCollectionEmojiCellID"];
    [self.collectionView registerClass:[LMCollectionGifCell class] forCellWithReuseIdentifier:@"LMCollectionGifCellID"];

    self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, TOP_AREA_HEIGHT, DEVICE_SIZE.width, AUTO_HEIGHT(30))];
    self.pageControl.userInteractionEnabled = NO;
    self.pageControl.hidesForSinglePage = YES;
    self.pageControl.currentPageIndicatorTintColor = [UIColor darkGrayColor];
    self.pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    self.pageControl.defersCurrentPageDisplay = YES;
    [self addSubview:self.pageControl];
    [self updatePageController:0];


    UIImageView *bottomBarBack = [[UIImageView alloc]
            initWithFrame:CGRectMake(0, self.pageControl.bottom, GJCFSystemScreenWidth, kMeunBarHeight - self.pageControl.bottom)];
    bottomBarBack.backgroundColor = [GJGCChatInputPanelStyle mainBackgroundColor];
    bottomBarBack.userInteractionEnabled = YES;
    [self addSubview:bottomBarBack];

    self.menuBar = [[GJGCChatInputExpandEmojiPanelMenuBar alloc] initWithDelegate:self height:kMeunBarHeight - self.pageControl.bottom];
    [bottomBarBack addSubview:self.menuBar];
    self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.sendButton.frame = CGRectMake(0, 0, AUTO_WIDTH(140), bottomBarBack.gjcf_height);
    self.sendButton.layer.cornerRadius = 3.f;
    [self.sendButton setTitle:LMLocalizedString(@"Link Send", nil) forState:UIControlStateNormal];
    self.sendButton.enabled = NO;
    [self.sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.sendButton setBackgroundImage:GJCFQuickImageByColorWithSize(GJCFQuickHexColor(@"858998"), self.sendButton.gjcf_size) forState:UIControlStateDisabled];
    [self.sendButton setBackgroundImage:GJCFQuickImageByColorWithSize(GJCFQuickHexColor(@"38425F"), self.sendButton.gjcf_size) forState:UIControlStateNormal];
    [bottomBarBack addSubview:self.sendButton];
    [self.sendButton addTarget:self action:@selector(sendEmojiAction) forControlEvents:UIControlEventTouchUpInside];
    self.sendButton.gjcf_right = bottomBarBack.gjcf_width;


    [self registerGestureRecognizer];
}

- (void)updatePageController:(NSInteger)section {
    LMSectionData *sectionData = [self sectionDataForSection:section];

    self.pageControl.numberOfPages = sectionData.totalSections;
    self.pageControl.currentPage = section - sectionData.startSection;

    [self.pageControl updateCurrentPageDisplay];

    if (sectionData.sectionIndex > 0 && self.sendButton.hidden == YES) {
        self.sendButton.hidden = NO;
        [UIView animateWithDuration:0.25
                         animations:^{
                             self.sendButton.right = DEVICE_SIZE.width;
                         }
                         completion:nil];
    } else if (sectionData.sectionIndex == 0 && self.sendButton.hidden == NO) {
        [UIView animateWithDuration:0.25
                         animations:^{
                             self.sendButton.left = DEVICE_SIZE.width;
                         }
                         completion:^(BOOL finished) {
                             self.sendButton.hidden = YES;
                         }];
    }

    [self.menuBar selectAtIndex:sectionData.sectionIndex];
}


#pragma mark - CollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    LMSectionData *sectionData = [self sectionDataForSection:section];

    return sectionData.pageNum;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    LMSectionData *sectionData = [self sectionDataForSection:indexPath.section];

    return sectionData.itemSize;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
    LMSectionData *sectionData = [self sectionDataForSection:section];

    return sectionData.sectionInset;
}

- (CGFloat)               collectionView:(UICollectionView *)collectionView
                                  layout:(UICollectionViewLayout *)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    LMSectionData *sectionData = [self sectionDataForSection:section];

    return sectionData.minimumInteritemSpacing;
}


- (CGFloat)          collectionView:(UICollectionView *)collectionView
                             layout:(UICollectionViewLayout *)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    LMSectionData *sectionData = [self sectionDataForSection:section];

    return sectionData.minimumLineSpacing;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    LMSectionData *lastSectionData = [self.sectionDatas lastObject];
    return lastSectionData.totalSections + lastSectionData.startSection;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    LMSectionData *sectionData = [self sectionDataForSection:indexPath.section];

    if (sectionData.groupModel.emojiType == GJGCChatInputExpandEmojiTypeSimple) {
        LMCollectionEmojiCell *cell = [self.collectionView
                dequeueReusableCellWithReuseIdentifier:@"LMCollectionEmojiCellID"
                                          forIndexPath:indexPath];

        NSInteger row = indexPath.item % ROWS_EMOJI;
        NSInteger col = indexPath.item / ROWS_EMOJI;
        NSInteger position = number_per_line_emoji * row + col;
        NSInteger newItem = position + (sectionData.pageNum - 1) * (indexPath.section - sectionData.startSection);

        if (newItem < sectionData.totalItem) {
            if (position == sectionData.pageNum - 1) {
                cell.isDelete = YES;
            } else {
                LMEmotionModel *model = sectionData.groupModel.emojiArrays[newItem];
                [cell setContent:model];
            }
        } else if (newItem == sectionData.totalItem) {
            cell.isDelete = YES;
        } else {
            [cell setContent:nil];
        }

        return cell;
    } else if (sectionData.groupModel.emojiType == GJGCChatInputExpandEmojiTypeGIF) {
        LMCollectionGifCell *cell = [self.collectionView
                dequeueReusableCellWithReuseIdentifier:@"LMCollectionGifCellID"
                                          forIndexPath:indexPath];

        NSInteger row = indexPath.item % ROWS_GIF;
        NSInteger col = indexPath.item / ROWS_GIF;
        NSInteger position = number_per_line_gif * row + col;
        NSInteger newItem = position + sectionData.pageNum * (indexPath.section - sectionData.startSection);

        LMEmotionModel *model;
        if (newItem < sectionData.totalItem)
            model = sectionData.groupModel.emojiArrays[newItem];
        [cell setContent:model];

        return cell;
    }

    return nil;
}

#pragma mark - PageControll

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView == self.collectionView) {
        NSInteger section = scrollView.contentOffset.x / DEVICE_SIZE.width;
        [self updatePageController:section];
    }
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView == self.collectionView) {
        NSInteger section = scrollView.contentOffset.x / DEVICE_SIZE.width;
        [self updatePageController:section];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (scrollView == self.collectionView) {
        NSInteger section = scrollView.contentOffset.x / DEVICE_SIZE.width;
        [self updatePageController:section];
    }
}


- (LMSectionData *)sectionDataForSection:(NSInteger)section {
    NSInteger index = 0;
    for (LMSectionData *sectionData in _sectionDatas) {
        index += sectionData.totalSections;

        if (section < index)
            return sectionData;
    }

    return nil;
}


#pragma mark - expression

- (void)gotoSection:(NSInteger)selectIndex {
    if (selectIndex < 0 || selectIndex >= self.sectionDatas.count) {
        return;
    }
    LMSectionData *sectionData = self.sectionDatas[selectIndex];
    [self.collectionView scrollRectToVisible:CGRectMake(DEVICE_SIZE.width * sectionData.startSection, 0, DEVICE_SIZE.width, TOP_AREA_HEIGHT) animated:NO];
    [self updatePageController:sectionData.startSection];
}


#pragma mark - TIPs

- (void)registerGestureRecognizer {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHandler:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;

    [self.collectionView addGestureRecognizer:tap];

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
            initWithTarget:self action:@selector(longPressHandler:)];
    longPress.allowableMovement = 10000;
    longPress.minimumPressDuration = 0.5;

    [self.collectionView addGestureRecognizer:longPress];
}


- (void)tapHandler:(UITapGestureRecognizer *)tap {
    CGPoint point = [tap locationInView:tap.view];
    UIView *touchView = [self subViewAtPoint:point];
    if (!touchView) return;
    if ([touchView isKindOfClass:[LMCollectionEmojiCell class]]) {
        LMCollectionEmojiCell *cell = (LMCollectionEmojiCell *) touchView;
        if (cell.isDelete) {
            NSString *formateNoti = [GJGCChatInputConst panelNoti:GJGCChatInputExpandEmojiPanelChooseDeleteNoti formateWithIdentifier:self.panelIdentifier];
            GJCFNotificationPost(formateNoti);
        } else {
            NSString *formateNoti = [GJGCChatInputConst panelNoti:GJGCChatInputExpandEmojiPanelChooseEmojiNoti formateWithIdentifier:self.panelIdentifier];
            GJCFNotificationPostObj(formateNoti, cell.emotionModel);
        }
    } else {
        LMEmotionModel *gifModel = ((LMCollectionGifCell *) touchView).emotionModel;
        NSString *formateNoti = [GJGCChatInputConst panelNoti:GJGCChatInputExpandEmojiPanelChooseGIFEmojiNoti formateWithIdentifier:self.panelIdentifier];
        GJCFNotificationPostObj(formateNoti, gifModel.imageGIF);
    }
}

- (UIView *)subViewAtPoint:(CGPoint)point {
    if (point.y <= 0)return nil;
    for (UIView *view in self.collectionView.subviews) {
        CGPoint localPoint = [view convertPoint:point fromView:self.collectionView];
        if ([view pointInside:localPoint withEvent:nil]) {
            return view;
        }
    }
    return nil;
}

- (void)longPressHandler:(UILongPressGestureRecognizer *)longPress {
    CGPoint point = [longPress locationInView:longPress.view];
    id <LMEmotionTipDelegate> touchView = (id <LMEmotionTipDelegate>) [self subViewAtPoint:point];

    if (longPress.state == UIGestureRecognizerStateEnded) {
        [_touchView didMoveOut];
    } else {
        if (touchView == _touchView) return;
        [_touchView didMoveOut];
        _touchView = touchView;
        [_touchView didMoveIn];
    }

}


@end
