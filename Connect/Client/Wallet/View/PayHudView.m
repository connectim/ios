//
//  PayHudView.m
//  Connect
//
//  Created by MoHuilin on 2016/11/9.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "PayHudView.h"

@interface PayHudView ()
@property(weak, nonatomic) IBOutlet UIView *dotView;
@property(weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property(weak, nonatomic) IBOutlet UILabel *titleLabel;

@property(nonatomic, assign) NSTimer *timer;
@property(nonatomic, assign) int currentDotIndex;
// Conventional space constraints
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *logoImageTopConstaton;


@end

@implementation PayHudView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.layer.cornerRadius = 6;
    self.layer.masksToBounds = YES;
    self.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
    self.titleLabel.text = LMLocalizedString(@"Wallet Connect Pay", nil);
    // Conventional space constraints
    self.logoImageTopConstaton.constant = AUTO_HEIGHT(55);
    [self setUpSubView];
}

- (void)setUpSubView {
    int count = 3;
    UIView *lasView = nil;
    CGFloat width = AUTO_WIDTH(15);
    CGFloat margin = AUTO_WIDTH(30);
    while (count > 0) {
        UIView *dot = [[UIView alloc] init];
        dot.layer.cornerRadius = AUTO_WIDTH(15) / 2;
        dot.layer.masksToBounds = YES;
        dot.backgroundColor = [UIColor lightGrayColor];
        [self.dotView addSubview:dot];
        if (lasView) {
            [dot mas_makeConstraints:^(MASConstraintMaker *make) {
                make.size.mas_equalTo(CGSizeMake(width, width));
                make.centerY.equalTo(self.dotView);
                make.left.equalTo(lasView.mas_right).offset(margin);
            }];
        } else {
            [dot mas_makeConstraints:^(MASConstraintMaker *make) {
                make.size.mas_equalTo(CGSizeMake(width, width));
                make.centerY.equalTo(self.dotView);
                make.centerX.equalTo(self.dotView).offset(-((width / 2) + margin));
            }];
        }
        lasView = dot;
        count--;
    }
    [self layoutIfNeeded];
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.5f
                                              target:self
                                            selector:@selector(timerFire:)
                                            userInfo:nil
                                             repeats:YES];
    [_timer fire];
}

- (void)dealloc {
    [_timer invalidate];
    _timer = nil;
}

- (void)timerFire:(NSTimer *)timer {
    NSArray *subViews = [self.dotView subviews];

    // Restore the default color
    UIView *dot = [subViews objectAtIndexCheck:self.currentDotIndex];
    dot.backgroundColor = [UIColor lightGrayColor];
    self.currentDotIndex++;
    if (self.currentDotIndex == subViews.count) {
        self.currentDotIndex = 0;
    }
    // Set the highlight color
    UIView *dot1 = [subViews objectAtIndexCheck:self.currentDotIndex];
    dot1.backgroundColor = [UIColor whiteColor];
}

@end
