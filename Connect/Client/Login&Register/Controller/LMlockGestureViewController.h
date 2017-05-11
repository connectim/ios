//
//  LMlockGestureViewController.h
//  Connect
//
//  Created by Connect on 2017/5/11.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "BaseViewController.h"

@interface LMlockGestureViewController : BaseViewController
- (instancetype)initWithAction:(void (^)(BOOL result))complete;
@end
