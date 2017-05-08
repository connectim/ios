//
//  MyInfoCell.m
//  Connect
//
//  Created by MoHuilin on 16/7/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "MyInfoCell.h"

@interface MyInfoCell ()

@property(weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property(weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property(weak, nonatomic) IBOutlet UIButton *showAddressQRButton;

@end

@implementation MyInfoCell
- (IBAction)showQRAction:(id)sender {

    if (self.qrBtnClickBlock) {
        self.qrBtnClickBlock();
    }

}

- (void)awakeFromNib {
    [super awakeFromNib];

    _avatarImageView.layer.cornerRadius = 6;
    _avatarImageView.layer.masksToBounds = YES;
    self.userNameLabel.font = [UIFont boldSystemFontOfSize:FONT_SIZE(36)];
    self.userIDLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
}

- (void)setData:(id)data {
    [super setData:data];

    AccountInfo *user = (AccountInfo *) data;
    [self.avatarImageView setPlaceholderImageWithAvatarUrl:user.avatar];
    _userNameLabel.text = user.username;
    // Safety measures
    if (user.contentId.length <= 0) {
        user.contentId = user.address;
    }

    if (user.contentId.length > 10) {
        NSMutableString *IdStringM = [NSMutableString stringWithFormat:@"%@", [user.contentId substringToIndex:user.contentId.length / 2]];
        [IdStringM appendString:@"\n"];
        [IdStringM appendString:[NSString stringWithFormat:@"%@", [user.contentId substringFromIndex:user.contentId.length / 2]]];
        _userIDLabel.text = IdStringM;
    } else {
        _userIDLabel.text = user.contentId;
    }
}

@end
