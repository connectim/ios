//
//  LMCustomBtn.m
//  Connect
//
//  Created by Edwin on 16/7/13.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMCustomBtn.h"

@implementation LMCustomBtn

-(CGRect)titleRectForContentRect:(CGRect)contentRect{
    
    CGRect titleRect = CGRectMake(0, CGRectGetHeight(contentRect)*(1-_ratio), CGRectGetWidth(contentRect), CGRectGetHeight(contentRect)*_ratio);
    return titleRect;
}
-(CGRect)imageRectForContentRect:(CGRect)contentRect{
    CGRect imageRect = CGRectMake(0, 0, CGRectGetWidth(contentRect), CGRectGetHeight(contentRect)*(1-_ratio));
    return imageRect;
}

@end
