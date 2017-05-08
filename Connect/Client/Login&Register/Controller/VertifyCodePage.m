//
//  VertifyCodePage.m
//  Connect
//
//  Created by MoHuilin on 16/5/10.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "VertifyCodePage.h"

#import "ConnectButton.h"
#import "ConnectLabel.h"

#import "LocalAccountLoginPage.h"
#import "NetWorkOperationTool.h"
#import "LMRandomSeedController.h"

#define kMaxLength 6
#define kMaxCountTime (60)

@interface VertifyCodePage () <UITextFieldDelegate> {
    int __block count;
    dispatch_source_t _timer;
}

@property(nonatomic, strong) ConnectButton *sendAgainBtn;

@property(nonatomic, strong) ConnectButton *nextButton;

@property(nonatomic, strong) UITextField *codeField;
@property(nonatomic, strong) ConnectLabel *phoneLabel;

@property(nonatomic, strong) ConnectLabel *tipLabel;

@property(nonatomic, strong) UIButton *sendVoiceBtn;

@property(nonatomic, strong) NSString *phoneStr;
//country code
@property(nonatomic, assign) int countryCode;
// is count
@property(nonatomic, assign) BOOL isCountting;
// is send voice
@property(nonatomic, assign) BOOL isSendedVoice;

@end

@implementation VertifyCodePage


#pragma mark - life crycle

- (instancetype)initWithCountryCode:(int)countryCode phone:(NSString *)phone {
    if (self = [super init]) {
        self.countryCode = countryCode;
        self.phoneStr = phone;
    }

    return self;
}

- (void)doLeft:(id)sender {
    if (_isCountting) {
        __weak typeof(&*self) weakSelf = self;
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:[NSString stringWithFormat:LMLocalizedString(@"Login Please wait for", nil), count] withType:ToastTypeCommon showInView:weakSelf.view complete:nil];
        }];
        return;
    }
    [super doLeft:sender];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    [self.navigationController.navigationBar lt_setBackgroundColor:[UIColor clearColor]];

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar lt_reset];
}

- (void)loadView {
    [super loadView];

    count = kMaxCountTime;
}

- (void)dealloc {
    if (_timer) {
        dispatch_source_cancel(_timer);
        _timer = nil;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setNavigationTitleImage:@"logo_black_small"];

    [self setBlackfBackArrowItem];

    // send text verification code
    if (count == kMaxCountTime) {
        [self sendCodeWithType:1];
    }

}


#pragma mark - set up

- (void)setup {

    self.codeField = [UITextField new];
    [_codeField becomeFirstResponder];
    _codeField.delegate = self;
    UIColor *color = [UIColor blackColor];
    _codeField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:LMLocalizedString(@"Login Code", nil) attributes:@{NSForegroundColorAttributeName: color}];
    [_codeField addTarget:self action:@selector(textValueChange) forControlEvents:UIControlEventEditingChanged];
    _codeField.font = [UIFont systemFontOfSize:FONT_SIZE(72)];
    _codeField.keyboardType = UIKeyboardTypeNumberPad;
    _codeField.textAlignment = NSTextAlignmentCenter;
    _codeField.keyboardAppearance = UIKeyboardAppearanceLight;
    _codeField.textColor = [UIColor blackColor];
    _codeField.tintColor = LMBasicBlack;
    [self.view addSubview:_codeField];
    _codeField.leftViewMode = UITextFieldViewModeAlways;
    [_codeField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(AUTO_HEIGHT(200));
        make.centerX.equalTo(self.view);
        make.height.mas_equalTo(AUTO_HEIGHT(100));
        make.width.mas_equalTo(AUTO_WIDTH(270));
    }];

    self.tipLabel = [[ConnectLabel alloc] initWithText:LMLocalizedString(@"Login Sending verification code", nil)];
    _tipLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
    [self.view addSubview:_tipLabel];
    _tipLabel.textAlignment = NSTextAlignmentCenter;
    [_tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.left.right.equalTo(self.view);
        make.top.equalTo(_codeField.mas_bottom).offset(AUTO_HEIGHT(206));
    }];

    self.phoneLabel = [[ConnectLabel alloc] initWithText:[NSString stringWithFormat:@"+%d %@", self.countryCode, self.phoneStr]];
    _phoneLabel.font = [UIFont systemFontOfSize:FONT_SIZE(32)];
    _phoneLabel.textColor = GJCFQuickHexColor(@"00C400");
    _phoneLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_phoneLabel];
    [_phoneLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(_tipLabel.mas_bottom).offset(5);
        make.left.right.equalTo(self.view);
    }];

    self.sendVoiceBtn = [UIButton new];
    [self.view addSubview:_sendVoiceBtn];
    [_sendVoiceBtn addTarget:self action:@selector(sendVoiceCode) forControlEvents:UIControlEventTouchUpInside];
    [_sendVoiceBtn setTitle:LMLocalizedString(@"Chat Send vioce", nil) forState:UIControlStateNormal];
    _sendVoiceBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [_sendVoiceBtn setTitleColor:LMBasicBlue forState:UIControlStateNormal];
    [_sendVoiceBtn setTitleColor:LMBasicDarkGray forState:UIControlStateDisabled];
    _sendVoiceBtn.enabled = NO;
    [_sendVoiceBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_phoneLabel.mas_bottom).offset(AUTO_HEIGHT(34));
        make.centerX.equalTo(self.view);
    }];

    self.sendAgainBtn = [[ConnectButton alloc] initWithNormalTitle:LMLocalizedString(@"Login Resend", nil) disableTitle:nil];
    _sendAgainBtn.enabled = NO;
    [_sendAgainBtn addTarget:self action:@selector(sendAgain) forControlEvents:UIControlEventTouchUpInside];
    _sendAgainBtn.bottom = self.view.bottom - AUTO_HEIGHT(477);
    _sendAgainBtn.centerX = self.view.centerX;
    [self.view addSubview:self.sendAgainBtn];

    self.nextButton = [[ConnectButton alloc] initWithNormalTitle:LMLocalizedString(@"Login Next", nil) disableTitle:LMLocalizedString(@"Common Loading", nil)];
    [self.view addSubview:_nextButton];
    _nextButton.hidden = YES;
    [_nextButton addTarget:self action:@selector(next) forControlEvents:UIControlEventTouchUpInside];
    _nextButton.frame = _sendAgainBtn.frame;
}

