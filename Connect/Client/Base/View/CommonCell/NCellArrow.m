//
//  NCellArrow.m
//  HashNest
//
//  Created by MoHuilin on 16/3/16.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "NCellArrow.h"

@interface NCellArrow(){
    UIImageView *imageView;
}

@end

@implementation NCellArrow

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
    
        imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ShareArrow"]];
        
        imageView.size = CGSizeMake(9, 14);
        imageView.centerY = self.centerY;
        imageView.right = DEVICE_SIZE.width - 10;
        
        [self.contentView addSubview:imageView];
        
        
        _customTitleLabel = [UILabel new];
        [self.contentView addSubview:_customTitleLabel];
        _customTitleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(32)];
        [_customTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(AUTO_WIDTH(30));
            make.centerY.equalTo(self.contentView);
        }];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    imageView.centerY = self.contentView.height / 2;

}

@end
