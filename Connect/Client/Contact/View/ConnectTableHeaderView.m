//
//  LinkmeTableHeaderView.m
//  LinkMe
//
//  Created by MoHuilin on 16/5/26.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "ConnectTableHeaderView.h"

@interface ConnectTableHeaderView ()

@property (nonatomic ,strong) UIImageView *customIconView;

@end

@implementation ConnectTableHeaderView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithReuseIdentifier:reuseIdentifier]) {
        
        
        [self.contentView addSubview:self.customIconView];
        [_customIconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self).offset(5);
            make.bottom.equalTo(self).offset(-5);
            make.left.equalTo(self).offset(17);
            make.width.mas_equalTo(0);
        }];
        
        [self.contentView addSubview:self.customTitle];
        [_customTitle mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self);
            make.left.equalTo(_customIconView.mas_right);
        }];
        
        self.contentView.backgroundColor = GJCFQuickHexColor(@"F0F0F6");
        
    }
    
    return self;
}


- (void)setCustomIcon:(NSString *)customIcon{
    if (customIcon) {
        _customIcon = customIcon;
        _customIconView.image = [UIImage imageNamed:customIcon];
        [_customIconView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self).offset(5);
            make.bottom.equalTo(self).offset(-5);
            make.left.equalTo(self).offset(17);
            make.width.equalTo(_customIconView.mas_height).multipliedBy(1.2);
        }];
        
        [_customTitle mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self);
            make.left.equalTo(_customIconView.mas_right).offset(5);
        }];
    }else{
        [_customIconView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self).offset(5);
            make.bottom.equalTo(self).offset(-5);
            make.left.equalTo(self).offset(17);
            make.width.mas_equalTo(0);
        }];
        
        [_customTitle mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self);
            make.left.equalTo(_customIconView.mas_right);
        }];
    }
}


- (UILabel *)customTitle{
    if (!_customTitle) {
        _customTitle = [UILabel new];
        _customTitle.font = [UIFont systemFontOfSize:12];
    }
    
    return _customTitle;
}

- (UIImageView *)customIconView{
    if (!_customIconView) {
        _customIconView = [[UIImageView alloc] init];
    }
    
    return _customIconView;
}

@end
