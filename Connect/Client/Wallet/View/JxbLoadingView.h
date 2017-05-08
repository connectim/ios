//
//  JxbLoadingView.h
//  TP
//
//  Created by Peter on 15/11/27.
//  Copyright © 2015年 VizLab. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface JxbLoadingView : UIView

/**
 *   callback block
 */
typedef void (^JxbLoadingCompleteBlock)();

/**
 *   Line width
 */
@property(nonatomic, assign) CGFloat lineWidth;

/**
 *   Line color
 */
@property(nonatomic, copy) UIColor *strokeColor;

/**
 *   start
 */
- (void)startLoading;

/**
 *   end, view will be removed
 */
- (void)endLoading;

/**
 *   stop animation with a success
 *
 *  @param block
 */
- (void)finishSuccess:(JxbLoadingCompleteBlock)block;

/**
 *    stop animation with a failure
 *
 *  @param block
 */
- (void)finishFailure:(JxbLoadingCompleteBlock)block;
@end
