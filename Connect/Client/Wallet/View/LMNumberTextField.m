//
//  LMNumberTextField.m
//  Connect
//
//  Created by bitmain on 2016/12/13.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import "LMNumberTextField.h"

@implementation LMNumberTextField
// Disable copy and paste, and so on
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if ([UIMenuController sharedMenuController]) {
        [UIMenuController sharedMenuController].menuVisible = NO;
    }
    return NO;
}
@end
