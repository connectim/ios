//
//  InputPayPassView.m
//  Connect
//
//  Created by MoHuilin on 2016/11/9.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "InputPayPassView.h"
#import "PassInputFieldView.h"
#import "JxbLoadingView.h"
#import "LocalAuthentication/LAContext.h"
#import "WJTouchID.h"


#define PerAnimationDuration 2.0


@interface InputPayPassView () <PassInputFieldViewDelegate, WJTouchIDDelegate>
@property(strong, nonatomic) UIView *contentView;
@property(strong, nonatomic) UILabel *titleLabel;
@property(strong, nonatomic) UIView *lineView;
@property(nonatomic, copy) NSString *fristPass; //The first time you enter the password
@property(nonatomic, strong) CAShapeLayer *walletLayer;
@property(nonatomic, strong) PassInputFieldView *secondPassView;
@property(nonatomic, strong) PassInputFieldView *fristPassView;
@property(nonatomic, strong) PassInputFieldView *payPassView;
@property(nonatomic, copy) void (^completeBlock)(InputPayPassView *passView, NSError *error, BOOL result);
@property(nonatomic, copy) void (^forgetPassBlock)();
@property(nonatomic, copy) void (^closeBlock)();

@property(strong, nonatomic) UIView *bottomView;
@property(strong, nonatomic) UIView *passInputView;
@property(strong, nonatomic) UILabel *passStatusLabel;


@property(nonatomic, strong) UIView *animationContentView;
@property(strong, nonatomic) JxbLoadingView *animationView;
@property(strong, nonatomic) UILabel *statusLabel;
@property(strong, nonatomic) UILabel *displayLbale;

@property(strong, nonatomic) UIView *passErrorContentView;
@property(strong, nonatomic) UILabel *passErrorTipLabel;
@property(strong, nonatomic) UIButton *forgetPassBtn;
@property(strong, nonatomic) UIButton *retryBtn;
@property(strong, nonatomic) UIButton *retryNewBtn;

@property(assign, nonatomic) BOOL isPassTag;

@end

@implementation InputPayPassView
- (IBAction)closeView:(id)sender {
    self.backgroundColor = [UIColor clearColor];
    [UIView animateWithDuration:0.3 animations:^{
        self.top = DEVICE_SIZE.height;
    }                completion:^(BOOL finished) {
        if (self.closeBlock) {
            self.closeBlock();
        }
        [self removeFromSuperview];
    }];
}

- (IBAction)retry:(id)sender {
    self.titleLabel.text = LMLocalizedString(@"Wallet Enter your PIN", nil);
    [self.bottomView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView.mas_left);
    }];
    [UIView animateWithDuration:0.3 animations:^{
        [self.contentView layoutIfNeeded];
    }];
    [self.payPassView clearAll];
    [self.payPassView becomeFirstResponder];
}

- (IBAction)NewRetry:(id)sender {
    [self.retryNewBtn removeFromSuperview];
    self.retryBtn = nil;
    [self.displayLbale removeFromSuperview];
    self.displayLbale = nil;
    self.titleLabel.text = LMLocalizedString(@"Wallet Enter your PIN", nil);
    self.statusLabel.text = LMLocalizedString(@"Set Set Payment Password", nil);
    self.style = InputPayPassViewSetPass;

}

- (IBAction)forgetPass:(id)sender {
    [UIView animateWithDuration:0.3 animations:^{
        self.top = DEVICE_SIZE.height;
        [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow];

    }                completion:^(BOOL finished) {
        if (self.forgetPassBlock) {
            self.forgetPassBlock();
        }
        [self removeFromSuperview];


    }];
}

