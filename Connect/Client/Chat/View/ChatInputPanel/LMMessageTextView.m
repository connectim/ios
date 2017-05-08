//
//  LMMessageTextView.m
//  Connect
//
//  Created by MoHuilin on 2017/3/10.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMMessageTextView.h"

@implementation LMMessageTextView

- (void)deleteBackward {
    if ([self.deleteCharDelegate respondsToSelector:@selector(deleteBackward)]) {
        [self.deleteCharDelegate deleteBackward];
    }

    [super deleteBackward];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    NSMutableArray *menuItems = [NSMutableArray arrayWithArray:[UIMenuController sharedMenuController].menuItems];
    for (UIMenuItem *item in menuItems) {
        if (item.action == @selector(retweetMessage:)) {
            [menuItems removeObject:item];
            [UIMenuController sharedMenuController].menuItems = menuItems.copy;
            break;
        }
    }
    return [super canPerformAction:action withSender:sender];
}
@end
