//
//  PhoneLoginPage.m
//  Connect
//
//  Created by MoHuilin on 16/5/9.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "PhoneLoginPage.h"
#import "VertifyCodePage.h"
#import "ScanQRCodePage.h"
#import "ConnectButton.h"
#import "ConnectLabel.h"
#import "LocalAccountLoginPage.h"
#import "LMRandomSeedController.h"
#import "NSData+Base64.h"
#import "SelectCountryView.h"
#import "BottomLineTextField.h"
#import "SelectCountryViewController.h"
#import "NetWorkOperationTool.h"
#import "RegisteredPrivkeyLoginPage.h"
#import "SystemTool.h"
#import "SetUserInfoPage.h"

@interface PhoneLoginPage ()

@property(nonatomic, strong) SelectCountryView *selectCountryInfo;
@property(nonatomic, strong) BottomLineTextField *phoneField;
@property(nonatomic, strong) ConnectButton *nextBtn;
@property(nonatomic, strong) ConnectLabel *tipLabel;

@property(nonatomic, strong) NSString *scanCodeString;
// country code
@property(nonatomic, assign) int countryCode;
@property(nonatomic, copy) NSString *coutryLocalCode;

@end

@implementation PhoneLoginPage

#pragma mark - life crycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    [self.navigationController.navigationBar lt_setBackgroundColor:[UIColor clearColor]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar lt_reset];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // need force update
    if ([SessionManager sharedManager].currentNewVersionInfo.force) {
        [UIAlertController showAlertInViewController:self withTitle:LMLocalizedString(@"Set Found new version", nil) message:[SessionManager sharedManager].currentNewVersionInfo.remark cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@[LMLocalizedString(@"Set Now update app", nil)] tapBlock:^(UIAlertController *_Nonnull controller, UIAlertAction *_Nonnull action, NSInteger buttonIndex) {
            // native distribution
            if ([SystemTool isNationChannel]) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:nationalAppDownloadUrl]];
            } else { // open appstore
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appstoreAppDownloadUrl]];
            }
        }];
    }
}

#pragma mark - 初始化

