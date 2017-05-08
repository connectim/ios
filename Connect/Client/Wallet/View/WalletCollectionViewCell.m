//
//  WalletCollectionViewCell.m
//  Connect
//
//  Created by Edwin on 16/7/14.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "WalletCollectionViewCell.h"

@implementation WalletCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.titleLabel.font = [UIFont boldSystemFontOfSize:FONT_SIZE(30)];
    self.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
}

@end
