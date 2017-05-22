//
//  KQXPasswordInputController.m
//  KQXPasswordInput
//
//  Created by Qingxu Kuang on 16/8/23.
//  Copyright © 2016年 Asahi Kuang. All rights reserved.
//

@interface KQXPasswordInputController () <CAAnimationDelegate> {
    CAShapeLayer *shapeLayer;
}
@property(weak, nonatomic) IBOutlet UIButton *closeButton;
@property(weak, nonatomic) IBOutlet UILabel *titleLabel;
@property(weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property(weak, nonatomic) IBOutlet UILabel *moneyLabel;
@property(weak, nonatomic) IBOutlet UITextField *inputTextField;
@property(weak, nonatomic) IBOutlet UIView *symbolView;
@property(weak, nonatomic) IBOutlet UIView *bodyView;
@property(weak, nonatomic) IBOutlet UIView *paySuccessView;

@property(assign, nonatomic) KQXPasswordInputStyle style;

@property(strong, nonatomic) NSMutableArray *spotArray;
@property(strong, nonatomic) NSMutableArray *circleArray;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *bodyCenterToX;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *resultViewToBodyRight;

@property(strong, nonatomic) KQXPasswordInputTipView *tip;

@property(nonatomic, assign) CGFloat margin;

@property(weak, nonatomic) IBOutlet NSLayoutConstraint *bodyViewHeightConstraint;
@end

@implementation KQXPasswordInputController

#define RGB(r, g, b) [UIColor colorWithRed:r/255.f green:g/255.f blue:b/255.f alpha:1.f]

#define k_BODY_VIEW_WIDTH 270.f
#define K_NUMBER_PASSWORD (int)4
#define K_SPOT_RADIUS 12.5

#pragma mark - lazy loading

- (NSMutableArray *)spotArray {
    if (!_spotArray) {
        _spotArray = @[].mutableCopy;
    }
    return _spotArray;
}

- (NSMutableArray *)circleArray {
    if (!_circleArray) {
        _circleArray = @[].mutableCopy;
    }
    return _circleArray;
}

- (KQXPasswordInputTipView *)tip {
    if (!_tip) {
        _tip = [KQXPasswordInputTipView sharedTipViewWithFrame:CGRectMake(0.f, -64.f, [UIScreen mainScreen].bounds.size.width, 64.f)];
    }
    return _tip;
}

#pragma mark --

#pragma mark - initial method

- (instancetype)init {
    self = [super init];
    if (self) {
        [NSException raise:@"请使用initWithPasswordInputStyle:构造方法" format:@"!!!"];
    }
    return self;
}

- (instancetype)initWithPasswordInputStyle:(KQXPasswordInputStyle)style {
    self = [super init];
    if (self) {
        [self setModalPresentationStyle:UIModalPresentationOverCurrentContext];
        [self setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
        _style = style;
    }
    return self;
}

+ (instancetype)passwordInputViewWithStyle:(KQXPasswordInputStyle)style {
    return [[self alloc] initWithPasswordInputStyle:style];
}

#pragma mark --

#pragma mark - life cycle

- (void)viewDidLoad {

    [self drawCircle];
    [self drawSpot];
    [self observerAdded];

    if (_style == KQXPasswordInputStyleWithMoney) {
        [self updateConstraints];
    }
    [super viewDidLoad];

    self.titleLabel.text = LMLocalizedString(@"Set Payment Password", nil);
    self.descriptionLabel.text = LMLocalizedString(@"Wallet Enter 4 Digits", nil);
}

- (void)paySuccess {
    
    // circle path
    CGPoint center = CGPointMake(self.paySuccessView.frame.size.width / 2, self.paySuccessView.frame.size.height / 2);// circle
    float radius = self.paySuccessView.frame.size.width / 2;// raius

    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:M_PI * 3 / 2 endAngle:M_PI * 7 / 2 clockwise:YES];// Clockwise
    path.lineCapStyle = kCGLineCapRound; // Line corner
    path.lineJoinStyle = kCGLineCapRound; // End point processing

    // Check the path
    UIBezierPath *linePath = [UIBezierPath bezierPath];
    [linePath moveToPoint:CGPointMake(center.x - radius / 2, center.y)];
    [linePath addLineToPoint:CGPointMake(center.x, center.y + radius / 2)];
    [linePath addLineToPoint:CGPointMake(center.x + radius * 2 / 3, center.y - radius / 3)];
    // Stitching two paths
    [path appendPath:linePath];

    shapeLayer = [CAShapeLayer layer];
    shapeLayer.lineJoin = kCALineJoinRound;
    shapeLayer.lineCap = kCALineCapRound;
    shapeLayer.path = path.CGPath;
    shapeLayer.strokeColor = [UIColor blueColor].CGColor;// Line color
    shapeLayer.fillColor = [UIColor clearColor].CGColor;// add color
    shapeLayer.lineWidth = 1.7;
    shapeLayer.strokeStart = 0.0;
    shapeLayer.strokeEnd = 0.0;
    [self.paySuccessView.layer addSublayer:shapeLayer];
}

- (void)startCircleAnimation {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    if (shapeLayer.strokeEnd == 1.0) {
        [animation setFromValue:@1.0];
        [animation setToValue:@0.0];
    } else {
        [animation setFromValue:@0.0];
        [animation setToValue:@1.0];
    }
    [animation setDuration:4];
    animation.removedOnCompletion = NO;
    animation.delegate = self;
    animation.fillMode = kCAFillModeForwards;
    [shapeLayer addAnimation:animation forKey:@"Circle"];
}


// update constant
- (void)changeToSuccess {
    self.bodyCenterToX.constant = -DEVICE_SIZE.width;
}

- (void)viewWillDisappear:(BOOL)animated {

    [self clearContents];

    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {

    [_inputTextField becomeFirstResponder];

    [super viewDidAppear:animated];
}

- (void)viewDidLayoutSubviews {

    if (self.margin == 0) {
        self.margin = self.bodyView.left;
        self.resultViewToBodyRight.constant = self.margin * 2;
    }
    CGFloat symbol_total = (k_BODY_VIEW_WIDTH - 100);
    CGFloat spot_halfWidth = K_SPOT_RADIUS / 2;
    CGFloat spot_x = symbol_total / K_NUMBER_PASSWORD;
    CGFloat symbolView_h = CGRectGetHeight(_symbolView.frame);

    // circle layout
    for (int i = 0; i < [self.spotArray count]; i++) {
        CAShapeLayer *spot = [self.spotArray objectAtIndexCheck:i];
        CAShapeLayer *circle = [self.circleArray objectAtIndexCheck:i];
        [spot setPosition:CGPointMake((spot_x / 2 - spot_halfWidth) + i * spot_x, symbolView_h / 2 - spot_halfWidth)];
        [circle setPosition:CGPointMake((spot_x / 2 - spot_halfWidth) + i * spot_x, symbolView_h / 2 - spot_halfWidth)];
    }

    [super viewDidLayoutSubviews];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:_inputTextField];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Methods

- (void)dismissWithClosed:(BOOL)isClosed {

    [_inputTextField resignFirstResponder];
    [self dismissViewControllerAnimated:NO completion:^{
        if (isClosed) {
            if ([self.delegate respondsToSelector:@selector(passwordInputControllerDidClosed)]) {
                [self.delegate passwordInputControllerDidClosed];
            }
            return;
        }
        if ([self.delegate respondsToSelector:@selector(passwordInputControllerDidDismissed)]) {
            [self.delegate passwordInputControllerDidDismissed];
        }
    }];
}

- (void)setTitleString:(NSString *)title descriptionString:(NSString *)description moneyString:(NSString *)money {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.titleLabel setText:title];
        [self.descriptionLabel setText:description];
        [self.moneyLabel setText:money];

        // refresh
        [self.view layoutIfNeeded];
    });
}

