//
//  UIGestureRecognizer+Cancel.m
//  Connect
//
//  Created by MoHuilin on 2017/3/5.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "UIGestureRecognizer+Cancel.h"

@implementation UIGestureRecognizer (Cancel)

- (void)cancel{
    self.enabled = NO;
    self.enabled = YES;
}

@end
