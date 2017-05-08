//
//  GJGCInputTextView.h
//  Connect
//
//  Created by KivenLin on 14-10-28.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GJGCChatInputConst.h"

@class GJGCChatInputTextView;

typedef void (^GJGCChatInputTextViewFrameDidChangeBlock)(GJGCChatInputTextView *textView, CGFloat changeDetal);

typedef void (^GJGCChatInputTextViewRecordActionChangeBlock)(GJGCChatInputTextViewRecordActionType actionType);

typedef void (^GJGCChatInputTextViewFinishInputTextBlock)(GJGCChatInputTextView *textView, NSString *text);

typedef void (^GJGCChatInputTextViewDidBecomeFirstResponseBlock)(GJGCChatInputTextView *textView);


@interface GJGCChatInputTextView : UIView
@property(nonatomic, strong) NSString *preRecordTitle;
@property(nonatomic, strong) NSString *recordingTitle;
@property(nonatomic, strong) UIImage *inputTextBackgroundImage;
@property(nonatomic, strong) UIImage *recordAudioBackgroundImage;
@property(nonatomic, assign, getter=isRecordState) BOOL recordState;
@property(nonatomic, strong) NSString *content;
@property(nonatomic, assign) CGFloat maxAutoExpandHeight;
@property(nonatomic, assign) CGFloat minAutoExpandHeight;
@property(nonatomic, strong) NSMutableArray *emojiInfoArray;
@property(nonatomic, strong) NSString *panelIdentifier;
@property(nonatomic, readonly) CGFloat inputTextStateHeight;
@property(nonatomic, strong) NSString *placeHolder;

- (BOOL)isValidateContent;

- (void)resignFirstResponder;

- (void)updateDisplayByInputContentTextChange;

- (void)layoutInputTextView;

- (BOOL)isInputTextFirstResponse;

- (void)becomeFirstResponder;

/**
 *  config frame change
 *
 *  @param changeBlock 
 */
- (void)configFrameChangeBlock:(GJGCChatInputTextViewFrameDidChangeBlock)changeBlock;

/**
 *  config Finish Input Text
 *
 *  @param finishBlock 
 */
- (void)configFinishInputTextBlock:(GJGCChatInputTextViewFinishInputTextBlock)finishBlock;

/**
 * config TextViewDidBecome FirstResponse
 * @param firstResponseBlock
 */
- (void)configTextViewDidBecomeFirstResponse:(GJGCChatInputTextViewDidBecomeFirstResponseBlock)firstResponseBlock;

- (void)clearInputText;

@end
