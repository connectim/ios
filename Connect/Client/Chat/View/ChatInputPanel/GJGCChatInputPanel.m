//
//  GJGCChatInputPanel.m
//  Connect
//
//  Created by KivenLin on 14-10-28.
//  Copyright (c) 2014年 ConnectSoft. All rights reserved.
//

#import "GJGCChatInputPanel.h"
#import "GJCFAudioRecord.h"
#import "GJGCChatInputRecordAudioTipView.h"

@interface GJGCChatInputPanel () <
        GJGCChatInputExpandMenuPanelDelegate,
        GJCFAudioRecordDelegate
        >
//input ui
@property(nonatomic, strong) GJGCChatInputBar *inputBar;
@property(nonatomic, strong) GJGCChatInputExpandEmojiPanel *emojiPanel;
@property(nonatomic, strong) GJGCChatInputExpandMenuPanel *menuPanel;
@property(nonatomic, strong) GJCFAudioRecord *audioRecord;


//call back
@property(nonatomic, copy) GJGCChatInputPanelKeyboardFrameChangeBlock frameChangeBlock;
@property(nonatomic, copy) GJGCChatInputPanelInputTextViewHeightChangedBlock inputHeightChangeBlock;

//hud view
@property(nonatomic, strong) GJGCChatInputRecordAudioTipView *recordTipView;

@end

@implementation GJGCChatInputPanel

- (instancetype)initWithPanelDelegate:(id <GJGCChatInputPanelDelegate>)aDelegate; {
    if (self = [super init]) {
        self.delegate = aDelegate;
        _panelIndentifier = [NSString stringWithFormat:@"GJGCChatInputPanel_%@", GJCFStringCurrentTimeStamp];
        self.inputBarHeight = AUTO_HEIGHT(100);
        self.backgroundColor = GJCFQuickHexColor(@"C7C7CD");
        [self initSubViews];
    }
    return self;
}

- (instancetype)initForCommentBarWithPanelDelegate:(id <GJGCChatInputPanelDelegate>)aDelegate {
    self = [self initWithPanelDelegate:aDelegate];
    [self adjustLayoutBarItemForCommentStyle];
    return self;
}

- (void)dealloc {
    if (self.audioRecord.isRecording) {
        [self.audioRecord cancelRecord];
    }
    [self.inputBar removeObserver:self forKeyPath:@"frame"];
    [self.emojiPanel removeEmojiOberverWithIdentifier:self.panelIndentifier];
    [GJCFNotificationCenter removeObserver:self];
}

- (void)initSubViews {

    self.inputBar = [[GJGCChatInputBar alloc] initWithFrame:(CGRect) {0, 0, GJCFSystemScreenWidth, self.inputBarHeight}];
    self.inputBar.barHeight = self.inputBarHeight;
    self.inputBar.panelIdentifier = self.panelIndentifier;
    [self addSubview:self.inputBar];

    GJCFWeakSelf weakSelf = self;
    [self.inputBar configBarDidChangeActionBlock:^(GJGCChatInputBar *inputBar, GJGCChatInputBarActionType toActionType) {
        [weakSelf inputBar:inputBar changeToAction:toActionType];
    }];

    [self.inputBar configBarDidChangeFrameBlock:^(GJGCChatInputBar *inputBar, CGFloat changeDelta) {
        [weakSelf inputBar:inputBar changeToFrame:changeDelta];
    }];

    [self.inputBar configBarTapOnSendTextBlock:^(GJGCChatInputBar *inputBar, NSString *text) {
        [weakSelf inputBar:inputBar sendText:text];
    }];

    [self.inputBar configInputBarRecordActionChangeBlock:^(GJGCChatInputTextViewRecordActionType actionType) {
        [weakSelf inputBarRecordActionChange:actionType];
    }];

    self.emojiPanel = [GJGCChatInputExpandEmojiPanel sharedInstance];
    self.emojiPanel.top = self.inputBarHeight;
    self.emojiPanel.backgroundColor = GJCFQuickHexColor(@"fcfcfc");
    [self addSubview:self.emojiPanel];

    [self.emojiPanel addEmojiOberverWithIdentifier:self.panelIndentifier];

    self.menuPanel = [[GJGCChatInputExpandMenuPanel alloc] initWithFrame:self.emojiPanel.frame withDelegate:self];
    self.menuPanel.backgroundColor = GJCFQuickHexColor(@"fcfcfc");
    [self addSubview:self.menuPanel];

    [self observePanelInnerEventNoti];

    [self initAudioRecord];

    NSString *formateNoti = [GJGCChatInputConst panelNoti:GJGCChatInputTextViewContentChangeNoti formateWithIdentifier:self.panelIndentifier];
    [GJCFNotificationCenter addObserver:self selector:@selector(updateInputTextContent:) name:formateNoti object:nil];

    [self.inputBar addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];

    [self startKeyboardObserve];
}

