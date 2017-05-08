//
//  ChangePhoneVertifyPage.m
//  Connect
//
//  Created by MoHuilin on 16/8/4.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "ChangePhoneVertifyPage.h"
#import "ConnectButton.h"
#import "ConnectLabel.h"
#import "NetWorkOperationTool.h"

#define kMaxLength 6
#define kMaxCountTime (60)

typedef NS_ENUM(NSInteger, BottonAction) {
    BottonActionSendAgain,
    BottonActionNext,
};

@interface ChangePhoneVertifyPage () <UITextFieldDelegate> {
    int __block count;
    dispatch_source_t _timer;
}

@property(nonatomic, strong) ConnectButton *sendAgainBtn;
@property(nonatomic, strong) ConnectButton *nextButton;
@property(nonatomic, strong) UITextField *codeField;
@property(nonatomic, strong) UILabel *phoneLabel;

@property(nonatomic, strong) UILabel *tipLabel;

@property(nonatomic, strong) UIButton *sendVoiceBtn;

@property(nonatomic, copy) NSString *phoneStr;
@property(nonatomic, assign) int countryCode;
// Whether it is counting down
@property(nonatomic, assign) BOOL isCountting;
// whether is sendVocie
@property(nonatomic, assign) BOOL isSendedVoice;


@end

@implementation ChangePhoneVertifyPage

- (instancetype)initWithCountryCode:(int)countryCode phone:(NSString *)phone {
    if (self = [super init]) {
        self.countryCode = countryCode;
        self.phoneStr = phone;
    }

    return self;
}


- (void)loadView {
    [super loadView];

    count = kMaxCountTime;
}


- (void)viewDidLoad {

    [super viewDidLoad];
    self.title = LMLocalizedString(@"Set Change Mobile", nil);
    self.view.backgroundColor = XCColor(241, 241, 241);
    if (count == kMaxCountTime) {
        [self sendCodeWithType:1];
    }

}


#pragma mark - set up

- (void)sendVoiceCode {

    // rsset time
    count = kMaxCountTime;
    if (self.isCountting && _timer) {
        dispatch_suspend(_timer);
        self.isCountting = NO;
    }

    [self sendCodeWithType:2];
}

- (void)next {

    __weak __typeof(&*self) weakSelf = self;

    [MBProgressHUD showMessage:LMLocalizedString(@"Common Loading", nil) toView:self.view];

    MobileVerify *setMobil = [[MobileVerify alloc] init];
    setMobil.countryCode = weakSelf.countryCode;
    setMobil.number = weakSelf.phoneStr;
    setMobil.code = weakSelf.codeField.text;
    [NetWorkOperationTool POSTWithUrlString:SetBindPhoneUrl postProtoData:setMobil.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *) response;
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
        }];
        if (hResponse.code != successCode) {
            if (hResponse.code == 2414) { // binded phone
                weakSelf.isCountting = NO;
                count = kMaxCountTime;
                // free timer
                if (_timer) {
                    dispatch_source_cancel(_timer);
                    _timer = nil;
                }
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Phone binded", nil) withType:ToastTypeFail showInView:self.view complete:nil];
                    SendNotify(LKUserCenterUserInfoUpdateNotification, self);
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [weakSelf dismissViewControllerAnimated:YES completion:nil];
                    });
                }];
            } else if (hResponse.code == 2406) { // vertification code
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Verification code error", nil) withType:ToastTypeFail showInView:self.view complete:nil];
                }];
            } else {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Verification code error", nil) withType:ToastTypeFail showInView:self.view complete:nil];
                }];
            }
            return;
        }

        weakSelf.isCountting = NO;
        count = kMaxCountTime;
        // free timer
        if (_timer) {
            dispatch_source_cancel(_timer);
            _timer = nil;
        }

        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Set Mobile Number has been updated", nil) withType:ToastTypeSuccess showInView:self.view complete:^{
                [weakSelf dismissViewControllerAnimated:YES completion:nil];
            }];
            [[LKUserCenter shareCenter] bindNewPhone:[NSString stringWithFormat:@"%d-%@", self.countryCode, self.phoneStr]];
            SendNotify(LKUserCenterUserInfoUpdateNotification, self);
        }];

    }                                  fail:^(NSError *error) {
        weakSelf.isCountting = NO;
        count = kMaxCountTime;
        //free timer
        if (_timer) {
            dispatch_source_cancel(_timer);
            _timer = nil;
        }
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Link update Failed", nil) withType:ToastTypeFail showInView:self.view complete:nil];
        }];
    }];

}

#pragma mark - event

- (void)doLeft:(id)sender {

    if (_isCountting) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:[NSString stringWithFormat:LMLocalizedString(@"Set Please wait", nil), count] withType:ToastTypeCommon showInView:self.view complete:nil];
        }];
        return;
    }

    [super doLeft:sender];
}

