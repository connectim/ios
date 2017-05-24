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

#define K_MAX_LENGTH 6
#define K_MAX_COUNT_TIME (60)
typedef NS_ENUM(NSUInteger,SendType) {
    
    SendTypeSMS    = 1,
    SendTypeVoice  = 2
    
};


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
    if (self.isCountting) {
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
    count = K_MAX_COUNT_TIME;
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
    if (count == K_MAX_COUNT_TIME) {
        [self sendCodeWithType:SendTypeSMS];
    }

}
#pragma mark - set up
- (void)setup {

    self.codeField = [UITextField new];
    [self.codeField becomeFirstResponder];
    self.codeField.delegate = self;
    UIColor *color = [UIColor blackColor];
    self.codeField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:LMLocalizedString(@"Login Code", nil) attributes:@{NSForegroundColorAttributeName: color}];
    [self.codeField addTarget:self action:@selector(textValueChange) forControlEvents:UIControlEventEditingChanged];
    self.codeField.font = [UIFont systemFontOfSize:FONT_SIZE(72)];
    self.codeField.keyboardType = UIKeyboardTypeNumberPad;
    self.codeField.textAlignment = NSTextAlignmentCenter;
    self.codeField.keyboardAppearance = UIKeyboardAppearanceLight;
    self.codeField.textColor = [UIColor blackColor];
    self.codeField.tintColor = LMBasicBlack;
    [self.view addSubview:_codeField];
    self.codeField.leftViewMode = UITextFieldViewModeAlways;
    [self.codeField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(AUTO_HEIGHT(200));
        make.centerX.equalTo(self.view);
        make.height.mas_equalTo(AUTO_HEIGHT(100));
        make.width.mas_equalTo(AUTO_WIDTH(270));
    }];

    self.tipLabel = [[ConnectLabel alloc] initWithText:LMLocalizedString(@"Login Sending verification code", nil)];
    self.tipLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
    [self.view addSubview:self.tipLabel];
    self.tipLabel.textAlignment = NSTextAlignmentCenter;
    [self.tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.left.right.equalTo(self.view);
        make.top.equalTo(_codeField.mas_bottom).offset(AUTO_HEIGHT(206));
    }];

    self.phoneLabel = [[ConnectLabel alloc] initWithText:[NSString stringWithFormat:@"+%d %@", self.countryCode, self.phoneStr]];
    self.phoneLabel.font = [UIFont systemFontOfSize:FONT_SIZE(32)];
    self.phoneLabel.textColor = GJCFQuickHexColor(@"00C400");
    self.phoneLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_phoneLabel];
    [self.phoneLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(_tipLabel.mas_bottom).offset(5);
        make.left.right.equalTo(self.view);
    }];

    self.sendVoiceBtn = [UIButton new];
    [self.view addSubview:_sendVoiceBtn];
    [self.sendVoiceBtn addTarget:self action:@selector(sendVoiceCode) forControlEvents:UIControlEventTouchUpInside];
    [self.sendVoiceBtn setTitle:LMLocalizedString(@"Chat Send vioce", nil) forState:UIControlStateNormal];
    self.sendVoiceBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.sendVoiceBtn setTitleColor:LMBasicBlue forState:UIControlStateNormal];
    [self.sendVoiceBtn setTitleColor:LMBasicDarkGray forState:UIControlStateDisabled];
    self.sendVoiceBtn.enabled = NO;
    [self.sendVoiceBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_phoneLabel.mas_bottom).offset(AUTO_HEIGHT(34));
        make.centerX.equalTo(self.view);
    }];

    self.sendAgainBtn = [[ConnectButton alloc] initWithNormalTitle:LMLocalizedString(@"Login Resend", nil) disableTitle:nil];
    self.sendAgainBtn.enabled = NO;
    [self.sendAgainBtn addTarget:self action:@selector(sendAgain) forControlEvents:UIControlEventTouchUpInside];
    self.sendAgainBtn.bottom = self.view.bottom - AUTO_HEIGHT(477);
    self.sendAgainBtn.centerX = self.view.centerX;
    [self.view addSubview:self.sendAgainBtn];

    self.nextButton = [[ConnectButton alloc] initWithNormalTitle:LMLocalizedString(@"Login Next", nil) disableTitle:LMLocalizedString(@"Common Loading", nil)];
    [self.view addSubview:self.nextButton];
    self.nextButton.hidden = YES;
    [self.nextButton addTarget:self action:@selector(nextAction) forControlEvents:UIControlEventTouchUpInside];
    self.nextButton.frame = self.sendAgainBtn.frame;
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
            count = K_MAX_COUNT_TIME;
            dispatch_source_cancel(_timer);
            _timer = nil;
            [GCDQueue executeInMainQueue:^{
                // set button
                self.sendAgainBtn.enabled = YES;
                self.sendVoiceBtn.enabled = YES;
                [self.sendAgainBtn setTitle:LMLocalizedString(@"Login Resend", nil) forState:UIControlStateNormal];
                if (self.codeField.text.length == K_MAX_LENGTH) {
                    self.nextButton.hidden = NO;
                    self.sendAgainBtn.hidden = YES;
                } else {
                    self.nextButton.hidden = YES;
                    self.sendAgainBtn.hidden = NO;
                }
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (count == K_MAX_COUNT_TIME - 5 && !weakSelf.isSendedVoice) {
                    // vertification code？
                    self.sendVoiceBtn.enabled = YES;
                    self.tipLabel.text = LMLocalizedString(@"Set Did not receive the verification code", nil);
                }
                [self.sendAgainBtn setTitle:[NSString stringWithFormat:LMLocalizedString(@"Login Resend Time", nil), count] forState:UIControlStateDisabled];
            });
            count--;
            DDLogInfo(@"time %d", count);
        }
    });
    self.isCountting = YES;
    dispatch_resume(_timer);
}
- (void)stopTimer {
    if (_timer) {
        dispatch_source_cancel(_timer);
        _timer = nil;
    }
}
- (void)sendCodeWithType:(int)sendType {

    SendMobileCode *mobileCode = [[SendMobileCode alloc] init];
    mobileCode.mobile = [NSString stringWithFormat:@"%d-%@", self.countryCode, self.phoneStr];
    mobileCode.category = sendType;
    
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
        if (sendType == SendTypeVoice) {
            // voice
            if (!weakSelf.isCountting && _timer) {
                dispatch_resume(_timer);
                self.isCountting = YES;
            }
            self.isSendedVoice = YES;
            self.tipLabel.text = LMLocalizedString(@"Login SMS code has been send", nil);
        } else if (sendType == SendTypeSMS) {
            self.isSendedVoice = NO;
            self.tipLabel.text = LMLocalizedString(@"Set verification code has been send to phone", nil);
        }
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Login SMS code has been send", nil) withType:ToastTypeSuccess showInView:self.view complete:nil];
        }];
        
        if (!self.isCountting || !_timer) {
            [self startTime];
        }
        self.sendVoiceBtn.enabled = NO;
        self.sendAgainBtn.enabled = NO;
    }   fail:^(NSError *error) {
        
        [GCDQueue executeInMainQueue:^{
            self.tipLabel.text = LMLocalizedString(@"Login SMS code sent failure", nil);
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Login SMS code sent failure", nil) withType:ToastTypeFail showInView:self.view complete:nil];
            self.sendAgainBtn.enabled = YES;
            [self.view layoutIfNeeded];
        }];
    }];
}