- (void)setup {


    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_black_middle"]];
    [self.view addSubview:logoImageView];
    logoImageView.frame = AUTO_RECT(0, 210, 300, 73);
    logoImageView.centerX = self.view.centerX;


    self.coutryLocalCode = [RegexKit countryCode];
    NSNumber *countryPhoneCode = [RegexKit phoneCode];
    self.countryCode = [countryPhoneCode intValue];
    NSString *disPlayName = [[NSLocale currentLocale] displayNameForKey:NSLocaleCountryCode value:self.coutryLocalCode];
    SelectCountryView *selectCountryInfo = [SelectCountryView viewWithCountryName:disPlayName countryCode:countryPhoneCode.intValue];
    self.selectCountryInfo = selectCountryInfo;
    [self.view addSubview:selectCountryInfo];
    selectCountryInfo.top = logoImageView.bottom + AUTO_HEIGHT(100);
    selectCountryInfo.width = AUTO_WIDTH(660);
    selectCountryInfo.height = AUTO_HEIGHT(110);
    selectCountryInfo.centerX = self.view.centerX;
    [selectCountryInfo addTarget:self action:@selector(updateCountryInfo) forControlEvents:UIControlEventTouchUpInside];

    self.phoneField = [[BottomLineTextField alloc] init];
    _phoneField.keyboardType = UIKeyboardTypeNumberPad;
    [_phoneField addTarget:self action:@selector(textValueChange) forControlEvents:UIControlEventEditingChanged];
    _phoneField.placeholder = LMLocalizedString(@"Set Your Phone", nil);
    _phoneField.font = [UIFont systemFontOfSize:FONT_SIZE(48)];
    [self.view addSubview:_phoneField];

    _phoneField.size = selectCountryInfo.size;
    _phoneField.left = selectCountryInfo.left;
    _phoneField.top = selectCountryInfo.bottom;

    // verfification phone
    self.nextBtn = [[ConnectButton alloc] initWithNormalTitle:LMLocalizedString(@"Set Verify Phone", nil) disableTitle:nil];
    [self.view addSubview:_nextBtn];
    _nextBtn.enabled = NO;
    [_nextBtn addTarget:self action:@selector(nextBtnClick) forControlEvents:UIControlEventTouchUpInside];
    _nextBtn.bottom = self.view.bottom - AUTO_HEIGHT(477);
    _nextBtn.centerX = self.view.centerX;


    // text creat
    NSString *tipString = LMLocalizedString(@"Set After verified your phone login on another phone", nil);
    GJCFCoreTextAttributedStringStyle *stringStyle = [[GJCFCoreTextAttributedStringStyle alloc] init];
    stringStyle.foregroundColor = [GJGCCommonFontColorStyle detailBigTitleColor];
    stringStyle.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
    GJCFCoreTextParagraphStyle *paragrpahStyle = [[GJCFCoreTextParagraphStyle alloc] init];
    paragrpahStyle.lineBreakMode = kCTLineBreakByCharWrapping;
    paragrpahStyle.maxLineSpace = 0;
    paragrpahStyle.minLineSpace = 0;
    NSString *actionWord = LMLocalizedString(@"Set Import your local private key backup", nil);
    NSMutableAttributedString *passTipAtt = [[NSMutableAttributedString alloc] initWithString:tipString attributes:[stringStyle attributedDictionary]];
    [passTipAtt addAttributes:[paragrpahStyle paragraphAttributedDictionary] range:NSMakeRange(0, passTipAtt.string.length)];

    // update text
    GJCFCoreTextKeywordAttributedStringStyle *changePassTip = [[GJCFCoreTextKeywordAttributedStringStyle alloc] init];
    changePassTip.keyword = LMLocalizedString(@"Set Import your local private key backup", nil);
    changePassTip.preGap = 3.0;
    changePassTip.endGap = 3.0;
    changePassTip.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
    changePassTip.keywordColor = [UIColor colorWithRed:0.000 green:0.502 blue:1.000 alpha:1.000];
    [passTipAtt setKeywordEffectByStyle:changePassTip];


    GJCFCoreTextContentView *tipTextView = [[GJCFCoreTextContentView alloc] init];
    tipTextView.frame = AUTO_RECT(0, 0, 600, 150);
    tipTextView.top = self.nextBtn.bottom + AUTO_HEIGHT(70);
    tipTextView.left = selectCountryInfo.left;
    tipTextView.contentBaseSize = tipTextView.size;
    [self.view addSubview:tipTextView];
    tipTextView.contentAttributedString = passTipAtt;
    tipTextView.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:passTipAtt forBaseContentSize:tipTextView.contentBaseSize];

    __weak __typeof(&*self) weakSelf = self;
    // add password tip action
    [tipTextView appenTouchObserverForKeyword:actionWord withHanlder:^(NSString *keyword, NSRange keywordRange) {
        [weakSelf importOrLocalLogin];
    }];

}

#pragma mark - event

- (void)updateCountryInfo {
    SelectCountryViewController *page = [[SelectCountryViewController alloc] initWithCallBackBlock:^(id countryInfo) {
        self.countryCode = [countryInfo[@"phoneCode"] intValue];
        self.coutryLocalCode = [countryInfo valueForKey:@"countryCode"];
        [self.selectCountryInfo updateCountryInfoWithCountryName:[countryInfo valueForKey:@"countryName"] countryCode:self.countryCode];
        [self textValueChange];
    }];
    [self.navigationController pushViewController:page animated:YES];
}

- (void)nextBtnClick {
    VertifyCodePage *page = [[VertifyCodePage alloc] initWithCountryCode:self.countryCode phone:self.phoneField.text];
    [self.navigationController pushViewController:page animated:YES];
}

- (void)textValueChange {
    self.nextBtn.enabled = [RegexKit vilidatePhoneNum:self.phoneField.text region:self.coutryLocalCode];
}

- (void)importOrLocalLogin {
    
    [UIAlertController showActionSheetInViewController:self withTitle:nil message:nil cancelButtonTitle:LMLocalizedString(@"Common Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:@[LMLocalizedString(@"Login Scan your backup for login", nil),LMLocalizedString(@"Login Sign In Up Local account", nil)] popoverPresentationControllerBlock:^(UIPopoverPresentationController * _Nonnull popover) {
        
    } tapBlock:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action, NSInteger buttonIndex) {
        switch (buttonIndex) {
            case 2:
            {
                [GCDQueue executeInMainQueue:^{
                    ScanQRCodePage *page = [[ScanQRCodePage alloc] initWithCallBack:^(NSString *value) {
                        self.scanCodeString = value;
                        [self handleScanCodeString];
                    }];
                    [self.navigationController pushViewController:page animated:YES];
                }];
            }
                break;
            case 3:
            {
                [GCDQueue executeInMainQueue:^{
                    [self showLocalAcount];
                }];
            }
                break;
            default:
                break;
        }
    }];
}