- (void)adjustLayoutBarItemForCommentStyle {
    [self.inputBar setupForCommentBarStyle];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"frame"] && object == self.inputBar) {
        [self.inputBar setNeedsLayout];
    }
}

- (CGFloat)inputBarHeight {
    if (_currentActionType == GJGCChatInputBarActionTypeRecordAudio) {
        return AUTO_HEIGHT(100);
    }
    return self.inputBar.inputTextStateBarHeight == 0 ? AUTO_HEIGHT(100) : self.inputBar.inputTextStateBarHeight;
}

- (void)setDisableActionType:(GJGCChatInputBarActionType)disableActionType {
    _disableActionType = disableActionType;
    [self.inputBar setDisableActionType:_disableActionType];
}

- (void)updateInputTextContent:(NSNotification *)noti {
    _messageDraft = noti.object;
}

- (void)setInputBarTextViewPlaceHolder:(NSString *)inputBarTextViewPlaceHolder {
    if ([_inputBarTextViewPlaceHolder isEqualToString:inputBarTextViewPlaceHolder]) {
        return;
    }

    _inputBarTextViewPlaceHolder = nil;
    _inputBarTextViewPlaceHolder = [inputBarTextViewPlaceHolder copy];

    [self.inputBar setInputTextViewPlaceHolder:_inputBarTextViewPlaceHolder];
}

#pragma mark - input bar action resposne

- (void)inputBar:(GJGCChatInputBar *)bar changeToAction:(GJGCChatInputBarActionType)actionType {
    switch (actionType) {

        case GJGCChatInputBarActionTypeChooseEmoji: {
            self.emojiPanel.hidden = NO;
            self.menuPanel.hidden = YES;
        }
            break;

        case GJGCChatInputBarActionTypeExpandPanel: {
            self.emojiPanel.hidden = YES;
            self.menuPanel.hidden = NO;
        }
            break;

        case GJGCChatInputBarActionTypeInputText: {

        }
            break;

        case GJGCChatInputBarActionTypeRecordAudio: {
//            self.inputBar.gjcf_height = self.inputBarHeight;
        }
            break;

        default:
            break;
    }

    _currentActionType = actionType;

    if (self.actionChangeBlock) {
        self.actionChangeBlock(self.inputBar, actionType);
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(chatInputPanel:didChangeToInputBarAction:)]) {
        [self.delegate chatInputPanel:self didChangeToInputBarAction:actionType];
    }
}

