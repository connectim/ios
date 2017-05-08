//
//  ChooseContactCell.m
//  Connect
//
//  Created by MoHuilin on 16/7/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "ChooseContactCell.h"

@interface ChooseContactCell ()
@property(weak, nonatomic) IBOutlet UIImageView *contactAvatarImageView;
@property(weak, nonatomic) IBOutlet UILabel *titleLabel;
@property(weak, nonatomic) IBOutlet UILabel *subTitleLabel;

@end

@implementation ChooseContactCell


- (void)awakeFromNib {
    [super awakeFromNib];

    self.checkBoxView.userInteractionEnabled = NO;
    self.checkBoxView.tintColor = LMBasicLightGray;
    self.checkBoxView.onTintColor = LMBasicGreen;
    self.checkBoxView.onFillColor = LMBasicGreen;
    self.checkBoxView.onCheckColor = [UIColor whiteColor];
    self.checkBoxView.animationDuration = 0.1;
}

- (void)setData:(id)data {
    [super setData:data];

    AccountInfo *info = (AccountInfo *) data;

    [self.contactAvatarImageView setPlaceholderImageWithAvatarUrl:info.avatar];

    _titleLabel.text = info.username;
    _subTitleLabel.text = info.remarks;
}

@end
