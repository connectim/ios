//
//  GestureThumbView.m
//  Connect
//
//  Created by MoHuilin on 16/8/11.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "GestureThumbView.h"

#define GestureColor [UIColor colorWithRed:0.200 green:0.576 blue:0.965 alpha:1.000]

@interface GestureThumbItem : UIView

@property(nonatomic, assign) BOOL isSelected;


// circle
@property(nonatomic, assign) CGRect calRect;

// select rect
@property(nonatomic, assign) CGRect selectedRect;


@end

@implementation GestureThumbItem

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }

    return self;
}

- (void)setup {
    self.backgroundColor = [UIColor clearColor];
}

- (void)drawRect:(CGRect)rect {

    // get context
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    // set width
    CGContextSetLineWidth(ctx, 1);

    // set color
    UIColor *color = nil;
    if (self.isSelected) {
        color = GestureColor;
    } else {
        color = GJCFQuickHexColor(@"B3B5BD");
    }
    [color set];

    // New path: outer ring
    CGMutablePathRef loopPath = CGPathCreateMutable();

    // Add a ring path
    CGRect calRect = self.calRect;
    CGPathAddEllipseInRect(loopPath, NULL, calRect);

    // Add the path to the context
    CGContextAddPath(ctx, loopPath);

    // Draw a circle
    CGContextStrokePath(ctx);

    // Release the path
    CGPathRelease(loopPath);

    // When selected, draw the background color
    if (self.isSelected) {

        CGMutablePathRef circlePath = CGPathCreateMutable();
        CGPathAddEllipseInRect(circlePath, NULL, self.selectedRect);
        [GestureColor set];
        CGContextAddPath(ctx, circlePath);
        CGContextFillPath(ctx);
        CGPathRelease(circlePath);

    }


}


- (CGRect)calRect {

    if (CGRectEqualToRect(_calRect, CGRectZero)) {

        CGFloat lineW = 1;

        CGFloat sizeWH = self.bounds.size.width - lineW;
        CGFloat originXY = lineW * .5f;

        // Add a ring path
        _calRect = (CGRect) {CGPointMake(originXY, originXY), CGSizeMake(sizeWH, sizeWH)};

    }

    return _calRect;
}

- (CGRect)selectedRect {

    if (CGRectEqualToRect(_selectedRect, CGRectZero)) {

        CGRect rect = self.bounds;

        CGFloat selectRectWH = rect.size.width;

        CGFloat selectRectXY = 0;

        _selectedRect = CGRectMake(selectRectXY, selectRectXY, selectRectWH, selectRectWH);
    }

    return _selectedRect;
}

- (void)setIsSelected:(BOOL)isSelected {
    _isSelected = isSelected;
    [self setNeedsDisplay];
}

@end


@implementation GestureThumbView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }

    return self;
}

- (void)setup {

    CGFloat margin = 3.5;

    CGFloat x = 0;
    CGFloat y = 0;
    CGFloat w = (self.width - margin * 2) / 3;
    CGFloat h = w;

    for (int i = 0; i < 9; i++) {
        y = (h + margin) * (i / 3);
        x = (w + margin) * (i % 3);
        GestureThumbItem *view = [[GestureThumbItem alloc] initWithFrame:CGRectMake(x, y, w, h)];
        view.tag = i;
        [self addSubview:view];
    }

}

- (void)setPassword:(NSString *)password {
    if (password.length < 4) {
        return;
    }
    _password = password;

    for (int i = 0; i < password.length; i++) {
        int tag = [[password substringWithRange:NSMakeRange(i, 1)] intValue];
        for (GestureThumbItem *view in self.subviews)
            if (view.tag == tag) {
                view.isSelected = YES;
            }
    }
}

- (void)reset {
    for (GestureThumbItem *view in self.subviews) {
        view.isSelected = NO;
    }
}

@end
