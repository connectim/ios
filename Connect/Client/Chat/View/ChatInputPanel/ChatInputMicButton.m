//
//  ChatInputMicButton.m
//  Connect
//
//  Created by MoHuilin on 16/6/14.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import "ChatInputMicButton.h"
#import "UIGestureRecognizer+Cancel.h"
#import <AVFoundation/AVFoundation.h>

static const CGFloat innerCircleRadius = 80;
static const CGFloat outerCircleRadius = innerCircleRadius + 50.0f;
static const CGFloat outerCircleMinScale = innerCircleRadius / outerCircleRadius;

@interface ChatInputMicButtonOverlayController : UIViewController


@end

@implementation ChatInputMicButtonOverlayController

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];

    [self.view.window.layer removeAnimationForKey:@"backgroundColor"];
    [CATransaction begin];
    [CATransaction setDisableActions:true];
    self.view.window.layer.backgroundColor = GJCFQuickHexColor(@"EFF0F2").CGColor;
    [CATransaction commit];

    for (UIView *view in self.view.window.subviews) {
        if (view != self.view) {
            [view removeFromSuperview];
            break;
        }
    }
}

@end


@interface ChatInputMicButton () <UIGestureRecognizerDelegate> {
    CGPoint _touchLocation;
    UIPanGestureRecognizer *_panRecognizer;

    CGFloat _lastVelocity;

    bool _processCurrentTouch;
    CFAbsoluteTime _lastTouchTime;
    bool _acceptTouchDownAsTouchUp;

    UIWindow *_overlayWindow;

    UIImageView *_innerCircleView;
    UIImageView *_outerCircleView;
    UIImageView *_innerIconView;

    CFAbsoluteTime _animationStartTime;

    CADisplayLink *_displayLink;
    CGFloat _currentLevel;
    CGFloat _inputLevel;
    bool _animatedIn;

    CGPoint _originCenter;

    UIImageView *_recordingView;

    UIImageView *_recordIndicatorView;
    MASConstraint *_recordIndicatorViewLeft;
    UILabel *_recordDurationLabel;
    MASConstraint *_recordDurationLabelLeft;

    UIImageView *_slideToCancelArrow;
    MASConstraint *_slideToCancelArrowLeft;
    UILabel *_slideToCancelLabel;
    MASConstraint *_slideToCancelLabelLeft;


    NSUInteger _audioRecordingDurationSeconds;
    NSUInteger _audioRecordingDurationMilliseconds;
    NSTimer *_audioRecordingTimer;


    UIImageView *_cancelRecordingView;
    MASConstraint *_cancelRecordingViewLeft;
    UILabel *_cancelTipLabel;
    MASConstraint *_cancelTipLabelLeft;
}


@property(nonatomic, copy) ChatInputMicButtonStateChangeEventBlock stateChangeblock;
@property(nonatomic, copy) GJGCChatInputTextViewRecordActionChangeBlock actionChangeBlock;
@property(nonatomic, strong) UIView *recordContentView;

@end

@implementation ChatInputMicButton

