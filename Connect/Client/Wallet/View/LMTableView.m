//
//  LMTableView.m
//  Connect
//
//  Created by Edwin on 16/7/22.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMTableView.h"

@interface LMTableView ()
@property(nonatomic, strong) UIImageView *bitcoinImageView;
@property(nonatomic, strong) UILabel *BalanceLabel;
@property(nonatomic, strong) UIImageView *moreImageView;
@property(nonatomic, copy) NSString *content;
@end

@implementation LMTableView

- (instancetype)initWithFrame:(CGRect)frame withBalanceContentStr:(NSString *)content {
    if (self = [super initWithFrame:frame]) {
        [self initTableViewCell];
    }
    _content = content;
    return self;
}

- (void)initTableViewCell {

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapTabelViewCellRecognizer:)];
    [self addGestureRecognizer:tap];
    self.bitcoinImageView = [[UIImageView alloc] initWithFrame:CGRectMake(AUTO_WIDTH(46), AUTO_HEIGHT(25), AUTO_HEIGHT(50), AUTO_HEIGHT(50))];
    self.bitcoinImageView.image = [UIImage imageNamed:@"wallet_bitcoin"];
    [self addSubview:self.bitcoinImageView];

    self.BalanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.frame) + AUTO_WIDTH(30), 0, AUTO_WIDTH(350), CGRectGetHeight(self.frame))];
    self.BalanceLabel.backgroundColor = [UIColor redColor];
    self.BalanceLabel.text = LMLocalizedString(@"Blance: ฿123.1234567", nil);
    self.BalanceLabel.font = [UIFont systemFontOfSize:FONT_SIZE(30)];
    self.BalanceLabel.textColor = [UIColor blackColor];
    self.BalanceLabel.textAlignment = NSTextAlignmentLeft;
    [self addSubview:self.BalanceLabel];

    self.moreImageView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.frame) - AUTO_WIDTH(90), AUTO_HEIGHT(20), AUTO_HEIGHT(53), AUTO_HEIGHT(60))];
    self.moreImageView.image = [UIImage imageNamed:@"more"];
    [self addSubview:self.moreImageView];
}

- (void)tapTabelViewCellRecognizer:(UITapGestureRecognizer *)tap {
    [self.delegate LMTableView:self tapTabelViewCellRecognizer:tap];
}
@end
