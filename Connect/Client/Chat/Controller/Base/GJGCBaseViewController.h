//
//  UIViewController.h
//  Connect
//
//  Created by KivenLin on 15/7/11.
//  Copyright (c) 2015年 Connect. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GJGCBaseViewController : UIViewController

@property(nonatomic, strong) UIBarButtonItem *rightBarBtn;
@property(strong, nonatomic) UIButton *whiteButton;

- (void)rightButtonPressed:(UIButton *)sender;
- (void)setStrNavTitle:(NSString *)title;
- (void)setRightButtonWithTitle:(NSString *)title;
- (void)setRightButtonWithStateImage:(NSString *)iconName stateHighlightedImage:(NSString *)highlightIconName stateDisabledImage:(NSString *)disableIconName titleName:(NSString *)title;

@end
