//
//  ConnectButton.m
//  Connect
//
//  Created by MoHuilin on 16/5/12.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "ConnectButton.h"
#import "UIImage+Color.h"


@implementation ConnectButton

- (instancetype)initWithNormalTitle:(NSString *)title disableTitle:(NSString *)disableTitle{
    if (self = [super init]) {
        [self setTitle:title forState:UIControlStateNormal];
        if (disableTitle) {
            [self setTitle:disableTitle forState:UIControlStateDisabled];
        }
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        self.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(36)];
        self.layer.cornerRadius = 4;
        self.layer.masksToBounds = YES;
        self.frame = CGRectMake(0, 0, AUTO_WIDTH(690), AUTO_HEIGHT(100));
        [self setBackgroundImage:[UIImage imageWithColor:GJCFQuickHexColor(@"D1D5DA")] forState:UIControlStateDisabled];
        [self setBackgroundImage:[UIImage imageWithColor:GJCFQuickHexColor(@"37C65C")] forState:UIControlStateNormal];
    }
    return self;
}

@end
