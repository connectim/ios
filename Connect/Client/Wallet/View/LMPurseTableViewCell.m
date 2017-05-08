//
//  LMPurseTableViewCell.m
//  Connect
//
//  Created by Edwin on 16/7/17.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMPurseTableViewCell.h"

@interface LMPurseTableViewCell ()

@property(weak, nonatomic) IBOutlet UILabel *bitcoinAddress;

@property(weak, nonatomic) IBOutlet UIImageView *QrcodeImage;

@property(weak, nonatomic) IBOutlet UILabel *listLabel;

@property(weak, nonatomic) IBOutlet UILabel *bitcoinAccout;
@end

@implementation LMPurseTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    UIView *tempView = [[UIView alloc] init];
    [self setBackgroundView:tempView];
    [self setBackgroundColor:[UIColor clearColor]];
    self.bitcoinAddress.font = [UIFont systemFontOfSize:FONT_SIZE(26)];
    self.layer.cornerRadius = 5;
    self.layer.masksToBounds = YES;

    UITapGestureRecognizer *tapQr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(QrcodeImageTapRecognizer:)];
    tapQr.numberOfTapsRequired = 1;
    self.QrcodeImage.userInteractionEnabled = YES;
    [self.QrcodeImage addGestureRecognizer:tapQr];

    UITapGestureRecognizer *listTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(listTapRecoginzer:)];
    [listTap setNumberOfTapsRequired:1];
    self.listLabel.userInteractionEnabled = YES;
    [self.listLabel addGestureRecognizer:listTap];
}

- (void)setBitCoinInfo:(BitcoinInfo *)info {
    if (info) {
        self.bitcoinAddress.text = info.bitcoinAddress;
        self.QrcodeImage.image = [UIImage imageNamed:@"qrcodeimage"];
        self.listLabel.text = info.mainAddress;
        self.bitcoinAccout.text = info.bitcoinAccout;
    }
}

- (void)QrcodeImageTapRecognizer:(UITapGestureRecognizer *)tap {
    [self.delegates LMPurseTableViewCell:self qrcodeImageTap:tap];
}

- (void)listTapRecoginzer:(UITapGestureRecognizer *)tap {

    [self.delegates LMPurseTableViewCell:self listTap:tap];
}

@end
