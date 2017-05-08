//
//  SetAvatarCell.m
//  Connect
//
//  Created by MoHuilin on 16/7/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "SetAvatarCell.h"

@interface SetAvatarCell ()

@property(weak, nonatomic) IBOutlet UILabel *titleLabel;
@property(weak, nonatomic) IBOutlet UIImageView *avatarView;


@end

@implementation SetAvatarCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.avatarView.layer.cornerRadius = 6;
    self.avatarView.layer.masksToBounds = YES;
}

- (void)setData:(id)data {
    [super setData:data];

    CellItem *item = (CellItem *) data;
    AccountInfo *user = item.userInfo;

    // cache circle
    [self.avatarView setPlaceholderImageWithAvatarUrl:user.avatar];
    _titleLabel.text = item.title;
}


@end
