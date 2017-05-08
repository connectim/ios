//
//  KQXPasswordInputTipView.h
//  Connect
//
//  Created by Qingxu Kuang on 16/8/22.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>

//=============== tip view ======================//
typedef enum KQXPasswordInputTipViewStyle : NSInteger {
    KQXPasswordInputTipViewStyleRight = 0,
    KQXPasswordInputTipViewStyleError
} tipViewStyle;

@interface KQXPasswordInputTipView : UIView
/** @brief Singleton gets password input for the top view.。
 *  @param frame size
 */
+ (instancetype)sharedTipViewWithFrame:(CGRect)frame;

/**
 *  @brief Show the top view。
 */
- (void)showTipViewWithStyle:(tipViewStyle)style tip:(NSString *)tipString;
@end


