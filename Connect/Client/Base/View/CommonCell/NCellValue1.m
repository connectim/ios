//
//  NCellValue1.m
//  Connect
//
//  Created by MoHuilin on 16/7/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "NCellValue1.h"

@interface NCellValue1 ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UILabel *subTitleLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftConstraint;

@end

@implementation NCellValue1

- (void)awakeFromNib{
    [super awakeFromNib];
    
    if ([UIScreen mainScreen].bounds.size.width > 390 && [UIScreen mainScreen].bounds.size.width < 420) {
        self.leftConstraint.constant = 9;
    } else if(GJCFSystemiPhone6){
        self.leftConstraint.constant = 7;
    }
    self.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(32)];
    self.subTitleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(32)];
}

- (void)setData:(id)data{
    [super setData:data];
    
    CellItem *item = (CellItem *)data;
    
    _titleLabel.text = item.title;
    
    _subTitleLabel.text = item.subTitle;
    _subTitleLabel.lineBreakMode =NSLineBreakByTruncatingMiddle;
    if (self.cellSourceType == CellSourceTypeAbout) {
        _subTitleLabel.textColor = LMBasicBlue;
    }
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
}

@end