- (UIView *)recordContentView {
    if (!_recordContentView) {
        _recordContentView = [[UIView alloc] init];
        _recordContentView.backgroundColor = self.superview.backgroundColor;

        UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, GJCFSystemScreenWidth, 0.5)];
        [topLine setBackgroundColor:LMBasicMiddleGray];
        [_recordContentView addSubview:topLine];

        if (_recordIndicatorView == nil) {
            _recordIndicatorView = [[UIImageView alloc] init];
            _recordIndicatorView.backgroundColor = GJCFQuickHexColor(@"F33D2B");
            _recordIndicatorView.layer.cornerRadius = 5;
            _recordIndicatorView.layer.masksToBounds = YES;
        }

        [_recordContentView addSubview:_recordIndicatorView];
        [_recordIndicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(_recordContentView);
            make.size.mas_equalTo(CGSizeMake(10, 10));
            _recordIndicatorViewLeft = make.left.equalTo(_recordContentView).offset(15);
        }];


        if (_cancelRecordingView == nil) {
            _cancelRecordingView = [[UIImageView alloc] initWithImage:GJCFQuickImage(@"chatbar_record_cancel")];
            _cancelRecordingView.hidden = YES;
        }

        [_recordContentView addSubview:_cancelRecordingView];
        [_cancelRecordingView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(_recordContentView);
            make.size.mas_equalTo(CGSizeMake(AUTO_WIDTH(30), AUTO_HEIGHT(54)));
            _cancelRecordingViewLeft = make.left.equalTo(_recordContentView).offset(AUTO_WIDTH(30));
        }];

        if (_cancelTipLabel == nil) {
            _cancelTipLabel = [[UILabel alloc] init];
            _cancelTipLabel.backgroundColor = [UIColor clearColor];
            _cancelTipLabel.textColor = [UIColor colorWithRed:0.922 green:0.216 blue:0.318 alpha:1.000];
            _cancelTipLabel.font = [UIFont systemFontOfSize:FONT_SIZE(30)];
            _cancelTipLabel.text = LMLocalizedString(@"Chat Release to cancel", nil);
            _cancelTipLabel.hidden = YES;
        }

        [_recordContentView addSubview:_cancelTipLabel];

        [_cancelTipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            _cancelTipLabelLeft = make.left.equalTo(_cancelRecordingView.mas_right).offset(AUTO_WIDTH(20));
            make.centerY.equalTo(_recordContentView);
        }];


        if (_recordDurationLabel == nil) {
            _recordDurationLabel = [[UILabel alloc] init];
            _recordDurationLabel.backgroundColor = [UIColor clearColor];
            _recordDurationLabel.textColor = [UIColor blackColor];
            _recordDurationLabel.font = [UIFont systemFontOfSize:15];
            _recordDurationLabel.text = @"0:00";
            _recordDurationLabel.alpha = 0.0f;
        }

        [_recordContentView addSubview:_recordDurationLabel];

        [_recordDurationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            _recordDurationLabelLeft = make.left.equalTo(_recordIndicatorView.mas_right).offset(10);
            make.centerY.equalTo(_recordContentView);
        }];

        if (_slideToCancelLabel == nil) {
            _slideToCancelLabel = [[UILabel alloc] init];
            _slideToCancelLabel.backgroundColor = [UIColor clearColor];
            _slideToCancelLabel.textColor = GJCFQuickHexColor(@"0xaaaab2");
            _slideToCancelLabel.font = [UIFont systemFontOfSize:14];
            _slideToCancelLabel.text = LMLocalizedString(@"Chat Slide left to cancel", nil);
            _slideToCancelLabel.clipsToBounds = false;
            [_slideToCancelLabel sizeToFit];
            _slideToCancelLabel.alpha = 0.0f;

            _slideToCancelArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"audio_play"]];
            _slideToCancelArrow.alpha = 0.0f;
        }


        [_recordContentView addSubview:_slideToCancelLabel];
        [_recordContentView addSubview:_slideToCancelArrow];
        [_slideToCancelArrow mas_makeConstraints:^(MASConstraintMaker *make) {
            _slideToCancelArrowLeft = make.left.equalTo(_recordDurationLabel.mas_right).offset(10);
            make.size.mas_equalTo(CGSizeMake(15, 14));
            make.centerY.equalTo(_recordContentView);
        }];

        [_slideToCancelLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            _slideToCancelLabelLeft = make.left.equalTo(_slideToCancelArrow.mas_right);
            make.centerY.equalTo(_recordContentView);
        }];

        [UIView animateWithDuration:0.2f animations:^{
            _recordDurationLabel.alpha = 1;
            _slideToCancelArrow.alpha = 1;
            _slideToCancelLabel.alpha = 1;
        }];
        if ([self.delegate respondsToSelector:@selector(micButtonFrame)]) {
            _recordContentView.frame = [self.delegate micButtonFrame];
        }
    }

    if (CGRectEqualToRect(_recordContentView.frame, CGRectZero)) {
        if ([self.delegate respondsToSelector:@selector(micButtonFrame)]) {
            _recordContentView.frame = [self.delegate micButtonFrame];
        }
    }

    [self addRecordingDotAnimation];
    return _recordContentView;
}

