//
//  Created by 刘超 on 15/4/30.
//  Copyright (c) 2015年 Leo. All rights reserved.
//

#import "LCNewFeatureVC.h"

@interface LCNewFeatureVC () <UIScrollViewDelegate> {

    NSString *_imageName;
    NSInteger _imageCount;
    UIPageControl *_pageControl;
    BOOL _showPageControl;
    UIButton *_enterButton;
    LCNewFeatureFinishBlock _finishBlock;
}

@property (nonatomic, weak) UIButton *skipBtn;

@end



@implementation LCNewFeatureVC

#pragma mark - device id

- (DeviceModel)deviceModel {

    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    if (10 * screenSize.height / screenSize.width == 15) {          // iPhone 4 / 4s

        return DeviceModeliPhone4;

    } else if (10 * screenSize.height / screenSize.width == 17) {   // iPhone 5 / 6 / 6 p / 6s / 6s p

        return DeviceModeliPhone56;

    }

    return DeviceModelUnknow;
}

#pragma mark - Whether to display the new feature view controller

+ (BOOL)shouldShowNewFeature {

    NSString *key = @"CFBundleShortVersionString";

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // Get the version number in the sandbox
    NSString *lastVersion = [defaults stringForKey:key];

    // Get the current version number
    NSString *currentVersion = [NSBundle mainBundle].infoDictionary[key];

    if ([currentVersion isEqualToString:lastVersion]) {

        return NO;

    } else {

        [defaults setObject:currentVersion forKey:key];
        [defaults synchronize];

        return YES;
    }
}

#pragma mark - Initialize the new feature view controller

+ (instancetype)newFeatureWithImageName:(NSString *)imageName
                             imageCount:(NSInteger)imageCount
                        showPageControl:(BOOL)showPageControl
                            enterButton:(UIButton *)enterButton {

    return [[self alloc] initWithImageName:imageName
                                imageCount:imageCount
                           showPageControl:showPageControl
                               enterButton:enterButton];
}

+ (instancetype)newFeatureWithImageName:(NSString *)imageName
                             imageCount:(NSInteger)imageCount
                        showPageControl:(BOOL)showPageControl
                            finishBlock:(LCNewFeatureFinishBlock)finishBlock {

    return [[self alloc] initWithImageName:imageName
                                imageCount:imageCount
                           showPageControl:showPageControl
                               finishBlock:finishBlock];
}

- (instancetype)initWithImageName:(NSString *)imageName
                       imageCount:(NSInteger)imageCount
                  showPageControl:(BOOL)showPageControl
                      enterButton:(UIButton *)enterButton {

    if (self = [super init]) {

        _imageName       = imageName;
        _imageCount      = imageCount;
        _showPageControl = showPageControl;
        _enterButton     = enterButton;

        [self setupMainView];
    }

    return self;
}

- (instancetype)initWithImageName:(NSString *)imageName
                       imageCount:(NSInteger)imageCount
                  showPageControl:(BOOL)showPageControl
                      finishBlock:(LCNewFeatureFinishBlock)finishBlock {

    if (self = [super init]) {

        _imageName       = imageName;
        _imageCount      = imageCount;
        _showPageControl = showPageControl;
        _finishBlock     = finishBlock;

        [self setupMainView];
    }

    return self;
}

#pragma mark set main Page

