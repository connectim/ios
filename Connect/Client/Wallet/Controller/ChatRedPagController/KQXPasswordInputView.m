//
//  KQXPasswordInputView.m
//  KQXPasswordInputViewDemo
//
//  Created by Qingxu Kuang on 16/7/31.
//  Copyright © 2016年 Asahi Kuang. All rights reserved.
//

#import "KQXPasswordInputView.h"

@interface KQXPasswordInputView ()
@property(nonatomic, weak) IBOutlet UIView *bodyView;
@property(weak, nonatomic) IBOutlet UITextField *inputField;
@property(weak, nonatomic) IBOutlet UIView *symbolView;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *descriptionString;
@property(weak, nonatomic) IBOutlet UILabel *titleLabel;
@property(weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property(weak, nonatomic) IBOutlet UIButton *okButton;
@property(weak, nonatomic) IBOutlet UIButton *cancelButton;
@property(strong, nonatomic) IBOutletCollection(UIView) NSArray *separatLines;
@property(nonatomic, strong) NSMutableArray *spotArray;
@property(nonatomic, copy) NSString *password;
@property(nonatomic, weak) IBOutlet UILabel *moneyLabel;
@property(nonatomic, assign) kqxInputViewStyle style;
@property(nonatomic, strong) UITapGestureRecognizer *tap;
@property(nonatomic, strong) KQXPasswordInputTipView *tipView;
@property(strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *textFieldViewToFuncConses;

@end

@implementation KQXPasswordInputView

#define WIDTH(view)  CGRectGetWidth(view.frame)
#define HEIGHT(view) CGRectGetHeight(view.frame)
#define kKeyboardHeight 216.f
#define kBodyViewWidth 270.f
#define kSpotWidth 12.f
#define kTipViewHeight 64.f
#define kNumberOfSpot 6 // pass

#pragma mark - lazy loading

- (NSMutableArray *)spotArray {
    if (!_spotArray) {
        _spotArray = @[].mutableCopy;
    }
    return _spotArray;
}

- (KQXPasswordInputTipView *)tipView {
    if (!_tipView) {
        _tipView = [KQXPasswordInputTipView sharedTipViewWithFrame:CGRectMake(0.f, -kTipViewHeight, WIDTH(self), kTipViewHeight)];
    }
    return _tipView;
}

#pragma mark --

#pragma mark - initial methods

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self = nil;
    [NSException raise:@"请使用sharedPasswordInputViewWithFrame:tittle:description:构造方法" format:@""];
    return self;
}

- (instancetype)initWithFramePrivate:(CGRect)frame title:(NSString *)title description:(NSString *)description style:(kqxInputViewStyle)style {
    self = [[NSBundle mainBundle] loadNibNamed:@"KQXPasswordInputView" owner:nil options:nil].firstObject;
    if (self) {
        _title = title;
        _descriptionString = description;
        _style = style;

        [self setFrame:frame];
        [self elementsOriginalConfigure];
        [self observerAdded];
        [self tapGestureAdded];
        [self configurationForStyle];
    }
    return self;
}

+ (instancetype)sharedPasswordInputViewWithFrame:(CGRect)frame tittle:(NSString *)title description:(NSString *)description style:(kqxInputViewStyle)style {
    static KQXPasswordInputView *inputView = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        inputView = [[self alloc] initWithFramePrivate:frame title:title description:description style:style];
    });
    return inputView;
}

- (void)layoutSubviews {
    [_inputField becomeFirstResponder];

    CGFloat symbol_total = (kBodyViewWidth - 30);
    CGFloat spot_halfWidth = kSpotWidth / 2;
    CGFloat spot_x = symbol_total / kNumberOfSpot;
    CGFloat symbolView_h = HEIGHT(_symbolView);

    // point
    for (CAShapeLayer *spot in self.spotArray) {
        NSInteger idx = [self.spotArray indexOfObject:spot];
        [spot setPosition:CGPointMake((spot_x / 2 - spot_halfWidth) + idx * spot_x, symbolView_h / 2 - spot_halfWidth)];
    }

    [super layoutSubviews];
}

- (void)dealloc {
    self.bodyView = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:_inputField];
}

#pragma mark --

#pragma mark - methods

- (void)observerAdded {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inputContentsChanged:) name:UITextFieldTextDidChangeNotification object:_inputField];
}

- (void)tapGestureAdded {
    _tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissTapHandler:)];
    [self addGestureRecognizer:_tap];
}