- (void)dealloc {
    if (_timer) {
        dispatch_source_cancel(_timer);
        _timer = nil;
    }

    DDLogError(@"dealloc");
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
    [self.view addSubview:_codeField];
    _codeField.leftViewMode = UITextFieldViewModeAlways;
    [_codeField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(AUTO_HEIGHT(200));
        make.centerX.equalTo(self.view);
        make.height.mas_equalTo(AUTO_HEIGHT(100));
        make.width.mas_equalTo(AUTO_WIDTH(270));
    }];

    self.tipLabel = [[ConnectLabel alloc] initWithText:LMLocalizedString(@"Login SMS code is sending", nil)];
    _tipLabel.font = [UIFont systemFontOfSize:FONT_SIZE(32)];
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
    [self.view addSubview:_phoneLabel];
    [_phoneLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(_tipLabel.mas_bottom).offset(5);
    }];

    self.sendVoiceBtn = [UIButton new];
    [self.view addSubview:_sendVoiceBtn];
    _sendVoiceBtn.enabled = NO;
    [_sendVoiceBtn addTarget:self action:@selector(sendVoiceCode) forControlEvents:UIControlEventTouchUpInside];
    [_sendVoiceBtn setTitle:LMLocalizedString(@"Chat Send vioce", nil) forState:UIControlStateNormal];
    _sendVoiceBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [_sendVoiceBtn setTitleColor:LMBasicBlue forState:UIControlStateNormal];
    [_sendVoiceBtn setTitleColor:LMBasicDarkGray forState:UIControlStateDisabled];
    [_sendVoiceBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_phoneLabel.mas_bottom).offset(AUTO_HEIGHT(34));
        make.centerX.equalTo(self.view);
    }];

    self.sendAgainBtn = [[ConnectButton alloc] initWithNormalTitle:LMLocalizedString(@"Login Resend", nil) disableTitle:nil];
    _sendAgainBtn.enabled = NO;
    [_sendAgainBtn addTarget:self action:@selector(sendAgain) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.sendAgainBtn];

    [self.sendAgainBtn mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_bottom).offset(-AUTO_HEIGHT(447));
        make.centerX.equalTo(self.view);
        make.height.mas_equalTo(self.sendAgainBtn.height);
        make.width.mas_equalTo(self.sendAgainBtn.width);
    }];


    self.nextButton = [[ConnectButton alloc] initWithNormalTitle:LMLocalizedString(@"Login Next", nil) disableTitle:LMLocalizedString(@"Wallet Verifying", nil)];
    _nextButton.hidden = YES;
    [_nextButton addTarget:self action:@selector(next) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_nextButton];
    [self.nextButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.sendAgainBtn.mas_top);
        make.centerX.equalTo(self.view);
        make.height.mas_equalTo(self.nextButton.height);
        make.width.mas_equalTo(self.nextButton.width);
    }];

}

#pragma mark - event

- (void)startTime {

    if (_timer) {
        return;
    }

    self.isCountting = YES;
    __weak __typeof(&*self) weakSelf = self;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(_timer, dispatch_walltime(NULL, 0), 1.0 * NSEC_PER_SEC, 0); //seconds
    dispatch_source_set_event_handler(_timer, ^{
        if (count <= 0) { // close
            weakSelf.isSendedVoice = NO;
            weakSelf.isCountting = NO;
            count = kMaxCountTime;
            dispatch_source_cancel(_timer);
            _timer = nil;
            [GCDQueue executeInMainQueue:^{
                // Set the interface button to display according to their own needs
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
                    _tipLabel.text = LMLocalizedString(@"Set Did not receive the verification code", nil);
                }
                // Set the interface button to display according to their own needs
                [_sendAgainBtn setTitle:[NSString stringWithFormat:LMLocalizedString(@"Login Resend Time", nil), count] forState:UIControlStateDisabled];
            });
            count--;
            DDLogInfo(@"time %d", count);
        }
    });
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
            return;
        }
        [GCDQueue executeInMainQueue:^{
            if (type == 2) { //voice
                if (!weakSelf.isCountting && _timer) {
                    dispatch_resume(_timer);
                    self.isCountting = YES;
                }
                weakSelf.isSendedVoice = YES;
                _tipLabel.text = LMLocalizedString(@"Login SMS code has been send", nil);
            } else if (type == 1) //title
            {
                _tipLabel.text = LMLocalizedString(@"Set verification code has been send to phone", nil);
            }
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Login SMS code has been send", nil) withType:ToastTypeSuccess showInView:self.view complete:nil];
            if (!weakSelf.isCountting || !_timer) {
                [weakSelf startTime];
            }
            _sendVoiceBtn.enabled = NO;
            _sendAgainBtn.enabled = NO;
        }];

    }                                  fail:^(NSError *error) {
        [GCDQueue executeInMainQueue:^{
            _tipLabel.text = LMLocalizedString(@"Login SMS code sent failure", nil);
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Send failed", nil) withType:ToastTypeFail showInView:self.view complete:nil];
            _sendAgainBtn.enabled = YES;
            [weakSelf.view layoutIfNeeded];
        }];
    }];
}

- (void)sendAgain {
    self.tipLabel.text = LMLocalizedString(@"Login SMS code is sending", nil);
    self.sendAgainBtn.enabled = NO;
    [self sendCodeWithType:1];
}

- (void)textValueChange {
    if (_codeField.text.length == kMaxLength) {
        // Automatically initiate verification
        [self next];
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
