//
//  GJGCCommonInputBarControlItem.h
//  Connect
//
//  Created by KivenLin on 14-10-28.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GJGCChatInputBarItem;

/**
 *  input bar item state change
 *
 *  @param item
 *  @param changeToState
 */
typedef void (^GJGCChatInputBarControlItemStateChangeEventBlock)(GJGCChatInputBarItem *item, BOOL changeToState);

/**
 *  input bar item state authorize
 *
 *  @param item
 */
typedef BOOL (^GJGCChatInputBarControlItemAuthorizedBlock)(GJGCChatInputBarItem *item);

@interface GJGCChatInputBarItem : UIView

@property(nonatomic, assign, getter=isSelected) BOOL selected;


- (instancetype)initWithSelectedIcon:(UIImage *)selectedIcon withNormalIcon:(UIImage *)normalIcon;

/**
 *  config statue change
 *
 *  @param eventBlock
 */
- (void)configStateChangeEventBlock:(GJGCChatInputBarControlItemStateChangeEventBlock)eventBlock;

/**
 *  config author
 *
 *  @param authorizeBlock
 */
- (void)configAuthorizeBlock:(GJGCChatInputBarControlItemAuthorizedBlock)authorizBlock;

@end
