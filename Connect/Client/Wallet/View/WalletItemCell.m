//
//  WalletItemCell.m
//  Connect
//
//  Created by MoHuilin on 2016/11/7.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "WalletItemCell.h"


@interface WalletItemCell ()


@end

@implementation WalletItemCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.titleLabel.textColor = LMBasicBlack;
    self.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
}

- (CGFloat)heightForCell {
    [self.contentView layoutIfNeeded];

    return self.titleLabel.bottom + AUTO_HEIGHT(10);
}

@end
