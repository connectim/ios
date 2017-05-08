//
//  Adapter.h
//  FindJob
//
//  Created by huangtao on 15/10/21.
//  Copyright © 2015年 huangtao. All rights reserved.
//
/**
 *  Screen adaptive
 *
 */

#define VSIZE [[UIScreen mainScreen] bounds].size

#define DESIGN_RESOLUTION_WIDTH   750
#define DESIGN_RESOLUTION_HEIGHT  1334

float minScale();   // X, y zoom the minimum proportion
float maxScale();   // X, y scaling the maximum ratio
float xScale();     // X scaling ratio
float yScale();     // Y scale ratio

// Pass the size and x, y ratio to return the corresponding value
CGSize  percentSize(CGSize size, float x, float y);
CGPoint percentPoint(CGSize size, float x, float y);
CGRect  percentRect(CGSize size, float x, float y);

// Scale factor macro definition
#define MinScale minScale()
#define MaxScale maxScale()
#define XScale   xScale()
#define YScale   yScale()

// Proportional count
#define P_SIZE(size, x, y) percentSize(size, x, y)
#define P_POINT(size, x, y) percentPoint(size, x, y)
#define P_RECT(size, x, y) percentRect(size, x, y)

// Adaptive size
#define AUTO_WIDTH(w)          ((w) * xScale())
#define AUTO_HEIGHT(h)         ((h) * yScale())
#define AUTO_SIZE(w, h)        CGSizeMake((w) * xScale(), (h) * yScale())
#define AUTO_RECT(x, y, w, h)  CGRectMake(x * xScale(), y * yScale(), w * xScale(), h * yScale())
#define MIN_WIDTH(w)           ((w) * minScale())
#define MIN_HEIGHT(h)          ((h) * minScale())
#define MIN_SIZE(w, h)         CGSizeMake((w) * minScale(), (h) * minScale())
#define MIN_RECT(x, y, w, h)   CGRectMake(x * MinScale, y * MinScale, w * MinScale, h * MinScale)

#define FONT_SIZE(s)        ((s) * minScale())






