//
//  RegisteredPrivkeyLoginPage.m
//  Connect
//
//  Created by MoHuilin on 2016/12/7.
//  Copyright © 2016年 Connect - P2P Encrypted Instant Message. All rights reserved.
//

#import "RegisteredPrivkeyLoginPage.h"
#import "BottomLineTextField.h"
#import "ConnectButton.h"
#import "LocalUserInfoView.h"
#import "NetWorkOperationTool.h"


@interface RegisteredPrivkeyLoginPage () <UITextFieldDelegate>

@property(nonatomic, strong) BottomLineTextField *passwordField;
@property(nonatomic, strong) ConnectButton *completeBtn;
@property(nonatomic, strong) LocalUserInfoView *accountUserNameView;
@property(nonatomic, strong) UILabel *tipLabel;

@property(nonatomic, strong) UITextField *passTipTextField;

@property(nonatomic, strong) GJCFCoreTextContentView *passTipTextView;

@property(nonatomic, strong) UserExistedToken *userToken;
// login user
@property(nonatomic, strong) AccountInfo *loginUser;

@property(nonatomic, strong) NSString *privteKey;


@end


#define MAX_TIP_LENGTH 10

@implementation RegisteredPrivkeyLoginPage


- (instancetype)initWithUserToken:(UserExistedToken *)userToken privkey:(NSString *)privkey {
    if (self = [super init]) {
        self.userToken = userToken;
        self.privteKey = privkey;
        self.loginUser = [AccountInfo new];
        self.loginUser.avatar = self.userToken.userInfo.avatar;
        self.loginUser.address = self.userToken.userInfo.address;
        self.loginUser.pub_key = self.userToken.userInfo.pubKey;
        self.loginUser.username = self.userToken.userInfo.username;
        self.loginUser.contentId = self.userToken.userInfo.connectId;
    }
    return self;
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

- (void)doLeft:(id)sender {

    if (self.navigationController.viewControllers.count > 2) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    } else {
        [super doLeft:sender];
    }
}


- (void)viewDidLoad {
    [self setNavigationTitleImage:@"logo_black_small"];
    [super viewDidLoad];
    [self setBlackfBackArrowItem];
}


