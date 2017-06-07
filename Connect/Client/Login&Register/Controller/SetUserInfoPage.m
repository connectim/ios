//
//  SetUserInfoPage.m
//  Connect
//
//  Created by MoHuilin on 16/5/11.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "SetUserInfoPage.h"

#import "StringTool.h"
#import "ConnectButton.h"

#import "NetWorkOperationTool.h"
#import "BottomLineTextField.h"
#import "YYImageCache.h"
#import "UIImage+YYAdd.h"
#import "CameraTool.h"
#import "CaptureAvatarPage.h"


#define MAX_TIP_LENGTH 10

@interface SetUserInfoPage () <UITextFieldDelegate>

@property(nonatomic, strong) UIImageView *avatarView;
@property(nonatomic, strong) UIImageView *bgIamgeView;
@property(nonatomic, strong) BottomLineTextField *nickNameFiled;
@property(nonatomic, strong) BottomLineTextField *passwordField;
@property(nonatomic, strong) ConnectButton *completeBtn;
@property(nonatomic, strong) UILabel *tipLabel;
@property(nonatomic, strong) UIImage *clipImage;
@property(nonatomic, strong) UIImage *originImage;
@property(nonatomic, copy) NSString *randomStrBySound;
@property(nonatomic, copy) NSString *commonRandomStr;
@property(nonatomic, copy) NSString *mobile;
@property(nonatomic, copy) NSString *token;
@property(nonatomic, copy) NSString *prikey;
@property(nonatomic, copy) NSString *pubKey;
@property(nonatomic, copy) NSString *address;
@property(nonatomic, copy) NSString *passwordTip;
@property(nonatomic, copy) NSString *avatar;
@property(nonatomic, copy) NSString *encryptionPrikey;
@property(nonatomic, strong) ServerInfo *serInfo;
@property(nonatomic, strong) AccountInfo *currentAccount;
// set userName and pass view
@property(nonatomic, strong) UIView *contentView;
// pass tip
@property(nonatomic, strong) UITextField *passTipTextField;
@property(nonatomic, strong) GJCFCoreTextContentView *passTipTextView;
// weather is upload avatar
@property(nonatomic, assign) BOOL uploadingAvataring;

@end

@implementation SetUserInfoPage

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

- (instancetype)initWithStr:(NSString *)dataStr {
    if (self = [super init]) {
        self.randomStrBySound = dataStr;
        self.avatar = DefaultHeadUrl;
        self.avatarView.image = self.clipImage;
    }
    return self;
}

- (instancetype)initWithPrikey:(NSString *)prikey {
    if (self = [super init]) {
        self.avatar = DefaultHeadUrl;
        self.avatarView.image = self.clipImage;
        self.prikey = prikey;
    }
    return self;
}

- (instancetype)initWithStr:(NSString *)str mobile:(NSString *)mobile token:(NSString *)token {
    if (self = [super init]) {
        self.randomStrBySound = str;
        self.mobile = mobile;
        self.token = token;
        self.avatar = DefaultHeadUrl;
        self.avatarView.image = self.clipImage;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setNavigationTitleImage:@"logo_black_small"];
    [self setBlackfBackArrowItem];
    NSData *randomData = [KeyHandle createRandom512bits];
    self.commonRandomStr = [StringTool hexStringFromData:randomData];
    // or
    NSString *random = [StringTool pinxCreator:self.commonRandomStr withPinv:self.randomStrBySound];
    DDLogInfo(@"random :%@ length:%lu", random, (unsigned long) random.length);
    if (self.prikey.length <= 0) {
        // Generates a private key from a random number
        self.prikey = [KeyHandle creatNewPrivkeyByRandomStr:random];
    }
    self.pubKey = [KeyHandle createPubkeyByPrikey:_prikey];
    self.address = [KeyHandle getAddressByPubkey:_pubKey];
}

- (void)dealloc {
    RemoveNofify;
}

#pragma mark - set up

