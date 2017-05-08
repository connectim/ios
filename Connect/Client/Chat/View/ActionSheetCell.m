//
//  ActionSheetCell.m
//  Connect
//
//  Created by MoHuilin on 16/9/5.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "ActionSheetCell.h"

@interface ActionSheetCell ()

@property(nonatomic, strong) UIImageView *cusIconView;

@property(nonatomic, strong) UILabel *cusTitleLabel;

@end

@implementation ActionSheetCell


- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    self.cusIconView = [[UIImageView alloc] init];
    [self.contentView addSubview:self.cusIconView];


    self.cusTitleLabel = [[UILabel alloc] init];
    self.cusTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.cusTitleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(36)];
    [self.contentView addSubview:self.cusTitleLabel];


    [self.cusIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.cusTitleLabel.mas_left).offset(-10);
        make.size.mas_equalTo(CGSizeMake(AUTO_WIDTH(42), AUTO_HEIGHT(45)));
        make.centerY.equalTo(self.contentView);
    }];


    [_cusTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.width.mas_equalTo(AUTO_WIDTH(500));
    }];

}

- (void)setData:(id)data {
    [super setData:data];
    CellItem *item = (CellItem *) data;
    if (!GJCFStringIsNull(item.icon)) {
        self.cusIconView.image = [UIImage imageNamed:item.icon];
    }
    self.cusTitleLabel.text = item.title;
    if (item.titleColor) {
        self.cusTitleLabel.textColor = item.titleColor;
    } else {
        self.cusTitleLabel.textColor = [UIColor blackColor];
    }

    if (item.isSelect) {
        self.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        self.accessoryType = UITableViewCellAccessoryNone;
    }
}

@end
