//
//  UIButton+GJAssetsPickerStyle.m
//  GJAssetsPickerViewController
//
//  Created by ZYVincent on 14-9-10.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import "UIButton+GJCFAssetsPickerStyle.h"

@implementation UIButton (GJCFAssetsPickerStyle)

- (void)setCommonStyleDescription:(GJCFAssetsPickerCommonStyleDescription *)aDescription
{
    //Need to be hidden
    if (aDescription.hidden) {
        self.hidden = aDescription.hidden;
        return;
    }
    
    UIImage *cancelBtnNormal = aDescription.normalStateImage;
    CGPoint originPoint = aDescription.originPoint;
    if (cancelBtnNormal) {
        self.frame = (CGRect){originPoint.x,originPoint.y,cancelBtnNormal.size.width,cancelBtnNormal.size.height};
    }else{
        if (CGSizeEqualToSize(aDescription.frameSize, CGSizeZero)) {
            
            self.frame = CGRectMake(originPoint.x, originPoint.y, 40, 20);
            
        }else{
            
            self.frame = (CGRect){originPoint.x,originPoint.y,aDescription.frameSize.width,aDescription.frameSize.height};
            
        }
    }
    
    // Status picture
    [self setBackgroundImage:cancelBtnNormal forState:UIControlStateNormal];
    [self setBackgroundImage:aDescription.selectedStateImage forState:UIControlStateSelected];
    [self setBackgroundImage:aDescription.highlightStateImage forState:UIControlStateHighlighted];
    
    //title
    if (aDescription.normalStateTitle) {
        [self setTitle:aDescription.normalStateTitle forState:UIControlStateNormal];
    }else{
        if (aDescription.title) {
            [self setTitle:aDescription.title forState:UIControlStateNormal];
        }
    }
    
    //title color exchange
    [self setTitle:aDescription.selectedStateTitle forState:UIControlStateSelected];
    [self setTitleColor:aDescription.normalStateTextColor forState:UIControlStateNormal];
    [self setTitleColor:aDescription.highlightStateTextColor forState:UIControlStateHighlighted];
    [self setTitleColor:aDescription.selectedStateTextColor forState:UIControlStateSelected];
     self.titleLabel.font = aDescription.font;
}

@end
