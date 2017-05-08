//
//  LMSelectTableViewCell.m
//  Connect
//
//  Created by Edwin on 16/7/19.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMSelectTableViewCell.h"

@interface LMSelectTableViewCell ()

@property(weak, nonatomic) IBOutlet UIImageView *userImageView;
@property(weak, nonatomic) IBOutlet UILabel *userNameLabel;

@end

@implementation LMSelectTableViewCell


- (void)drawRect:(CGRect)rect {

    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);

    CGContextFillRect(context, rect);
    // Under the dividing line
    UIColor *lineColor = [UIColor colorWithHex:0xf0f0f6];
    CGContextSetStrokeColorWithColor(context, lineColor.CGColor);
    CGFloat height = AUTO_HEIGHT(0.4);
    CGContextStrokeRect(context, CGRectMake(0, rect.size.height - height, rect.size.width, height));
}


- (void)awakeFromNib {
    [super awakeFromNib];
    self.userImageView.layer.cornerRadius = 5;
    self.userImageView.layer.masksToBounds = YES;

    self.checkBox.tintColor = LMBasicLightGray;
    self.checkBox.onTintColor = LMBasicGreen;
    self.checkBox.onFillColor = LMBasicGreen;
    self.checkBox.onCheckColor = [UIColor whiteColor];
    self.checkBox.animationDuration = 0.1;
    self.userNameLabel.font = [UIFont systemFontOfSize:FONT_SIZE(30)];
    self.checkBox.userInteractionEnabled = NO;
}

- (void)setAccoutInfo:(AccountInfo *)info {
    if (info) {
        [self.userImageView setPlaceholderImageWithAvatarUrl:info.avatar];
        self.userNameLabel.text = info.username;
    }

    self.checkBox.on = info.isSelected;
}

@end
