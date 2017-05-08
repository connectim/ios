//
//  LMTranferFriendsTableViewCell.m
//  Connect
//
//  Created by Edwin on 16/7/22.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMTranferFriendsTableViewCell.h"

@implementation LMTranferFriendsTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self initTableViewCell];
    }
    return self;
}

- (void)initTableViewCell {

    for (NSInteger i = self.infoArr.count; i >= 0; i--) {
        AccountInfo *info = self.infoArr[i];
        UIImageView *iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(AUTO_WIDTH(30) + (AUTO_WIDTH(60) + VSIZE.width / 8) * i, AUTO_HEIGHT(10), VSIZE.width / 8, VSIZE.width / 8)];
        iconImageView.layer.cornerRadius = 5;
        iconImageView.layer.masksToBounds = YES;
        if (i == self.infoArr.count) {
            iconImageView.image = [UIImage imageNamed:@"add_white"];
            iconImageView.backgroundColor = [UIColor lightGrayColor];
        } else {
            iconImageView.image = [UIImage imageNamed:info.avatar];
        }

        [self.contentView addSubview:iconImageView];

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(iconImageView.frame), CGRectGetMaxY(iconImageView.frame) + AUTO_HEIGHT(10), CGRectGetWidth(iconImageView.frame), AUTO_HEIGHT(40))];

        label.text = info.username;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:FONT_SIZE(22)];
        [self.contentView addSubview:label];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
