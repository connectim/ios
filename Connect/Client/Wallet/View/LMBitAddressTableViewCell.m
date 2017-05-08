//
//  LMBitAddressTableViewCell.m
//  Connect
//
//  Created by Edwin on 16/7/21.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMBitAddressTableViewCell.h"


@interface LMBitAddressTableViewCell ()

@property(weak, nonatomic) IBOutlet UILabel *listLabel;
@property(weak, nonatomic) IBOutlet UILabel *BitAddressLabel;


@end

@implementation LMBitAddressTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.layer.cornerRadius = 8;
    self.layer.masksToBounds = YES;
    self.listLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
    self.BitAddressLabel.font = [UIFont systemFontOfSize:FONT_SIZE(26)];
}

- (void)setAddressWithAddressBookInfo:(AddressBookInfo *)info {
    self.listLabel.text = info.tag;
    self.BitAddressLabel.text = info.address;
}

@end