- (void)setup {


    self.accountUserNameView = [LocalUserInfoView viewWithAccountInfo:self.loginUser];
    self.accountUserNameView.hidenArrowView = YES;
    [self.view addSubview:_accountUserNameView];
    self.accountUserNameView.frame = CGRectMake(0, AUTO_HEIGHT(320), AUTO_WIDTH(640), AUTO_HEIGHT(90));
    self.accountUserNameView.centerX = self.view.centerX;


    self.passwordField = [[BottomLineTextField alloc] init];
    _passwordField.secureTextEntry = YES;
    _passwordField.delegate = self;
    _passwordField.placeholder = LMLocalizedString(@"Login Password Standard Tip", nil);
    _passwordField.font = [UIFont systemFontOfSize:FONT_SIZE(48)];
    [_passwordField addTarget:self action:@selector(textValueChange:) forControlEvents:UIControlEventEditingChanged];
    [self.view addSubview:_passwordField];
    self.passwordField.size = self.accountUserNameView.size;
    self.passwordField.left = self.accountUserNameView.left;
    self.passwordField.top = self.accountUserNameView.bottom;


    GJCFCoreTextAttributedStringStyle *stringStyle = [[GJCFCoreTextAttributedStringStyle alloc] init];
    stringStyle.foregroundColor = [GJGCCommonFontColorStyle detailBigTitleColor];
    stringStyle.font = [UIFont systemFontOfSize:FONT_SIZE(28)];

    GJCFCoreTextParagraphStyle *paragrpahStyle = [[GJCFCoreTextParagraphStyle alloc] init];
    paragrpahStyle.lineBreakMode = kCTLineBreakByCharWrapping;
    paragrpahStyle.maxLineSpace = 5.f;
    paragrpahStyle.minLineSpace = 5.f;
    NSString *actionWord = LMLocalizedString(@"Login Edit", nil);
    NSString *str = [NSString stringWithFormat:LMLocalizedString(@"Login Password Hint", nil), [NSString stringWithFormat:@"%@ %@", LMLocalizedString(@"Login Not set", nil), actionWord]];
    NSString *passTip = str;
    NSMutableAttributedString *passTipAtt = [[NSMutableAttributedString alloc] initWithString:passTip attributes:[stringStyle attributedDictionary]];
    [passTipAtt addAttributes:[paragrpahStyle paragraphAttributedDictionary] range:NSMakeRange(0, passTipAtt.string.length)];

    // update
    GJCFCoreTextKeywordAttributedStringStyle *changePassTip = [[GJCFCoreTextKeywordAttributedStringStyle alloc] init];
    changePassTip.keyword = LMLocalizedString(@"Login Edit", nil);
    changePassTip.preGap = 3.0;
    changePassTip.endGap = 3.0;
    changePassTip.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    changePassTip.keywordColor = [UIColor colorWithRed:0.000 green:0.502 blue:1.000 alpha:1.000];
    [passTipAtt setKeywordEffectByStyle:changePassTip];

    GJCFCoreTextContentView *passTipTextView = [[GJCFCoreTextContentView alloc] init];
    self.passTipTextView = passTipTextView;
    passTipTextView.frame = AUTO_RECT(0, 0, 670, 40);
    passTipTextView.left = self.accountUserNameView.left;
    passTipTextView.top = self.passwordField.bottom + AUTO_HEIGHT(20);
    passTipTextView.contentBaseSize = passTipTextView.size;
    [self.view addSubview:passTipTextView];
    passTipTextView.contentAttributedString = passTipAtt;
    passTipTextView.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:passTipAtt forBaseContentSize:passTipTextView.contentBaseSize];


    __weak __typeof(&*self) weakSelf = self;
    // Add a response to the modified password prompt
    [passTipTextView appenTouchObserverForKeyword:actionWord withHanlder:^(NSString *keyword, NSRange keywordRange) {
        [weakSelf tapOnChangePassTip];
    }];

    NSString *tipString = LMLocalizedString(@"Login Password explain", nil);
    NSMutableAttributedString *tipAttrString = [[NSMutableAttributedString alloc] initWithString:tipString];
    [tipAttrString addAttribute:NSFontAttributeName
                          value:[UIFont systemFontOfSize:FONT_SIZE(28)]
                          range:NSMakeRange(0, tipString.length)];
    GJCFCoreTextContentView *tipTextView = [[GJCFCoreTextContentView alloc] init];
    tipTextView.frame = AUTO_RECT(0, 0, 670, 300);
    tipTextView.left = self.accountUserNameView.left;
    tipTextView.top = passTipTextView.bottom + AUTO_HEIGHT(20);
    tipTextView.contentBaseSize = tipTextView.size;
    [self.view addSubview:tipTextView];
    tipTextView.contentAttributedString = tipAttrString;
    tipTextView.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:tipAttrString forBaseContentSize:tipTextView.contentBaseSize];

    self.completeBtn = [[ConnectButton alloc] initWithNormalTitle:LMLocalizedString(@"Login Reset Password And Login", nil) disableTitle:nil];
    [self.view addSubview:_completeBtn];
    [_completeBtn addTarget:self action:@selector(tapCompleteBtn) forControlEvents:UIControlEventTouchUpInside];
    _completeBtn.bottom = self.view.bottom - AUTO_HEIGHT(477);
    _completeBtn.centerX = self.view.centerX;


}

- (void)tapOnChangePassTip {
    if (!self.completeBtn.enabled) {
        return;
    }
    __weak __typeof(&*self) weakSelf = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LMLocalizedString(@"Set Password Hint", nil) message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        weakSelf.passTipTextField = textField;
        [GCDQueue executeInMainQueue:^{
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFiledEditChanged:)
                                                         name:UITextFieldTextDidChangeNotification object:textField];
        }];
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Set Save", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        weakSelf.loginUser.password_hint = weakSelf.passTipTextField.text;
        weakSelf.passTipTextField.text = nil;
        //Empty state
        [weakSelf reloadTipView];
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];

    alertController.automaticallyAdjustsScrollViewInsets = NO;
    [self presentViewController:alertController animated:YES completion:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (self.completeBtn.enabled) {
        [self tapCompleteBtn];
    }
    return YES;
}

- (void)textFiledEditChanged:(NSNotification *)obj {
    UITextField *textField = (UITextField *) obj.object;
    NSString *toBeString = textField.text;
    NSString *lang = [textField.textInputMode primaryLanguage];
    if ([lang isEqualToString:@"zh-Hans"]) {
        // Get the highlight section
        UITextRange *selectedRange = [textField markedTextRange];
        UITextPosition *position = [textField positionFromPosition:selectedRange.start offset:0];
        // If there is no highlighted word, the number of words that have been entered is counted and restricted
        if (!position) {
            if (toBeString.length > MAX_TIP_LENGTH) {
                textField.text = [toBeString substringToIndex:MAX_TIP_LENGTH];
            }
        }
    }
        // Chinese input method other than the statistical restrictions can be directly, regardless of other language situation
    else {
        if (toBeString.length > MAX_TIP_LENGTH) {
            NSRange rangeIndex = [toBeString rangeOfComposedCharacterSequenceAtIndex:MAX_TIP_LENGTH];
            if (rangeIndex.length == 1) {
                textField.text = [toBeString substringToIndex:MAX_TIP_LENGTH];
            } else {
                NSRange rangeRange = [toBeString rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, MAX_TIP_LENGTH)];
                textField.text = [toBeString substringWithRange:rangeRange];
            }
        }
    }
}


