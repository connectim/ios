//
//  UIViewController.m
//  ZYChat
//
//  Created by KivenLin on 15/7/11.
//  Copyright (c) 2015年 ConnectSoft. All rights reserved.
//

#define BUTTONMarginX    10
#define BUTTONMarginUP   0
#define NAVBUTTON_WIDTH  44
#define NAVBUTTON_HEIGHT 44
#define SCREEN_WIDTH    [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGHT   [[UIScreen mainScreen] bounds].size.height
#define NAVIGATION_BAR_HEIGHT self.navigationController.navigationBar.frame.size.height

@interface GJGCBaseViewController ()

@property(nonatomic, strong) UILabel *titleLabel;

@end

@implementation GJGCBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setWhitefBackArrowItem];
}

- (void)dealloc {
    RemoveNofify;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (![UIView areAnimationsEnabled]) {
        [UIView setAnimationsEnabled:YES];
    }
}

- (void)setWhitefBackArrowItem {

    UIBarButtonItem *item = [self whiteBackItem];

    if (item) {
        UIBarButtonItem *offset = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        offset.width = -10;
        NSArray *items = @[offset, item];
        self.navigationItem.leftBarButtonItems = items;
    }
}

- (UIBarButtonItem *)whiteBackItem {
    UIButton *btn = nil;
    if (GJCFSystemiPhone6 || GJCFSystemiPhone5) {
        btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    } else {
        btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
    }
    [btn setImage:[UIImage imageNamed:@"back_white"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(doLeft:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.whiteButton = btn;
    return item;
}

- (void)doLeft:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)rightButtonPressed:(UIButton *)sender {

}

- (void)setStrNavTitle:(NSString *)title {
    self.title = title;
}

- (void)setRightButtonWithTitle:(NSString *)title {
    UIBarButtonItem *nextBarBtn = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:self action:@selector(rightButtonPressed:)];
    self.rightBarBtn = nextBarBtn;
    self.navigationItem.rightBarButtonItem = nextBarBtn;

}


- (void)setRightButtonWithStateImage:(NSString *)iconName stateHighlightedImage:(NSString *)highlightIconName stateDisabledImage:(NSString *)disableIconName titleName:(NSString *)title {
    UIButton *tmpRightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    tmpRightButton.exclusiveTouch = YES;//add by ljj 修改push界面问题

    tmpRightButton.frame = CGRectMake(self.view.frame.size.width - NAVBUTTON_WIDTH - BUTTONMarginX, BUTTONMarginUP, NAVBUTTON_WIDTH, NAVBUTTON_HEIGHT);
    if (title) {
        [tmpRightButton setTitle:title forState:UIControlStateNormal];
        [tmpRightButton setTitle:title forState:UIControlStateDisabled];
    }
    tmpRightButton.showsTouchWhenHighlighted = NO;
    [tmpRightButton setImage:[UIImage imageNamed:iconName] forState:UIControlStateNormal];
    [tmpRightButton setImage:[UIImage imageNamed:highlightIconName] forState:UIControlStateHighlighted];
    [tmpRightButton setImage:[UIImage imageNamed:disableIconName] forState:UIControlStateDisabled];

    [tmpRightButton addTarget:self action:@selector(rightButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rightButtonItem = [[UIBarButtonItem alloc] initWithCustomView:tmpRightButton];

    if (GJCFSystemIsOver7)//左边button的偏移量，从左移动13个像素
    {
        UIBarButtonItem *negativeSeperator = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        negativeSeperator.width = -10;
        [self.navigationItem setRightBarButtonItems:@[negativeSeperator, rightButtonItem]];
    } else {
        [self.navigationItem setRightBarButtonItem:rightButtonItem];
    }
}

@end
