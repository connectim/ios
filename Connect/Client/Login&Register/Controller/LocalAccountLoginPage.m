//
//  LocalAccountLoginPage.m
//  Connect
//
//  Created by MoHuilin on 16/5/12.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LocalAccountLoginPage.h"
#import "ConnectButton.h"
#import "LocalUserInfoView.h"
#import "BottomLineTextField.h"
#import "SelectLoginUserViewController.h"
#import "LMRandomSeedController.h"


@interface LocalAccountLoginPage () <UITextFieldDelegate>

@property(nonatomic, strong) LocalUserInfoView *accountUserNameView;
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UILabel *passTipLabel;
@property(nonatomic, strong) BottomLineTextField *passwordField;
@property(nonatomic, strong) ConnectButton *loginBtn;
@property(nonatomic, strong) AccountInfo *selectedAccount;
//is phone download user login
@property(nonatomic, assign) BOOL phoneLogin;

@property (nonatomic ,strong) NSMutableArray *chainUsers;

@end

@implementation LocalAccountLoginPage


- (instancetype)initWithUser:(AccountInfo *)downUser {
    if (self = [super init]) {
        if (downUser) {
            self.selectedAccount = downUser;
            self.phoneLogin = YES;
        }
    }
    return self;
}

- (instancetype)initWithLocalUsers:(NSArray *)users{
    if (self = [super init]) {
        self.chainUsers = [NSMutableArray arrayWithArray:users];
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

    if (!self.phoneLogin) {
        [self setNavigationRight:LMLocalizedString(@"Login Sign Up", nil) titleColor:LMBasicTextButtonColor];

    }
    [self setNavigationTitleImage:@"logo_black_small"];
    [super viewDidLoad];
    [self setBlackfBackArrowItem];
}


#pragma mark - init

- (void)setup {

    self.view.backgroundColor = [UIColor whiteColor];

    self.titleLabel = [[UILabel alloc] init];
    if (self.phoneLogin) {
        _titleLabel.text = LMLocalizedString(@"Login Welcome", nil);
    } else {
        _titleLabel.text = LMLocalizedString(@"Login Local account", nil);
    }
    _titleLabel.frame = AUTO_RECT(0, 250, 750, 50);
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(36)];
    [self.view addSubview:_titleLabel];

    if (!self.selectedAccount) {
        self.selectedAccount = [self.chainUsers objectAtIndexCheck:0];
        self.selectedAccount.isSelected = YES;
    }

    self.accountUserNameView = [LocalUserInfoView viewWithAccountInfo:_selectedAccount];
    NSUInteger localSourceValue = self.localSourceType;
    self.accountUserNameView.soureInfoType = localSourceValue;
    if (self.localSourceType != SourTypeEncryPri) {
        [_accountUserNameView addTarget:self action:@selector(tapAccountNameView) forControlEvents:UIControlEventTouchUpInside];
    }
    [self.view addSubview:_accountUserNameView];
    self.accountUserNameView.top = _titleLabel.bottom + AUTO_HEIGHT(75);
    self.accountUserNameView.width = AUTO_WIDTH(660);
    self.accountUserNameView.height = AUTO_HEIGHT(110);
    self.accountUserNameView.centerX = self.view.centerX;

    self.passwordField = [[BottomLineTextField alloc] init];
    _passwordField.secureTextEntry = YES;
    _passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _passwordField.placeholder = LMLocalizedString(@"Login Password", nil);
    _passwordField.delegate = self;
    _passwordField.returnKeyType = UIReturnKeyContinue;
    _passwordField.font = [UIFont systemFontOfSize:FONT_SIZE(36)];
    _passwordField.textColor = LMBasicTextFieldColor;
    [_passwordField setEnablesReturnKeyAutomatically:YES];
    [self.view addSubview:_passwordField];
    _passwordField.size = self.accountUserNameView.size;
    _passwordField.left = self.accountUserNameView.left;
    _passwordField.top = self.accountUserNameView.bottom;

    self.passTipLabel = [[UILabel alloc] init];
    _passTipLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Login Password Hint", nil), _selectedAccount.password_hint];
    _passTipLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
    _passTipLabel.textColor = LMBasicTextFieldColor;
    [self.view addSubview:_passTipLabel];
    _passTipLabel.left = self.accountUserNameView.left;
    _passTipLabel.top = self.passwordField.bottom + AUTO_HEIGHT(20);
    _passTipLabel.textAlignment = NSTextAlignmentLeft;
    _passTipLabel.size = CGSizeMake(AUTO_WIDTH(640), AUTO_HEIGHT(60));
    
    //hiden passtip
    self.passTipLabel.hidden = GJCFStringIsNull(self.selectedAccount.password_hint);

    self.loginBtn = [[ConnectButton alloc] initWithNormalTitle:LMLocalizedString(@"Login Login", nil) disableTitle:nil];
    [self.view addSubview:_loginBtn];
    [_loginBtn addTarget:self action:@selector(tapLoginBtn) forControlEvents:UIControlEventTouchUpInside];
    _loginBtn.bottom = self.view.bottom - AUTO_HEIGHT(477);
    _loginBtn.centerX = self.view.centerX;
}