- (void)startAudioRecordingTimer {
    _recordDurationLabel.text = @"0:00";

    _audioRecordingDurationSeconds = 0;
    _audioRecordingDurationMilliseconds = 0.0;
    _audioRecordingTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(audioTimerEvent) userInfo:nil repeats:YES];
}


- (void)audioTimerEvent {
    _audioRecordingDurationSeconds++;
    _recordDurationLabel.text = [[NSString alloc] initWithFormat:@"%d:%02d", (int) _audioRecordingDurationSeconds / 60, (int) _audioRecordingDurationSeconds % 60];
}

- (void)stopAudioRecordingTimer {
    if (_audioRecordingTimer != nil) {
        [_audioRecordingTimer invalidate];
        _audioRecordingTimer = nil;
    }
}


- (void)addRecordingDotAnimation {
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    animation.values = @[@1.0f, @1.0f, @0.0f];
    animation.keyTimes = @[@.0, @0.4546, @0.9091, @1];
    animation.duration = 0.5;
    animation.autoreverses = true;
    animation.repeatCount = INFINITY;

    [_recordIndicatorView.layer addAnimation:animation forKey:@"opacity-dot"];
}

- (void)removeDotAnimation {
    [_recordIndicatorView.layer removeAnimationForKey:@"opacity-dot"];
}

- (void)setPanelIdentifier:(NSString *)panelIdentifier {
    if ([_panelIdentifier isEqualToString:panelIdentifier]) {
        return;
    }
    _panelIdentifier = nil;
    _panelIdentifier = [panelIdentifier copy];

    [self observeRequiredNoti];
}

#pragma mark - 观察必要通知

- (void)observeRequiredNoti {
    /* 观察输入音量 */
    NSString *soundMeterNoti = [GJGCChatInputConst panelNoti:GJGCChatInputTextViewRecordSoundMeterNoti formateWithIdentifier:self.panelIdentifier];
    NSString *recordTooShortNoti = [GJGCChatInputConst panelNoti:GJGCChatInputTextViewRecordTooShortNoti formateWithIdentifier:self.panelIdentifier];
    NSString *recordTooLongNoti = [GJGCChatInputConst panelNoti:GJGCChatInputTextViewRecordTooLongNoti formateWithIdentifier:self.panelIdentifier];
    NSString *recordCancelNoti = [GJGCChatInputConst panelNoti:GJGCChatInputTextViewRecordCancelNoti formateWithIdentifier:self.panelIdentifier];

    [GJCFNotificationCenter addObserver:self selector:@selector(observeRecordSoundMeter:) name:soundMeterNoti object:nil];
    [GJCFNotificationCenter addObserver:self selector:@selector(observeRecordTooShort:) name:recordTooShortNoti object:nil];
    [GJCFNotificationCenter addObserver:self selector:@selector(observeRecordTooLong:) name:recordTooLongNoti object:nil];
    [GJCFNotificationCenter addObserver:self selector:@selector(recordCancel) name:recordCancelNoti object:nil];
}

- (void)observeRecordSoundMeter:(NSNotification *)noti {
    CGFloat soundMeter = [noti.object floatValue];

    [self addMicLevel:soundMeter];

}

- (void)observeRecordTooShort:(NSNotification *)noti {
}

- (void)observeRecordTooLong:(NSNotification *)noti {
    [_panRecognizer cancel];
    self.actionChangeBlock(GJGCChatInputTextViewRecordActionTypeFinish);
    self.stateChangeblock(self, NO);

    [self animateOut];
}

