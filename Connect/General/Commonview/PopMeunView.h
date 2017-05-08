//
//  PopMeunView.h
//  WeixinPopMeunView
//
//  Created by MoHuilin on 16/6/13.
//  Copyright © 2016年 bitmian. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,PopMeunDirectionType) {
    PopMeunDirectionTypeUpLeft = 0,
    PopMeunDirectionTypeUpCenter,
    PopMeunDirectionTypeUpRight,
    
    
    PopMeunDirectionTypeDownLeft,
    PopMeunDirectionTypeDownCenter,
    PopMeunDirectionTypeDownRight,
    
    PopMeunDirectionTypeLeftUp,
    PopMeunDirectionTypeLeftCenter,
    PopMeunDirectionTypeLeftDown,
    
    PopMeunDirectionTypeRithtUp,
    PopMeunDirectionTypeRithtCenter,
    PopMeunDirectionTypeRithtDown,
};

@protocol PopMeunViewDelegate <NSObject>

- (void)selectIndex:(NSInteger)index;

@end

@interface PopMeunView : UIView

@property (nonatomic ,strong) UIView *backgroudView;

@property (nonatomic ,strong) NSArray *titles;

@property (nonatomic ,strong) NSArray *images;

@property (nonatomic ,assign) CGFloat rowHeight;

@property (nonatomic ,assign) CGFloat fontSize;

@property (nonatomic ,strong) UIColor *titleColor;

@property (nonatomic ,weak) id<PopMeunViewDelegate> delegate;

- (instancetype)initWithOrigin:(CGPoint)origin width:(CGFloat)width height:(CGFloat)height type:(PopMeunDirectionType)directionType color:(UIColor *)color;

- (instancetype)initWithOrigin:(CGPoint)origin width:(CGFloat)width rowHeight:(CGFloat)height type:(PopMeunDirectionType)directionType color:(UIColor *)color;

- (void)popView;

@end
