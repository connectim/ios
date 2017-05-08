//
//  LMProgressView.m
//  MKCustomCamera
//
//  Created by bitmain on 2017/2/6.
//  Copyright © 2017年 MK. All rights reserved.
//

#import "LMProgressView.h"
#import "LMPhotoViewController.h"

@implementation LMProgressView

- (void)setProgress:(CGFloat)progress {
    _progress = progress;

    [self setNeedsDisplay];

}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGPoint center = CGPointMake(CommonButtonWidth, CommonButtonWidth);
    CGFloat radius = CommonButtonWidth - 12;
    CGFloat startA = -M_PI_2;
    CGFloat endA = -M_PI_2 + _progress * M_PI * 2;
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:startA endAngle:endA clockwise:YES];
    path.lineWidth = 10;
    [self.currentColor setStroke];
    [path stroke];
    CGContextAddPath(ctx, path.CGPath);
    
    CGContextStrokePath(ctx);
}


@end