- (void)handleScanCodeString {
    __weak typeof(self) weakSelf = self;
    if ([_scanCodeString hasPrefix:@"connect://"]) { // encription pri
        NSString *content = [_scanCodeString stringByReplacingOccurrencesOfString:@"connect://" withString:@""];
        NSData *data = [NSData dataWithBase64EncodedString:content];
        if (data) {
            ExoprtPrivkeyQrcode *exportQrcode = [ExoprtPrivkeyQrcode parseFromData:data error:nil];
            switch (exportQrcode.version) {
                case 1:
                case 2: {
                    AccountInfo *user = [[AccountInfo alloc] init];
                    user.username = exportQrcode.username;
                    user.encryption_pri = exportQrcode.encriptionPri;
                    user.password_hint = exportQrcode.passwordHint;
                    user.bondingPhone = exportQrcode.phone;
                    user.contentId = exportQrcode.connectId;
                    user.avatar = [NSString stringWithFormat:@"%@/avatar/v1/%@.jpg", baseServer,exportQrcode.avatar];
                    AccountInfo *getChainUser = [[MMAppSetting sharedSetting] getLoginChainUsersByEncodePri:user.encryption_pri];
                    if (getChainUser) {
                        user = getChainUser;
                        if (exportQrcode.phone.length > 0) {
                            user.bondingPhone = exportQrcode.phone;
                        }
                        
                    }
                    LocalAccountLoginPage *page = [[LocalAccountLoginPage alloc] initWithUser:user];
                    [self.navigationController pushViewController:page animated:YES];
                }
                    break;
                default:
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Invalid version number", nil) withType:ToastTypeFail showInView:self.view complete:nil];
                    }];
                    break;
            }
        } else {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"ErrorCode data error", nil) withType:ToastTypeFail showInView:self.view complete:nil];
            }];
        }
    } else {
        if ([KeyHandle checkPrivkey:_scanCodeString]) {
            [MBProgressHUD showLoadingMessageToView:self.view];
            // weathre is regist prikey
            [NetWorkOperationTool POSTWithUrlString:PrivkeyLoginExistedUrl postProtoData:nil pirkey:_scanCodeString publickey:[KeyHandle createPubkeyByPrikey:_scanCodeString] complete:^(id response) {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD hideHUDForView:self.view];
                }];
                HttpResponse *hResponse = (HttpResponse *) response;
                if (hResponse.code == 2404) {
                    SetUserInfoPage *page = [[SetUserInfoPage alloc] initWithPrikey:_scanCodeString];
                    [self.navigationController pushViewController:page animated:YES];
                } else if(hResponse.code != successCode){
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Set Query failed", nil) withType:ToastTypeFail showInView:self.view complete:nil];
                    }];
                    return;
                }else {
                    NSData *data = [ConnectTool decodeHttpResponse:hResponse withPrivkey:_scanCodeString publickey:nil emptySalt:YES];
                    if (data && data.length > 0) {
                        NSError *error = nil;
                        UserExistedToken *userExisted = [UserExistedToken parseFromData:data error:&error];
                        if (!error) {
                            RegisteredPrivkeyLoginPage *page = [[RegisteredPrivkeyLoginPage alloc] initWithUserToken:userExisted privkey:_scanCodeString];
                            [self.navigationController pushViewController:page animated:YES];
                        }
                    }
                }
            }                                  fail:^(NSError *error) {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD hideHUDForView:self.view];
                    [MBProgressHUD showToastwithText:[LMErrorCodeTool showToastErrorType:ToastErrorTypeLoginOrReg withErrorCode:error.code withUrl:PrivkeyLoginExistedUrl] withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                }];
            }];
        }
    }
}

- (void)showLocalAcount {
    NSArray *users = [[MMAppSetting sharedSetting] getKeyChainUsers];
    if (users.count <= 0) {
        LMRandomSeedController *randomSeedVC = [[LMRandomSeedController alloc] init];
        [self.navigationController pushViewController:randomSeedVC animated:YES];
    } else {
        LocalAccountLoginPage *page = [[LocalAccountLoginPage alloc] initWithLocalUsers:users];
        [self.navigationController pushViewController:page animated:YES];
    }
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

@end
