//
//  LocalUserInfoView.m
//  Connect
//
//  Created by MoHuilin on 2016/12/6.
//  Copyright © 2016年 Connect - P2P Encrypted Instant Message. All rights reserved.
//

#import "LocalUserInfoView.h"

@interface LocalUserInfoView ()

@property(nonatomic, strong) UIImageView *arrowImageView;

@end

@implementation LocalUserInfoView
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {

        self.avatarImageView = [[UIImageView alloc] init];
        [self addSubview:self.avatarImageView];
        [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(AUTO_WIDTH(20));
            make.top.equalTo(self).offset(AUTO_HEIGHT(10));
            make.bottom.equalTo(self).offset(-AUTO_HEIGHT(10));
            make.width.equalTo(self.avatarImageView.mas_height);
        }];

        self.userNameLabel = [UILabel new];
        self.userNameLabel.font = [UIFont systemFontOfSize:FONT_SIZE(32)];
        [self addSubview:self.userNameLabel];
        [_userNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.avatarImageView.mas_right).offset(AUTO_WIDTH(20));
            make.centerY.equalTo(self);
        }];
        UIImageView *arrowImageView = [[UIImageView alloc] init];
        self.arrowImageView = arrowImageView;
        [self addSubview:arrowImageView];
        arrowImageView.image = [UIImage imageNamed:@"set_grey_right_arrow"];
        [arrowImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self).offset(-AUTO_WIDTH(20));
            make.centerY.equalTo(self);
        }];  
        
       
        UIView *bottomLine = [UIView new];
        bottomLine.backgroundColor = LMBasicLineViewColor;
//        bottomLine.alpha = 0.5;
        [self addSubview:bottomLine];
        [bottomLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.left.bottom.equalTo(self);
            make.height.mas_equalTo(@0.5);
        }];
    }
    return self;
}

+ (instancetype)viewWithAccountInfo:(AccountInfo *)user {
    LocalUserInfoView *view = [[LocalUserInfoView alloc] init];
    view.userNameLabel.text = user.username;
    [view.avatarImageView setPlaceholderImageWithAvatarUrl:user.avatar];
    return view;
}
-(void)setSoureInfoType:(SourceInfoType)soureInfoType
{
    _soureInfoType = soureInfoType;
    if (soureInfoType == SourceInfoViewTypeEncryPri) {
        self.arrowImageView.hidden = YES;
    }else {
        self.arrowImageView.hidden = NO;
    }
}
- (void)reloadWithUser:(AccountInfo *)user {
    self.userNameLabel.text = user.username;
    // cache userHead image
    [self.avatarImageView setPlaceholderImageWithAvatarUrl:user.avatar];
    [self layoutIfNeeded];
}

- (void)setHidenArrowView:(BOOL)hidenArrowView {
    _hidenArrowView = hidenArrowView;
    self.arrowImageView.hidden = hidenArrowView;
}

@end
