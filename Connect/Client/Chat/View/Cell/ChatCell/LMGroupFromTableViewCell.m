//
//  LMGroupFromTableViewCell.m
//  Connect
//
//  Created by bitmain on 2016/12/28.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import "LMGroupFromTableViewCell.h"

@implementation LMGroupFromTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.fromLable.layer.cornerRadius = 4;
    self.fromLable.layer.masksToBounds = YES;
    self.fromLable.backgroundColor = LMBasicBackGroudDarkGray;
    self.fromLable.font = [UIFont systemFontOfSize:FONT_SIZE(23)];
    self.fromLable.textAlignment = NSTextAlignmentCenter;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
