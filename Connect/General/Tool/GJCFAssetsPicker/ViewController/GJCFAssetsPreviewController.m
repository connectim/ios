//
//  GJAssetsPreviewController.m
//  GJAssetsPickerViewController
//
//  Created by ZYVincent on 14-9-8.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import "GJCFAssetsPreviewController.h"
#import "GJCFAssetsPickerPreviewItemViewController.h"
#import "GJCFPhotosViewController.h"
#import "GJCFAssetsPickerConstans.h"
#import "GJCFUitils.h"

@interface GJCFAssetsPreviewController ()<UIPageViewControllerDataSource,UIPageViewControllerDelegate,GJCFAssetsPickerPreviewItemViewControllerDataSource>

@property (nonatomic,strong)UIButton *finishDoneBtn;

@property (nonatomic,strong)UIButton *stateChangeBtn;

@end

@implementation GJCFAssetsPreviewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (instancetype)initWithAssets:(NSArray *)sAsstes
{
    self = [super initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                    navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                  options:@{UIPageViewControllerOptionInterPageSpacingKey:@30.f}];

    if (self) {
        
        self.assets = [[NSMutableArray alloc]initWithArray:sAsstes];
        self.dataSource             = self;
        self.delegate               = self;
        self.view.backgroundColor   = [UIColor whiteColor];
        if ([GJCFAssetsPickerConstans isIOS7]) {
            self.automaticallyAdjustsScrollViewInsets = NO;
        }
        
    }
    return self;
}