- (void)sendVoiceCode {
    // reset time
    count = K_MAX_COUNT_TIME;
    if (self.isCountting && _timer) {
        dispatch_suspend(_timer);
        self.isCountting = NO;
    }
    self.sendVoiceBtn.enabled = NO;
    [self sendCodeWithType:SendTypeVoice];
}

- (void)nextAction {
    [self signin];
}

- (void)sendAgain {
    self.tipLabel.text = LMLocalizedString(@"Login Sending verification code", nil);
    self.sendAgainBtn.enabled = NO;
    [self sendCodeWithType:SendTypeSMS];
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
        
        switch (hResponse.code) {
            case 2404: {
                [self skipRegieterAction:hResponse];
            }
                break;
            case successCode: {
                [self successAction:hResponse];
            }
                break;
            case 2416: {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Verification code error", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                }];

            }
                break;
            default:{
                [GCDQueue executeInMainQueue:^{
                    weakSelf.nextButton.enabled = YES;
                    [MBProgressHUD showToastwithText:[LMErrorCodeTool showToastErrorType:ToastErrorTypeLoginOrReg withErrorCode:hResponse.code withUrl:LoginSignInUrl] withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                }];
            }
                break;
        }
    }  fail:^(NSError *error) {
        [self failureAction];
    }];

}
- (void)failureAction {
    self.isCountting = NO;
    count = K_MAX_COUNT_TIME;
    //free timer
    [self stopTimer];
    [GCDQueue executeInMainQueue:^{
        self.nextButton.enabled = YES;
        [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:self.view complete:nil];
    }];

}
- (void)successAction:(HttpNotSignResponse *)hResponse {
    
    NSError *error = nil;
    self.isCountting = NO;
    count = K_MAX_COUNT_TIME;
    // free timer
    [self stopTimer];
    UserInfoDetail *userInfo = [UserInfoDetail parseFromData:hResponse.body error:&error];
    if (error || !userInfo || hResponse.body.length <= 0) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:self.view complete:nil];
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
        user.bondingPhone = [NSString stringWithFormat:@"%d-%@", self.countryCode, self.phoneStr];
        [[MMAppSetting sharedSetting] saveUserToKeyChain:user];
        // skip login
        LocalAccountLoginPage *page = [[LocalAccountLoginPage alloc] initWithUser:user];
        [self.navigationController pushViewController:page animated:YES];
    }];

}
- (void)skipRegieterAction:(HttpNotSignResponse *)hResponse {
    
    NSError *error = nil;
    self.isCountting = NO;
    count = K_MAX_COUNT_TIME;
    // timer
    [self stopTimer];
    SecurityToken *secToken = [SecurityToken parseFromData:hResponse.body error:&error];
    if (!error) {
        if (GJCFStringIsNull(secToken.token)) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:self.view complete:nil];
            }];
        } else {
            [GCDQueue executeInMainQueue:^{
                NSString *phone = [NSString stringWithFormat:@"%d-%@", self.countryCode, self.phoneStr];
                LMRandomSeedController *page = [[LMRandomSeedController alloc] initWithMobile:phone token:secToken.token];
                [self.navigationController pushViewController:page animated:YES];
            }];
        }
    }
}

- (void)textValueChange {
    if (_codeField.text.length == K_MAX_LENGTH) {
        [self signin];
        self.sendAgainBtn.hidden = YES;
        self.nextButton.hidden = NO;
    } else {
        self.sendAgainBtn.hidden = NO;
        self.nextButton.hidden = YES;
        self.sendAgainBtn.enabled = count == 60;
    }
}
#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *toBeString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (toBeString.length > K_MAX_LENGTH && range.length != 1) {
        textField.text = [toBeString substringToIndex:K_MAX_LENGTH];
        return NO;
    }
    return YES;
}

#pragma mark - getter setter

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}


@end