- (void)setup {

    self.avatarView = [UIImageView new];
    [self.view addSubview:_avatarView];
    self.avatarView.image = [UIImage imageNamed:@"singup_change_avatar"];
    self.avatarView.layer.cornerRadius = 5;
    self.avatarView.layer.masksToBounds = YES;
    self.avatarView.frame = CGRectMake(0, AUTO_HEIGHT(177), AUTO_WIDTH(130), AUTO_WIDTH(130));
    self.avatarView.centerX = self.view.centerX;
    self.avatarView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(avatarViewTapAction:)];
    [self.avatarView addGestureRecognizer:tapGes];


    self.nickNameFiled = [[BottomLineTextField alloc] init];
    _nickNameFiled.delegate = self;
    _nickNameFiled.placeholder = LMLocalizedString(@"Set Name", nil);
    _nickNameFiled.font = [UIFont systemFontOfSize:FONT_SIZE(36)];
    [self.view addSubview:_nickNameFiled];
    self.nickNameFiled.frame = CGRectMake(0, self.avatarView.bottom + AUTO_HEIGHT(30), AUTO_WIDTH(640), AUTO_HEIGHT(110));
    self.nickNameFiled.centerX = self.view.centerX;

    self.passwordField = [[BottomLineTextField alloc] init];
    _passwordField.secureTextEntry = YES;
    _passwordField.delegate = self;


    _passwordField.placeholder = LMLocalizedString(@"Login Password Standard Tip", nil);
    _passwordField.font = [UIFont systemFontOfSize:FONT_SIZE(36)];
    [_passwordField addTarget:self action:@selector(textValueChange:) forControlEvents:UIControlEventEditingChanged];
    [_nickNameFiled addTarget:self action:@selector(textValueChange:) forControlEvents:UIControlEventEditingChanged];
    [self.view addSubview:_passwordField];
    self.passwordField.size = self.nickNameFiled.size;
    self.passwordField.left = self.nickNameFiled.left;
    self.passwordField.top = self.nickNameFiled.bottom;


    GJCFCoreTextAttributedStringStyle *stringStyle = [[GJCFCoreTextAttributedStringStyle alloc] init];
    stringStyle.foregroundColor = [GJGCCommonFontColorStyle detailBigTitleColor];
    stringStyle.font = [UIFont systemFontOfSize:FONT_SIZE(28)];

    GJCFCoreTextParagraphStyle *paragrpahStyle = [[GJCFCoreTextParagraphStyle alloc] init];
    paragrpahStyle.lineBreakMode = kCTLineBreakByCharWrapping;
    paragrpahStyle.maxLineSpace = 5.f;
    paragrpahStyle.minLineSpace = 5.f;
    NSString *actionWord = LMLocalizedString(@"Login Edit", nil);
    NSString *passTip = [NSString stringWithFormat:LMLocalizedString(@"Login Password Hint", nil), [NSString stringWithFormat:@"%@ %@", LMLocalizedString(@"Login Not set", nil), actionWord]];
    NSMutableAttributedString *passTipAtt = [[NSMutableAttributedString alloc] initWithString:passTip attributes:[stringStyle attributedDictionary]];
    [passTipAtt addAttributes:[paragrpahStyle paragraphAttributedDictionary] range:NSMakeRange(0, passTipAtt.string.length)];

    // update text
    GJCFCoreTextKeywordAttributedStringStyle *changePassTip = [[GJCFCoreTextKeywordAttributedStringStyle alloc] init];
    changePassTip.keyword = LMLocalizedString(@"Login Edit", nil);
    changePassTip.preGap = 3.0;
    changePassTip.endGap = 3.0;
    changePassTip.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
    changePassTip.keywordColor = [UIColor colorWithRed:0.000 green:0.502 blue:1.000 alpha:1.000];
    [passTipAtt setKeywordEffectByStyle:changePassTip];

    GJCFCoreTextContentView *passTipTextView = [[GJCFCoreTextContentView alloc] init];
    self.passTipTextView = passTipTextView;
    passTipTextView.frame = AUTO_RECT(0, 0, 670, 40);
    passTipTextView.left = self.nickNameFiled.left;
    passTipTextView.top = self.passwordField.bottom + AUTO_HEIGHT(20);
    passTipTextView.contentBaseSize = passTipTextView.size;
    [self.view addSubview:passTipTextView];
    passTipTextView.contentAttributedString = passTipAtt;
    passTipTextView.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:passTipAtt forBaseContentSize:passTipTextView.contentBaseSize];


    __weak __typeof(&*self) weakSelf = self;
    // add password action
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
    tipTextView.left = self.nickNameFiled.left;
    tipTextView.top = passTipTextView.bottom + AUTO_HEIGHT(20);
    tipTextView.contentBaseSize = tipTextView.size;
    [self.view addSubview:tipTextView];
    tipTextView.contentAttributedString = tipAttrString;
    tipTextView.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:tipAttrString forBaseContentSize:tipTextView.contentBaseSize];

    self.completeBtn = [[ConnectButton alloc] initWithNormalTitle:LMLocalizedString(@"Chat Complete", nil) disableTitle:nil];
    [self.view addSubview:_completeBtn];
    _completeBtn.enabled = NO;
    [_completeBtn addTarget:self action:@selector(tapCompleteBtn) forControlEvents:UIControlEventTouchUpInside];
    _completeBtn.bottom = self.view.bottom - AUTO_HEIGHT(477);
    _completeBtn.centerX = self.view.centerX;
}

