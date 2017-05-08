//
//  LMFriendTableViewCell.m
//  Connect
//
//  Created by Edwin on 16/7/19.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMFriendTableViewCell.h"

@interface LMFriendTableViewCell ()

@property(nonatomic, weak) IBOutlet UIImageView *userImageView;
@property(nonatomic, weak) IBOutlet UILabel *userNameLabel;

@end

@implementation LMFriendTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.userImageView.layer.cornerRadius = 5;
    self.userImageView.layer.masksToBounds = YES;
}

- (void)setAccoutInfoFriends:(AccountInfo *)info {
    if (info) {
        [self.userImageView setPlaceholderImageWithAvatarUrl:info.avatar];
        self.userNameLabel.text = info.normalShowName;
    }
}

@end