- (void)dealloc
{
    [GJCFNotificationCenter removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //set UI
    [self setupStyle];
    
    //observer
    [self addObserverForItemViewController];
}

#pragma mark - set out
// Exterior
- (GJCFAssetsPickerStyle *)defaultStyle
{
    GJCFAssetsPickerStyle *defaultStyle = nil;
    if (self.previewDelegate && [self.previewDelegate respondsToSelector:@selector(previewControllerShouldCustomStyle:)]) {
        defaultStyle = [self.previewDelegate previewControllerShouldCustomStyle:self];
    }else{
        defaultStyle = [GJCFAssetsPickerStyle defaultStyle];
    }
    return defaultStyle;
}

// set
- (void)setupStyle
{
    GJCFAssetsPickerStyle *defaultStyle = [self defaultStyle];
    
    //navigationBar
    if (defaultStyle.sysPreviewNavigationBarDes.backgroundColor) {
        UIImage *colorImage = [GJCFAssetsPickerConstans imageForColor:defaultStyle.sysPhotoNavigationBarDes.backgroundColor withSize:CGSizeMake(self.view.frame.size.width,64)];
        [self.navigationController.navigationBar setBackgroundImage:colorImage forBarMetrics:UIBarMetricsDefault];
    }
    if (defaultStyle.sysPreviewNavigationBarDes.backgroundImage) {
        [self.navigationController.navigationBar setBackgroundImage:defaultStyle.sysPreviewNavigationBarDes.backgroundImage forBarMetrics:UIBarMetricsDefault];
    }
    
    // title
    UILabel *titleLabel = [[UILabel alloc]init];
    [titleLabel setCommonStyleDescription:defaultStyle.sysPhotoNavigationBarDes];
    if (self.importantTitle) {
        titleLabel.text = self.importantTitle;
    }
    self.navigationItem.titleView = titleLabel;
    titleLabel = nil;
    
    //back
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [backBtn setCommonStyleDescription:defaultStyle.sysBackBtnDes];
    [backBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [backBtn setTitle:[self defaultStyle].sysPhotoNavigationBarDes.title forState:UIControlStateNormal];
    
    // Set the return to Item
    UIBarButtonItem *backBarItem = [[UIBarButtonItem alloc]initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = backBarItem;
    
    self.stateChangeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.stateChangeBtn setCommonStyleDescription:defaultStyle.sysPreviewChangeSelectStateBtnDes];
    [self.stateChangeBtn addTarget:self action:@selector(changeCurrentAssetState:) forControlEvents:UIControlEventTouchUpInside];

    UIBarButtonItem *rightBarItem = [[UIBarButtonItem alloc]initWithCustomView:self.stateChangeBtn];
    self.navigationItem.rightBarButtonItem = rightBarItem;
    rightBarItem = nil;
    
 
    self.customBottomToolBar = [[UIImageView alloc]init];
    self.customBottomToolBar.userInteractionEnabled = YES;
    self.customBottomToolBar.frame = CGRectOffset(self.view.frame,0,self.view.frame.size.height - defaultStyle.sysPreviewBottomToolBarDes.frameSize.height-64);
    self.customBottomToolBar.backgroundColor = defaultStyle.sysPreviewBottomToolBarDes.backgroundColor;
    self.customBottomToolBar.image = defaultStyle.sysPreviewBottomToolBarDes.backgroundImage;
    [self.view addSubview:self.customBottomToolBar];
    
    
    self.finishDoneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.finishDoneBtn setCommonStyleDescription:defaultStyle.sysFinishDoneBtDes];
    [self.customBottomToolBar addSubview:self.finishDoneBtn];
    CGRect oldFrame = self.finishDoneBtn.frame;
    oldFrame.origin.x = GJCFSystemScreenWidth - self.finishDoneBtn.frame.size.width - 2.5;
    self.finishDoneBtn.frame = oldFrame;
    [self.finishDoneBtn addTarget:self action:@selector(finishSelectImage) forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)back
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)changeCurrentAssetState:(UIButton*)sender
{
    NSInteger currentAssetsIndex = [self pageIndex];

    GJCFAsset *currentAsset = [self.assets objectAtIndex:currentAssetsIndex];
    
    /* First judge is not to become a selected state, if it is never selected into the selected state, then the first to determine the current number has been selected */
    if ( currentAsset.selected == NO && [self totalSelectedAssets].count == self.mutilSelectLimitCount && self.mutilSelectLimitCount > 0) {
        
        [GJCFAssetsPickerConstans postNoti:kGJAssetsPickerPhotoControllerDidReachLimitCountNoti withObject:[NSNumber numberWithInteger:self.mutilSelectLimitCount]];
        
        return;
    }
    
    sender.selected = !sender.selected;
    
    currentAsset.selected = !currentAsset.selected;
    
    [self.assets replaceObjectAtIndex:currentAssetsIndex withObject:currentAsset];
    
    if (self.previewDelegate && [self.previewDelegate respondsToSelector:@selector(previewController:didUpdateAssetSelectedState:)]) {
        [self.previewDelegate previewController:self didUpdateAssetSelectedState:[self.assets objectAtIndex:[self pageIndex]]];
    }
    
    [self updateFinishDoneBtnTitle];
    
}

#pragma mark - Calculate the number of images that have been selected
- (NSArray *)totalSelectedAssets
{
    NSMutableArray *selectedArray = [NSMutableArray array];
    [self.assets enumerateObjectsUsingBlock:^(GJCFAsset *asset, NSUInteger idx, BOOL *stop) {
        
        if (asset.selected) {
            [selectedArray objectAddObject:asset];
        }
        
    }];
    
    return selectedArray;
}

- (void)finishSelectImage
{
    /**
     *  The current selected number of photos 0, the initiative to select the current picture as a result
     */
    GJCFAssetsPickerStyle *defaultStyle = [self defaultStyle];
    if (defaultStyle.enableAutoChooseInDetail && [self totalSelectedAssets].count == 0) {
        [self changeCurrentAssetState:self.stateChangeBtn];
    }
    
    [GJCFAssetsPickerConstans postNoti:kGJAssetsPickerDidFinishChooseMediaNoti withObject:[self totalSelectedAssets]];
}

- (void)updateStateBtn
{
    NSInteger currentAssetsIndex = [self pageIndex];
    
    GJCFAsset *currentAsset = [self.assets objectAtIndex:currentAssetsIndex];
    
    self.stateChangeBtn.selected = currentAsset.selected;
    
    [self updateFinishDoneBtnTitle];
}

- (void)updateFinishDoneBtnTitle
{
    GJCFAssetsPickerStyle *defaultStyle = [self defaultStyle];
    NSString *newTitle = [NSString stringWithFormat:@"%@(%d)",defaultStyle.sysFinishDoneBtDes.normalStateTitle,[self totalSelectedAssets].count];
    
    [self.finishDoneBtn setTitle:newTitle forState:UIControlStateNormal];
}

#pragma mark - Page Index
- (NSInteger)pageIndex
{
    return [(GJCFAssetsPickerPreviewItemViewController *)self.viewControllers[0] pageIndex];
}

- (void)setPageIndex:(NSInteger)pageIndex
{
    NSInteger count = self.assets.count;
    
    if (pageIndex >= 0 && pageIndex < count)
    {
        GJCFAssetsPickerPreviewItemViewController *page = [GJCFAssetsPickerPreviewItemViewController itemViewForPageIndex:pageIndex];
        page.dataSource = self;
        
        [self setViewControllers:@[page]
                       direction:UIPageViewControllerNavigationDirectionForward
                        animated:NO
                      completion:NULL];
        
        [self setTitleIndex:pageIndex + 1];
        
        [self updateStateBtn];
    }
}


#pragma mark - exchange title

- (void)setTitleIndex:(NSInteger)index
{
    NSInteger count = self.assets.count;
    self.title      = [NSString stringWithFormat:@"%d / %d", index, count];
    
    //title
    UILabel *titleLabel = [[UILabel alloc]init];
    [titleLabel setCommonStyleDescription:[self defaultStyle].sysPreviewNavigationBarDes];
    titleLabel.text = self.title;
    /* If an important title is set */
    if (self.importantTitle) {
        titleLabel.text = self.importantTitle;
    }
    self.navigationItem.titleView = titleLabel;
    titleLabel = nil;
}


#pragma mark - UIPageViewController DataSource and Delegate

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSInteger index = ((GJCFAssetsPickerPreviewItemViewController *)viewController).pageIndex;
    
    if (index > 0)
    {
        GJCFAssetsPickerPreviewItemViewController *page = [GJCFAssetsPickerPreviewItemViewController itemViewForPageIndex:(index - 1)];
        page.dataSource = self;
        
        return page;
    }
    
    return nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSInteger count = self.assets.count;
    NSInteger index = ((GJCFAssetsPickerPreviewItemViewController *)viewController).pageIndex;
    
    if (index < count - 1)
    {
        GJCFAssetsPickerPreviewItemViewController *page = [GJCFAssetsPickerPreviewItemViewController itemViewForPageIndex:(index + 1)];
        page.dataSource = self;
        
        return page;
    }
    
    return nil;
}