+ (InputPayPassView *)showInputPayPassViewWithStyle:(InputPayPassViewStyle)style complete:(void (^)(InputPayPassView *passView, NSError *error, BOOL result))complete {
    InputPayPassView *passView = [[InputPayPassView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    passView.style = style;
    passView.completeBlock = complete;
    passView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:passView];
    return passView;
}

+ (InputPayPassView *)showInputPayPassWithComplete:(void (^)(InputPayPassView *passView, NSError *error, BOOL result))complete {
    InputPayPassView *passView = [[InputPayPassView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    if ([[MMAppSetting sharedSetting] getPayPass]) {
        passView.style = InputPayPassViewVerfyPass;
        __weak __typeof(&*passView) weakSelf = passView;
        passView.requestCallBack = ^(NSError *error) {
            [weakSelf showResultStatusWithError:error];
        };
    } else {
        passView.style = InputPayPassViewSetPass;
    }
    passView.completeBlock = complete;
    passView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:passView];
    return passView;
}

+ (InputPayPassView *)showInputPayPassWithComplete:(void (^)(InputPayPassView *passView, NSError *error, BOOL result))complete forgetPassBlock:(void (^)())forgetPassBlock closeBlock:(void (^)())closeBlock {
    InputPayPassView *passView = [[InputPayPassView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
#pragma mark - The verification password is 4 digits long
    if ([[MMAppSetting sharedSetting] getPayPass].length == MAX_PASS_LEN) {
        passView.style = InputPayPassViewVerfyPass;
        __weak __typeof(&*passView) weakSelf = passView;
        passView.requestCallBack = ^(NSError *error) {
            [weakSelf showResultStatusWithError:error];
        };
    } else {
        passView.style = InputPayPassViewSetPass;
    }
    passView.completeBlock = complete;
    passView.forgetPassBlock = forgetPassBlock;
    passView.closeBlock = closeBlock;
    passView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:passView];
    return passView;
}


- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupSubviews];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupSubviews];
    }
    return self;
}

