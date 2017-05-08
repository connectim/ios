//
//  BottomLineTextField.m
//  Connect
//
//  Created by MoHuilin on 2016/12/6.
//  Copyright © 2016年 Connect - P2P Encrypted Instant Message. All rights reserved.
//

#import "BottomLineTextField.h"

@interface BottomLineTextField ()

@property(strong, nonatomic) UIView *bottomLine;

@end

@implementation BottomLineTextField

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        if (self.bottomLine == nil) {
            UIView *bottomLine = [UIView new];
            bottomLine.backgroundColor = LMBasicLineViewColor;
            [self addSubview:bottomLine];
            [bottomLine mas_makeConstraints:^(MASConstraintMaker *make) {
                make.right.left.equalTo(self);
                make.bottom.equalTo(self).offset(-0.5);
                make.height.mas_equalTo(@0.5);
            }];
            self.bottomLine = bottomLine;
        }
        self.tintColor = LMBasicBlack;
    }
    return self;
}

- (CGRect)textRectForBounds:(CGRect)bounds {

    CGRect tem = [super textRectForBounds:bounds];
    tem.origin.x += 10;
    return tem;
}

// text position
- (CGRect)editingRectForBounds:(CGRect)bounds {
    CGRect tem = [super textRectForBounds:bounds];
    tem.origin.x += 10;
    return tem;
}

@end