- (void)setupMainView {

    self.view.backgroundColor = [UIColor whiteColor];

    // Default status bar style
    self.statusBarStyle = LCStatusBarStyleNone;

    // When the image array is empty
    if (_imageCount) {

        // scroll view
        UIScrollView *scrollView = [[UIScrollView alloc] init];
        [scrollView setDelegate:self];
        [scrollView setBounces:NO];
        [scrollView setPagingEnabled:YES];
        [scrollView setShowsHorizontalScrollIndicator:NO];
        [scrollView setFrame:(CGRect){0, 0, LC_NEW_FEATURE_SCREEN_SIZE}];
        [scrollView setContentSize:(CGSize){LC_NEW_FEATURE_SCREEN_SIZE.width * _imageCount, 0}];
        [self.view addSubview:scrollView];

        NSArray *titleArray = @[LMLocalizedString(@"Login guide encryptedChat", nil),LMLocalizedString(@"Login guide bitcoinWallet", nil),LMLocalizedString(@"Login guide funStickers", nil)];
        NSArray *subTitleArray = @[LMLocalizedString(@"Login guide encryptedChat guide encryptedChatDescribe", nil),LMLocalizedString(@"Login guide bitcoinWalletDescribe", nil),LMLocalizedString(@"Login guide funStickersDescribe", nil)];
        
        // scroll photo
        CGFloat imageW = AUTO_WIDTH(740);
        CGFloat imageH = AUTO_HEIGHT(800);

        CGFloat pageControlTop = 0;
        
        for (int i = 0; i < _imageCount; i++) {

            CGFloat left = DEVICE_SIZE.width * i;
            
            UIView *pageContentView = [UIView new];
            [pageContentView setFrame:(CGRect){left, 0, DEVICE_SIZE.width, DEVICE_SIZE.height}];
            
            
            // add text desription
            UILabel *titleLabel = [UILabel new];
            [pageContentView addSubview:titleLabel];
            titleLabel.textAlignment = NSTextAlignmentCenter;
            titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(36)];
            titleLabel.textColor = GJCFQuickHexColor(@"161A21");
            titleLabel.text = [titleArray objectAtIndexCheck:i];
            titleLabel.frame = CGRectMake(0, AUTO_HEIGHT(150), DEVICE_SIZE.width, AUTO_HEIGHT(60));
            
            UILabel *subTitleLabel = [UILabel new];
            [pageContentView addSubview:subTitleLabel];
            subTitleLabel.textAlignment = NSTextAlignmentCenter;
            subTitleLabel.numberOfLines = 0;
            subTitleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
            subTitleLabel.textColor = GJCFQuickHexColor(@"B3B5BD");
            subTitleLabel.text = [subTitleArray objectAtIndexCheck:i];
            subTitleLabel.frame = CGRectMake(0, titleLabel.bottom, DEVICE_SIZE.width, AUTO_HEIGHT(100));

            NSString *realImageName = [NSString stringWithFormat:@"%@_%d", _imageName, i + 1];
            UIImage *realImage = [UIImage imageNamed:realImageName];
            UIImageView *imageView = [[UIImageView alloc] init];
            [imageView setImage:realImage];
            [imageView setFrame:(CGRect){(DEVICE_SIZE.width - imageW) / 2, subTitleLabel.bottom + AUTO_HEIGHT(20), imageW, imageH}];
            [pageContentView addSubview:imageView];
            
            [scrollView addSubview:pageContentView];

            if (_enterButton && i == _imageCount - 1) {

                [imageView setUserInteractionEnabled:YES];
                [imageView addSubview:_enterButton];
            }
            
            pageControlTop = imageView.bottom + AUTO_HEIGHT(10);
        }

        // page
        if (_showPageControl) {
            UIPageControl *pageControl = [[UIPageControl alloc] init];
            [pageControl setNumberOfPages:_imageCount];
            [pageControl setHidesForSinglePage:YES];
            [pageControl setUserInteractionEnabled:NO];
            [pageControl setPageIndicatorTintColor:[UIColor lightGrayColor]];
            [pageControl setCurrentPageIndicatorTintColor:[UIColor darkGrayColor]];
            [pageControl setFrame:(CGRect){0, pageControlTop, LC_NEW_FEATURE_SCREEN_SIZE.width, 37.0f}];
            [self.view addSubview:pageControl];
            _pageControl = pageControl;
        }

        // skip button
        UIButton *skipBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        skipBtn.hidden = YES;
        skipBtn.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(30)];
        [skipBtn setTitle:LMLocalizedString(@"Set Start encrypted messaging", nil) forState:UIControlStateNormal];
        [skipBtn addTarget:self action:@selector(skipBtnClicked) forControlEvents:UIControlEventTouchUpInside];
        skipBtn.frame = CGRectMake(0,_pageControl.bottom,DEVICE_SIZE.width, AUTO_HEIGHT(100));
        [self.view addSubview:skipBtn];
        self.skipBtn = skipBtn;
    } else {

        NSLog(@"Warning: Please put new image!");
    }
}

- (void)skipBtnClicked {

    if (self.skipBlock) {
        self.skipBlock();
    }
}

- (void)setShowSkip:(BOOL)showSkip {
    _showSkip = showSkip;

    self.skipBtn.hidden = !self.showSkip;
}

#pragma mark - New feature view controller display and disappear

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    switch (self.statusBarStyle) {

        case LCStatusBarStyleBlack:
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
            break;

        case LCStatusBarStyleWhite:
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
            break;

        case LCStatusBarStyleNone:
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
            break;

        default:
            break;
    }

    if (_showPageControl) {

        // If the color of the current point of the paged controller is set
        if (self.pointCurrentColor) {

            [_pageControl setCurrentPageIndicatorTintColor:self.pointCurrentColor];
        }

        // If the color of the other points of the paging controller is set
        if (self.pointOtherColor) {

            [_pageControl setPageIndicatorTintColor:self.pointOtherColor];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {

    [super viewWillDisappear:animated];

    if (self.statusBarStyle == LCStatusBarStyleNone) {                                                                                                                                      
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    }
}

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {

    // The last one to the left
    if (scrollView.contentOffset.x == LC_NEW_FEATURE_SCREEN_SIZE.width * (_imageCount - 1)) {

        if (_finishBlock) {

            [UIView animateWithDuration:0.4f animations:^{

                self.view.transform = CGAffineTransformMakeTranslation(-LC_NEW_FEATURE_SCREEN_SIZE.width, 0);

            } completion:^(BOOL finished) {

                _finishBlock();
            }];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {

    CGPoint currentPoint = scrollView.contentOffset;
    NSInteger page = currentPoint.x / scrollView.bounds.size.width;
    _pageControl.currentPage = page;
    
    if ([self.delegate respondsToSelector:@selector(newFeatureVC:page:)]) {
        [self.delegate newFeatureVC:self page:page];
    }
}

@end
