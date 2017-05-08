//
//  BaseViewController.m
//  Connect
//
//  Created by MoHuilin on 16/5/9.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseViewController.h"

@interface BaseViewController ()

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // implement in subclass
    [self setup];
    [self setDatas];
    [self setWhitefBackArrowItem];
}

- (void)dealloc {
    RemoveNofify;
}

- (void)removeDelegate {

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (![UIView areAnimationsEnabled]) {
        [UIView setAnimationsEnabled:YES];
    }
}

- (void)addCloseBarItem {
    self.navigationItem.rightBarButtonItems = nil;

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(0, 0, AUTO_WIDTH(48), AUTO_HEIGHT(48));
    [btn setBackgroundImage:[UIImage imageNamed:@"close_white"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(closeBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *closeBtnItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.navigationItem.rightBarButtonItem = closeBtnItem;

    self.navigationItem.leftBarButtonItems = nil;
}

- (void)addNewCloseBarItem {

    self.navigationItem.leftBarButtonItems = nil;

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(0, 0, AUTO_WIDTH(48), AUTO_HEIGHT(48));
    [btn setBackgroundImage:[UIImage imageNamed:@"close_white"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(closeBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *closeBtnItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.navigationItem.leftBarButtonItem = closeBtnItem;

}

- (void)closeBtnClicked:(UIButton *)btn {
    [self.view endEditing:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
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

    return item;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setNeedsStatusBarAppearanceUpdate];
}


- (void)setBlackfBackArrowItem {

    UIBarButtonItem *item = [self blackBackItem];

    if (item) {
        UIBarButtonItem *offset = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        //offset.width = -10;
        NSArray *items = @[offset, item];
        self.navigationItem.leftBarButtonItems = items;
    }
}

- (UIBarButtonItem *)blackBackItem {
    UIButton *btn = nil;
    if (GJCFSystemiPhone6 || GJCFSystemiPhone5) {
        btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    } else {
        btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
    }
    //    [btn setTitle:@"返回" forState:UIControlStateNormal];
    [btn setImage:[UIImage imageNamed:@"top_back_black"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(doLeft:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:btn];

    return item;
}


- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)doLeft:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)doRight:(id)sender {

}


- (void)setup {

}

- (void)setDatas {

}


- (void)setNavigationItemWithSystemItem:(UIBarButtonSystemItem)systemItem sel:(SEL)sel isRight:(BOOL)isRight {
    if (isRight) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:systemItem target:self action:sel];
    } else {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:systemItem target:self action:sel];
    }

}

- (void)setNavigationTitle:(NSString *)title {
    self.title = title;
}

- (void)setNavigationTitleImage:(NSString *)imageName {
    UIImage *image = [UIImage imageNamed:imageName];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];

    self.navigationItem.titleView = imageView;
}

- (void)setNavBarImage {
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];

    NSDictionary *attribute = @{
            NSForegroundColorAttributeName: [UIColor whiteColor],
            NSFontAttributeName: [UIFont systemFontOfSize:18]
    };

    [self.navigationController.navigationBar setTitleTextAttributes:attribute];
}

- (UIButton *)customButton:(NSString *)imageName
                  selector:(SEL)sel {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.rightButton = btn;
    UIImage *image = [UIImage imageNamed:imageName];
    btn.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    [btn setImage:image forState:UIControlStateNormal];
    [btn addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (UIButton *)customButton:(NSString *)title titleColor:(UIColor *)color
                  selector:(SEL)sel {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(0, 0, 100, 40);
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:color forState:UIControlStateNormal];
    [btn setTitleColor:LMBasicLightGray forState:UIControlStateDisabled];
    btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [btn addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    self.rightTitleButton = btn;
    return btn;
}

- (void)setNavigationLeftWithTitle:(NSString *)title {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:self action:@selector(doLeft:)];
}

- (void)setNavigationLeft:(NSString *)imageName {
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:[self customButton:imageName selector:@selector(doLeft:)]];

    self.navigationItem.leftBarButtonItem = item;
}

- (void)setNavigationRight:(NSString *)title titleColor:(UIColor *)color {
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:[self customButton:title titleColor:color selector:@selector(doRight:)]];

    self.navigationItem.rightBarButtonItem = item;

}

- (void)setNavigationRight:(NSString *)imageName {
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:[self customButton:imageName selector:@selector(doRight:)]];
    self.rightBarBtn = item;
    self.navigationItem.rightBarButtonItem = item;
}

- (void)removeNavigationRight; {
    self.navigationItem.rightBarButtonItem = nil;
}


- (void)setNavigationRightWithTitle:(NSString *)title {
    UIBarButtonItem *nextBarBtn = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:self action:@selector(doRight:)];
    self.rightBarBtn = nextBarBtn;
    self.navigationItem.rightBarButtonItem = nextBarBtn;
}

@end
