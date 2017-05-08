//
//  LMDrawView.m
//  Connect
//
//  Created by bitmain on 2016/12/9.
//  Copyright © 2016年 Connect - P2P Encrypted Instant Message. All rights reserved.
//

#import "LMDrawView.h"

@implementation LMDrawView


- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(currentContext, LMBasicMiddleGray.CGColor);
    CGContextSetLineWidth(currentContext, AUTO_HEIGHT(10));
    CGContextMoveToPoint(currentContext, 0, 0);
    CGContextAddLineToPoint(currentContext, self.frame.origin.x + self.frame.size.width, 0);
    CGFloat arr[] = {AUTO_WIDTH(20), AUTO_WIDTH(6)};
    CGContextSetLineDash(currentContext, 0, arr, 2);
    CGContextDrawPath(currentContext, kCGPathStroke);
}
@end
