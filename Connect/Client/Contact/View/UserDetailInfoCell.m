//
//  UserDetailInfoCell.m
//  Connect
//
//  Created by MoHuilin on 16/7/21.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "UserDetailInfoCell.h"
#import "UUImageAvatarBrowser.h"

@interface UserDetailInfoCell () <UITextViewDelegate>
@property(weak, nonatomic) IBOutlet UILabel *addressLabel;

@property(weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property(weak, nonatomic) IBOutlet UIImageView *avatarImageView;
// source lable
@property(weak, nonatomic) IBOutlet UILabel *sourceLabel;
// black list tip lable
@property(weak, nonatomic) IBOutlet UILabel *blackListTipLabel;
// user message content
@property(weak, nonatomic) IBOutlet UIView *infoContentView;
// localtion Lable
@property(weak, nonatomic) IBOutlet UILabel *locationLabel;
// weather is black list
@property(weak, nonatomic) IBOutlet UISwitch *isAddToBlackList;
// msgTextView
@property(weak, nonatomic) IBOutlet UITextView *msgTextView;
@property(weak, nonatomic) IBOutlet UILabel *acceptLable;
@property(weak, nonatomic) IBOutlet UIImageView *acceptImageView;
@property(weak, nonatomic) IBOutlet UILabel *idLable;
@property(weak, nonatomic) IBOutlet UIView *bearerButtonView;


@end

@implementation UserDetailInfoCell
// button action
- (IBAction)chaiButtonAction:(UIButton *)sender {
    if (self.friendButtonBlock) {
        self.friendButtonBlock(ButtonTypeChat);
    }

}

- (IBAction)transferAction:(UIButton *)sender {
    if (self.friendButtonBlock) {
        self.friendButtonBlock(ButtonTypeTransfer);
    }

}

- (IBAction)mesageAction:(UIButton *)sender {
    if (self.friendButtonBlock) {
        self.friendButtonBlock(ButtonTypeMessage);
    }

}

- (IBAction)shareAction:(UIButton *)sender {
    if (self.friendButtonBlock) {
        self.friendButtonBlock(ButtonTypeShare);
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];
    _avatarImageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(avatarTap)];
    [_avatarImageView addGestureRecognizer:tap];
    _avatarImageView.layer.cornerRadius = 6;
    _avatarImageView.layer.masksToBounds = YES;
    _infoContentView.backgroundColor = GJCFQuickHexColor(@"F0F0F6");

    [_isAddToBlackList addTarget:self action:@selector(switchValueChange) forControlEvents:UIControlEventValueChanged];

    _msgTextView.delegate = self;
    _msgTextView.font = [UIFont systemFontOfSize:FONT_SIZE(36)];
    _msgTextView.returnKeyType = UIReturnKeySend;

    _msgTextView.text = [NSString stringWithFormat:LMLocalizedString(@"Link Hello I am", nil), [[LKUserCenter shareCenter] currentLoginUser].username];

    self.blackListTipLabel.text = LMLocalizedString(@"Link Block", nil);
    UITapGestureRecognizer *tapAddress = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(copyAddress)];
    [self.addressLabel addGestureRecognizer:tapAddress];
    self.addressLabel.userInteractionEnabled = YES;


    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.acceptLable.hidden = YES;
    self.acceptImageView.hidden = YES;
    self.bearerButtonView.hidden = YES;
}

- (void)copyAddress {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    CellItem *item = (CellItem *) self.data;
    AccountInfo *user = item.userInfo;
    pasteboard.string = user.address;

    if (self.copyBlock) {
        self.copyBlock();
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if (1 == range.length) {
        // press enter key
        return YES;
    }
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        // send notification
        if (self.inviteBlock) {
            self.inviteBlock(textView.text);
        }
        return NO;
    } else {
        if ([textView.text length] < 20) {
            // Determine the number of characters
            return YES;
        }
    }
    return NO;
}


- (void)dealloc {
    self.msgTextView.delegate = nil;
}

- (void)textViewDidChange:(UITextView *)textView {
    if (self.TextValueChangeBlock) {
        self.TextValueChangeBlock(textView.text);
    }
}

/**
 *  head click
 */
- (void)avatarTap {
    [UUImageAvatarBrowser showImage:_avatarImageView];
}

- (void)switchValueChange {
    if (self.switchValueChangeBlock) {
        self.switchValueChangeBlock(_isAddToBlackList.on);
    }
}

- (void)setData:(id)data {
    [super setData:data];


    CellItem *item = (CellItem *) data;

    AccountInfo *user = item.userInfo;

    _isAddToBlackList.on = user.isBlackMan;

    [self setSourceLabelTextWithUser:user];

    // cache user avatar
    [self.avatarImageView setPlaceholderImageWithAvatarUrl:user.avatar400 imageByRoundCornerRadius:0];

    NSString *name = user.username;
    if (!GJCFStringIsNull(user.remarks)) {
        name = [NSString stringWithFormat:@"%@(%@)", user.remarks, user.username];
    }
    _usernameLabel.text = name;
    _addressLabel.text = user.address;

    if (!user.stranger) {
        _msgTextView.text = nil;
        _msgTextView.userInteractionEnabled = NO;
        self.sourceLabel.hidden = NO;
        self.isAddToBlackList.hidden = NO;
        self.blackListTipLabel.hidden = NO;
        self.msgTextView.hidden = YES;
        self.acceptLable.hidden = YES;
        self.acceptImageView.hidden = YES;
        self.bearerButtonView.hidden = NO;
    } else {
        self.bearerButtonView.hidden = YES;
        _msgTextView.userInteractionEnabled = YES;
        self.sourceLabel.hidden = YES;
        self.isAddToBlackList.hidden = YES;
        self.blackListTipLabel.hidden = YES;
        self.msgTextView.hidden = YES;
        self.acceptImageView.hidden = NO;
        self.acceptLable.hidden = NO;
        self.acceptLable.text = user.message;
        if (GJCFStringIsNull(user.message)) {
            self.acceptLable.text = [NSString stringWithFormat:LMLocalizedString(@"Link Hello I am", nil), [[LKUserCenter shareCenter] currentLoginUser].username];
        }
        self.acceptLable.hidden = YES;
        self.acceptImageView.hidden = YES;
    }
}

- (void)setSourceLabelTextWithUser:(AccountInfo *)user {
    switch (user.source) {
        case UserSourceTypeQrcode:
            _sourceLabel.text = LMLocalizedString(@"Link From QR Code", nil);
            break;
        case UserSourceTypeContact:
            _sourceLabel.text = LMLocalizedString(@"Link From Contact Match", nil);
            break;
        case UserSourceTypeTransaction:
            _sourceLabel.text = LMLocalizedString(@"Link From Transaction", nil);
            break;
        case UserSourceTypeGroup:
            _sourceLabel.text = LMLocalizedString(@"Link From Group", nil);
            break;
        case UserSourceTypeSearch:
            _sourceLabel.text = LMLocalizedString(@"Link From Search", nil);
            break;
        case UserSourceTypeRecommend:
            _sourceLabel.text = LMLocalizedString(@"Link Friend Recommendation", nil);
            break;
        case UserSourceTypeDefault:
            _sourceLabel.text = LMLocalizedString(@"Link From Search", nil);
            break;
        default:
            break;
    }
}


@end
