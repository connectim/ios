//
//  TopImageBottomItem.m
//  Connect
//
//  Created by MoHuilin on 16/8/24.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "TopImageBottomItem.h"

@interface TopImageBottomItem ()

@property (nonatomic ,strong) UIImageView *iconView;

@end

@implementation TopImageBottomItem

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        self.margin = 2;
        self.iconView = [[UIImageView alloc] init];
        [self addSubview:_iconView];
        
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.textColor = GJCFQuickHexColor(@"161A21");
        self.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
        [self addSubview:_titleLabel];
        
        [_iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.equalTo(self).offset(self.margin);
            make.right.equalTo(self).offset(-self.margin);
            make.height.equalTo(_iconView.mas_width);
        }];
        
        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_iconView.mas_bottom).offset(self.margin);
            make.centerX.equalTo(self.mas_centerX);
            make.bottom.equalTo(self.mas_bottom);
        }];
        
    }
    
    return self;
}

+ (instancetype)itemWihtIcon:(NSString *)icon title:(NSString *)title{
    TopImageBottomItem *item = [[TopImageBottomItem alloc] init];
    
    item.iconView.image = [UIImage imageNamed:icon];
    item.titleLabel.text = title;
    
    return item;
}

- (void)setMargin:(CGFloat)margin{
    _margin = margin;
    
    [self setNeedsDisplay];
}

@end
