//
//  CollectionReusableView.h
//  Connect
//
//  Created by Edwin on 16/7/14.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMTopView.h"

@class CollectionReusableView;

@protocol CollectionReusableViewDelegate <NSObject>

/**
 *  Wallet button click method
 *
 *  @param view view
 *  @param btn  button
 */
- (void)CollectionReusableView:(CollectionReusableView *)view WalletBtnClick:(UIButton *)btn;

/**
 *  Payment button click method
 *
 *  @param view view
 *  @param btn  button
 */
- (void)CollectionReusableView:(CollectionReusableView *)view PayBtnClick:(UIButton *)btn;

/**
 *  The click button of the payment button
 *
 *  @param view view
 *  @param btn  button
 */
- (void)CollectionReusableView:(CollectionReusableView *)view CollectBtnClick:(UIButton *)btn;

@end

@interface CollectionReusableView : UICollectionReusableView

@property(nonatomic, strong) LMTopView *topView;
@property(nonatomic, strong) id <CollectionReusableViewDelegate> delegate;
@end
