//
//  LMReManFriendViewController.m
//  Connect
//
//  Created by Edwin on 16/7/24.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMReManFriendViewController.h"
#import "UICustomBtn.h"
#import "LMTranFriendLsitViewController.h"
#import "TransferInputView.h"

@interface LMReManFriendViewController () <UICustomBtnDelegate>
// Top transfer
@property(nonatomic, strong) UIView *sectionTitleView;
// Transfer title
@property(nonatomic, strong) UILabel *titleLabel;
// Enter the amount of money transferred
@property(nonatomic, strong) TransferInputView *inputAmountView;
@property(nonatomic, strong) UICustomBtn *addBtn;
@property(nonatomic, strong) UIView *btnViews;
@property(nonatomic, strong) UIImageView *cellMoreImageView;
@end

@implementation LMReManFriendViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LMLocalizedString(@"Wallet Select friends", nil);

    [self addTopBtns];
    __weak __typeof(&*self) weakSelf = self;
    TransferInputView *view = [[TransferInputView alloc] init];
    self.inputAmountView = view;
    [self.view addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.btnViews.mas_bottom).offset(AUTO_HEIGHT(20));
        make.width.equalTo(self.view);
        make.height.mas_equalTo(AUTO_HEIGHT(334));
        make.left.equalTo(self.view);
    }];
    view.topTipString = LMLocalizedString(@"Enter the payment amount", nil);
    view.resultBlock = ^(NSDecimalNumber *btcMoney, NSString *note) {
        [weakSelf createTranscationWithMoney:btcMoney note:note];
    };

    [[PayTool sharedInstance] getRateComplete:^(NSDecimalNumber *rate, NSError *error) {
        if (!error) {
            weakSelf.rate = rate.floatValue;
            [[MMAppSetting sharedSetting] saveRate:[rate floatValue]];
            [weakSelf.inputAmountView reloadWithRate:rate.floatValue];
        } else {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Fail to get rate.", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
            }];
        }
    }];
}

- (void)addTopBtns {
    self.sectionTitleView = [[UIView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, AUTO_HEIGHT(40))];
    self.sectionTitleView.backgroundColor = [UIColor colorWithHexString:@"F1F1F1"];
    [self.view addSubview:self.sectionTitleView];

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(AUTO_WIDTH(30), 0, AUTO_WIDTH(300), AUTO_HEIGHT(40))];
    self.titleLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Transfer Count", nil), (int) self.selectArr.count];
    self.titleLabel.textColor = [UIColor blackColor];
    self.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(22)];
    self.titleLabel.textAlignment = NSTextAlignmentLeft;
    [self.sectionTitleView addSubview:self.titleLabel];

    self.btnViews = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.sectionTitleView.frame), VSIZE.width, AUTO_HEIGHT(148))];
    self.btnViews.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.btnViews];

    self.cellMoreImageView = [[UIImageView alloc] initWithFrame:CGRectMake(VSIZE.width - AUTO_WIDTH(68), AUTO_HEIGHT(51), AUTO_WIDTH(36), AUTO_HEIGHT(46))];
    self.cellMoreImageView.image = [UIImage imageNamed:@"cellmore"];
    [self.btnViews addSubview:self.cellMoreImageView];

    self.addBtn = [[UICustomBtn alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.cellMoreImageView.frame) - AUTO_WIDTH(160), AUTO_HEIGHT(30), AUTO_WIDTH(80), AUTO_HEIGHT(108))];
    self.addBtn.imageView.image = [UIImage imageNamed:@"message_add_friends"];
    self.addBtn.delegate = self;
    [self.btnViews addSubview:self.addBtn];

    // Loop create button
    if (self.selectArr.count > 2) {
        for (NSInteger i = 2; i >= 0; i--) {
            AccountInfo *info = self.selectArr[i];
            UICustomBtn *btn = [[UICustomBtn alloc] initWithFrame:CGRectMake(AUTO_WIDTH(30) + AUTO_WIDTH(180) * i, AUTO_HEIGHT(30), AUTO_WIDTH(80), AUTO_HEIGHT(108))];
            btn.imageView.image = [UIImage imageNamed:info.avatar];
            btn.titleLabel.text = info.username;
            [self.btnViews addSubview:btn];
        }
    } else {
        for (NSInteger i = self.selectArr.count - 1; i >= 0; i--) {
            AccountInfo *info = self.selectArr[i];
            UICustomBtn *btn = [[UICustomBtn alloc] initWithFrame:CGRectMake(AUTO_WIDTH(30) + AUTO_WIDTH(180) * i, AUTO_HEIGHT(30), AUTO_WIDTH(80), AUTO_HEIGHT(108))];
            btn.imageView.image = [UIImage imageNamed:info.avatar];
            btn.titleLabel.text = info.username;
            [self.btnViews addSubview:btn];
        }
    }

}


#pragma mark -- Custom proxy method

- (void)UICustomBtn:(UICustomBtn *)view tapClickRecognizer:(UITapGestureRecognizer *)tap {
    NSLog(@"More friends");
    LMTranFriendLsitViewController *friendsList = [[LMTranFriendLsitViewController alloc] init];
    friendsList.dataArr = self.selectArr.mutableCopy;
    friendsList.title = LMLocalizedString(@"Wallet Firends", nil);
    [self.navigationController pushViewController:friendsList animated:YES];
}


@end
