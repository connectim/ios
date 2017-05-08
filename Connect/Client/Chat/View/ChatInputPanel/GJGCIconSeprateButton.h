//
//  GJGCIconSeprateButton.h
//  Connect
//
//  Created by KivenLin on 14-11-26.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GJGCIconSeprateImageView.h"

@class GJGCIconSeprateButton;

typedef void (^GJGCIconSeprateButtonDidTapedBlock)(GJGCIconSeprateButton *button);

@interface GJGCIconSeprateButton : UIView

@property(nonatomic, strong) UIButton *backButton;

@property(nonatomic, strong) GJGCIconSeprateImageView *iconView;

@property(nonatomic, getter=isSelected) BOOL selected;

@property(nonatomic, copy) GJGCIconSeprateButtonDidTapedBlock tapBlock;

- (instancetype)initWithFrame:(CGRect)frame withSelectedIcon:(UIImage *)selectIcon withNormalIcon:(UIImage *)normalIcon;

@property(nonatomic, strong) UIImage *selectedStateImage;
@property(nonatomic, strong) UIImage *normalStateImage;

@end