#pragma mark - UIPageViewControllerDelegate

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (completed)
    {
        GJCFAssetsPickerPreviewItemViewController *vc   = (GJCFAssetsPickerPreviewItemViewController *)pageViewController.viewControllers[0];
        NSInteger index                 = vc.pageIndex + 1;
        
        [self setTitleIndex:index];
        
        [self updateStateBtn];
    }
}

#pragma mark - GJAssetsPickerPreviewItemViewController dataSource
- (GJCFAsset *)assetAtIndex:(NSInteger)index
{
    return [self.assets objectAtIndex:index];
}

#pragma mark - Hide the display navigation barar and the bottom of the custom toolbar

- (void)fadeNavigationBarAndBottomToolBar
{
    [UIView animateWithDuration:0.3 animations:^{
        
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        self.view.backgroundColor = [UIColor blackColor];
        
        self.customBottomToolBar.alpha = 0;
        self.customBottomToolBar.hidden = YES;
        
    } completion:^(BOOL finished) {
        
    }];
}

- (void)showNavigationBarAndBottomToolBar
{
    [UIView animateWithDuration:0.3 animations:^{
        
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        self.view.backgroundColor = [UIColor whiteColor];
        
        self.customBottomToolBar.alpha = 1;
        self.customBottomToolBar.hidden = NO;
        
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark - Watch the click details of the details page
- (void)addObserverForItemViewController
{
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(observeItemViewControllerDidTapNoti:) name:kGJAssetsPickerPreviewItemControllerDidTapNoti object:nil];
}
- (void)observeItemViewControllerDidTapNoti:(NSNotification*)noti
{
    if (self.customBottomToolBar.hidden == NO) {
        [self fadeNavigationBarAndBottomToolBar];
    }else{
        [self showNavigationBarAndBottomToolBar];
    }
}


@end