#pragma mark - event

- (void)startTime {

    if (_timer) {
        return;
    }
    __weak __typeof(&*self) weakSelf = self;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(_timer, dispatch_walltime(NULL, 0), 1.0 * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(_timer, ^{
        if (count <= 0) {
            // close
            weakSelf.isSendedVoice = NO;
            weakSelf.isCountting = NO;
            count = kMaxCountTime;
            dispatch_source_cancel(_timer);
            _timer = nil;
            [GCDQueue executeInMainQueue:^{
                // set button
                _sendAgainBtn.enabled = YES;
                _sendVoiceBtn.enabled = YES;
                [_sendAgainBtn setTitle:LMLocalizedString(@"Login Resend", nil) forState:UIControlStateNormal];
                [_sendAgainBtn setTitle:LMLocalizedString(@"Login Resend", nil) forState:UIControlStateDisabled];
                if (_codeField.text.length == kMaxLength) {
                    _nextButton.hidden = NO;
                    _sendAgainBtn.hidden = YES;
                } else {
                    _nextButton.hidden = YES;
                    _sendAgainBtn.hidden = NO;
                }
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (count == kMaxCountTime - 5 && !weakSelf.isSendedVoice) {
                    // vertification code？
                    _sendVoiceBtn.enabled = YES;
                    _tipLabel.text = LMLocalizedString(@"Set Did not receive the verification code", nil);
                }
                [_sendAgainBtn setTitle:[NSString stringWithFormat:LMLocalizedString(@"Login Resend Time", nil), count] forState:UIControlStateDisabled];
            });
            count--;
            DDLogInfo(@"time %d", count);
        }
    });
    self.isCountting = YES;
    dispatch_resume(_timer);
}

- (void)sendCodeWithType:(int)type {

    SendMobileCode *mobileCode = [[SendMobileCode alloc] init];
    mobileCode.mobile = [NSString stringWithFormat:@"%d-%@", self.countryCode, self.phoneStr];
    mobileCode.category = type;
    __weak __typeof(&*self) weakSelf = self;
    [NetWorkOperationTool POSTWithUrlString:PhoneGetPhoneCode noSignProtoData:mobileCode.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *) response;
        if (hResponse.code != successCode) {
            [GCDQueue executeInMainQueue:^{
                _tipLabel.text = LMLocalizedString(@"Login SMS code sent failure", nil);
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Login SMS code sent failure", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                _sendAgainBtn.enabled = YES;
                [weakSelf.view layoutIfNeeded];
            }];
            return;
        }
        if (type == 2) {
            // voice
            if (!weakSelf.isCountting && _timer) {
                dispatch_resume(_timer);
                self.isCountting = YES;
            }
            weakSelf.isSendedVoice = YES;
            _tipLabel.text = LMLocalizedString(@"Login SMS code has been send", nil);
        } else if (type == 1)
            // text
        {
            _tipLabel.text = LMLocalizedString(@"Set verification code has been send to phone", nil);
        }
        [MBProgressHUD showToastwithText:LMLocalizedString(@"Login SMS code has been send", nil) withType:ToastTypeSuccess showInView:self.view complete:nil];
        if (!weakSelf.isCountting || !_timer) {
            [weakSelf startTime];
        }
        _sendVoiceBtn.enabled = NO;
        _sendAgainBtn.enabled = NO;
    }                                  fail:^(NSError *error) {
        [GCDQueue executeInMainQueue:^{
            _tipLabel.text = LMLocalizedString(@"Login SMS code sent failure", nil);
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Login SMS code sent failure", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
            _sendAgainBtn.enabled = YES;
            [weakSelf.view layoutIfNeeded];
        }];
    }];
}

