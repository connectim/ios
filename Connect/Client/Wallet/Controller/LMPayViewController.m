//
//  LMPayViewController.m
//  Connect
//
//  Created by Edwin on 16/7/14.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMPayViewController.h"
//#import "LMScanResultViewController.h"

@interface LMPayViewController ()

@property(nonatomic, strong) UIButton *closeBtn;

@end

@implementation LMPayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = LMLocalizedString(@"Link Scan", nil);
    self.navigationItem.hidesBackButton = YES;
    [self addRightNavigaionBarItem];

}


/**
 *  add left button
 */
- (void)addRightNavigaionBarItem {
    self.closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    if (GJCFSystemiPhone6 || GJCFSystemiPhone5) {
        self.closeBtn.frame = CGRectMake(0, 0, 22, 22);
    } else {
        self.closeBtn.frame = CGRectMake(0, 0, 44, 44);
    }
    [self.closeBtn setBackgroundImage:[UIImage imageNamed:@"close_white"] forState:UIControlStateNormal];
    [self.closeBtn addTarget:self action:@selector(closeBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *closeBtnItem = [[UIBarButtonItem alloc] initWithCustomView:self.closeBtn];
    self.navigationItem.rightBarButtonItem = closeBtnItem;
}

- (void)closeBtnClicked:(UIButton *)btn {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
