//
//  UINavigationController+LM.m
//  Connect
//
//  Created by Qingxu Kuang on 16/8/17.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "UINavigationController+LM.h"

@implementation UINavigationController (LM)
- (void)IGWPushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    self.interactivePopGestureRecognizer.delegate = self;
    [self IGWPushViewController:viewController animated:animated];
}

+ (void)load {
    Method _origin = class_getInstanceMethod([UINavigationController class], @selector(pushViewController:animated:));
    Method _new    = class_getInstanceMethod([self class], @selector(IGWPushViewController:animated:));
    method_exchangeImplementations(_origin, _new);
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([self.viewControllers count] <= 1) {
        return NO;
    }
    return YES;
}
@end