- (void)sendVoiceCode {
    // reset time
    count = kMaxCountTime;
    if (self.isCountting && _timer) {
        dispatch_suspend(_timer);
        self.isCountting = NO;
    }
    _sendVoiceBtn.enabled = NO;
    [self sendCodeWithType:2];
}

- (void)next {
    [self signin];
}

- (void)sendAgain {
    self.tipLabel.text = LMLocalizedString(@"Login Sending verification code", nil);
    self.sendAgainBtn.enabled = NO;
    [self sendCodeWithType:1];
}

- (void)signin {

    __weak __typeof(&*self) weakSelf = self;
    [MBProgressHUD showMessage:LMLocalizedString(@"Common Loading", nil) toView:self.view];

    self.nextButton.enabled = NO;
    MobileVerify *setMobil = [[MobileVerify alloc] init];
    setMobil.countryCode = self.countryCode;
    setMobil.number = self.phoneStr;
    setMobil.code = self.codeField.text;

    [NetWorkOperationTool POSTWithUrlString:LoginSignInUrl noSignProtoData:setMobil.data complete:^(id response) {

        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:weakSelf.view];
        }];

        HttpNotSignResponse *hResponse = (HttpNotSignResponse *) response;
        weakSelf.nextButton.enabled = YES;
        NSError *error = nil;
        switch (hResponse.code) {
            case 2414: {
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Phone binded", nil) withType:ToastTypeFail showInView:self.view complete:nil];
            }
                break;
            case 2404: {
                weakSelf.isCountting = NO;
                count = kMaxCountTime;
                // timer
                if (_timer) {
                    dispatch_source_cancel(_timer);
                    _timer = nil;
                }
                SecurityToken *token = [SecurityToken parseFromData:hResponse.body error:&error];
                if (error) {
                    return;
                }
                error = nil;

                if (GJCFStringIsNull(token.token)) {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                    }];
                } else {
                    [GCDQueue executeInMainQueue:^{
                        NSString *phone = [NSString stringWithFormat:@"%d-%@", weakSelf.countryCode, weakSelf.phoneStr];
                        LMRandomSeedController *page = [[LMRandomSeedController alloc] initWithMobile:phone token:token.token];
                        [weakSelf.navigationController pushViewController:page animated:YES];
                    }];
                }
            }
                break;
            case successCode: {
                weakSelf.isCountting = NO;
                count = kMaxCountTime;
                // free timer
                if (_timer) {
                    dispatch_source_cancel(_timer);
                    _timer = nil;
                }
                UserInfoDetail *userInfo = [UserInfoDetail parseFromData:hResponse.body error:&error];
                if (error || !userInfo || hResponse.body.length <= 0) {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                    }];
                }
                error = nil;
                [GCDQueue executeInMainQueue:^{
                    AccountInfo *user = [[AccountInfo alloc] init];
                    user.avatar = userInfo.avatar;
                    user.username = userInfo.username;
                    user.pub_key = userInfo.pubKey;
                    user.address = userInfo.address;
                    user.contentId = userInfo.connectId;
                    user.password_hint = userInfo.passwordHint;
                    user.encryption_pri = userInfo.encryptionPri;
                    user.bondingPhone = [NSString stringWithFormat:@"%d-%@", weakSelf.countryCode, weakSelf.phoneStr];
                    [[MMAppSetting sharedSetting] saveUserToKeyChain:user];
                    // skip login
                    LocalAccountLoginPage *page = [[LocalAccountLoginPage alloc] initWithUser:user];
                    [weakSelf.navigationController pushViewController:page animated:YES];
                }];
            }
                break;
            case 2416: {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Verification code error", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                }];

            }
                break;

            default:
                break;
        }
    }                                  fail:^(NSError *error) {
        weakSelf.isCountting = NO;
        count = kMaxCountTime;
        //free timer
        if (_timer) {
            dispatch_source_cancel(_timer);
            _timer = nil;
        }
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:weakSelf.view];
        }];
        [GCDQueue executeInMainQueue:^{
            weakSelf.nextButton.enabled = YES;
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
        }];


    }];

}

- (void)textValueChange {
    if (_codeField.text.length == kMaxLength) {
        [self signin];
        self.sendAgainBtn.hidden = YES;
        self.nextButton.hidden = NO;
    } else {
        self.sendAgainBtn.hidden = NO;
        self.nextButton.hidden = YES;
        _sendAgainBtn.enabled = count == 60;
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *toBeString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (toBeString.length > kMaxLength && range.length != 1) {
        textField.text = [toBeString substringToIndex:kMaxLength];
        return NO;
    }
    return YES;
}

#pragma mark - getter setter

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}


@end
