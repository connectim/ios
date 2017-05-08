//
//  BaseViewController.h
//  Connect
//
//  Created by MoHuilin on 16/5/9.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UINavigationBar+Awesome.h"
#import "ConnectTool.h"


@interface BaseViewController : UIViewController {
}

/*
 *  add right close button
 */
- (void)addCloseBarItem;

/*
 *  add left close button
 */
- (void)addNewCloseBarItem;

- (void)removeDelegate;

- (void)setNavigationItemWithSystemItem:(UIBarButtonSystemItem)systemItem sel:(SEL)sel isRight:(BOOL)isRight;

- (void)setNavigationRight:(NSString *)imageName;

- (void)removeNavigationRight;

- (void)setNavigationRightWithTitle:(NSString *)title;

- (void)setNavigationTitle:(NSString *)title;

- (void)setNavigationTitleImage:(NSString *)imageName;

- (void)setNavigationLeftWithTitle:(NSString *)title;

- (void)setNavigationLeft:(NSString *)imageName;

/**
 *  nav black back arrow
 */
- (void)setBlackfBackArrowItem;
/**
 * nav white back arrow
 */
- (void)setWhitefBackArrowItem;

- (void)setNavigationRight:(NSString *)title titleColor:(UIColor *)color;

- (IBAction)doLeft:(id)sender;

- (IBAction)doRight:(id)sender;

- (void)closeBtnClicked:(UIButton *)btn;

- (void)setup;
- (void)setDatas;

@property(nonatomic, strong) UIButton *rightButton;
@property(nonatomic, strong) UIBarButtonItem *rightBarBtn;
@property(nonatomic, strong) UIButton *rightTitleButton;

@end
