//
//  CollectionReusableView.m
//  Connect
//
//  Created by Edwin on 16/7/14.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "CollectionReusableView.h"

@interface CollectionReusableView () <LMTopViewDelegate>

@end

@implementation CollectionReusableView
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.topView = [[LMTopView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        self.topView.delegate = self;
        self.topView.backgroundColor = [UIColor blackColor];
        [self addSubview:self.topView];
    }
    return self;
}

- (void)LMTopView:(LMTopView *)view PayBtnClick:(UIButton *)btn {
    [self.delegate CollectionReusableView:self PayBtnClick:btn];
}

- (void)LMTopView:(LMTopView *)view WalletBtnClick:(UIButton *)btn {
    [self.delegate CollectionReusableView:self WalletBtnClick:btn];
}

- (void)LMTopView:(LMTopView *)view CollectBtnClick:(UIButton *)btn {
    [self.delegate CollectionReusableView:self CollectBtnClick:btn];
}


@end
