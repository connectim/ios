//
//  UITabBar+Reddot.m
//  Connect
//
//  Created by MoHuilin on 16/9/24.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "UITabBar+Reddot.h"
#define TabbarItemNums 4.0

@implementation UITabBar (Reddot)

//Show little red dot
- (void)showBadgeOnItemIndex:(int)index{
    // remove little red dot
    [self removeBadgeOnItemIndex:index];
    
    // set new red dot
    UIView *badgeView = [[UIView alloc]init];
    badgeView.tag = 888 + index;
    badgeView.layer.cornerRadius = 5;
    badgeView.backgroundColor = [UIColor redColor];
    CGRect tabFrame = self.frame;
    
    float percentX = (index +0.6) / TabbarItemNums;
    CGFloat x = ceilf(percentX * tabFrame.size.width);
    CGFloat y = ceilf(0.1 * tabFrame.size.height);
    badgeView.frame = CGRectMake(x, y, 10, 10);
    [self addSubview:badgeView];
}  

// Hide little red dot
- (void)hideBadgeOnItemIndex:(int)index{
    // remove little red dot
    [self removeBadgeOnItemIndex:index];
}

// remove little red dot
- (void)removeBadgeOnItemIndex:(int)index{
    //
    for (UIView *subView in self.subviews) {
        if (subView.tag == 888+index) {
            [subView removeFromSuperview];
        }
    }
}


@end
