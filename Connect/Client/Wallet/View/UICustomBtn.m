//
//  UICustomBtn.m
//  Connect
//
//  Created by Edwin on 16/7/22.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "UICustomBtn.h"

@implementation UICustomBtn

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initView];
    }
    return self;
}

- (void)initView {
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.width)];
    self.imageView.layer.cornerRadius = 5;
    self.imageView.layer.masksToBounds = YES;
    [self addSubview:self.imageView];

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.imageView.frame), self.frame.size.width, self.frame.size.height - self.frame.size.width)];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(22)];
    [self addSubview:self.titleLabel];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapClickRecognizer:)];
    [self addGestureRecognizer:tap];
}

- (void)tapClickRecognizer:(UITapGestureRecognizer *)tap {
    [self.delegate UICustomBtn:self tapClickRecognizer:tap];
}


@end
