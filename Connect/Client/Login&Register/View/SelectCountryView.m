//
//  SelectCountryView.m
//  Connect
//
//  Created by MoHuilin on 2016/12/6.
//  Copyright © 2016年 Connect - P2P Encrypted Instant Message. All rights reserved.
//

#import "SelectCountryView.h"

@interface SelectCountryView ()

@end

@implementation SelectCountryView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.countryInfoLabel = [UILabel new];
        self.countryInfoLabel.font = [UIFont systemFontOfSize:FONT_SIZE(32)];
        [self addSubview:self.countryInfoLabel];
        [_countryInfoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(AUTO_WIDTH(20));
            make.centerY.equalTo(self);
        }];

        UIImageView *arrowImageView = [[UIImageView alloc] init];
        [self addSubview:arrowImageView];
        arrowImageView.image = [UIImage imageNamed:@"set_grey_right_arrow"];
        [arrowImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self).offset(-AUTO_WIDTH(20));
            make.centerY.equalTo(self);
        }];

        UIView *bottomLine = [UIView new];
        bottomLine.backgroundColor = LMBasicLineViewColor;
        [self addSubview:bottomLine];
        [bottomLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.left.bottom.equalTo(self);
            make.height.mas_equalTo(@0.5);
        }];
    }
    return self;
}

+ (instancetype)viewWithCountryName:(NSString *)countryName countryCode:(int)code {
    SelectCountryView *view = [[SelectCountryView alloc] init];
    view.countryInfoLabel.text = [NSString stringWithFormat:@"+ %d %@", code, countryName];
    return view;
}

- (void)updateCountryInfoWithCountryName:(NSString *)countryName countryCode:(int)code {
    self.countryInfoLabel.text = [NSString stringWithFormat:@"+ %d %@", code, countryName];
    [self layoutIfNeeded];
}

@end
