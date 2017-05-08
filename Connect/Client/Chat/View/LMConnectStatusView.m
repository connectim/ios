//
//  LMConnectStatusView.m
//  Connect
//
//  Created by MoHuilin on 2017/3/13.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMConnectStatusView.h"

@interface LMConnectStatusView ()

@property (nonatomic ,strong) UILabel *statusLabel;
@property (nonatomic ,strong) UIActivityIndicatorView *indicator;
@property (nonatomic ,strong) UIImageView *tipIconView;

@end

@implementation LMConnectStatusView


- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = LMBasicBackGroudDarkGray;
        self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.indicator.hidesWhenStopped = YES;
        [self addSubview:self.indicator];
        
        [self.indicator mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(AUTO_WIDTH(40));
            make.size.mas_equalTo(AUTO_SIZE(50, 50));
            make.centerY.equalTo(self);
        }];
        
        self.tipIconView = [[UIImageView alloc] init];
        [self addSubview:self.tipIconView];
        [self.tipIconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(AUTO_WIDTH(40));
            make.size.mas_equalTo(AUTO_SIZE(35, 35));
            make.centerY.equalTo(self);
        }];
        
        self.statusLabel = [UILabel new];
        self.statusLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
        [self addSubview:self.statusLabel];
        [self.statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.tipIconView.mas_right).offset(AUTO_WIDTH(30));
            make.centerY.equalTo(self);
        }];
    }
    return self;
}


- (void)showViewWithStatue:(LMConnectStatus)status{
    switch (status) {
        case LMConnectStatusViewDisconnect:
        {
            self.tipIconView.hidden = NO;
            self.tipIconView.image = [UIImage imageNamed:@"attention_message"];
            self.statusLabel.text = LMLocalizedString(@"Chat Network connection failed please check network", nil);
            [self.indicator stopAnimating];
        }
            break;
        case LMConnectStatusViewUpdatingEcdh:
        {
            self.tipIconView.hidden = YES;
            self.indicator.hidden = NO;
            self.statusLabel.text = LMLocalizedString(@"Chat Refreshing Secret Key", nil);
            [self.indicator startAnimating];
        }
            break;
        case LMConnectStatusViewUpdateecdhSuccess://top_success_icon
        {
            self.tipIconView.hidden = NO;
            self.tipIconView.image = [UIImage imageNamed:@"top_success_icon"];
            self.statusLabel.text = LMLocalizedString(@"Chat Secret Key Refreshed", nil);
            [self.indicator stopAnimating];
        }
            break;
        default:
            break;
    }
}

@end