- (BOOL)checkRecordPermission {
    AVAudioSession *avSession = [AVAudioSession sharedInstance];
    if (avSession && [avSession respondsToSelector:@selector(requestRecordPermission:)]) {
        __block BOOL isPermission;
        [avSession requestRecordPermission:^(BOOL granted) {
            if (!granted) {
                self.actionChangeBlock(GJGCChatInputTextViewRecordActionTypeCancel);
                self.stateChangeblock(self, NO);
                id <ChatInputMicButtonDelegate> delegate = _delegate;
                if ([delegate respondsToSelector:@selector(micButtonInteractionCancelled:)])
                    [delegate micButtonInteractionCancelled:0];
                [[[UIAlertView alloc] initWithTitle:LMLocalizedString(@"Chat Unable to record", nil) message:LMLocalizedString(@"Chat Allow Connect to access your microphone", nil) delegate:nil cancelButtonTitle:LMLocalizedString(@"Common OK", nil) otherButtonTitles:nil] show];
            }
            isPermission = granted;
        }];
        return isPermission;
    }
    return YES;
}

- (void)configRecordActionChangeBlock:(GJGCChatInputTextViewRecordActionChangeBlock)actionBlock {
    if (self.actionChangeBlock) {
        self.actionChangeBlock = nil;
    }
    self.actionChangeBlock = actionBlock;
}

- (UIImage *)innerCircleImage:(UIColor *)color {
    static UIImage *image = nil;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(innerCircleRadius, innerCircleRadius), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, innerCircleRadius, innerCircleRadius));
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)outerCircleImage {
    static UIImage *image = nil;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(outerCircleRadius, outerCircleRadius), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:0.243 green:0.820 blue:0.000 alpha:1.000].CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, outerCircleRadius, outerCircleRadius));
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        self.exclusiveTouch = true;
        self.multipleTouchEnabled = false;

        _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
        _panRecognizer.cancelsTouchesInView = false;
        _panRecognizer.delegate = self;
        [self addGestureRecognizer:_panRecognizer];
    }
    return self;
}

- (void)dealloc {
    _displayLink.paused = true;
    [_displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [self stopAudioRecordingTimer];

    [GJCFNotificationCenter removeObserver:self];
}


- (void)micButtonInteractionUpdate:(CGFloat)value {
    CGFloat offset = value * 100.0f;

    offset = MAX(0.0f, offset - 5.0f);

    if (value < 0.3f)
        offset = value / 0.6f * offset;
    else
        offset -= 0.15f * 100.0f;

    _slideToCancelArrow.transform = CGAffineTransformMakeTranslation(-offset, 0.0f);

    CGAffineTransform labelTransform = CGAffineTransformIdentity;
    labelTransform = CGAffineTransformTranslate(labelTransform, -offset, 0.0f);
    _slideToCancelLabel.transform = labelTransform;

    CGAffineTransform indicatorTransform = CGAffineTransformIdentity;
    CGAffineTransform durationTransform = CGAffineTransformIdentity;

    static CGFloat freeOffsetLimit = 35.0f;

    if (offset > freeOffsetLimit) {
        indicatorTransform = CGAffineTransformMakeTranslation(freeOffsetLimit - offset, 0.0f);
        durationTransform = CGAffineTransformMakeTranslation(freeOffsetLimit - offset, 0.0f);
    }

    if (!CGAffineTransformEqualToTransform(indicatorTransform, _recordIndicatorView.transform))
        _recordIndicatorView.transform = indicatorTransform;

    if (!CGAffineTransformEqualToTransform(durationTransform, _recordDurationLabel.transform))
        _recordDurationLabel.transform = durationTransform;
}

- (CADisplayLink *)displayLink {
    if (_displayLink == nil) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkUpdate)];
        _displayLink.paused = true;
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    return _displayLink;
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    if ([super beginTrackingWithTouch:touch withEvent:event]) {
        if (_acceptTouchDownAsTouchUp) {
            _acceptTouchDownAsTouchUp = false;
            _processCurrentTouch = false;

            [self _commitCompleted];
        } else {
            _lastVelocity = 0.0;

            if (ABS(CFAbsoluteTimeGetCurrent() - _lastTouchTime) < 1.0) {
                _processCurrentTouch = false;

                return false;
            } else {
                _processCurrentTouch = true;
                _lastTouchTime = CFAbsoluteTimeGetCurrent();

                id <ChatInputMicButtonDelegate> delegate = _delegate;
                if ([delegate respondsToSelector:@selector(micButtonInteractionBegan)]) {
                    [delegate micButtonInteractionBegan];
                }
                _touchLocation = [touch locationInView:self];
            }
        }

        return true;
    }

    return false;
}