- (void)avatarViewTapAction:(UITapGestureRecognizer *)tapGes {
    __weak typeof(self) weakSelf = self;
    CaptureAvatarPage *page = [[CaptureAvatarPage alloc] init];
    page.registImageBlock = ^(UIImage *clipImage, UIImage *originImage) {
        NSData *imageData = UIImageJPEGRepresentation(clipImage, 0.5);
        clipImage = [UIImage imageWithData:imageData];
        weakSelf.clipImage = clipImage;
        weakSelf.originImage = originImage;
        if ([weakSelf.avatar isEqualToString:DefaultHeadUrl]) {
            weakSelf.avatarView.image = [UIImage imageNamed:@"sigup_album"];
        }
        // upload user
        [weakSelf uploadAvatar];
    };
    [self.navigationController pushViewController:page animated:YES];
}

- (void)tapOnChangePassTip {

    __weak __typeof(&*self) weakSelf = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LMLocalizedString(@"Login Login Password Hint Title", nil) message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        weakSelf.passTipTextField = textField;
        if ([weakSelf.passwordTip containsString:@"＊＊＊"]) {
            weakSelf.passTipTextField.placeholder = weakSelf.passwordTip;
        } else {
            weakSelf.passTipTextField.text = weakSelf.passwordTip;
        }
        [GCDQueue executeInMainQueue:^{
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFiledEditChanged:)
                                                         name:UITextFieldTextDidChangeNotification object:textField];
        }];
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Set Save", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        weakSelf.passwordTip = weakSelf.passTipTextField.text;
        if (weakSelf.passwordTip.length <= 0) {
            weakSelf.passwordTip = [NSString stringWithFormat:@"%@＊＊＊＊＊%@", [weakSelf.passwordField.text substringToIndex:1], [weakSelf.passwordField.text substringFromIndex:weakSelf.passwordField.text.length - 1]];
        }
        weakSelf.passTipTextField.text = nil; // clear status
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
    } else {
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
    NSString *passT = GJCFStringIsNull(self.passTipTextField.text) ? self.passwordTip : self.passTipTextField.text;
    NSString *str = [NSString stringWithFormat:LMLocalizedString(@"Login Password Hint", nil), passT];
    NSString *passTip = [str stringByAppendingString:LMLocalizedString(@"Login Edit", nil)];
    NSMutableAttributedString *passTipAtt = [[NSMutableAttributedString alloc] initWithString:passTip attributes:[stringStyle attributedDictionary]];
    [passTipAtt addAttributes:[paragrpahStyle paragraphAttributedDictionary] range:NSMakeRange(0, passTipAtt.string.length)];
    // update text
    GJCFCoreTextKeywordAttributedStringStyle *changePassTip = [[GJCFCoreTextKeywordAttributedStringStyle alloc] init];
    changePassTip.keyword = LMLocalizedString(@"Login Edit", nil);
    changePassTip.preGap = 3.0;
    changePassTip.endGap = 3.0;
    changePassTip.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    changePassTip.keywordColor = [UIColor colorWithRed:0.000 green:0.502 blue:1.000 alpha:1.000];
    [passTipAtt setKeywordEffectByStyle:changePassTip];
    self.passTipTextView.contentAttributedString = passTipAtt;

    __weak __typeof(&*self) weakSelf = self;
    // add pass action
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

    // set user login message
    self.currentAccount = [[AccountInfo alloc] init];
    _currentAccount.address = _address;
    _currentAccount.avatar = _avatar;
    _currentAccount.encryption_pri = _encryptionPrikey;
    _currentAccount.password_hint = _passwordTip;
    _currentAccount.pub_key = _pubKey;
    _currentAccount.username = _nickNameFiled.text;
    _currentAccount.address = _address;
    _currentAccount.prikey = _prikey;
    _currentAccount.contentId = _address;
    _currentAccount.lastLoginTime = [[NSDate date] timeIntervalSince1970];
    // phone
    if (!GJCFStringIsNull(self.mobile)) {
        _currentAccount.bondingPhone = self.mobile;
    }

    // save curent user
    [[MMAppSetting sharedSetting] saveUserToKeyChain:_currentAccount];
    [[MMAppSetting sharedSetting] saveLoginUserPrivkey:_prikey];
}

