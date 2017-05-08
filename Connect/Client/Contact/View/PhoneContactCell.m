//
//  PhoneContactCell.m
//  Connect
//
//  Created by MoHuilin on 16/5/30.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "PhoneContactCell.h"
#import "PhoneContactInfo.h"

@interface PhoneContactCell ()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *checkBoxWidth;


@end

@implementation PhoneContactCell

- (void)awakeFromNib{
    [super awakeFromNib];
    _checkBox.userInteractionEnabled = NO;
    [self setup];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.nameLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.phoneLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
    self.checkBox.tintColor = LMBasicLightGray;
    self.checkBox.onTintColor = LMBasicGreen;
    self.checkBox.onFillColor = LMBasicGreen;
    self.checkBox.onCheckColor = [UIColor whiteColor];
    self.checkBox.animationDuration = 0.1;
}
- (void)setData:(id)data{
    [super setData:data];
    
    PhoneContactInfo *phoneContact = (PhoneContactInfo *)data;
    
    _nameLabel.text = [NSString stringWithFormat:@"%@ %@",phoneContact.lastName,phoneContact.firstName];
    if (phoneContact.phones.count) {
        Phone *phone = [phoneContact.phones firstObject];
        _phoneLabel.text = phone.phoneNum;
    }
    
    self.checkBox.on = phoneContact.isSelected;
}

@end