- (void)inputBarRecordActionChange:(GJGCChatInputTextViewRecordActionType)action {
    switch (action) {

        case GJGCChatInputTextViewRecordActionTypeStart: {
            if (self.recordStateChangeBlock) {
                self.recordStateChangeBlock(self, YES);
            }

            [self.audioRecord startRecord];

            NSString *formateNoti = [GJGCChatInputConst panelNoti:GJGCChatInputPanelBeginRecordNoti formateWithIdentifier:self.panelIndentifier];
            GJCFNotificationPost(formateNoti);
        }
            break;

        case GJGCChatInputTextViewRecordActionTypeFinish: {
            self.inputBar.userInteractionEnabled = YES;
            if (self.recordStateChangeBlock) {
                self.recordStateChangeBlock(self, NO);
            }

            [self.audioRecord finishRecord];
        }
            break;

        case GJGCChatInputTextViewRecordActionTypeCancel: {
            self.inputBar.userInteractionEnabled = YES;
            if (self.recordStateChangeBlock) {
                self.recordStateChangeBlock(self, NO);
            }

            [self.audioRecord cancelRecord];
        }
            break;
        case GJGCChatInputTextViewRecordActionTypeTooShort: {
            self.inputBar.userInteractionEnabled = YES;
            if (self.recordStateChangeBlock) {
                self.recordStateChangeBlock(self, NO);
            }

            [self showRecordTipView];
        }
            break;
        default:
            break;
    }
}

- (void)inputBar:(GJGCChatInputBar *)bar changeToFrame:(CGFloat)changeDelta {
    if (self.inputHeightChangeBlock) {
        self.emojiPanel.gjcf_top = bar.gjcf_bottom;
        self.menuPanel.gjcf_top = bar.gjcf_bottom;
        self.inputHeightChangeBlock(self, changeDelta);
    }
}


- (void)inputBar:(GJGCChatInputBar *)bar sendText:(NSString *)text {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatInputPanel:sendTextMessage:)]) {
        [self.delegate chatInputPanel:self sendTextMessage:text];
    }
}

- (void)showRecordTipView {
    if (self.recordTipView) {
        [self.recordTipView removeFromSuperview];
        self.recordTipView = nil;
    }
    self.recordTipView = [[GJGCChatInputRecordAudioTipView alloc] init];
    self.recordTipView.isTooShortRecordDuration = YES;
    [[[UIApplication sharedApplication] keyWindow] addSubview:self.recordTipView];
    [self removeRecordTipView];
}

- (void)removeRecordTipView {
    GJCFAsyncMainQueueDelay(0.5, ^{

        if (self.recordTipView) {
            [self.recordTipView removeFromSuperview];
            self.recordTipView = nil;
        }

    });
}

- (void)initAudioRecord {
    self.audioRecord = [[GJCFAudioRecord alloc] init];
    self.audioRecord.delegate = self;
    self.audioRecord.limitRecordDuration = 60.0f;
    self.audioRecord.minEffectDuration = 1.f;
}

- (void)audioRecord:(GJCFAudioRecord *)audioRecord didFaildByMinRecordDuration:(NSTimeInterval)minDuration {
    [self showRecordTipView];
}

- (void)audioRecord:(GJCFAudioRecord *)audioRecord didOccusError:(NSError *)error {
    NSLog(@"录音失败:%@", error);
}

- (void)audioRecord:(GJCFAudioRecord *)audioRecord finishRecord:(GJCFAudioModel *)resultAudio {
    NSLog(@"录音成功:%@", resultAudio.description);
    NSString *formateNoti = [GJGCChatInputConst panelNoti:GJGCChatInputTextViewRecordTooLongNoti formateWithIdentifier:self.panelIndentifier];
    GJCFNotificationPost(formateNoti);
    [GJCFAudioFileUitil setupAudioFileTempEncodeFilePath:resultAudio];

    if ([GJCFEncodeAndDecode convertAudioFileToAMR:resultAudio]) {
        NSLog(@"ChatInputPanel 录音文件转码成功");
        NSLog(@"%@", resultAudio);
        if (self.delegate && [self.delegate respondsToSelector:@selector(chatInputPanel:didFinishRecord:)]) {
            [self.delegate chatInputPanel:self didFinishRecord:resultAudio];
        }
    }
}

