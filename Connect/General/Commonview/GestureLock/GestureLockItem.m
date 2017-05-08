//
//  GestureLockItem.m
//  Connect
//
//  Created by MoHuilin on 16/7/30.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "GestureLockItem.h"

#define CoreLockArcLineW 1

@interface GestureLockItem ()


// circle rect
@property (nonatomic,assign) CGRect calRect;

// select rect
@property (nonatomic,assign) CGRect selectedRect;


@end

@implementation GestureLockItem

-(instancetype)initWithFrame:(CGRect)frame{
    
    self = [super initWithFrame:frame];
    
    if(self){
        
        self.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}


-(void)drawRect:(CGRect)rect{
    
    // get context
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    // set attribute
    [self propertySetting:ctx];
    
    // Outer ring
    [self circleNormal:ctx rect:rect];
    
    // When selected, draw the background color
    if(self.isSelected){
        
        //  outer 
        [self circleSelected:ctx rect:rect];
        
    }
    
    
}






/*
 *  上下文属性设置
 */
-(void)propertySetting:(CGContextRef)ctx{
    
    //设置线宽
    CGContextSetLineWidth(ctx, CoreLockArcLineW);
    
    //设置颜色
    UIColor *color = nil;
    if(self.isSelected){
        
        color = GestureColor;
    }else{
        color = GestureColor;
    }
    [color set];
}



/*
 *  外环：普通
 */
-(void)circleNormal:(CGContextRef)ctx rect:(CGRect)rect{
    
    //新建路径：外环
    CGMutablePathRef loopPath = CGPathCreateMutable();
    
    //添加一个圆环路径
    CGRect calRect = self.calRect;
    CGPathAddEllipseInRect(loopPath, NULL, calRect);
    
    //将路径添加到上下文中
    CGContextAddPath(ctx, loopPath);
    
    //绘制圆环
    CGContextStrokePath(ctx);
    
    //释放路径
    CGPathRelease(loopPath);
}


/*
 *  外环：选中
 */
-(void)circleSelected:(CGContextRef)ctx rect:(CGRect)rect{
    
    //新建路径：外环
    CGMutablePathRef circlePath = CGPathCreateMutable();
    
    //绘制一个圆形
    CGPathAddEllipseInRect(circlePath, NULL, self.selectedRect);
    
    [GestureColor set];
    
    //将路径添加到上下文中
    CGContextAddPath(ctx, circlePath);
    
    //绘制圆环
    CGContextFillPath(ctx);
    
    //释放路径
    CGPathRelease(circlePath);
}




- (void)setSelected:(BOOL)selected{
    [super setSelected:selected];
    [self setNeedsDisplay];
}


-(CGRect)calRect{
    
    if(CGRectEqualToRect(_calRect, CGRectZero)){
        
        CGFloat lineW =CoreLockArcLineW;
        
        CGFloat sizeWH = self.bounds.size.width - lineW;
        CGFloat originXY = lineW *.5f;
        
        //添加一个圆环路径
        _calRect = (CGRect){CGPointMake(originXY, originXY),CGSizeMake(sizeWH, sizeWH)};
        
    }
    
    return _calRect;
}



-(CGRect)selectedRect{
    
    if(CGRectEqualToRect(_selectedRect, CGRectZero)){
        
        CGRect rect = self.bounds;
        
        CGFloat selectRectWH = rect.size.width * 0.5;
        
        CGFloat selectRectXY = rect.size.width * (1 - 0.5) *.5f;
        
        _selectedRect = CGRectMake(selectRectXY, selectRectXY, selectRectWH, selectRectWH);
    }
    
    return _selectedRect;
}


@end
