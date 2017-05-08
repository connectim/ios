//
//  AccountUserNameWidget.m
//  Connect
//
//  Created by MoHuilin on 16/5/12.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "AccountUserNameWidget.h"

@interface AccountUserNameWidget ()

@property(nonatomic, strong) UIImageView *avatarView;

@property(nonatomic, strong) UILabel *nameLabel;

@end

@implementation AccountUserNameWidget

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.avatarView = [UIImageView new];
        _avatarView.layer.cornerRadius = 5;
        _avatarView.layer.masksToBounds = YES;
        [self addSubview:_avatarView];
        [_avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.left.equalTo(self).offset(15);
            make.size.mas_equalTo(CGSizeMake(40, 40));
        }];

        self.nameLabel = [UILabel new];
        _nameLabel.textColor = [UIColor blackColor];
        _nameLabel.font = [UIFont systemFontOfSize:FONT_SIZE(48)];
        [self addSubview:_nameLabel];
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.left.equalTo(_avatarView.mas_right).offset(30);
        }];
    }

    return self;
}

- (void)loadData {
    [self.avatarView setPlaceholderImageWithAvatarUrl:_account.avatar];
    _nameLabel.text = _account.username;
}

@end
