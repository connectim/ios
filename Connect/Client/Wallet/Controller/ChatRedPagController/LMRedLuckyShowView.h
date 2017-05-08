//
//  LMRedLuckyShowView.h
//  Connect
//
//  Created by Qingxu Kuang on 16/7/30.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>

@class LMRedLuckyShowView;

@protocol LMRedLuckyShowViewDelegate <NSObject>

@required
/** @brief The red envelope opens the gesture response agent
 *  @param showView: Red envelope animation view。
 *  @param tapGesture: Click gestures。
 */
- (void)redLuckyShowView:(LMRedLuckyShowView *)showView goRedLuckyDetailWithSender:(UIButton *)sender;

@end

@interface LMRedLuckyShowView : UIView
@property(nonatomic, weak) id <LMRedLuckyShowViewDelegate> delegate;
@property(nonatomic, copy) NSString *hashId;


/** @brief Constructs a red envelope animation pop-up view。
 *  @param frame: View size。
 *  @param images: An array of pictures with UIImage objects。
 */
- (instancetype)initWithFrame:(CGRect)frame redLuckyGifImages:(NSArray<UIImage *> *)images;

/**
 *  @brief Pop-up animated view of red envelopes。
 *  @param getARedLucky Whether to grab a red envelope。
 */
- (void)showRedLuckyViewIsGetARedLucky:(BOOL)getARedLucky;

/**
 *  @brief Hide red envelopes view。
 */
- (void)dismissRedLuckyView;

/**
 *  @brief Remove images and reduce memory usage。
 */
- (void)deallocImagesForFree;

@end
