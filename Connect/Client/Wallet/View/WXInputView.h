//
//  InputView.h
//  WXPayView
//
//  Created by apple on 16/1/6.
//  Copyright © 2016年 apple. All rights reserved.
//  密码输入框视图

#import <UIKit/UIKit.h>


@interface WXInputView : UIView

+ (instancetype)inputView;

@property(nonatomic, assign) NSInteger places;

// success call block
@property(nonatomic, copy) void (^WXInputViewDidCompletion)(NSString *text);

- (void)beginInput;

- (void)endInput;

- (void)clearPassword;

@end
