//
//  MMLaunchViewController.h
//  Connect
//
//  Created by MoHuilin on 2016/11/3.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MMLaunchViewController : UIViewController

@property(assign, nonatomic) CGFloat duration;
@property(assign, nonatomic) CGFloat animationDuration;
@property(nonatomic, copy) void (^hidenAdByUserBlock)();

@end
