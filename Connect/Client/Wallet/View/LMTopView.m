//
//  LMTopView.m
//  Connect
//
//  Created by Edwin on 16/7/13.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMTopView.h"
#import "LMCustomBtn.h"

@interface LMTopView ()

@property(nonatomic, strong) UIImageView *logoImageView;
/**
 *  payment
 */
@property(nonatomic, strong) LMCustomBtn *payBtn;
/**
 *  money
 */
@property(nonatomic, strong) LMCustomBtn *walletBtn;
/**
 *  Receipts
 */
@property(nonatomic, strong) LMCustomBtn *ColletBtn;
@end

@implementation LMTopView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initView];
    }
    return self;
}

/**
 *  Initialize UI
 */
- (void)initView {

    self.logoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(VSIZE.width / 2 - 20, AUTO_HEIGHT(20), 40, 20)];
    self.logoImageView.image = [UIImage imageNamed:@"logo_black_middle"];
    [self addSubview:self.logoImageView];
    self.walletBtn = [LMCustomBtn buttonWithType:UIButtonTypeCustom];
    self.walletBtn.frame = CGRectMake(0, 0, AUTO_WIDTH(94), AUTO_HEIGHT(94));
    [self.walletBtn setBackgroundImage:[UIImage imageNamed:@"wallet_balance_icon"] forState:UIControlStateNormal];
    [self.walletBtn setTitle:LMLocalizedString(@"Wallet Wallet", nil) forState:UIControlStateNormal];
    self.walletBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.walletBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.walletBtn.titleLabel.font = [UIFont boldSystemFontOfSize:FONT_SIZE(30)];
    self.walletBtn.ratio = -0.8;
    CGPoint walletCenter = self.center;
    walletCenter.y = self.center.y - AUTO_HEIGHT(70);
    self.walletBtn.center = walletCenter;
    [self.walletBtn addTarget:self action:@selector(WalletBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.walletBtn];

    self.payBtn = [LMCustomBtn buttonWithType:UIButtonTypeCustom];
    self.payBtn.frame = CGRectMake(CGRectGetMinX(self.walletBtn.frame) - AUTO_WIDTH(264), CGRectGetMinY(self.walletBtn.frame), CGRectGetWidth(self.walletBtn.frame), CGRectGetHeight(self.walletBtn.frame));
    [self.payBtn setBackgroundImage:[UIImage imageNamed:@"pay_icon"] forState:UIControlStateNormal];
    [self.payBtn setTitle:LMLocalizedString(@"Set Payment", nil) forState:UIControlStateNormal];
    self.payBtn.ratio = -0.8;
    self.payBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.payBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.payBtn.titleLabel.font = [UIFont boldSystemFontOfSize:FONT_SIZE(30)];
    [self.payBtn addTarget:self action:@selector(payBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.payBtn];

    self.ColletBtn = [LMCustomBtn buttonWithType:UIButtonTypeCustom];
    self.ColletBtn.frame = CGRectMake(CGRectGetMaxX(self.walletBtn.frame) + AUTO_WIDTH(174), CGRectGetMinY(self.walletBtn.frame), CGRectGetWidth(self.walletBtn.frame), CGRectGetHeight(self.walletBtn.frame));
    self.ColletBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.ColletBtn setBackgroundImage:[UIImage imageNamed:@"scan"] forState:UIControlStateNormal];
    self.ColletBtn.ratio = -0.8;
    [self.ColletBtn setTitle:LMLocalizedString(@"Receivables", nil) forState:UIControlStateNormal];
    self.ColletBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.ColletBtn.titleLabel.font = [UIFont boldSystemFontOfSize:FONT_SIZE(30)];
    [self.ColletBtn addTarget:self action:@selector(collectionBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.ColletBtn];

    self.BalanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(VSIZE.width - AUTO_WIDTH(100), CGRectGetMaxY(self.ColletBtn.frame) + AUTO_HEIGHT(170), AUTO_WIDTH(80), AUTO_HEIGHT(50))];
    self.BalanceLabel.text = @"฿1234.13123123";
    self.BalanceLabel.textColor = [UIColor whiteColor];
    self.BalanceLabel.font = [UIFont boldSystemFontOfSize:FONT_SIZE(26)];
    self.BalanceLabel.textAlignment = NSTextAlignmentRight;
    [self addSubview:self.BalanceLabel];

    self.BanContentLabel = [[UILabel alloc] initWithFrame:CGRectMake(VSIZE.width - AUTO_WIDTH(500), CGRectGetMaxY(self.BalanceLabel.frame), AUTO_WIDTH(480), AUTO_HEIGHT(80))];
    self.BanContentLabel.text = @"฿1234.13123123";
    self.BanContentLabel.font = [UIFont boldSystemFontOfSize:FONT_SIZE(30)];
    self.BanContentLabel.textColor = [UIColor colorWithRed:236 / 255.0 green:196 / 255.0 blue:55 / 255.0 alpha:1.0f];
    self.BanContentLabel.textAlignment = NSTextAlignmentRight;
    [self addSubview:self.BanContentLabel];

}


#pragma mark -- Button click method

- (void)payBtnClick:(UIButton *)btn {
    [self.delegate LMTopView:self PayBtnClick:btn];
}

- (void)WalletBtnClick:(UIButton *)btn {
    [self.delegate LMTopView:self WalletBtnClick:btn];
}

- (void)collectionBtnClick:(UIButton *)btn {
    [self.delegate LMTopView:self CollectBtnClick:btn];
}


@end
