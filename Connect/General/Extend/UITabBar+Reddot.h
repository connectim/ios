//
//  UITabBar+Reddot.h
//  Connect
//
//  Created by MoHuilin on 16/9/24.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITabBar (Reddot)
// Show little red dot
- (void)showBadgeOnItemIndex:(int)index;
// Hide little red dot
- (void)hideBadgeOnItemIndex:(int)index;


@end
