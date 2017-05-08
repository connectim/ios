//
//  LMTopView.h
//  Connect
//
//  Created by Edwin on 16/7/13.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>

@class LMTopView;

@protocol LMTopViewDelegate <NSObject>

/**
 *  Wallet button click method
 *
 *  @param view view
 *  @param btn  button
 */
- (void)LMTopView:(LMTopView *)view WalletBtnClick:(UIButton *)btn;

/**
 *  Payment button click method
 *
 *  @param view view
 *  @param btn  button
 */
- (void)LMTopView:(LMTopView *)view PayBtnClick:(UIButton *)btn;

/**
 *  The click button of the payment button
 *
 *  @param view view
 *  @param btn  button
 */
- (void)LMTopView:(LMTopView *)view CollectBtnClick:(UIButton *)btn;
@end

@interface LMTopView : UIView

/**
 *  Balance content
 */
@property(nonatomic, strong) UILabel *BanContentLabel;

@property(nonatomic, strong) id <LMTopViewDelegate> delegate;
/**
 *  Balance
 */
@property(nonatomic, strong) UILabel *BalanceLabel;
@end
