//
//  AddFriendCell.m
//  Connect
//
//  Created by MoHuilin on 16/5/26.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "AddFriendCell.h"
#import "AccountInfo.h"

@interface AddFriendCell ()

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (weak, nonatomic) IBOutlet UIButton *actionButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *avatarToTop;

@end

@implementation AddFriendCell

- (IBAction)addBtnClick:(id)sender {
    AccountInfo *user = (AccountInfo *)self.data;
    if (user.customOperation) {
        user.customOperation();
    }
}

- (void)setData:(id)data{
    
    [super setData:data];
    AccountInfo *user = (AccountInfo *)data;
    if (user.remarks && user.remarks.length) {
        _nameLabel.text = user.remarks;
    } else{
        _nameLabel.text = user.username;
    }
    
    
    if (user.isUnRegisterAddress) {
        [self.actionButton setTitle:LMLocalizedString(@"Wallet Transfer", nil) forState:UIControlStateNormal];
        self.actionButton.backgroundColor = GJCFQuickHexColor(@"5554D5");
    } else{
        [self.actionButton setTitle:LMLocalizedString(@"Link Add", nil) forState:UIControlStateNormal];
        self.actionButton.backgroundColor = GJCFQuickHexColor(@"00C400");

    }

    
    if (!user.stranger) {
        self.actionButton.hidden = YES;
    } else{
        self.actionButton.hidden = NO;
    }
    
    [self.avatarImageView setPlaceholderImageWithAvatarUrl:user.avatar];
}

@end
