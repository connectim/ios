//
//  GJGCCommonInputBar.m
//  Connect
//
//  Created by KivenLin on 14-10-28.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJGCChatInputBar.h"

@interface GJGCChatInputBar () <ChatInputMicButtonDelegate>

@property(nonatomic, strong) GJGCChatInputBarItem *emojiBarItem;

@property(nonatomic, strong) GJGCChatInputBarItem *openPanelBarItem;

@property(nonatomic, strong) ChatInputMicButton *micButton;

@property(nonatomic, strong) GJGCChatInputTextView *inputTextView;

@property(nonatomic, copy) GJGCChatInputBarDidChangeActionBlock changeActionBlock;

@property(nonatomic, copy) GJGCChatInputBarDidChangeFrameBlock changeFrameBlock;

@property(nonatomic, copy) GJGCChatInputBarDidTapOnSendTextBlock textSendBlock;

@property(nonatomic, assign) CGFloat itemMargin;

@property(nonatomic, assign) CGFloat itemToBarMargin;

@property(nonatomic, strong) UIView *bottomLine;

@property(nonatomic, assign) CGFloat inputViewH;

@end

@implementation GJGCChatInputBar

#pragma mark - 生命周期

- (instancetype)init {
    if (self = [super init]) {

        [self initSubViews];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {

        [self initSubViews];
    }
    return self;
}

- (void)dealloc {
    [GJCFNotificationCenter removeObserver:self];
}

#pragma mark - 内部接口

- (void)initSubViews {
    self.backgroundColor = GJCFQuickHexColor(@"EFF0F2");
    self.barHeight = AUTO_HEIGHT(100);
    self.inputTextStateBarHeight = self.barHeight;

    /* 首尾分割线  */
    UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, GJCFSystemScreenWidth, 0.5)];
    [topLine setBackgroundColor:GJCFQuickHexColor(@"d9d9d9")];
    [self addSubview:topLine];

    self.bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, self.barHeight - 0.5, GJCFSystemScreenWidth, 0.5)];
    [self.bottomLine setBackgroundColor:GJCFQuickHexColor(@"d9d9d9")];
    [self addSubview:self.bottomLine];

    GJCFWeakSelf weakSelf = self;
    UIImage *keybordIcon = GJCFQuickImage(@"chatbar_keyboard");
    /* 默认参数 */
    self.itemMargin = AUTO_WIDTH(15);
    self.itemToBarMargin = AUTO_WIDTH(15);
    CGFloat buttonWH = AUTO_WIDTH(65);
    CGFloat marginToBottom = (self.barHeight - buttonWH) / 2;
    /* 展开面板按钮 */
    UIImage *extendIcon = GJCFQuickImage(@"chat_chatbar_plus");
    self.openPanelBarItem = [[GJGCChatInputBarItem alloc] initWithSelectedIcon:keybordIcon withNormalIcon:extendIcon];
    [self addSubview:self.openPanelBarItem];
    self.openPanelBarItem.frame = CGRectMake(self.itemToBarMargin, 0, buttonWH, buttonWH);
    self.openPanelBarItem.bottom = self.bottom - marginToBottom;
    [self.openPanelBarItem configStateChangeEventBlock:^(GJGCChatInputBarItem *item, BOOL changeToState) {
        [weakSelf barItem:item changeToState:changeToState];
    }];

    /* 输入文本 */
    CGFloat scale = 1.1;
    CGFloat inputViewH = AUTO_HEIGHT(70);
    self.inputViewH = inputViewH;
    self.inputTextView = [[GJGCChatInputTextView alloc] initWithFrame:CGRectMake(self.itemMargin + self.itemToBarMargin + buttonWH, 0, GJCFSystemScreenWidth - buttonWH * 2 - buttonWH * scale - 2 * self.itemToBarMargin - self.itemMargin * 3, inputViewH)];
    [self addSubview:self.inputTextView];
    [self.inputTextView setInputTextBackgroundImage:GJCFQuickImage(@"inputbar_bg_white")];
    self.inputTextView.gjcf_centerY = self.barHeight / 2;
    [self.inputTextView configFinishInputTextBlock:^(GJGCChatInputTextView *textView, NSString *text) {
        if (weakSelf.textSendBlock) {
            weakSelf.textSendBlock(weakSelf, text);
        }
    }];
    [self.inputTextView configTextViewDidBecomeFirstResponse:^(GJGCChatInputTextView *textView) {
        weakSelf.inputTextView.recordState = NO;
        weakSelf.emojiBarItem.selected = NO;
        weakSelf.openPanelBarItem.selected = NO;
    }];

    [self.inputTextView configFrameChangeBlock:^(GJGCChatInputTextView *textView, CGFloat changeDetal) {
        if (weakSelf.changeFrameBlock) {
            weakSelf.height += changeDetal;
            //不能消息最小的高度
            if (weakSelf.height < weakSelf.barHeight) {
                weakSelf.height = weakSelf.barHeight;
            }
            weakSelf.inputTextStateBarHeight = weakSelf.height;
            weakSelf.micButton.bottom = weakSelf.bottom - marginToBottom;
            weakSelf.changeFrameBlock(weakSelf, changeDetal);
        }
    }];

    /* 表情按钮 */
    UIImage *emojiIcon = GJCFQuickImage(@"chat_chatbar_emoji");
    self.emojiBarItem = [[GJGCChatInputBarItem alloc] initWithSelectedIcon:keybordIcon withNormalIcon:emojiIcon];
    [self addSubview:self.emojiBarItem];
    self.emojiBarItem.frame = CGRectMake(GJCFSystemScreenWidth - self.itemToBarMargin - 2 * buttonWH - self.itemMargin, self.openPanelBarItem.bottom, buttonWH, buttonWH);

    [self.emojiBarItem configStateChangeEventBlock:^(GJGCChatInputBarItem *item, BOOL changeToState) {
        [weakSelf barItem:item changeToState:changeToState];
    }];


    /* 录音按钮 */
    self.micButton = [[ChatInputMicButton alloc] init];
    self.micButton.delegate = self;
    [self.micButton setBackgroundImage:GJCFQuickImage(@"chat_chatbar_audio") forState:UIControlStateNormal];
    UIImageView *micButtonIconView = [[UIImageView alloc] initWithImage:GJCFQuickImage(@"chat_chatbar_audio")];
    self.micButton.iconView = micButtonIconView;
    [self addSubview:_micButton];
    self.micButton.frame = CGRectMake(GJCFSystemScreenWidth - self.itemToBarMargin - buttonWH, 0, buttonWH, buttonWH);
    self.micButton.bottom = self.bottom - marginToBottom;
    [self.micButton configStateChangeEventBlock:^(ChatInputMicButton *item, BOOL changeToState) {
        [weakSelf barItem:item changeToState:changeToState];
    }];

    /* 观察进入前台 */
    [GJCFNotificationCenter addObserver:self selector:@selector(becomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark -

- (CGRect)micButtonFrame {
    return CGRectMake(0, DEVICE_SIZE.height - self.barHeight, DEVICE_SIZE.width, self.barHeight);
}

- (void)micButtonInteractionBegan {
    [self.inputTextView clearInputTextWhenRecord];
    [self setShowRecordingInterface:true velocity:0.0f];
}

- (void)micButtonInteractionCancelled:(CGFloat)velocity {
    [self.inputTextView reserveToNormal];
    [self setShowRecordingInterface:false velocity:0.0f];
}

- (void)micButtonInteractionCompleted:(CGFloat)velocity {
    [self.inputTextView reserveToNormal];
    [self setShowRecordingInterface:false velocity:0.0f];
}

- (void)micButtonInteractionUpdate:(CGFloat)value {

}


- (void)setupForCommentBarStyle {
    self.openPanelBarItem.hidden = YES;
    self.inputTextView.gjcf_left = self.itemToBarMargin;
    self.inputTextView.gjcf_width = GJCFSystemScreenWidth - 2 * self.itemToBarMargin - self.itemMargin - self.emojiBarItem.gjcf_width;
    self.emojiBarItem.gjcf_left = self.inputTextView.gjcf_right + self.itemMargin;

}

- (void)setInputTextViewPlaceHolder:(NSString *)inputTextViewPlaceHolder {
    if ([_inputTextViewPlaceHolder isEqualToString:inputTextViewPlaceHolder]) {
        return;
    }
    _inputTextViewPlaceHolder = nil;
    _inputTextViewPlaceHolder = [inputTextViewPlaceHolder copy];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.bottomLine.gjcf_bottom = self.gjcf_height;

    if (GJCFSystemiPhone6Plus) {
        self.emojiBarItem.gjcf_bottom = self.gjcf_height - 8;
    } else {
        self.emojiBarItem.gjcf_bottom = self.gjcf_height - 7.5;
    }
    if (GJCFSystemiPhone6Plus) {
        self.openPanelBarItem.gjcf_bottom = self.gjcf_height - 8;
    } else {
        self.openPanelBarItem.gjcf_bottom = self.gjcf_height - 7.5;
    }
}

- (void)setPanelIdentifier:(NSString *)panelIdentifier {
    if ([_panelIdentifier isEqualToString:panelIdentifier]) {
        return;
    }
    _panelIdentifier = nil;
    _panelIdentifier = [panelIdentifier copy];
    [self.inputTextView setPanelIdentifier:panelIdentifier];
    self.micButton.panelIdentifier = panelIdentifier;
}

- (void)barItem:(id)item changeToState:(BOOL)state {
    if (item == self.micButton) {
        DDLogError(@"录音 %d", state);
        if (state) {
            [self selectActionType:GJGCChatInputBarActionTypeRecordAudio isReserveState:YES];
        }
    }

    if (item == self.emojiBarItem) {

        if (state) {
            [self selectActionType:GJGCChatInputBarActionTypeChooseEmoji isReserveState:NO];
        } else {
            [self selectActionType:GJGCChatInputBarActionTypeInputText isReserveState:NO];
        }
    }

    if (item == self.openPanelBarItem) {

        if (state) {
            [self selectActionType:GJGCChatInputBarActionTypeExpandPanel isReserveState:NO];
        } else {
            [self selectActionType:GJGCChatInputBarActionTypeInputText isReserveState:NO];
        }
    }

}

#pragma mark - 公开接口

- (void)selectActionType:(GJGCChatInputBarActionType)actionType isReserveState:(BOOL)isReserve {
    _currentActionType = actionType;

    switch (actionType) {
        case GJGCChatInputBarActionTypeChooseEmoji: {
            self.openPanelBarItem.selected = NO;
            [self.inputTextView setRecordState:NO];
            if (!isReserve) {
                [self.inputTextView resignFirstResponder];
                [self.inputTextView updateDisplayByInputContentTextChange];
                [self.inputTextView layoutInputTextView];
            }

            self.emojiBarItem.selected = YES;

        }
            break;
        case GJGCChatInputBarActionTypeExpandPanel: {
            self.emojiBarItem.selected = NO;
            [self.inputTextView setRecordState:NO];
            if (!isReserve) {
                [self.inputTextView resignFirstResponder];
                [self.inputTextView updateDisplayByInputContentTextChange];
                [self.inputTextView layoutInputTextView];
            }

            self.openPanelBarItem.selected = YES;

        }
            break;
        case GJGCChatInputBarActionTypeInputText: {
            self.inputTextView.recordState = NO;
            self.emojiBarItem.selected = NO;
            self.openPanelBarItem.selected = NO;

            if (!isReserve) {
                [self.inputTextView becomeFirstResponder];
            } else {
                [self.inputTextView resignFirstResponder];
            }

            [self.inputTextView updateDisplayByInputContentTextChange];

        }
            break;
        case GJGCChatInputBarActionTypeRecordAudio: {
            self.emojiBarItem.selected = NO;
            self.openPanelBarItem.selected = NO;
        }
            break;
        default:
            break;
    }

    if (self.changeActionBlock) {
        self.changeActionBlock(self, _currentActionType);
    }
}


- (void)configBarDidChangeActionBlock:(GJGCChatInputBarDidChangeActionBlock)actionBlock {
    if (self.changeActionBlock) {
        self.changeActionBlock = nil;
    }
    self.changeActionBlock = actionBlock;
}

- (void)configBarDidChangeFrameBlock:(GJGCChatInputBarDidChangeFrameBlock)changeBlock {
    if (self.changeFrameBlock) {
        self.changeFrameBlock = nil;
    }
    self.changeFrameBlock = changeBlock;
}

- (void)configInputBarRecordActionChangeBlock:(GJGCChatInputTextViewRecordActionChangeBlock)actionBlock {
    if (self.micButton) {
        [self.micButton configRecordActionChangeBlock:actionBlock];
    }
}

- (void)configBarTapOnSendTextBlock:(GJGCChatInputBarDidTapOnSendTextBlock)sendTextBlock {
    if (self.textSendBlock) {
        self.textSendBlock = nil;
    }
    self.textSendBlock = sendTextBlock;
}

- (void)reserveState {
    if (self.currentActionType != GJGCChatInputBarActionTypeRecordAudio) {
        [self selectActionType:GJGCChatInputBarActionTypeInputText isReserveState:YES];
    }
}

- (void)reserveCommentState {
    if (self.currentActionType == GJGCChatInputBarActionTypeChooseEmoji) {

        [self selectActionType:GJGCChatInputBarActionTypeInputText isReserveState:YES];

    } else {

        [self.inputTextView resignFirstResponder];

    }
}

- (void)inputTextResigionFirstResponse {
    [self.inputTextView resignFirstResponder];
}

- (BOOL)isInputTextFirstResponse {
    return [self.inputTextView isInputTextFirstResponse];
}

- (void)inputTextBecomeFirstResponse {
    [self.inputTextView becomeFirstResponder];
}

- (void)clearInputText {
    [self.inputTextView clearInputText];
}

- (void)recordRightStartLimit {
    self.inputTextView.recordState = NO;
    self.emojiBarItem.selected = NO;
    self.openPanelBarItem.selected = NO;
}

#pragma mark - 进入前台

- (void)becomeActive:(NSNotification *)noti {
    self.userInteractionEnabled = YES;
}


- (void)setShowRecordingInterface:(bool)show velocity:(CGFloat)velocity {
    if (show) {
        [_micButton animateIn];
    } else {
        [_micButton animateOut];
    }
}

@end
