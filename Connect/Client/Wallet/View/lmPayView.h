//
//  WXPayView.h
//  WXPayView
//
//  Created by apple on 16/1/6.
//  Copyright © 2016年 apple. All rights reserved.
//  微信红包支付界面模拟

#import <UIKit/UIKit.h>
#import "WXInputView.h"

typedef void(^WXPayViewCompletion)(NSString *password);

typedef void(^passwordInputEnded)(NSString *password);

@interface lmPayView : UIView

// Password input frame number (default 6 digits)
@property(nonatomic, assign) NSInteger places;

@property(nonatomic, copy) void (^exitBtnClicked)();
@property(nonatomic, copy) void (^switchCardBtnClicked)();
@property(nonatomic, copy) passwordInputEnded endBlock;
@property(weak, nonatomic) IBOutlet WXInputView *inputView;


- (instancetype)initWithMoney:(CGFloat)money title:(NSString *)title transferName:(NSString *)name completion:(WXPayViewCompletion)completion;

- (void)showView;

- (void)hiddenView;

- (void)reloadTitle:(NSString *)title;

@end