- (void)showErrorTipWithString:(NSString *)tip {
    [self.tip showTipViewWithStyle:KQXPasswordInputTipViewStyleError tip:tip];
}

- (void)clearContents {
    [_inputTextField setText:nil];
    for (CAShapeLayer *spot in self.spotArray) {
        [spot setHidden:YES];
    }
}

- (void)updateConstraints {
    [_moneyLabel setHidden:NO];
    _bodyViewHeightConstraint.constant = 181;

}

- (void)observerAdded {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inputContentsChanged:) name:UITextFieldTextDidChangeNotification object:_inputTextField];
}

- (void)drawSpot {
    for (int i = 0; i < K_NUMBER_PASSWORD; i++) {
        UIBezierPath *spotBezier = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0.f, 0.f, K_SPOT_RADIUS, K_SPOT_RADIUS)];
        CAShapeLayer *spot = [CAShapeLayer layer];
        [spot setPath:spotBezier.CGPath];
        [spot setFillColor:RGB(56, 66, 95).CGColor];
        [spot setHidden:YES];
        [self.spotArray objectAddObject:spot];
        [_symbolView.layer insertSublayer:spot atIndex:0];
    }
}

- (void)drawCircle {
    for (int i = 0; i < K_NUMBER_PASSWORD; i++) {
        UIBezierPath *spotBezier = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0.f, 0.f, K_SPOT_RADIUS, K_SPOT_RADIUS)];
        CAShapeLayer *spot = [CAShapeLayer layer];
        [spot setPath:spotBezier.CGPath];
        [spot setStrokeColor:RGB(56, 66, 95).CGColor];
        [spot setFillColor:[UIColor clearColor].CGColor];
        [spot setLineWidth:1.f];
        [self.circleArray objectAddObject:spot];
        [_symbolView.layer insertSublayer:spot atIndex:0];
    }
}

#pragma mark - selectors

- (void)inputContentsChanged:(NSNotification *)notification {
    UITextField *textField = notification.object;
    NSInteger length = [textField.text length];
    if (length > K_NUMBER_PASSWORD) {
        // Enter more than 4 truncated text
        textField.text = [textField.text substringToIndex:K_NUMBER_PASSWORD];
        return;
    };
    [self.spotArray enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        CAShapeLayer *spot = (CAShapeLayer *) obj;
        spot.hidden = idx < length ? NO : YES;
    }];

    if (length == K_NUMBER_PASSWORD) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self clearContents];
        });
        self.fillCompleteBlock(textField.text);
    }
}

- (IBAction)dismiss:(id)sender {
    [self dismissWithClosed:YES];
}

#pragma mark -- CAAnimationDelegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    [self.paySuccessView.layer removeAllAnimations];
    [self dismiss:nil];
}

@end
