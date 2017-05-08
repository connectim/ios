//
//  Adapter.m
//  FindJob
//
//  Created by huangtao on 15/10/21.
//  Copyright © 2015年 huangtao. All rights reserved.
//

#import "Adapter.h"

float minScale()
{
    CGSize frameSize = [[UIScreen mainScreen] bounds].size;
    float scaleX = frameSize.width / DESIGN_RESOLUTION_WIDTH;
    float scaleY = frameSize.height / DESIGN_RESOLUTION_HEIGHT;
    return MIN(scaleX, scaleY);
}

float maxScale()
{
    CGSize frameSize = [[UIScreen mainScreen] bounds].size;
    float scaleX = frameSize.width / DESIGN_RESOLUTION_WIDTH;
    float scaleY = frameSize.height / DESIGN_RESOLUTION_HEIGHT;
    return MAX(scaleX, scaleY);
}

float xScale()
{
    CGSize frameSize = [[UIScreen mainScreen] bounds].size;
    float scaleX = frameSize.width / DESIGN_RESOLUTION_WIDTH;
    return scaleX;
}

float yScale()
{
    CGSize frameSize = [[UIScreen mainScreen] bounds].size;
    float scaleY = frameSize.height / DESIGN_RESOLUTION_HEIGHT;
    return scaleY;
}

#pragma mark -- 按比例计算
CGSize  percentSize(CGSize size, float x, float y) {
    CGSize resultSize = CGSizeMake(size.width * x, size.height * y);
    return resultSize;
}

CGPoint percentPoint(CGSize size, float x, float y) {
    CGPoint center = CGPointMake(size.width * x, size.height * y);
    return center;
}

CGRect percentRect(CGSize size, float x, float y) {
    CGRect rect = CGRectMake(0, 0, size.width * x, size.height * y);
    return rect;
}