- (void)elementsOriginalConfigure {
    [_bodyView setTransform:CGAffineTransformMakeTranslation(0.f, -HEIGHT(self))];
    [_bodyView.layer setCornerRadius:16.f];
    [_bodyView.layer setMasksToBounds:YES];

    [_symbolView.layer setBorderWidth:0.7f];
    [_symbolView.layer setBorderColor:[UIColor colorWithRed:202 / 255.f green:202 / 255.f blue:202 / 255.f alpha:1.f].CGColor];

    [_inputField setHidden:YES];

    [_titleLabel setText:_title];
    [_descriptionLabel setText:_descriptionString];

    [self drawLines];
    [self drawSpote];
}

- (void)configurationForStyle {
    if (_style == KQXPasswordInputViewStyleWithFunctionButton) {
        [_moneyLabel setHidden:YES];
        [self makeFunctionButtonHidden:NO];
        [self makeTextFieldViewTofuncButtonConsShorter:NO];
    } else {
        [_moneyLabel setHidden:NO];
        [self makeFunctionButtonHidden:YES];
        [self makeTextFieldViewTofuncButtonConsShorter:YES];


    }
}

- (void)drawLines {
    UIBezierPath *bezier = [UIBezierPath bezierPath];
    CGFloat symbol_total = (kBodyViewWidth - 30);
    for (int i = 1; i < kNumberOfSpot; i++) {
        [bezier moveToPoint:CGPointMake((symbol_total / kNumberOfSpot) * i, 0.f)];
        [bezier addLineToPoint:CGPointMake((symbol_total / kNumberOfSpot) * i, HEIGHT(_symbolView))];
    }
    [bezier closePath];

    CAShapeLayer *shape = [CAShapeLayer layer];
    [shape setFrame:_symbolView.bounds];
    [shape setLineWidth:0.5f];
    [shape setPath:bezier.CGPath];
    [shape setStrokeColor:[UIColor colorWithRed:202 / 255.f green:202 / 255.f blue:202 / 255.f alpha:1.f].CGColor];

    [_symbolView.layer insertSublayer:shape atIndex:0];
}

- (void)drawSpote {

    for (int i = 0; i < kNumberOfSpot; i++) {
        CAShapeLayer *shape = [CAShapeLayer layer];
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0.f, 0.f, kSpotWidth, kSpotWidth)];
        [shape setPath:bezierPath.CGPath];
        [shape setFillColor:[UIColor darkGrayColor].CGColor];
        [_symbolView.layer insertSublayer:shape atIndex:0];
        [shape setHidden:YES];
        [self.spotArray objectAddObject:shape];
    }
}

- (void)changeStyle:(kqxInputViewStyle)style {
    _style = style;
    [self configurationForStyle];
}

- (void)updateTitle:(NSString *)title description:(NSString *)descriptionString {
    _title = title;
    _descriptionString = descriptionString;
    [_titleLabel setText:_title];
    [_descriptionLabel setText:_descriptionString];
    [self clearContents];
}

- (void)updateTitle:(NSString *)title description:(NSString *)descriptionString moneyValueString:(NSString *)moneyString {
    [self updateTitle:title description:descriptionString];
    [_moneyLabel setText:moneyString];
}

- (void)clearContents {
    [_inputField setText:nil];
    for (CAShapeLayer *symbol in self.spotArray) {
        [symbol setHidden:YES];
    }
}

- (void)showPasswordInputView {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    [keyWindow addSubview:self];
    [self scaleAnimationForBodyViewShow];
}

- (void)dismissPasswordInputView {
//
    [self.spotArray enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        [obj setHidden:YES];
    }];
    [self scaleAnimationForBodyViewDismiss];
}

- (void)scaleAnimationForBodyViewShow {
    [UIView animateWithDuration:0.4f delay:0.f usingSpringWithDamping:0.8f initialSpringVelocity:5.f options:UIViewAnimationOptionCurveLinear animations:^{
        [_bodyView setTransform:CGAffineTransformMakeTranslation(0.f, 0.f)];
    }                completion:^(BOOL finished) {
    }];
}

- (void)scaleAnimationForBodyViewDismiss {
    [UIView animateWithDuration:0.4f delay:0.f usingSpringWithDamping:0.8f initialSpringVelocity:5.f options:UIViewAnimationOptionCurveLinear animations:^{
        [_bodyView setTransform:CGAffineTransformMakeTranslation(0.f, -HEIGHT(self))];
    }                completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];


}