- (void)animateIn {

    DDLogInfo(@"animateIn");
    if (![self checkRecordPermission]) {
        return;
    }
    AVAudioSessionRecordPermission permission = [[AVAudioSession sharedInstance] recordPermission];
    if (permission == AVAudioSessionRecordPermissionUndetermined) {
        return;
    }

    _animatedIn = true;
    _animationStartTime = CACurrentMediaTime();

    if (_overlayWindow == nil) {
        _overlayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _overlayWindow.windowLevel = UIWindowLevelAlert;
        UIViewController *controller = [[ChatInputMicButtonOverlayController alloc] init];
        _overlayWindow.rootViewController = controller;

        [_overlayWindow.rootViewController.view addSubview:self.recordContentView];

        _innerCircleView = [[UIImageView alloc] initWithImage:[self innerCircleImage:[UIColor colorWithRed:0.243 green:0.820 blue:0.000 alpha:1.000]]];

        _innerCircleView.alpha = 0.0f;
        [_overlayWindow.rootViewController.view addSubview:_innerCircleView];

        _outerCircleView = [[UIImageView alloc] initWithImage:[self outerCircleImage]];
        _outerCircleView.alpha = 0.0f;
        [_overlayWindow.rootViewController.view addSubview:_outerCircleView];

        _innerIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_chatbar_audio_recording"]];
        _innerIconView.alpha = 0.0f;
        [_overlayWindow.rootViewController.view addSubview:_innerIconView];
    }

    _overlayWindow.hidden = false;

    dispatch_block_t block = ^{
        CGPoint centerPoint = [self.superview convertPoint:self.center toView:_overlayWindow.rootViewController.view];
        _innerCircleView.center = centerPoint;
        _outerCircleView.center = centerPoint;
        _innerIconView.center = centerPoint;
        _recordContentView.gjcf_centerY = centerPoint.y;
    };

    block();
    dispatch_async(dispatch_get_main_queue(), block);

    _innerCircleView.transform = CGAffineTransformMakeScale(0.2f, 0.2f);
    _outerCircleView.transform = CGAffineTransformMakeScale(0.2f, 0.2f);
    _innerCircleView.alpha = 0.2f;
    _outerCircleView.alpha = 0.2f;

    [UIView animateWithDuration:0.50 delay:0.0 usingSpringWithDamping:0.55f initialSpringVelocity:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        _innerCircleView.transform = CGAffineTransformIdentity;
        _outerCircleView.transform = CGAffineTransformMakeScale(outerCircleMinScale, outerCircleMinScale);
    }                completion:nil];

    [UIView animateWithDuration:0.1 animations:^{
        _innerCircleView.alpha = 1.0f;
        self.iconView.alpha = 0.0f;
        _innerIconView.alpha = 1.0f;
        _outerCircleView.alpha = 1.0f;
    }];

    _cancelTipLabel.hidden = YES;
    _cancelRecordingView.hidden = YES;

    _recordDurationLabel.hidden = NO;
    _recordIndicatorView.hidden = NO;
    _slideToCancelLabel.hidden = NO;
    _slideToCancelArrow.hidden = NO;

    [self displayLink].paused = false;

    self.actionChangeBlock(GJGCChatInputTextViewRecordActionTypeStart);
    self.stateChangeblock(self, YES);
    [self startAudioRecordingTimer];

}