- (void)setSelectedAccount:(AccountInfo *)selectedAccount {
    if ([_selectedAccount.address isEqualToString:selectedAccount.address]) {
        return;
    }
    _selectedAccount = selectedAccount;
    //pass tips
    _passTipLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Login Password Hint", nil), _selectedAccount.password_hint];
    self.passTipLabel.hidden = GJCFStringIsNull(self.selectedAccount.password_hint);
    
    //clear passText
    self.passwordField.text = nil;
    [self.accountUserNameView reloadWithUser:selectedAccount];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self tapLoginBtn];
    return YES;
}


- (NSArray *)subviewsOfView:(UIView *)view withType:(NSString *)type {
    NSString *prefix = [NSString stringWithFormat:@"<%@", type];
    NSMutableArray *subviewArray = [NSMutableArray array];
    for (UIView *subview in view.subviews) {
        NSArray *tempArray = [self subviewsOfView:subview withType:type];
        for (UIView *view in tempArray) {
            [subviewArray objectAddObject:view];
        }
    }
    if ([[view description] hasPrefix:prefix]) {
        [subviewArray objectAddObject:view];
    }
    return [NSArray arrayWithArray:subviewArray];
}

- (void)addColorToUIKeyboardButton {
    for (UIWindow *keyboardWindow in [[UIApplication sharedApplication] windows]) {
        for (UIView *keyboard in [keyboardWindow subviews]) {
            for (UIView *view in [self subviewsOfView:keyboard withType:@"UIKBKeyplaneView"]) {
                UIView *newView = [[UIView alloc] initWithFrame:[(UIView *) [[self subviewsOfView:keyboard withType:@"UIKBKeyView"] lastObject] frame]];
                newView.frame = CGRectMake(newView.frame.origin.x + 2, newView.frame.origin.y + 1, newView.frame.size.width - 4, newView.frame.size.height - 3);
                [newView setBackgroundColor:[UIColor greenColor]];
                newView.layer.cornerRadius = 4;
                [view insertSubview:newView belowSubview:((UIView *) [[self subviewsOfView:keyboard withType:@"UIKBKeyView"] lastObject])];

            }
        }
    }
}


#pragma mark - AccountListWidgetDelegate

- (void)accountListWidgetDidSelectAccount:(AccountInfo *)info {
    [UIView animateWithDuration:0.3 animations:^{
        _accountUserNameView.alpha = 1;
    }];
    if (self.selectedAccount == info) {
        return;
    }
    self.selectedAccount.isSelected = NO;
    self.selectedAccount = info;
    info.isSelected = YES;
    _passTipLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Login Password Hint", nil), info.password_hint];
    _passwordField.text = @"";
}

- (void)accountListWidgetDismiss {
    _accountUserNameView.alpha = 1;

}

#pragma mark - event

- (void)doRight:(id)sender {
    LMRandomSeedController *randomSeedVC = [[LMRandomSeedController alloc] init];
    [self.navigationController pushViewController:randomSeedVC animated:YES];
}

- (void)tapAccountNameView {
    SelectLoginUserViewController *selectUserPage = [[SelectLoginUserViewController alloc]
                                                     initWithCallBackBlock:^(AccountInfo *user) {
        self.selectedAccount = user;
    }
                                                     chainUser:self.chainUsers
                                                     selectedUser:self.selectedAccount];
    [self.navigationController pushViewController:selectUserPage animated:YES];
}

- (void)tapLoginBtn {
    [MBProgressHUD showMessage:LMLocalizedString(@"Common Loading", nil) toView:self.view];
    __weak __typeof(&*self) weakSelf = self;
    [[LKUserCenter shareCenter] LoginUserWithAccountUser:_selectedAccount withPassword:_passwordField.text withComplete:^(NSString *privkey, NSError *error) {
        if (error) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Password incorrect", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
            }];
        } else{
            //save to keychan
            [[MMAppSetting sharedSetting] saveUserAnduploadLoginTimeToKeyChain:_selectedAccount];
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD hideHUDForView:weakSelf.view];
            }];
        }
    }];
}

#pragma mark - getter setter

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}


- (void)showLogoutTipWithInfo:(id)info {

    // get current system time
    NSDate *currentDate = [NSDate date];
    // Used to format NSDate objects
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    // set formate
    [dateFormatter setDateFormat:@"HH:mm"];
    NSString *currentDateString = [dateFormatter stringFromDate:currentDate];

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:[NSString stringWithFormat:LMLocalizedString(@"Login Your account logged on at", nil), info, currentDateString] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
    }];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
