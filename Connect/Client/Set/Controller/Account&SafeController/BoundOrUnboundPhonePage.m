//
//  BoundOrUnboundPhonePage.m
//  Connect
//
//  Created by MoHuilin on 16/7/29.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BoundOrUnboundPhonePage.h"

#import "UpdateChangePhonePage.h"
#import "NetWorkOperationTool.h"

@interface BoundOrUnboundPhonePage () {
    AccountInfo *loginUser;
}
// bind phone button
@property(strong, nonatomic) UIButton *boundPhoneButton;
// tips
@property(strong, nonatomic) UILabel *tipLabel;
@property(strong, nonatomic) UILabel *phoneLabel;
// phone number
@property(nonatomic, copy) NSString *phoneNum;


@end

@implementation BoundOrUnboundPhonePage

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LMLocalizedString(@"Set Link Mobile", nil);
    
    [self setUpUI];
    // refresh ui
    [self reloadView];
    RegisterNotify(LKUserCenterUserInfoUpdateNotification, @selector(reloadView));


}
- (void)setUpUI {
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"setting_phone"]];
    [self.view addSubview:imageView];
    imageView.frame = AUTO_RECT(285, 280, 180, 288);
    
    self.view.backgroundColor = LMBasicBackgroudGray;
    
    
    self.tipLabel = [[UILabel alloc] init];
    [self.view addSubview:self.tipLabel];
    
    _tipLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    _tipLabel.textAlignment = NSTextAlignmentCenter;
    [_tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_centerY);
        make.centerX.equalTo(self.view.mas_centerX);
        make.left.mas_equalTo(self.view).offset(10);
        make.right.mas_equalTo(self.view).offset(-10);
    }];
    
    self.phoneLabel = [[UILabel alloc] init];
    [self.view addSubview:self.phoneLabel];
    _phoneLabel.font = [UIFont systemFontOfSize:FONT_SIZE(64)];
    _phoneLabel.textAlignment = NSTextAlignmentCenter;
    [_phoneLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tipLabel.mas_bottom);
        make.centerX.equalTo(self.view.mas_centerX);
        make.left.mas_equalTo(self.view).offset(10);
        make.right.mas_equalTo(self.view).offset(-10);
    }];
    
    self.boundPhoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.boundPhoneButton addTarget:self action:@selector(boundNewPhone) forControlEvents:UIControlEventTouchUpInside];
    self.boundPhoneButton.layer.masksToBounds = YES;
    self.boundPhoneButton.layer.cornerRadius = 5;
    self.boundPhoneButton.backgroundColor = LMBasicGreen;
    [self.boundPhoneButton setTitle:LMLocalizedString(@"Set Change Mobile", nil) forState:UIControlStateNormal];
    _boundPhoneButton.width = AUTO_WIDTH(700);
    _boundPhoneButton.height = AUTO_HEIGHT(100);
    _boundPhoneButton.centerX = self.view.centerX;
    _boundPhoneButton.bottom = DEVICE_SIZE.height - AUTO_HEIGHT(400);
    [self.view addSubview:self.boundPhoneButton];

}
- (void)dealloc {
    RemoveNofify;
}


/**
 *  refresh ui
 */
- (void)reloadView {
    loginUser = [[LKUserCenter shareCenter] currentLoginUser];

    self.phoneNum = loginUser.bondingPhone;
    NSString *phone = @"";
    if (!GJCFStringIsNull(self.phoneNum)) {
        if ([self.phoneNum containsString:@"-"]) {
            phone = [self.phoneNum substringFromIndex:[self.phoneNum rangeOfString:@"-"].location + 1];
        } else {
            phone = self.phoneNum;
        }//
        [self.boundPhoneButton setTitle:LMLocalizedString(@"Set Change Mobile", nil) forState:UIControlStateNormal];
    }else{   // phone is not have
         if (loginUser.bonding) { // have bind phone
            phone = LMLocalizedString(@"ErrorCode Phone number is incorrect", nil);
        } else {
            [self.boundPhoneButton setTitle:LMLocalizedString(@"Set Add mobile", nil) forState:UIControlStateNormal];
        }
    }
    if (!GJCFStringIsNull(phone)) {
        _tipLabel.text = LMLocalizedString(@"Set Your cell phone number", nil);
        _phoneLabel.text = phone;
        _phoneLabel.hidden = NO;
        [self setNavigationRight:@"menu_white"];
    } else {
        _tipLabel.text = LMLocalizedString(@"Set Not connected to mobile network", nil);
        _phoneLabel.hidden = YES;
        [self removeNavigationRight];
    }


}

- (void)doRight:(id)sender {

    UIAlertController *actionController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *unlockAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Set Unlink", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        [self action];

    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:nil];

    [actionController addAction:unlockAction];
    [actionController addAction:cancelAction];
    [self presentViewController:actionController animated:YES completion:nil];


}


- (void)boundNewPhone {
    UpdateChangePhonePage *page = [[UpdateChangePhonePage alloc] init];
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:page] animated:YES completion:nil];
}

/**
 *  Phone unbundled
 */
- (void)action {
    __weak __typeof(&*self) weakSelf = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LMLocalizedString(@"Set Unlink your mobile phone", nil) message:LMLocalizedString(@"Set unlink Connect not find friend your backup deleted", nil) preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *unBoundAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Set Unlink", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showMessage:LMLocalizedString(@"Common Loading", nil) toView:weakSelf.view];
        }];
        [weakSelf unboudingPhone];
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:unBoundAction];

    [self presentViewController:alertController animated:YES completion:nil];

}


/**
 *  Unlock the phone, you need to remind the user, once the tie may be lost account
 */
- (void)unboudingPhone {

    __weak __typeof(&*self) weakSelf = self;
    NSArray *codePhone = [self.phoneNum componentsSeparatedByString:@"-"];
    NSString *phone = [codePhone lastObject];
    NSString *code = [codePhone firstObject];
    // add judge
    if ([self.phoneNum containsString:@"**"]) {
       codePhone = [self.phoneNum componentsSeparatedByString:@"**"];
       phone = [codePhone lastObject];
       code = [codePhone firstObject];
    }
    
    MobileVerify *setMobile = [[MobileVerify alloc] init];
    setMobile.countryCode = [code intValue];
    setMobile.number = phone;
    [NetWorkOperationTool POSTWithUrlString:SetUnBindPhoneUrl postProtoData:setMobile.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *) response;
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:weakSelf.view];
        }];
        if (hResponse.code != successCode) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Set Unlink failed", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
            }];

            return;
        }

        loginUser.bondingPhone = @"";
        loginUser.bonding = NO;
        [[LKUserCenter shareCenter] updateUserInfo:loginUser];
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Set Unlink successful", nil) withType:ToastTypeSuccess showInView:weakSelf.view complete:^{
                if (weakSelf.UnBindBlock) {
                    weakSelf.UnBindBlock();
                }
                [weakSelf.navigationController popViewControllerAnimated:YES];
            }];
        }];

    }                                  fail:^(NSError *error) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
        }];
    }];
}


@end
