//
//  GJAssetsPickerOverlayView.m
//  GJAssetsPickerViewController
//
//  Created by ZYVincent on 14-9-8.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import "GJCFAssetsPickerOverlayView.h"
#import "GJCFAssetsPickerStyle.h"

@implementation GJCFAssetsPickerOverlayView

#pragma mark - 谨慎覆盖这两个方法

+ (GJCFAssetsPickerOverlayView*)defaultOverlayView
{
    GJCFAssetsPickerOverlayView *defaultView = [[GJCFAssetsPickerOverlayView alloc]init];
    defaultView.selected = NO;
    defaultView.enableChooseToSeeBigImageAction = YES;
    
    return defaultView;
}

- (void)setSelected:(BOOL)selected
{
    if (_selected == selected) {
        return;
    }
    _selected = selected;
    
    if (_selected) {
        [self switchSelectState];
    }else{
        [self switchNormalState];
    }
    
    [self setNeedsLayout];
}

#pragma mark - Customize the method that needs to be overridden

- (id)init
{
    if (self = [super init]) {
        
        self.selectIconImgView = [[UIImageView alloc]init];
        [self addSubview:self.selectIconImgView];
        
        self.selected = NO;
        self.enableChooseToSeeBigImageAction = YES;
    
        UITapGestureRecognizer *tapR = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(didTapOnSelf:)];
        [self addGestureRecognizer:tapR];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.selectIconImgView = [[UIImageView alloc]init];
        [self addSubview:self.selectIconImgView];
        
        self.selected = NO;
        self.enableChooseToSeeBigImageAction = YES;

        UITapGestureRecognizer *tapR = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(didTapOnSelf:)];
        [self addGestureRecognizer:tapR];
        
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGSize iconSize = self.selectIconImgView.image.size;
    
    if (CGSizeEqualToSize(CGSizeZero, iconSize)) {
        return;
    }
    
    CGRect bounds = self.bounds;
    
    CGFloat xOrigin = bounds.size.width - 5 -iconSize.width;
    CGFloat yOrigin = 5;
    
    self.selectIconImgView.frame = (CGRect){xOrigin,yOrigin,iconSize.width,iconSize.height};
    

    if (self.enableChooseToSeeBigImageAction) {
        
        self.frameToShowSelectedWhileBigImageActionEnabled = CGRectMake(self.selectIconImgView.frame.origin.x - 15, self.selectIconImgView.frame.origin.y - 5, self.selectIconImgView.frame.size.width + 20, self.selectIconImgView.frame.size.height + 20);
    }
    
}

- (void)switchNormalState
{
    self.selectIconImgView.image = [GJCFAssetsPickerStyle bundleImage:@"GjAssetsPicker_image_unselect.png"];
}

- (void)switchSelectState
{
    self.selectIconImgView.image = [GJCFAssetsPickerStyle bundleImage:@"GjAssetsPicker_image_selected.png"];
}

- (void)setEnableChooseToSeeBigImageAction:(BOOL)enableChooseToSeeBigImageAction
{
    if (_enableChooseToSeeBigImageAction == enableChooseToSeeBigImageAction) {
        return;
    }
    
    _enableChooseToSeeBigImageAction = enableChooseToSeeBigImageAction;
    
    __block BOOL hasSetTapGesture = NO;
    [self.gestureRecognizers enumerateObjectsUsingBlock:^(UIGestureRecognizer *obj, NSUInteger idx, BOOL *stop) {
        
        if ([obj isKindOfClass:[UITapGestureRecognizer class]]) {
            
            hasSetTapGesture = YES;
            
            if (!_enableChooseToSeeBigImageAction) {
                obj.enabled = NO;
                [obj removeTarget:self action:@selector(didTapOnSelf:)];
            }
        }
        
    }];
    

    if (!hasSetTapGesture && _enableChooseToSeeBigImageAction) {
        

        UITapGestureRecognizer *tapR = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(didTapOnSelf:)];
        [self addGestureRecognizer:tapR];
        
    }
    
}


#pragma mark - NSCoding

#pragma mark - tapGesture

/* The big picture mode itself will enable click interaction, otherwise it is the parent view GJAssetsView direct judgment click event */
- (void)didTapOnSelf:(UITapGestureRecognizer *)tapR
{
    // If you do not support the view big picture mode, then directly change the state on it
    if (!self.enableChooseToSeeBigImageAction) {
        
        // Is currently unselected
        if (self.selected == NO) {
            
            BOOL canChangeToSelected = YES;
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(pickerOverlayViewCanChangeToSelectedState:)]) {
                
                canChangeToSelected = [self.delegate pickerOverlayViewCanChangeToSelectedState:self];
            }
            
            if (!canChangeToSelected) {
                return;
            }
        }
        
        self.selected = !self.selected;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(pickerOverlayView:responseToChangeSelectedState:)]) {
            [self.delegate pickerOverlayView:self responseToChangeSelectedState:self.selected];
        }
        
        return;
    }
    
    // If the support view large map mode
    if (self.enableChooseToSeeBigImageAction) {
        
        CGPoint tapPoint = [tapR locationInView:self];
        
        // If the click is in the range of the changed state of the frame, then the response state changes the proxy event
        if (CGRectContainsPoint(self.frameToShowSelectedWhileBigImageActionEnabled, tapPoint)) {
            
            // Is currently unselected
            if (self.selected == NO) {
                
                BOOL canChangeToSelected = YES;
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(pickerOverlayViewCanChangeToSelectedState:)]) {
                    
                    canChangeToSelected = [self.delegate pickerOverlayViewCanChangeToSelectedState:self];
                }
                
                if (!canChangeToSelected) {
                    return;
                }
            }
            
            self.selected = !self.selected;
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(pickerOverlayView:responseToChangeSelectedState:)]) {
                
                [self.delegate pickerOverlayView:self responseToChangeSelectedState:self.selected];
                
            }
            
        }else{
            
            // Need to enter the big picture view mode
            if (self.delegate && [self.delegate respondsToSelector:@selector(pickerOverlayViewResponseToShowBigImage:)]) {
                
                [self.delegate pickerOverlayViewResponseToShowBigImage:self];
            }
        }
        
    }
}

@end