- (void)reloadTipView {
    GJCFCoreTextAttributedStringStyle *stringStyle = [[GJCFCoreTextAttributedStringStyle alloc] init];
    stringStyle.foregroundColor = [GJGCCommonFontColorStyle detailBigTitleColor];
    stringStyle.font = [UIFont systemFontOfSize:FONT_SIZE(28)];

    GJCFCoreTextParagraphStyle *paragrpahStyle = [[GJCFCoreTextParagraphStyle alloc] init];
    paragrpahStyle.lineBreakMode = kCTLineBreakByCharWrapping;
    paragrpahStyle.maxLineSpace = 5.f;
    paragrpahStyle.minLineSpace = 5.f;
    NSString *passT = GJCFStringIsNull(self.passTipTextField.text) ? self.loginUser.password_hint : self.passTipTextField.text;
    NSString *str = [NSString stringWithFormat:LMLocalizedString(@"Login Password Hint", nil), passT];
    NSString *passTip = [str stringByAppendingString:LMLocalizedString(@"Login Edit", nil)];
    NSMutableAttributedString *passTipAtt = [[NSMutableAttributedString alloc] initWithString:passTip attributes:[stringStyle attributedDictionary]];
    [passTipAtt addAttributes:[paragrpahStyle paragraphAttributedDictionary] range:NSMakeRange(0, passTipAtt.string.length)];
    // Modify the text
    GJCFCoreTextKeywordAttributedStringStyle *changePassTip = [[GJCFCoreTextKeywordAttributedStringStyle alloc] init];
    changePassTip.keyword = LMLocalizedString(@"Login Edit", nil);
    changePassTip.preGap = 3.0;
    changePassTip.endGap = 3.0;
    changePassTip.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    changePassTip.keywordColor = [UIColor colorWithRed:0.000 green:0.502 blue:1.000 alpha:1.000];
    [passTipAtt setKeywordEffectByStyle:changePassTip];
    self.passTipTextView.contentAttributedString = passTipAtt;


    __weak __typeof(&*self) weakSelf = self;
    // Add a response to the modified password prompt
    [self.passTipTextView appenTouchObserverForKeyword:changePassTip.keyword withHanlder:^(NSString *keyword, NSRange keywordRange) {
        [weakSelf tapOnChangePassTip];
    }];
    self.passTipTextView.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:passTipAtt forBaseContentSize:self.passTipTextView.contentBaseSize];

    [GCDQueue executeInMainQueue:^{
        [self.view layoutIfNeeded];
    }];


}

#pragma mark - event

- (void)saveUserInfoToKeyChain {
    self.loginUser.lastLoginTime = [[NSDate date] timeIntervalSince1970];
    // phone number
    self.loginUser.bonding = self.userToken.binding;
    // Save the current login user
    [[MMAppSetting sharedSetting] saveUserToKeyChain:self.loginUser];
    [[MMAppSetting sharedSetting] saveLoginUserPrivkey:self.loginUser.prikey];
}

- (void)tapCompleteBtn {
    BOOL passLegal = [RegexKit vilidatePassword:_passwordField.text];
    if (!passLegal) {
        [MBProgressHUD showToastwithText:LMLocalizedString(@"Login letter number and character must be included in your login password", nil) withType:ToastTypeFail showInView:self.view complete:nil];
        return;
    }
    __weak typeof(self) weakSelf = self;
    UserPrivateSign *privateSign = [[UserPrivateSign alloc] init];
    privateSign.token = self.userToken.token;
    NSString *encodePrivkey = [KeyHandle getEncodePrikey:self.privteKey withBitAddress:self.loginUser.address password:self.passwordField.text];
    self.loginUser.encryption_pri = encodePrivkey;
    privateSign.encryptionPri = encodePrivkey;
    privateSign.passwordHint = self.loginUser.password_hint;

    [MBProgressHUD showMessage:LMLocalizedString(@"Common Loading", nil) toView:self.view];
    [NetWorkOperationTool POSTWithUrlString:PrivkeySignupUrl postProtoData:privateSign.data pirkey:self.privteKey publickey:[KeyHandle createPubkeyByPrikey:self.privteKey] complete:^(id response) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:self.view];
            HttpResponse *hResponse = (HttpResponse *) response;
            if (hResponse.code != successCode) {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:hResponse.message withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                }];
            } else {
                [GCDQueue executeInGlobalQueue:^{
                    [self saveUserInfoToKeyChain];
                }];
                [[LKUserCenter shareCenter] LoginUserWithAccountUser:self.loginUser withPassword:self.passwordField.text withComplete:nil];

            }
        }];
    }                                  fail:^(NSError *error) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:self.view];
        }];
    }];
}

- (void)textValueChange:(UITextField *)sender {

}

#pragma mark - getter setter

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

@end
