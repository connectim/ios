//
//  NewFriendTipCell.m
//  Connect
//
//  Created by MoHuilin on 16/8/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "NewFriendTipCell.h"
#import "NewFriendItemModel.h"

@interface NewFriendTipCell ()

@property(weak, nonatomic) IBOutlet UILabel *subTitleLabel;
@property(weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property(weak, nonatomic) IBOutlet UILabel *nameLabel;
@property(weak, nonatomic) IBOutlet UILabel *badgeLabel;

@end

@implementation NewFriendTipCell

- (void)awakeFromNib {

    [super awakeFromNib];

    self.badgeLabel.backgroundColor = [UIColor redColor];
    self.badgeLabel.textColor = [UIColor whiteColor];

    self.badgeLabel.layer.cornerRadius = self.badgeLabel.size.width / 2;
    self.badgeLabel.layer.masksToBounds = YES;
    self.badgeLabel.hidden = YES;
    self.badgeLabel.textAlignment = NSTextAlignmentCenter;
    self.badgeLabel.font = [UIFont systemFontOfSize:FONT_SIZE(25)];


    self.nameLabel.font = [UIFont boldSystemFontOfSize:FONT_SIZE(32)];
    self.subTitleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.subTitleLabel.textColor = GJCFQuickHexColor(@"767A82");

}


- (void)setData:(id)data {
    [super setData:data];
    NewFriendItemModel *newFriendModel = (NewFriendItemModel *) data;
    if (newFriendModel.addMeUser) {
        // cache headimage
        [self.avatarImageView setPlaceholder:@"contract_new_friend" imageWithAvatarUrl:newFriendModel.addMeUser.avatar];
        self.subTitleLabel.hidden = NO;
        self.nameLabel.text = newFriendModel.addMeUser.username;
        self.subTitleLabel.text = newFriendModel.addMeUser.message;
        self.backgroundColor = GJCFQuickHexColor(@"D0D2D6");
        self.nameLabel.textColor = [UIColor blackColor];
        self.subTitleLabel.textColor = GJCFQuickHexColor(@"767A82");
    } else {
        [self.avatarImageView setImage:[UIImage imageNamed:newFriendModel.icon]];
        self.nameLabel.text = LMLocalizedString(@"Link New friend", nil);
        self.subTitleLabel.hidden = YES;
        self.subTitleLabel.text = nil;
        self.backgroundColor = [UIColor whiteColor];
        self.nameLabel.textColor = [UIColor blackColor];
        self.subTitleLabel.textColor = [UIColor blackColor];
    }
    // refresh
    if ([newFriendModel.FriendBadge integerValue] > 0) {
        self.badgeLabel.hidden = NO;
        self.badgeLabel.text = newFriendModel.FriendBadge;
    } else {
        self.badgeLabel.hidden = YES;
        self.badgeLabel.text = nil;
    }
}

@end
