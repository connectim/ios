//
//  LMRecLuckyDetailCell.m
//  Connect
//
//  Created by Qingxu Kuang on 16/7/30.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMRecLuckyDetailCell.h"

@interface LMRecLuckyDetailCell ()
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *iconWidthConstaton;

@end

@implementation LMRecLuckyDetailCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.moneyValueLabel.font = [UIFont systemFontOfSize:FONT_SIZE(36)];
    [self.winerTipView setTitle:LMLocalizedString(@"Chat Best luck", nil) forState:UIControlStateNormal];
    self.iconWidthConstaton.constant = AUTO_HEIGHT(100);

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];


}

@end