- (void)setupSubviews {
    self.contentView = [[UIView alloc] init];
    self.contentView.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.contentView];
    [_contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.left.right.equalTo(self);
        make.height.mas_equalTo(AUTO_HEIGHT(880));
    }];

    UIButton *closeBtn = [[UIButton alloc] init];
    [closeBtn addTarget:self action:@selector(closeView:) forControlEvents:UIControlEventTouchUpInside];
    [closeBtn setImage:[UIImage imageNamed:@"cancel_grey"] forState:UIControlStateNormal];
    [self.contentView addSubview:closeBtn];
    [closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(AUTO_WIDTH(20));
        make.top.equalTo(self.contentView).offset(AUTO_HEIGHT(10));
        make.size.mas_equalTo(CGSizeMake(AUTO_WIDTH(88), AUTO_HEIGHT(88)));
    }];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = LMLocalizedString(@"Set Payment Password", nil);
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.titleLabel];
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(closeBtn);
        make.centerX.equalTo(self.contentView);
    }];

    self.lineView = [[UIView alloc] init];
    self.lineView.backgroundColor = LMBasicLineViewColor;
    [self.contentView addSubview:self.lineView];
    [_lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(closeBtn.mas_bottom).offset(AUTO_HEIGHT(10));
        make.left.right.equalTo(self.contentView);
        make.height.mas_equalTo(0.5);
    }];

    // enter password
    self.bottomView = [[UIView alloc] init];
    [self.contentView addSubview:self.bottomView];
    [_bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.lineView.mas_bottom);
        make.left.equalTo(self.contentView);
        make.width.mas_equalTo(DEVICE_SIZE.width);
        make.bottom.equalTo(self.contentView);
    }];

    self.passInputView = [[UIView alloc] init];
    [self.bottomView addSubview:self.passInputView];
    [_passInputView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bottomView.mas_top).offset(AUTO_HEIGHT(147));
        make.left.equalTo(self.bottomView.mas_left);
        make.height.mas_equalTo(AUTO_HEIGHT(80));
        make.width.mas_equalTo(DEVICE_SIZE.width);
    }];

    self.passStatusLabel = [[UILabel alloc] init];
    self.passStatusLabel.textAlignment = NSTextAlignmentCenter;
    self.passStatusLabel.numberOfLines = 0;
    [self.bottomView addSubview:self.passStatusLabel];
    [_passStatusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.passInputView.mas_bottom).offset(AUTO_HEIGHT(80));
        make.centerX.equalTo(self.bottomView);
    }];



    // status
    self.animationContentView = [[UIView alloc] init];
    [self.contentView addSubview:self.animationContentView];
    [_animationContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bottomView);
        make.left.equalTo(self.bottomView.mas_right);
        make.width.equalTo(self.bottomView);
        make.height.equalTo(self.bottomView);
    }];

    self.animationView = [[JxbLoadingView alloc] init];
    [self.animationContentView addSubview:self.animationView];
    self.animationView.lineWidth = 4;
    self.animationView.strokeColor = LMBasicBlue;

    [_animationView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.animationContentView.mas_top).offset(AUTO_HEIGHT(150));
        make.centerX.equalTo(self.animationContentView);
        make.size.mas_equalTo(CGSizeMake(AUTO_WIDTH(100), AUTO_HEIGHT(100)));
    }];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 0;
    [self.animationContentView addSubview:self.statusLabel];
    [_statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.animationView.mas_bottom).offset(AUTO_HEIGHT(50));
        make.centerX.equalTo(self.animationContentView);
        make.left.right.equalTo(self.animationContentView);
    }];

    // error
    self.passErrorContentView = [[UIView alloc] init];
    [self.contentView addSubview:self.passErrorContentView];
    [_passErrorContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bottomView);
        make.left.equalTo(self.bottomView.mas_right);
        make.width.equalTo(self.bottomView);
        make.height.equalTo(self.bottomView);
    }];

    self.passErrorTipLabel = [[UILabel alloc] init];
    self.passErrorTipLabel.text = LMLocalizedString(@"Wallet Payment Password is incorrect", nil);
    self.passErrorTipLabel.textAlignment = NSTextAlignmentCenter;
    [self.passErrorContentView addSubview:self.passErrorTipLabel];
    [_passErrorTipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.passErrorContentView.mas_top).offset(AUTO_HEIGHT(140));
        make.centerX.equalTo(self.animationContentView);
        make.left.right.equalTo(self.animationContentView);
    }];

    self.forgetPassBtn = [[UIButton alloc] init];
    [self.forgetPassBtn setTitle:LMLocalizedString(@"Wallet Forget Password", nil) forState:UIControlStateNormal];
    self.forgetPassBtn.titleLabel.numberOfLines = 0;
    self.forgetPassBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.forgetPassBtn addTarget:self action:@selector(forgetPass:) forControlEvents:UIControlEventTouchUpInside];
    [self.passErrorContentView addSubview:self.forgetPassBtn];
    [_forgetPassBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.passErrorTipLabel.mas_bottom).offset(AUTO_HEIGHT(20));
        make.centerX.equalTo(self.passErrorContentView);
    }];

    self.retryBtn = [[UIButton alloc] init];
    [self.retryBtn setTitle:LMLocalizedString(@"Wallet Retry", nil) forState:UIControlStateNormal];
    [self.retryBtn addTarget:self action:@selector(retry:) forControlEvents:UIControlEventTouchUpInside];
    [self.passErrorContentView addSubview:self.retryBtn];
    [_retryBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.forgetPassBtn.mas_bottom).offset(AUTO_HEIGHT(60));
        make.centerX.equalTo(self.passErrorContentView);
    }];

    self.style = InputPayPassViewVerfyPass;
    self.contentView.alpha = 0.98;
    self.titleLabel.text = LMLocalizedString(@"Set Payment Password", nil);
    self.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(36)];
    self.titleLabel.textColor = GJCFQuickHexColor(@"161A21");
    self.statusLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.statusLabel.textColor = GJCFQuickHexColor(@"B3B5BC");
    self.passStatusLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.passStatusLabel.textColor = GJCFQuickHexColor(@"B3B5BC");
    self.passErrorTipLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.passErrorTipLabel.textColor = GJCFQuickHexColor(@"B3B5BC");
    [self.retryBtn.titleLabel setFont:[UIFont boldSystemFontOfSize:FONT_SIZE(36)]];
    [self.retryBtn setTitleColor:GJCFQuickHexColor(@"007AFF") forState:UIControlStateNormal];
    [self.forgetPassBtn.titleLabel setFont:[UIFont boldSystemFontOfSize:FONT_SIZE(28)]];
    [self.forgetPassBtn setTitleColor:GJCFQuickHexColor(@"007AFF") forState:UIControlStateNormal];

}

