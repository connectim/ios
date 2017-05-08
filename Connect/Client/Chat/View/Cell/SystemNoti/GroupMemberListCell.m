//
//  GroupMemberListCell.m
//  Connect
//
//  Created by MoHuilin on 16/7/21.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "GroupMemberListCell.h"

@interface GroupMemberListCell ()

@property(weak, nonatomic) IBOutlet UIImageView *avatarImageView;

@property(weak, nonatomic) IBOutlet UILabel *nameLabel;

@end

@implementation GroupMemberListCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setData:(id)data {
    [super setData:data];
    AccountInfo *user = (AccountInfo *) data;
    [self.avatarImageView setPlaceholderImageWithAvatarUrl:user.avatar];
    self.nameLabel.text = user.groupShowName;
}

@end
