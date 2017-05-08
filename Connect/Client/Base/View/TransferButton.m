//
//  TransferButton.m
//  Connect
//
//  Created by MoHuilin on 16/9/30.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "TransferButton.h"
#import "UIImage+Color.h"

@interface TransferButton ()

@property (nonatomic ,strong) UIActivityIndicatorView *indicatorView ;

@end

@implementation TransferButton

- (instancetype)initWithNormalTitle:(NSString *)title disableTitle:(NSString *)disableTitle{
    if (self = [super init]) {
        [self setTitle:title forState:UIControlStateNormal];
        if (disableTitle) {
            [self setTitle:disableTitle forState:UIControlStateDisabled];
        }
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        self.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(36)];
        [self setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithHexString:@"B3B5BD"]] forState:UIControlStateDisabled];
        [self setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithHexString:@"37C65C"]] forState:UIControlStateNormal];
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        self.indicatorView = indicatorView;
        [self addSubview:indicatorView];
        [indicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self);
            make.centerX.equalTo(self);
            make.width.equalTo(indicatorView.mas_height);
        }];
        indicatorView.hidden = YES;
    }
    return self;
}

- (void)setEnabled:(BOOL)enabled{
    [super setEnabled:enabled];
    if (enabled) {
        self.indicatorView.hidden = YES;
        [self.indicatorView stopAnimating];
    } else{
        if (GJCFStringIsNull([self titleForState:UIControlStateDisabled])) {
            self.indicatorView.hidden = NO;
            [self.indicatorView startAnimating];
        }
    }
}

@end
