//
//  LMWalletViewCell.m
//  Connect
//
//  Created by Edwin on 16/7/14.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMWalletViewCell.h"

@interface LMWalletViewCell ()

// money
@property(nonatomic, strong) UIImageView *iconImageView;
// more
@property(nonatomic, strong) UIImageView *moreImageView;
@end

@implementation LMWalletViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self creatView];
    }
    return self;
}

- (void)creatView {
    self.iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(AUTO_WIDTH(30), AUTO_HEIGHT(10), self.frame.size.height - AUTO_HEIGHT(20), self.frame.size.height - AUTO_HEIGHT(20))];
    self.iconImageView.image = [UIImage imageNamed:@"wallet_bitcoin"];
    self.iconImageView.contentMode = UIViewContentModeCenter;
    [self addSubview:self.iconImageView];

    self.walletAccout = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.iconImageView.frame) + AUTO_WIDTH(20), CGRectGetMinY(self.iconImageView.frame), VSIZE.width / 2, CGRectGetHeight(self.iconImageView.frame))];
    self.walletAccout.textAlignment = NSTextAlignmentLeft;
    self.walletAccout.font = [UIFont boldSystemFontOfSize:FONT_SIZE(36)];
    [self addSubview:self.walletAccout];

    self.moreImageView = [[UIImageView alloc] initWithFrame:CGRectMake(VSIZE.width - self.frame.size.height, AUTO_HEIGHT(30), self.frame.size.height - AUTO_HEIGHT(60), self.frame.size.height - AUTO_HEIGHT(60))];
    self.moreImageView.image = [UIImage imageNamed:@"more"];
    self.moreImageView.contentMode = UIViewContentModeCenter;
    [self addSubview:self.moreImageView];
}

@end