- (void)animateOut {
    _recordContentView.frame = CGRectZero;
    _animatedIn = false;
    _displayLink.paused = true;
    _currentLevel = 0.0f;
    [UIView animateWithDuration:0.18 animations:^{
        _innerCircleView.transform = CGAffineTransformMakeScale(0.2f, 0.2f);
        _outerCircleView.transform = CGAffineTransformMakeScale(0.2f, 0.2f);
        _innerCircleView.alpha = 0.0f;
        _outerCircleView.alpha = 0.0f;
        self.iconView.alpha = 1.0f;
        _innerIconView.alpha = 0.0f;
    }                completion:^(BOOL finished) {
        if (finished) {
            _overlayWindow.hidden = true;
            _overlayWindow = nil;
        }
    }];
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    if ([super continueTrackingWithTouch:touch withEvent:event]) {
        _lastVelocity = [_panRecognizer velocityInView:self].x;

        if (_processCurrentTouch) {
            CGFloat distance = [touch locationInView:self].x - _touchLocation.x;
            CGFloat value = (-distance) / 100.0f;
            value = MAX(0.0f, MIN(1.0f, value));

            CGFloat velocity = [_panRecognizer velocityInView:self].x;

            if (CACurrentMediaTime() > _animationStartTime + 0.1) {
                CGFloat scale = MAX(0.4f, MIN(1.0f, 1.0f - value));
                if (scale > 0.8f) {
                    scale = 1.0f;
                } else {
                    scale /= 0.8f;
                }
                _innerCircleView.transform = CGAffineTransformMakeScale(scale, scale);
            }

            if (distance < -100.0f) {
                id <ChatInputMicButtonDelegate> delegate = _delegate;
                if ([delegate respondsToSelector:@selector(micButtonInteractionCancelled:)])
                    [delegate micButtonInteractionCancelled:velocity];

                return false;
            }

            id <ChatInputMicButtonDelegate> delegate = _delegate;
            if ([delegate respondsToSelector:@selector(micButtonInteractionUpdate:)])
                [delegate micButtonInteractionUpdate:value];

            return true;
        }
    }

    return false;
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
    if (_processCurrentTouch) {
        self.actionChangeBlock(GJGCChatInputTextViewRecordActionTypeCancel);
        self.stateChangeblock(self, NO);
        [self stopAudioRecordingTimer];
        GJCFAsyncGlobalBackgroundQueueDelay(1, ^{
            id <ChatInputMicButtonDelegate> delegate = _delegate;
            if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
                if ([delegate respondsToSelector:@selector(micButtonInteractionCancelled:)])
                    [delegate micButtonInteractionCancelled:_lastVelocity];
            } else {
                if ([delegate respondsToSelector:@selector(micButtonInteractionCancelled:)])
                    [delegate micButtonInteractionCancelled:_lastVelocity];
            }
        });

    }

    [super cancelTrackingWithEvent:event];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    if (_processCurrentTouch) {
        CGFloat velocity = _lastVelocity;
        id <ChatInputMicButtonDelegate> delegate = _delegate;
        if (velocity < -400.0f) {
            self.actionChangeBlock(GJGCChatInputTextViewRecordActionTypeTooShort);
            self.stateChangeblock(self, NO);
            [self stopAudioRecordingTimer];
            if ([delegate respondsToSelector:@selector(micButtonInteractionCancelled:)])
                [delegate micButtonInteractionCancelled:_lastVelocity];
        } else {
            [self _commitCompleted];
        }
    }

    NSLog(@"endTrackingWithTouch");
    [super endTrackingWithTouch:touch withEvent:event];
}


- (void)recordCancel {
    NSLog(@"recordCancel");
    if (_processCurrentTouch) {
        CGFloat velocity = _lastVelocity;
        id <ChatInputMicButtonDelegate> delegate = _delegate;
        if (velocity < -400.0f) {
            self.actionChangeBlock(GJGCChatInputTextViewRecordActionTypeTooShort);
            self.stateChangeblock(self, NO);
            [self stopAudioRecordingTimer];
            if ([delegate respondsToSelector:@selector(micButtonInteractionCancelled:)])
                [delegate micButtonInteractionCancelled:_lastVelocity];
        } else {
            [self _commitCompleted];
        }
    }
    [self animateOut];
}