- (void)showResultStatusWithError:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    [GCDQueue executeInMainQueue:^{
        if (error) {
            weakSelf.titleLabel.text = LMLocalizedString(@"Wallet Pay Faied", nil);
            _walletLayer.speed = 0;
            [_walletLayer removeFromSuperlayer];
            weakSelf.statusLabel.hidden = NO;
            weakSelf.statusLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Error code Domain Pelese try later", nil), (int) error.code, [LMErrorCodeTool showToastErrorType:ToastErrorTypeWallet withErrorCode:error.code withUrl:@""]];
            [weakSelf.animationView finishFailure:nil];
        } else {
            weakSelf.statusLabel.text = LMLocalizedString(@"Wallet Payment Successful", nil);
            weakSelf.titleLabel.text = LMLocalizedString(@"Wallet Payment Successful", nil);
            [weakSelf.animationView finishSuccess:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

                [GCDQueue executeInMainQueue:^{
                    [self closeView:nil];
                }             afterDelaySecs:1.f];

            });
        }
    }];
}

/**
 * Turn on the relevant processing of the fingerprint
 */
- (void)figerOpenAction {
    BOOL fingerLock = [[MMAppSetting sharedSetting] needFingerPay];
    if (fingerLock) {
        return;
    }
    // Turn on fingerprint recognition
    LAContext *myContext = [[LAContext alloc] init];
    NSError *authError = nil;
    NSString *myLocalizedReasonString = LMLocalizedString(@"Set Verify fingerPrint for Pay", nil);
    // Determine whether the device supports fingerprint identification
    if ([myContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&authError]) {
        // Fingerprint recognition only determines whether the current user is the owner
        [myContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                  localizedReason:myLocalizedReasonString
                            reply:^(BOOL success, NSError *error) {
                                if (success) {
                                    [[MMAppSetting sharedSetting] setFingerPay];
                                } else {
                                    DDLogInfo(@"Fingerprint authentication failed，%@", error.description);
                                }
                            }];

    } else {
        DDLogInfo(@"TTouchID device is not available");
    }
}

- (void)setPass {

    CGFloat passWH = AUTO_HEIGHT(80);
    CGFloat margin = (DEVICE_SIZE.width - (4 * passWH)) / 2;
    if (self.fristPassView == nil) {
        PassInputFieldView *fristPassView = [[PassInputFieldView alloc] init];
        self.fristPassView = fristPassView;
        fristPassView.delegate = self;
        fristPassView.tag = PassWordTagOne;

        [self.passInputView addSubview:fristPassView];
        [fristPassView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.passInputView).offset((-margin));
            make.height.mas_equalTo(passWH);
            make.width.mas_equalTo(4 * passWH);
            make.top.equalTo(self.passInputView);
        }];
    }
    if (self.secondPassView == nil) {
        PassInputFieldView *secondPassView = [[PassInputFieldView alloc] init];
        self.secondPassView = secondPassView;
        secondPassView.tag = PassWordTagTwo;
        secondPassView.delegate = self;
        [self.passInputView addSubview:secondPassView];
        [secondPassView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.fristPassView.mas_right).offset((DEVICE_SIZE.width - (4 * passWH)));
            make.height.equalTo(self.fristPassView.mas_height);
            make.width.equalTo(self.fristPassView.mas_width);
            make.top.equalTo(self.passInputView);
        }];

    }

    self.titleLabel.text = LMLocalizedString(@"Set Set Payment Password", nil);
    self.passStatusLabel.text = LMLocalizedString(@"Wallet Enter 4 Digits", nil);
    [GCDQueue executeInMainQueue:^{
        [self.fristPassView becomeFirstResponder];
    }             afterDelaySecs:0.3];
}

- (void)verfyPass {
    PassInputFieldView *payPassView = [[PassInputFieldView alloc] init];
    self.payPassView = payPassView;
    payPassView.delegate = self;
    payPassView.tag = PassWordTagThree;
    CGFloat passWH = AUTO_HEIGHT(80);
    [self.passInputView addSubview:payPassView];
    [payPassView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.passInputView);
        make.height.mas_equalTo(passWH);
        make.width.mas_equalTo(4 * passWH);
        make.top.equalTo(self.passInputView);
    }];
    [self.payPassView resignFirstResponder];
    [GCDQueue executeInMainQueue:^{
        [payPassView becomeFirstResponder];
    }             afterDelaySecs:0.3];
}

- (void)setStyle:(InputPayPassViewStyle)style {
    _style = style;
    switch (style) {
        case InputPayPassViewSetPass:
            [self setPass];
            break;

        case InputPayPassViewVerfyPass:
            [self verfyPass];
            break;
        default:
            break;
    }
}

#pragma mark - passWordCompleteInput

