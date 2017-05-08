//
//  XWTableViewCell.m
//  XWTableViewCell
//
//  Created by Edwin on 16/7/18.
//  Copyright © 2016年 EdwinXiang. All rights reserved.
//

#import "XWTableViewCell.h"

#define LocationCellSpace  50

@interface XWTableViewCell ()


@property(weak, nonatomic) IBOutlet UIView *contentViews;

@property(weak, nonatomic) IBOutlet UILabel *bitcoinAddress;
@property(weak, nonatomic) IBOutlet UILabel *mainAddress;
@property(weak, nonatomic) IBOutlet UILabel *bitcoinAccout;

@end

@implementation XWTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.contentViews.backgroundColor = [UIColor colorWithRed:32 / 255.0 green:35 / 255.0 blue:41 / 255.0 alpha:1.0f];

    UIView *tempView = [[UIView alloc] init];
    [self setBackgroundView:tempView];
    [self setBackgroundColor:[UIColor clearColor]];
    self.bitcoinAddress.font = [UIFont systemFontOfSize:FONT_SIZE(26)];
    self.mainAddress.font = [UIFont systemFontOfSize:FONT_SIZE(32)];
    self.contentViews.layer.cornerRadius = 5;
    self.contentViews.layer.masksToBounds = YES;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    frame.origin.x += LocationCellSpace;
    frame.size.width -= 2 * LocationCellSpace;
}

- (void)setBitCoinInfo:(BitcoinInfo *)info {
    if (info) {
        self.bitcoinAddress.text = info.bitcoinAddress;
        self.mainAddress.text = info.mainAddress;
        self.bitcoinAccout.text = info.bitcoinAccout;
    }
}
@end