- (void)audioRecord:(GJCFAudioRecord *)audioRecord limitDurationProgress:(CGFloat)progress {
}

- (void)audioRecord:(GJCFAudioRecord *)audioRecord soundMeter:(CGFloat)soundMeter {

    NSString *formateNoti = [GJGCChatInputConst panelNoti:GJGCChatInputTextViewRecordSoundMeterNoti formateWithIdentifier:self.panelIndentifier];

    GJCFNotificationPostObj(formateNoti, @(soundMeter));

}

- (void)audioRecordDidCancel:(GJCFAudioRecord *)audioRecord {
    NSString *formateNoti = [GJGCChatInputConst panelNoti:GJGCChatInputTextViewRecordCancelNoti formateWithIdentifier:self.panelIndentifier];
    GJCFNotificationPostObj(formateNoti, @"");
    NSLog(@"录音取消");
}


#pragma mark - menuPanel  Delegate

- (void)menuPanel:(GJGCChatInputExpandMenuPanel *)panel didChooseAction:(GJGCChatInputMenuPanelActionType)action {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatInputPanel:didChooseMenuAction:)]) {

        [self.delegate chatInputPanel:self didChooseMenuAction:action];
    }

}

- (GJGCChatInputExpandMenuPanelConfigModel *)menuPanelRequireCurrentConfigData:(GJGCChatInputExpandMenuPanel *)panel; {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatInputPanelRequiredCurrentConfigData:)]) {

        return [self.delegate chatInputPanelRequiredCurrentConfigData:self];

    } else {

        return nil;
    }
}

#pragma mark - keyboard

- (void)configInputPanelKeyboardFrameChange:(GJGCChatInputPanelKeyboardFrameChangeBlock)changeBlock {
    if (self.frameChangeBlock) {
        self.frameChangeBlock = nil;
    }
    self.frameChangeBlock = changeBlock;
}

- (void)configInputPanelRecordStateChange:(GJGCChatInputPanelRecordStateChangeBlock)recordChangeBlock {
    if (self.recordStateChangeBlock) {
        self.recordStateChangeBlock = nil;
    }
    self.recordStateChangeBlock = recordChangeBlock;
}

- (void)configInputPanelInputTextViewHeightChangedBlock:(GJGCChatInputPanelInputTextViewHeightChangedBlock)heightChangeBlock {
    if (self.inputHeightChangeBlock) {
        self.inputHeightChangeBlock = nil;
    }
    self.inputHeightChangeBlock = heightChangeBlock;
}