- (void)passWordCompleteInput:(PassInputFieldView *)passWord {
    self.titleLabel.text = LMLocalizedString(@"Set Payment Password", nil);
    self.payPassView.hidden = YES;
    if (self.isPassTag) {
        passWord.tag = PassWordTagOne;
    }
    switch (passWord.tag) {
        case PassWordTagOne: {

            self.passInputView.hidden = NO;
            passWord.hidden = NO;
            self.titleLabel.text = LMLocalizedString(@"Wallet Confirm Payment password", nil);
            self.passStatusLabel.text = LMLocalizedString(@"Wallet Enter again", nil);
            CGFloat passWH = AUTO_HEIGHT(80);
            CGFloat margin = (DEVICE_SIZE.width - (4 * passWH)) / 2;
            self.fristPass = passWord.textStore;
            if (self.fristPassView) {
                [self.fristPassView mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.right.mas_equalTo(self.passInputView.mas_left).offset(-margin);
                }];
            }
            self.secondPassView.hidden = NO;
            [UIView animateWithDuration:0.3 animations:^{
                [self.passInputView layoutIfNeeded];
                [self.secondPassView becomeFirstResponder];

            }];
            [self.fristPassView clearAll];
            self.isPassTag = NO;

        }
            break;
        case PassWordTagTwo: {
            if ([self.fristPass isEqualToString:passWord.textStore]) {
                self.isPassTag = NO;
                __weak typeof(self) weakSelf = self;
                [weakSelf.bottomView mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.left.equalTo(self.contentView.mas_left).offset(-DEVICE_SIZE.width);
                }];
                weakSelf.passErrorContentView.hidden = YES;
                weakSelf.animationContentView.hidden = NO;
                [UIView animateWithDuration:0.2 animations:^{
                    [weakSelf.contentView layoutIfNeeded];
                }];
                weakSelf.statusLabel.text = LMLocalizedString(@"Wallet Saving Payment Password", nil);
                weakSelf.titleLabel.text = LMLocalizedString(@"Wallet Saving Payment Password", nil);
                [weakSelf endEditing:YES];
                weakSelf.passInputView.hidden = YES;
                weakSelf.animationView.hidden = NO;
                weakSelf.statusLabel.hidden = NO;
                // Start the animation
                [weakSelf.animationView startLoading];
                /**
                 *  Save and upload
                 */
                [GCDQueue executeInBackgroundPriorityGlobalQueue:^{
                    [SetGlobalHandler setPaySetNoPass:[[MMAppSetting sharedSetting] isCanNoPassPay] payPass:passWord.textStore fee:[[MMAppSetting sharedSetting] getTranferFee] compete:^(BOOL result) {
                        [GCDQueue executeInMainQueue:^{
                            if (result) {
                                weakSelf.titleLabel.text = LMLocalizedString(@"Login Save successful", nil);
                                weakSelf.statusLabel.text = LMLocalizedString(@"Wallet Set Payment Password Successful", nil);
                                _walletLayer.speed = 0;
                                [weakSelf.animationView finishSuccess:nil];
                                [GCDQueue executeInMainQueue:^{
                                    weakSelf.backgroundColor = [UIColor clearColor];
                                    [UIView animateWithDuration:0.3 animations:^{
                                        weakSelf.top = DEVICE_SIZE.height;
                                    }                completion:^(BOOL finished) {
                                        [weakSelf removeFromSuperview];
                                        __weak __typeof(&*self) weakSelf = self;
                                        if (weakSelf.completeBlock) {
                                            weakSelf.completeBlock(weakSelf, nil, YES);
                                        }
                                        [weakSelf figerOpenAction];
                                    }];
                                }             afterDelaySecs:3.f];
                            } else {
                                weakSelf.statusLabel.text = LMLocalizedString(@"Wallet Payment Password do not match", nil);
                                [weakSelf.animationView finishFailure:nil];
                            }
                        }];
                    }];
                }];
            } else   // The passwords are not equal
            {

                self.titleLabel.text = LMLocalizedString(@"Set Setting Faied", nil);
                self.passStatusLabel.text = LMLocalizedString(@"Wallet Enter again", nil);
                self.fristPass = nil;
                [self.payPassView resignFirstResponder];
                [self.fristPassView removeFromSuperview];
                [self.secondPassView removeFromSuperview];
                self.fristPassView = nil;
                self.secondPassView = nil;

                [UIView animateWithDuration:0.3 animations:^{
                    [self.passInputView layoutIfNeeded];
                    [self.secondPassView resignFirstResponder];
                    [self.fristPassView resignFirstResponder];
                    // Create button
                    UIButton *retryBtn = [[UIButton alloc] init];
                    [retryBtn setTitle:LMLocalizedString(@"Wallet Retry", nil) forState:UIControlStateNormal];
                    retryBtn.titleLabel.font = [UIFont boldSystemFontOfSize:FONT_SIZE(36)];
                    [retryBtn setTitleColor:LMBasicBlue forState:UIControlStateNormal];
                    [retryBtn addTarget:self action:@selector(NewRetry:) forControlEvents:UIControlEventTouchUpInside];
                    [self.contentView addSubview:retryBtn];
                    [retryBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                        make.top.equalTo(self.contentView.mas_top).offset(AUTO_HEIGHT(200));
                        make.centerX.equalTo(self.contentView);
                        make.width.mas_equalTo(100);
                        make.height.mas_equalTo(50);
                    }];
                    self.displayLbale = [[UILabel alloc] init];
                    self.displayLbale.text = LMLocalizedString(@"Wallet Payment Password do not match", nil);
                    self.displayLbale.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
                    self.displayLbale.textColor = LMBasicLableColor;
                    [self.contentView addSubview:self.displayLbale];
                    [self.displayLbale mas_makeConstraints:^(MASConstraintMaker *make) {
                        make.top.equalTo(self.contentView.mas_top).offset(AUTO_HEIGHT(350));
                        make.centerX.equalTo(self.contentView);
                    }];

                    self.retryNewBtn = retryBtn;
                    self.isPassTag = YES;
                }];
            }
        }
            break;
        case PassWordTagThree: {
            self.isPassTag = NO;
            self.payPassView.hidden = NO;
            [self endEditing:YES];
            [SetGlobalHandler syncPaypinversionWithComplete:^(NSString *password, NSError *error) {
                if (error) {
                    self.titleLabel.text = LMLocalizedString(@"Network Server error", nil);
                    _walletLayer.speed = 0;
                    [_walletLayer removeFromSuperlayer];
                    self.statusLabel.hidden = NO;
                    self.statusLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Error code Domain Pelese try later", nil), (int) error.code, [LMErrorCodeTool showToastErrorType:ToastErrorTypeWallet withErrorCode:error.code withUrl:@""]];
                    [self.bottomView mas_updateConstraints:^(MASConstraintMaker *make) {
                        make.left.equalTo(self.contentView.mas_left).offset(-DEVICE_SIZE.width);
                    }];
                    [UIView animateWithDuration:0.3 animations:^{
                        [self.contentView layoutIfNeeded];
                    }];
                    self.passErrorContentView.hidden = YES;
                    self.animationContentView.hidden = NO;
                } else {
                    if ([password isEqualToString:passWord.textStore]) {
                        [self.bottomView mas_updateConstraints:^(MASConstraintMaker *make) {
                            make.left.equalTo(self.contentView.mas_left).offset(-DEVICE_SIZE.width);
                        }];
                        self.passErrorContentView.hidden = YES;
                        self.animationContentView.hidden = NO;
                        [UIView animateWithDuration:0.2 animations:^{
                            [self.contentView layoutIfNeeded];
                        }];

                        self.statusLabel.text = LMLocalizedString(@"Wallet Verifying", nil);
                        [self.animationView startLoading];
                        __weak typeof(self) weakSelf = self;
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            if (weakSelf.completeBlock) {
                                weakSelf.completeBlock(weakSelf, nil, YES);
                            }
                        });
                    } else {
                        [self.bottomView mas_updateConstraints:^(MASConstraintMaker *make) {
                            make.left.equalTo(self.contentView.mas_left).offset(-DEVICE_SIZE.width);
                        }];
                        self.passErrorContentView.hidden = NO;
                        self.animationContentView.hidden = YES;
                        self.titleLabel.text = LMLocalizedString(@"Set Verification Faied", nil);
                        [UIView animateWithDuration:0.3 animations:^{
                            [self.contentView layoutIfNeeded];
                        }];
                        [self.animationView finishFailure:nil];
                    }
                }
            }];
        }
            break;
        default:
            break;
    }
}
@end