- (void)makeFunctionButtonHidden:(BOOL)hidden {
    [_okButton setHidden:hidden];
    [_cancelButton setHidden:hidden];
    for (UIView *separatLine in _separatLines) {
        [separatLine setHidden:hidden];
    }
}

- (void)makeTextFieldViewTofuncButtonConsShorter:(BOOL)shorter {
    if (shorter) {
        for (NSLayoutConstraint *cons in _textFieldViewToFuncConses) {
            cons.constant = -30;
        }
    } else {
        for (NSLayoutConstraint *cons in _textFieldViewToFuncConses) {
            cons.constant = 10;
        }
    }
}

// filter gesture
- (CGFloat)bodyView_min_x {
    return CGRectGetMinX(_bodyView.frame);
}

- (CGFloat)bodyView_min_y {
    return CGRectGetMinY(_bodyView.frame);
}

- (CGFloat)bodyView_max_x {
    return CGRectGetMaxX(_bodyView.frame);
}

- (CGFloat)bodyView_max_y {
    return CGRectGetMaxY(_bodyView.frame);
}

// tip view
- (void)showSuccessTip:(NSString *)successString {
    [self.tipView showTipViewWithStyle:KQXPasswordInputTipViewStyleRight tip:successString];
    [self tipViewAnimation];
    [self addSubview:self.tipView];
}

- (void)showErrorTip:(NSString *)errorString {
    [self.tipView showTipViewWithStyle:KQXPasswordInputTipViewStyleError tip:errorString];
    [self tipViewAnimation];
    [self addSubview:self.tipView];
}

- (void)tipViewAnimation {
    [UIView animateWithDuration:0.3f animations:^{
        [self.tipView setTransform:CGAffineTransformMakeTranslation(0.f, kTipViewHeight)];
        [self hideTipView];
    }                completion:^(BOOL finished) {

    }];
}

- (void)tipViewDismissAnimation {
    [UIView animateWithDuration:0.3f animations:^{
        [self.tipView setTransform:CGAffineTransformMakeTranslation(0.f, 0.f)];
    }                completion:^(BOOL finished) {
        [self.tipView removeFromSuperview];
    }];
}

- (void)hideTipView {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self tipViewDismissAnimation];
    });
}

#pragma mark --

#pragma mark - selectors

- (void)dismissTapHandler:(UITapGestureRecognizer *)tap {
    CGPoint tapPoint = [tap locationInView:self];
    CGFloat tap_x = tapPoint.x;
    CGFloat tap_y = tapPoint.y;
    BOOL outOfBodyBounds = (tap_x > [self bodyView_min_x] && tap_y > [self bodyView_min_y]) && (tap_x < [self bodyView_max_x] && tap_y < [self bodyView_max_y]);
    if (_style == KQXPasswordInputViewStyleWithFunctionButton || outOfBodyBounds) return;
    [self dismissPasswordInputView];
}

- (void)inputContentsChanged:(NSNotification *)notification {
    UITextField *textFiled = notification.object;
    NSInteger length = [textFiled.text length];
    if (length >= kNumberOfSpot) {
        [_okButton setEnabled:YES];
    } else {
        [_okButton setEnabled:NO];
    }
    if (length > kNumberOfSpot) {
        textFiled.text = [textFiled.text substringToIndex:kNumberOfSpot];
        return;
    };
    [self.spotArray enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        CAShapeLayer *spot = (CAShapeLayer *) obj;
        spot.hidden = idx < length ? NO : YES;
    }];
    _password = textFiled.text;
    if (length == kNumberOfSpot && _style == KQXPasswordInputViewStyleWithoutFunctionButton) {
        self.fillCompleteBlock(_password);
    }
}

- (IBAction)close:(UIButton *)sender {
    [UIView animateWithDuration:0.5f delay:0.f usingSpringWithDamping:0.8f initialSpringVelocity:0.f options:UIViewAnimationOptionCurveLinear animations:^{
        if (sender.tag == 1) return;
        [sender setTransform:CGAffineTransformMakeRotation(-M_PI)];
    }                completion:^(BOOL finished) {
        [sender setTransform:CGAffineTransformMakeRotation(0)];
        [self dismissPasswordInputView];
    }];
}

- (IBAction)ensureToComplete:(UIButton *)sender {
    if ([_inputField.text length] < kNumberOfSpot) return;
    self.fillCompleteBlock(_password);
}

#pragma mark --


@end
