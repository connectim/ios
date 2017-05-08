//
//  KQXPasswordInputController.h
//  KQXPasswordInput
//
//  Created by Qingxu Kuang on 16/8/23.
//  Copyright © 2016年 Asahi Kuang. All rights reserved.
//

#import <UIKit/UIKit.h>


@class KQXPasswordInputController;

@protocol KQXPasswordInputControllerDelegate <NSObject>

@optional
- (void)passwordInputControllerDidDismissed;

- (void)passwordInputControllerDidClosed;

@end

typedef NS_ENUM(NSInteger, KQXPasswordInputStyle) {
    KQXPasswordInputStyleWithoutMoney = 0,
    KQXPasswordInputStyleWithMoney = 1
};

typedef void (^passwordInputComplete)(NSString *psw);

@interface KQXPasswordInputController : UIViewController

@property(nonatomic, weak) id <KQXPasswordInputControllerDelegate> delegate;

@property(nonatomic, copy) passwordInputComplete fillCompleteBlock;

/**
 *  @brief Password input box construction method.。
 *  @param style Password input box style (0. do not need to show the money 1. need to show the money)
 */
- (instancetype)initWithPasswordInputStyle:(KQXPasswordInputStyle)style;

/**
 *  @brief Password input box constructor class method.
 *  @param style Password input box style (0. do not need to show the money 1. need to show the money)）
 */
+ (instancetype)passwordInputViewWithStyle:(KQXPasswordInputStyle)style;

/** 
 *  @brief Set the title, subtitle, money strin。
 *  @param title title
 *
 */
- (void)setTitleString:(NSString *)title descriptionString:(NSString *)description moneyString:(NSString *)money;

/** @brief Error prompt view.。
 *  @param tip tips
 */
- (void)showErrorTipWithString:(NSString *)tip;

/**
 *  @brief Introduce the password input controller。
 *  @param isClosed Is not click off。
 **/
- (void)dismissWithClosed:(BOOL)isClosed;
@end
