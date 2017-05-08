//
//  LMDBUpdataController.h
//  Connect
//
//  Created by MoHuilin on 2017/4/12.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LMDBUpdataController : UIViewController

- (instancetype)initWithUpdateComplete:(void (^)(BOOL complete))complete;

@end
