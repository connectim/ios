//
//  ChatInputMicButton.h
//  Connect
//
//  Created by MoHuilin on 16/6/14.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GJGCChatInputConst.h"

@class ChatInputMicButton;

typedef void (^GJGCChatInputTextViewRecordActionChangeBlock)(GJGCChatInputTextViewRecordActionType actionType);

typedef void (^ChatInputMicButtonStateChangeEventBlock)(ChatInputMicButton *item, BOOL changeToState);

@protocol ChatInputMicButtonDelegate <NSObject>

@optional

- (CGRect)micButtonFrame;

- (void)micButtonInteractionBegan;

- (void)micButtonInteractionCancelled:(CGFloat)velocity;

- (void)micButtonInteractionCompleted:(CGFloat)velocity;

- (void)micButtonInteractionUpdate:(CGFloat)value;

@end

@interface ChatInputMicButton : UIButton

@property(nonatomic, weak) id <ChatInputMicButtonDelegate> delegate;

@property(nonatomic, strong) UIImageView *iconView;

/**
 *  observe record action change
 *
 *  @param actionBlock
 */
- (void)configRecordActionChangeBlock:(GJGCChatInputTextViewRecordActionChangeBlock)actionBlock;

- (void)configStateChangeEventBlock:(ChatInputMicButtonStateChangeEventBlock)eventBlock;

@property(nonatomic, copy) NSString *panelIdentifier;

- (void)animateIn;

- (void)animateOut;

- (void)addMicLevel:(CGFloat)level;

@end
