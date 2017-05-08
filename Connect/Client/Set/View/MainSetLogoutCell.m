//
//  MainSetLogoutCell.m
//  Connect
//
//  Created by MoHuilin on 16/7/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "MainSetLogoutCell.h"

@interface MainSetLogoutCell ()

@property(nonatomic, strong) UIButton *logoutButton;

@end

@implementation MainSetLogoutCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.logoutButton = [[UIButton alloc] init];

        [self.logoutButton addTarget:self action:@selector(logout:) forControlEvents:UIControlEventTouchUpInside];
        [self.logoutButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];

        [self.logoutButton setBackgroundColor:[UIColor whiteColor]];
        self.logoutButton.layer.cornerRadius = 5;
        self.logoutButton.layer.masksToBounds = YES;

        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];

        self.logoutButton.left = 15;
        self.logoutButton.width = DEVICE_SIZE.width - 30;
        self.logoutButton.top = 0;
        self.logoutButton.height = 50;

        self.logoutButton.userInteractionEnabled = NO;

        [self.contentView addSubview:self.logoutButton];

        self.separatorInset = UIEdgeInsetsMake(0.f, DEVICE_SIZE.width, 0.f, 0.f);

    }

    return self;
}

- (void)setData:(id)data {
    [super setData:data];

    CellItem *item = (CellItem *) data;
    [self.logoutButton setTitle:item.title forState:UIControlStateNormal];
    self.logoutButton.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(36)];
}


- (void)logout:(UIButton *)sender {
    DDLogInfo(@"Log Out");
}


- (void)layoutSubviews {
    [super layoutSubviews];
}

@end
