//
//  LMDisplayProgressView.h
//  Connect
//
//  Created by bitmain on 2017/3/14.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LMDisplayProgressView : UIView
// progress
@property(assign, nonatomic) CGFloat progress;
// color
@property(strong, nonatomic) UIColor *currentColor;
// circle
@property(assign, nonatomic) CGFloat radius;
// width
@property(assign, nonatomic) CGFloat progressWidth;


// whether is circle
@property(assign, nonatomic) BOOL isCircle;
// out circle color
@property(strong, nonatomic) UIColor *circleColor;
// out circle width
@property(assign, nonatomic) CGFloat circleWidth;
// out circle radius
@property(assign, nonatomic) CGFloat circleRadius;

@end