- (void)keyboardWillChangeFrame:(NSNotification *)noti {
    CGRect keyboardBeginFrame = [noti.userInfo[@"UIKeyboardFrameBeginUserInfoKey"] CGRectValue];
    CGRect keyboardEndFrame = [noti.userInfo[@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];
    CGFloat duration = [noti.userInfo[@"UIKeyboardAnimationDurationUserInfoKey"] doubleValue];

    if (self.frameChangeBlock) {
        if (self.inputBar.currentActionType == GJGCChatInputBarActionTypeChooseEmoji || self.inputBar.currentActionType == GJGCChatInputBarActionTypeExpandPanel) {
            self.frameChangeBlock(self, keyboardBeginFrame, keyboardEndFrame, duration, NO);
        } else {
            self.frameChangeBlock(self, keyboardBeginFrame, keyboardEndFrame, duration, YES);
        }
    }

}

- (void)startKeyboardObserve {
    __weak __typeof(&*self) weakSelf = self;
    [NSNotificationCenter.defaultCenter addObserverForName:UIKeyboardWillChangeFrameNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        CGRect keyboardBeginFrame = [note.userInfo[@"UIKeyboardFrameBeginUserInfoKey"] CGRectValue];
        CGRect keyboardEndFrame = [note.userInfo[@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];
        CGFloat duration = [note.userInfo[@"UIKeyboardAnimationDurationUserInfoKey"] doubleValue];

        if (weakSelf.frameChangeBlock) {
            if (weakSelf.inputBar.currentActionType == GJGCChatInputBarActionTypeChooseEmoji || weakSelf.inputBar.currentActionType == GJGCChatInputBarActionTypeExpandPanel) {
                weakSelf.frameChangeBlock(weakSelf, keyboardBeginFrame, keyboardEndFrame, duration, NO);
            } else {
                weakSelf.frameChangeBlock(weakSelf, keyboardBeginFrame, keyboardEndFrame, duration, YES);
            }
        }
    }];
}

- (void)removeKeyboardObserve {
    [GJCFNotificationCenter removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
}


- (void)observePanelInnerEventNoti {
    /* expresion send event */
    NSString *formateNoti = [GJGCChatInputConst panelNoti:GJGCChatInputExpandEmojiPanelChooseSendNoti formateWithIdentifier:self.panelIndentifier];
    [GJCFNotificationCenter addObserver:self selector:@selector(observeEmojiPanelSend:) name:formateNoti object:nil];

    /* gif send event */
    NSString *formateGifSendNoti = [GJGCChatInputConst panelNoti:GJGCChatInputExpandEmojiPanelChooseGIFEmojiNoti formateWithIdentifier:self.panelIndentifier];
    [GJCFNotificationCenter addObserver:self selector:@selector(observeGifEmojiPanelSend:) name:formateGifSendNoti object:nil];

}

- (void)observeEmojiPanelSend:(NSNotification *)noti {
    BOOL isAllWhiteSpace = GJCFStringIsAllWhiteSpace(self.messageDraft);
    if (isAllWhiteSpace) {
        return;
    }
    if (self.messageDraft.length == 0) {
        return;
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(chatInputPanel:sendTextMessage:)]) {

        [self.delegate chatInputPanel:self sendTextMessage:self.messageDraft];

        [self.inputBar clearInputText];

        _messageDraft = @"";

    }
}

- (void)observeGifEmojiPanelSend:(NSNotification *)noti {
    NSString *gifLocalId = noti.object;

    if (self.delegate && [self.delegate respondsToSelector:@selector(chatInputPanel:sendGIFMessage:)]) {

        [self.delegate chatInputPanel:self sendGIFMessage:gifLocalId];
    }
}

- (void)reserveState {
    self.isFullState = NO;
    [self.inputBar reserveState];
}

- (void)reserveCommentState {
    [self.inputBar reserveCommentState];
}

- (void)recordRightStartLimit {
    [self.inputBar recordRightStartLimit];
}

- (void)inputBarRegsionFirstResponse {
    [self.inputBar inputTextResigionFirstResponse];
}

- (BOOL)isInputTextFirstResponse {
    return [self.inputBar isInputTextFirstResponse];
}

- (void)becomeFirstResponse {
    [self.inputBar inputTextBecomeFirstResponse];
}

- (void)setLastMessageDraft:(NSString *)msgDraft {
    _messageDraft = [msgDraft copy];
    NSString *formateNoti = [GJGCChatInputConst panelNoti:GJGCChatInputSetLastMessageDraftNoti formateWithIdentifier:self.panelIndentifier];
    GJCFNotificationPostObj(formateNoti, msgDraft);

    if (!GJCFStringIsNull(msgDraft)) {
        if ([UIView areAnimationsEnabled]) {
            [UIView setAnimationsEnabled:NO];
        }
        [self.inputBar inputTextBecomeFirstResponse];
    }
}

- (void)appendFocusOnOther:(NSString *)otherName {
    if (GJCFStringIsNull(otherName)) {
        return;
    }

    NSString *formateNoti = [GJGCChatInputConst panelNoti:GJGCChatInputPanelNeedAppendTextNoti formateWithIdentifier:self.panelIndentifier];
    GJCFNotificationPostObj(formateNoti, otherName);

}

@end
