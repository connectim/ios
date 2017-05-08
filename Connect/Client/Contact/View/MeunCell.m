//
//  MeunCell.m
//  Connect
//
//  Created by MoHuilin on 16/5/19.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "MeunCell.h"

@implementation MeunCell

- (void)layoutSubviews{
    [super layoutSubviews];
    self.imageView.frame = CGRectMake(15, 0, 30, 40);
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
}

@end
