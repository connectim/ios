//
//  PhoneRegisterCell.m
//  Connect
//
//  Created by MoHuilin on 16/5/30.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "PhoneRegisterCell.h"
#import "UIImage+Color.h"

@interface PhoneRegisterCell ()
@property(weak, nonatomic) IBOutlet UILabel *nameLabel;
@property(weak, nonatomic) IBOutlet UIButton *addButton;
@property(weak, nonatomic) IBOutlet UIImageView *avatarView;
@property(weak, nonatomic) IBOutlet UILabel *nickNameLabel;

@end

@implementation PhoneRegisterCell
- (IBAction)rithtButtonAction:(id)sender {
    AccountInfo *user = (AccountInfo *) self.data;
    user.customOperation ? user.customOperation() : nil;
}

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

    self.nameLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.nickNameLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
    self.addButton.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
    _addButton.userInteractionEnabled = NO;
    [_addButton setBackgroundImage:[UIImage imageWithColor:XCColor(69, 69, 216)] forState:UIControlStateNormal];
    [_addButton setBackgroundImage:[UIImage imageWithColor:XCColor(242, 242, 242)] forState:UIControlStateDisabled];
    [_addButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
}

- (void)setData:(id)data {
    [super setData:data];
    AccountInfo *user = (AccountInfo *) data;
    _nameLabel.text = user.username;
    _nickNameLabel.text = user.phoneContactName;


    if (!user.stranger) {
        [_addButton setTitle:LMLocalizedString(@"Link Added", nil) forState:UIControlStateDisabled];
        _addButton.enabled = NO;
    } else {
        switch (user.status) {
            case RequestFriendStatusVerfing: {
                [_addButton setTitle:LMLocalizedString(@"Link Verify", nil) forState:UIControlStateDisabled];
                _addButton.enabled = NO;
            }
                break;
            case RequestFriendStatusAdded: {
                [_addButton setTitle:LMLocalizedString(@"Link Added", nil) forState:UIControlStateDisabled];
                _addButton.enabled = NO;
            }
                break;
            case RequestFriendStatusAdd: {
                [_addButton setTitle:LMLocalizedString(@"Link Add", nil) forState:UIControlStateNormal];
                _addButton.enabled = YES;
            }
                break;
            case RequestFriendStatusAccept: {
                [_addButton setTitle:LMLocalizedString(@"Link Accept", nil) forState:UIControlStateNormal];
                _addButton.enabled = YES;
            }
                break;

            default:
                break;
        }
    }
    [self.avatarView setPlaceholderImageWithAvatarUrl:user.avatar];
}
@end