- (void)_commitCompleted {
    id <ChatInputMicButtonDelegate> delegate = _delegate;
    self.actionChangeBlock(GJGCChatInputTextViewRecordActionTypeFinish);
    self.stateChangeblock(self, NO);
    if ([delegate respondsToSelector:@selector(micButtonInteractionCompleted:)])
        [delegate micButtonInteractionCompleted:_lastVelocity];

    [self stopAudioRecordingTimer];
}

- (void)panGesture:(UIPanGestureRecognizer *)__unused recognizer {
    NSLog(@"recognizer.state%ld", (long) recognizer.state);
    switch (recognizer.state) {
        case UIGestureRecognizerStateChanged: {
            if (CGPointEqualToPoint(_originCenter, CGPointZero)) {
                _originCenter = self.center;
            }
            CGPoint center = self.center;
            center.x = [recognizer locationInView:self.recordContentView].x;
            self.center = center;
            CGPoint cricleCenter = _innerCircleView.center;
            cricleCenter.x = [recognizer locationInView:self.superview].x;
            _innerCircleView.center = cricleCenter;
            _outerCircleView.center = cricleCenter;
            _innerIconView.center = cricleCenter;
            if (cricleCenter.x < GJCFSystemScreenWidth / 2 + 50) {
                _outerCircleView.image = [self innerCircleImage:[UIColor colorWithRed:1.000 green:0.165 blue:0.169 alpha:1.000]];
                _cancelTipLabel.hidden = NO;
                _cancelRecordingView.hidden = NO;
                _recordDurationLabel.hidden = YES;
                _recordIndicatorView.hidden = YES;
                _slideToCancelLabel.hidden = YES;
                _slideToCancelArrow.hidden = YES;
            } else {
                _outerCircleView.image = [self innerCircleImage:[UIColor colorWithRed:0.243 green:0.820 blue:0.000 alpha:1.000]];
                _cancelTipLabel.hidden = YES;
                _cancelRecordingView.hidden = YES;

                _recordDurationLabel.hidden = NO;
                _recordIndicatorView.hidden = NO;
                _slideToCancelLabel.hidden = NO;
                _slideToCancelArrow.hidden = NO;
            }
        }
            break;
        case UIGestureRecognizerStateEnded: {
            if (CGPointEqualToPoint(_originCenter, CGPointZero)) {
                _originCenter = self.center;
            }
            self.center = _originCenter;
            CGPoint cricleCenter = [recognizer locationInView:self.superview];

            if (cricleCenter.x < GJCFSystemScreenWidth / 2 + 50) {
                self.actionChangeBlock(GJGCChatInputTextViewRecordActionTypeCancel);
                self.stateChangeblock(self, NO);
            } else {
                self.actionChangeBlock(GJGCChatInputTextViewRecordActionTypeFinish);
                self.stateChangeblock(self, NO);
            }
        }
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed: {
            self.actionChangeBlock(GJGCChatInputTextViewRecordActionTypeCancel);
            self.stateChangeblock(self, NO);

            id <ChatInputMicButtonDelegate> delegate = _delegate;
            if ([delegate respondsToSelector:@selector(micButtonInteractionCancelled:)])
                [delegate micButtonInteractionCancelled:0];
        }
            break;
        default:
            break;
    }
}


- (void)displayLinkUpdate {
    NSTimeInterval t = CACurrentMediaTime();
    if (t > _animationStartTime) {
        _currentLevel = _currentLevel * 0.8f + _inputLevel * 1.f;

        CGFloat scale = outerCircleMinScale + _currentLevel * (1.0f - outerCircleMinScale);
        _outerCircleView.transform = CGAffineTransformMakeScale(scale, scale);
    }
}

- (void)addMicLevel:(CGFloat)level {
    _inputLevel = level;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    NSLog(@"otherGestureRecognizer %@", NSStringFromClass([otherGestureRecognizer class]));
    NSLog(@"gestureRecognizer %@", NSStringFromClass([gestureRecognizer class]));
    return YES;
}

- (void)configStateChangeEventBlock:(ChatInputMicButtonStateChangeEventBlock)eventBlock {
    if (self.stateChangeblock) {
        self.stateChangeblock = nil;
    }
    self.stateChangeblock = eventBlock;
}


@end
