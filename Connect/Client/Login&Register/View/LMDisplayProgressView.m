//
//  LMDisplayProgressView.m
//  Connect
//
//  Created by bitmain on 2017/3/14.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMDisplayProgressView.h"

@implementation LMDisplayProgressView


- (void)setProgress:(CGFloat)progress {
    _progress = progress;

    [self setNeedsDisplay];

}

- (void)drawRect:(CGRect)rect {

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (self.isCircle) {
        // 1.path
        CGPoint centerCircle = CGPointMake(self.width * 0.5, self.height * 0.5);
        CGFloat radiusCircle = self.circleRadius;
        CGFloat startCircle = -M_PI_2;
        CGFloat endCircle = -M_PI_2 + M_PI * 2;
        UIBezierPath *pathCircle = [UIBezierPath bezierPathWithArcCenter:centerCircle radius:radiusCircle startAngle:startCircle endAngle:endCircle clockwise:YES];
        pathCircle.lineWidth = self.circleWidth;
        [self.circleColor setStroke];
        [pathCircle stroke];
        CGContextAddPath(ctx, pathCircle.CGPath);
        // set context
        CGContextStrokePath(ctx);

    }
    // 2. path
    CGPoint center = CGPointMake(self.width * 0.5, self.height * 0.5);
    CGFloat radius = self.radius;
    CGFloat startA = -M_PI_2;
    CGFloat endA = -M_PI_2 + _progress * M_PI * 2;
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:startA endAngle:endA clockwise:YES];
    path.lineWidth = self.progressWidth;
    [self.currentColor setStroke];
    [path stroke];
    CGContextAddPath(ctx, path.CGPath);
    // set context
    CGContextStrokePath(ctx);

}
@end
