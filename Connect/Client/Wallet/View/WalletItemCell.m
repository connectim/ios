//
//  WalletItemCell.m
//  Connect
//
//  Created by MoHuilin on 2016/11/7.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "WalletItemCell.h"


@interface WalletItemCell ()
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *lableBottomConstaton;


@end

@implementation WalletItemCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.titleLabel.textColor = LMBasicBlack;
    self.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
    if (GJCFSystemiPhone5) {
        self.lableBottomConstaton.constant = 5;
    } else {
        self.lableBottomConstaton.constant = AUTO_HEIGHT(30);
    }
}

- (CGFloat)heightForCell {
    [self.contentView layoutIfNeeded];

    return self.titleLabel.bottom + AUTO_HEIGHT(10);
}

@end
