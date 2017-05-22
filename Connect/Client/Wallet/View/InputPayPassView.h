//
//  InputPayPassView.h
//  Connect
//
//  Created by MoHuilin on 2016/11/9.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, InputPayPassViewStyle) {
    InputPayPassViewSetPass = 0,
    InputPayPassViewVerfyPass,
};
typedef NS_ENUM(NSInteger, PassWordTag) {
    PassWordSet               = 1,
    PassWordSetVerification   = 2,
    PassWordVerification      = 3

};


@interface InputPayPassView : UIView

@property(nonatomic, assign) InputPayPassViewStyle style;

@property(nonatomic, copy) void (^requestCallBack)(NSError *error);

+ (InputPayPassView *)showInputPayPassViewWithStyle:(InputPayPassViewStyle)style complete:(void (^)(InputPayPassView *passView, NSError *error, BOOL result))complete;

+ (InputPayPassView *)showInputPayPassWithComplete:(void (^)(InputPayPassView *passView, NSError *error, BOOL result))complete;

+ (InputPayPassView *)showInputPayPassWithComplete:(void (^)(InputPayPassView *passView, NSError *error, BOOL result))complete forgetPassBlock:(void (^)())forgetPassBlock closeBlock:(void (^)())closeBlock;

- (IBAction)closeView:(id)sender;

@end
