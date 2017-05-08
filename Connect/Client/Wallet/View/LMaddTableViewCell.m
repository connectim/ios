//
//  LMaddTableViewCell.m
//  Connect
//
//  Created by Edwin on 16/7/19.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMaddTableViewCell.h"

@interface LMaddTableViewCell ()


@end

@implementation LMaddTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.iconImageView.layer.cornerRadius = 5;
    self.iconImageView.layer.masksToBounds = YES;
}


@end
