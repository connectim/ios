//
//  PassInputFieldView.h
//  Connect
//
//  Created by MoHuilin on 2016/11/10.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>

@class PassInputFieldView;

@protocol PassInputFieldViewDelegate <NSObject>

@optional
/**
 *  Monitor the change of the input
 */
- (void)passWordDidChange:(PassInputFieldView *)passWord;

/**
 *  When the listening input is complete
 */
- (void)passWordCompleteInput:(PassInputFieldView *)passWord;

/**
 *  Listen to start typing
 */
- (void)passWordBeginInput:(PassInputFieldView *)passWord;


@end

IB_DESIGNABLE

@interface PassInputFieldView : UIView <UIKeyInput>

@property(assign, nonatomic) IBInspectable NSUInteger passWordNum;
@property(assign, nonatomic) IBInspectable CGFloat squareWidth;
@property(assign, nonatomic) IBInspectable CGFloat pointRadius;
@property(strong, nonatomic) IBInspectable UIColor *pointColor;
@property(strong, nonatomic) IBInspectable UIColor *rectColor;
@property(weak, nonatomic) IBOutlet id <PassInputFieldViewDelegate> delegate;
@property(strong, nonatomic, readonly) NSMutableString *textStore;


- (void)clearAll;

@end