- (void)uploadAvatar {

    [MBProgressHUD showMessage:LMLocalizedString(@"Common Loading", nil) toView:self.view];
    self.uploadingAvataring = YES;
    __weak __typeof(&*self) weakSelf = self;
    NSData *imageData = UIImageJPEGRepresentation(_clipImage, 1.0);
    // limit less than 2M
    imageData = [CameraTool imageSizeLessthan2M:imageData withOriginImage:_clipImage];
    [NetWorkOperationTool POSTWithUrlString:UserSetOrUpdataAvatar noSignProtoData:imageData complete:^(id response) {
        HttpNotSignResponse *hResponse = (HttpNotSignResponse *) response;
        [MBProgressHUD hideHUDForView:weakSelf.view];
        weakSelf.uploadingAvataring = NO;
        if (hResponse.code != successCode) {
            DDLogError(@"Server error");
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Avatar upload failed", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
            }];
        } else {
            NSError *error = nil;
            AvatarInfo *userHead = [AvatarInfo parseFromData:hResponse.body error:&error];
            // refresh cache
            NSString *avatarName = [NSString stringWithFormat:@"%@.png", [userHead.URL md5String]];
            NSString *filePath = [[GJCFCachePathManager shareManager] mainImageCacheDirectory];
            filePath = [filePath stringByAppendingPathComponent:@"ContactAvatars"];
            if (!GJCFFileDirectoryIsExist(filePath)) {
                GJCFFileDirectoryCreate(filePath);
            }
            NSString *avatarPath = [filePath stringByAppendingPathComponent:avatarName];
            GJCFFileWrite(imageData, avatarPath);
            if (!error) {
                DDLogInfo(@"userhead success!");
                weakSelf.avatar = userHead.URL;
                weakSelf.avatarView.image = weakSelf.clipImage;
            }

        }
    }                                  fail:^(NSError *error) {
        weakSelf.uploadingAvataring = NO;
        [GCDQueue executeInMainQueue:^{
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD hideHUDForView:weakSelf.view];
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Avatar upload failed", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
            }];
        }];
    }];
}

- (void)registerAction {
    __weak __typeof(&*self) weakSelf = self;
    if (GJCFStringIsNull(_nickNameFiled.text)) {
        self.completeBtn.enabled = NO;
        return;
    }
    if (![RegexKit vilidatePassword:_passwordField.text]) {
        self.completeBtn.enabled = NO;
        return;
    }
    _nickNameFiled.text = [StringTool filterStr:_nickNameFiled.text];
    // Encrypt private key string
    self.encryptionPrikey = [KeyHandle getEncodePrikey:_prikey withBitAddress:_address password:_passwordField.text];
    RegisterUser *regisUser = [[RegisterUser alloc] init];
    regisUser.avatar = self.avatar;
    regisUser.username = _nickNameFiled.text;
    regisUser.encryptionPri = _encryptionPrikey;
    regisUser.passwordHint = _passwordTip;
    // phone number
    if (!GJCFStringIsNull(self.mobile)) {
        regisUser.mobile = self.mobile;
        if (self.token) {
            regisUser.token = self.token;
        }
    }
    [MBProgressHUD showMessage:LMLocalizedString(@"Common Loading", nil) toView:self.view];
    [NetWorkOperationTool POSTWithUrlString:LoginSignUpUrl postProtoData:regisUser.data pirkey:self.prikey publickey:self.pubKey complete:^(id response) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:weakSelf.view];
        }];
        HttpResponse *hResponse = (HttpResponse *) response;
        if (hResponse.code != successCode) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:[LMErrorCodeTool showToastErrorType:ToastErrorTypeLoginOrReg withErrorCode:hResponse.code withUrl:LoginSignUpUrl] withType:ToastTypeFail showInView:weakSelf.view complete:nil];
            }];
            return;
        }
        // save user message
        [weakSelf saveUserInfoToKeyChain];
        // refrsh cache
        UIImage *corImage = [self.clipImage imageByRoundCornerRadius:6];
        [[YYImageCache sharedCache] setImage:self.clipImage forKey:[NSString stringWithFormat:@"%@?size=600", self.avatar]];
        [[YYImageCache sharedCache] setImage:corImage forKey:self.avatar];
        // regiset message
        [[LKUserCenter shareCenter] registerUser:self.currentAccount];
    }  fail:^(NSError *error) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
        }];
    }];

}


- (void)tapCompleteBtn {
    BOOL passLegal = [RegexKit vilidatePassword:_passwordField.text];
    if (passLegal) {
        [self registerAction];
    } else {
        [MBProgressHUD showToastwithText:LMLocalizedString(@"Login letter number and character must be included in your login password", nil) withType:ToastTypeFail showInView:self.view complete:nil];
    }
}

- (void)textValueChange:(UITextField *)sender {
    BOOL nickLegal = [RegexKit nameLengthLimit:_nickNameFiled.text] && ![[_nickNameFiled.text uppercaseString] isEqualToString:@"CONNECT"];
    _completeBtn.enabled = nickLegal;
}

#pragma mark - getter setter

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

@end
