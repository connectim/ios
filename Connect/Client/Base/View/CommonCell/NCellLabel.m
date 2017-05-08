//
//  NCellLabel.m
//  HashNest
//
//  Created by MoHuilin on 16/3/16.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "NCellLabel.h"
#import "UIView+Frame.h"

@interface NCellLabel ()


@end

@implementation NCellLabel

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_titleLabel];
        _titleLabel.textColor = [UIColor blackColor];
        _titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(32)];
    }
    return self;
}

- (void)setTitleColor:(UIColor *)titleColor{
    _titleColor = titleColor;
    _titleLabel.textColor = titleColor;
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment{
    _textAlignment = textAlignment;
    _titleLabel.textAlignment = textAlignment;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    _titleLabel.frame = self.bounds;
    _titleLabel.left = 15;
    _titleLabel.width = self.width - 30;
    _titleLabel.textAlignment = NSTextAlignmentCenter;
}

@end
