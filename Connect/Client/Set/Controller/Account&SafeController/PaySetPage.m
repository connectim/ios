//
//  PaySetPage.m
//  Connect
//
//  Created by MoHuilin on 16/7/30.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "PaySetPage.h"
#import "SetTransferFeePage.h"
#import "WJTouchID.h"


@interface PaySetPage () <WJTouchIDDelegate>

@property(nonatomic, weak) UITextField *passTextField;
@property(nonatomic, assign) BOOL poptoRoot;
@property(copy, nonatomic) NSString *fee;


@end

@implementation PaySetPage

- (instancetype)initIsNeedPoptoRoot:(BOOL)poptoRoot {
    if (self = [super init]) {
        self.poptoRoot = poptoRoot;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self setupCellData];
    [self.tableView reloadData];

}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = LMLocalizedString(@"Set Payment", nil);
    self.view.backgroundColor = LMBasicBackgroudGray;

    __weak __typeof(&*self) weakSelf = self;
    if (![[MMAppSetting sharedSetting] isHaveSyncPaySet]) {
        // download pay data
        [SetGlobalHandler getPaySetComplete:^(NSError *erro) {
            if (!erro) {
                [GCDQueue executeInMainQueue:^{
                    [weakSelf setupCellData];
                    [weakSelf.tableView reloadData];
                }];
            }
        }];
    }


    if (self.poptoRoot) {
        [GCDQueue executeInMainQueue:^{
            [self resetPayPass];
        }             afterDelaySecs:1.f];
    }
}

- (void)configTableView {

    self.tableView.separatorColor = self.tableView.backgroundColor;

    [self.tableView registerClass:[NCellSwitch class] forCellReuseIdentifier:@"NCellSwitcwID"];

    [self.tableView registerNib:[UINib nibWithNibName:@"NCellValue1" bundle:nil] forCellReuseIdentifier:@"NCellValue1ID"];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"SystemCellID"];

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"setting_finger_pay"]];
    [self.view addSubview:imageView];
    imageView.frame = AUTO_RECT(0, 0, 750, 508);
    imageView.contentMode = UIViewContentModeCenter;

    self.tableView.tableHeaderView = imageView;

}

- (void)reload {
    [GCDQueue executeInMainQueue:^{
        [self setupCellData];
        [self.tableView reloadData];
    }];
}


- (void)setupCellData {


    [self.groups removeAllObjects];

    __weak __typeof(&*self) weakSelf = self;


    // zero group
    CellGroup *group0 = [[CellGroup alloc] init];

    NSString *tip = LMLocalizedString(@"Set Setting", nil);
    if ([[MMAppSetting sharedSetting] getPayPass].length == MAX_PASS_LEN) {
        tip = LMLocalizedString(@"Wallet Reset password", nil);
    }
    CellItem *payPass = [CellItem itemWithTitle:LMLocalizedString(@"Set Payment Password", nil) subTitle:tip type:CellItemTypeValue1 operation:^{
        [weakSelf resetPayPass];
    }];


    CellItem *fingerPay = [CellItem itemWithTitle:LMLocalizedString(@"Set Pay with Fingerprint", nil) type:CellItemTypeSwitch operation:nil];
    fingerPay.switchIsOn = [[MMAppSetting sharedSetting] needFingerPay];
    fingerPay.operationWithInfo = ^(id userInfo) {

        if (GJCFStringIsNull([[MMAppSetting sharedSetting] getPayPass])) {
            // need user set pass
            [GCDQueue executeInMainQueue:^{
                [weakSelf setupCellData];
                [weakSelf.tableView reloadData];

            }];
            return;
        }

        if (![[MMAppSetting sharedSetting] isDeviceSupportFingerPay]) {
            // Need to open the fingerprint payment, and non-jailbreak of the machine
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LMLocalizedString(@"Set tip title", nil) message:LMLocalizedString(@"Set fingerprint not allowed on jailbreaking phones", nil) preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Wallet Confirmed", nil) style:UIAlertActionStyleDefault handler:nil];
            [alertController addAction:okAction];
            [GCDQueue executeInMainQueue:^{
                [weakSelf presentViewController:alertController animated:YES completion:nil];
                [weakSelf setupCellData];
                [weakSelf.tableView reloadData];
            }];
            return;
        }

        [GCDQueue executeInMainQueue:^{
            // Let the return button all can not click
            self.whiteButton.enabled = NO;
            if ([userInfo boolValue]) {
                [[WJTouchID touchID] startWJTouchIDWithMessage:LMLocalizedString(@"Wallet Allow fingerprint to pay", nil) fallbackTitle:LMLocalizedString(@"Wallet Confirmed", nil) delegate:weakSelf];
            } else {
                [[WJTouchID touchID] startWJTouchIDWithMessage:LMLocalizedString(@"Set Disbale fingerprint payment", nil) fallbackTitle:LMLocalizedString(@"Wallet Confirmed", nil) delegate:weakSelf];
            }
        }];
    };

    CellItem *noPassPay = [CellItem itemWithTitle:LMLocalizedString(@"Set Skip password", nil) type:CellItemTypeSwitch operation:nil];
    noPassPay.switchIsOn = [[MMAppSetting sharedSetting] isCanNoPassPay];
    noPassPay.operationWithInfo = ^(id userInfo) {
        [weakSelf openNoPassPay:[userInfo boolValue]];
    };


    group0.items = @[payPass, fingerPay, noPassPay];


    [self.groups objectAddObject:group0];


    // second group
    CellGroup *group1 = [[CellGroup alloc] init];
    if ([[MMAppSetting sharedSetting] canAutoCalculateTransactionFee]) {
        weakSelf.fee = LMLocalizedString(@"Set Auto", nil);
    } else {
        weakSelf.fee = [NSString stringWithFormat:@"฿ %@", [PayTool getBtcStringWithAmount:[[MMAppSetting sharedSetting] getTranferFee]]];
    }
    CellItem *transferFee = [CellItem itemWithTitle:LMLocalizedString(@"Set Miner fee", nil) subTitle:weakSelf.fee type:CellItemTypeValue1 operation:^{
        SetTransferFeePage *page = [[SetTransferFeePage alloc] init];
        page.changeCallBack = ^(BOOL flag, long long value) {
            if (flag) {
                weakSelf.fee = LMLocalizedString(@"Set Auto", nil);
            } else {
                weakSelf.fee = [NSString stringWithFormat:@"฿ %@", [PayTool getBtcStringWithAmount:[[MMAppSetting sharedSetting] getTranferFee]]];
            }
            [weakSelf.tableView reloadData];
        };
        [weakSelf hidenTabbarWhenPushController:page];
    }];
    group1.items = @[transferFee];

    [self.groups objectAddObject:group1];
}


- (void)openNoPassPay:(BOOL)nopassPay {

    __weak __typeof(&*self) weakSelf = self;
    AccountInfo *loginUser = [[LKUserCenter shareCenter] currentLoginUser];

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LMLocalizedString(@"Set Enter Login Password", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.secureTextEntry = YES;
        weakSelf.passTextField = textField;
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *_Nonnull action) {
        [weakSelf setupCellData];
        [weakSelf.tableView reloadData];
    }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {

        [GCDQueue executeInGlobalQueue:^{

            weakSelf.navigationController.view.userInteractionEnabled = NO;
            NSDictionary *decodeDict = [KeyHandle decodePrikeyGetDict:loginUser.encryption_pri withPassword:weakSelf.passTextField.text];
            weakSelf.navigationController.view.userInteractionEnabled = YES;

            if (decodeDict) {
                [SetGlobalHandler setPaySetNoPass:nopassPay payPass:[[MMAppSetting sharedSetting] getPayPass] fee:[[MMAppSetting sharedSetting] getTranferFee] compete:^(BOOL result) {
                    if (result) {
                        [weakSelf reload];
                    }
                }];
            } else {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Password incorrect", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                    [weakSelf setupCellData];
                    [weakSelf.tableView reloadData];
                }];
            }
        }];

    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];


    [self presentViewController:alertController animated:YES completion:nil];


}

- (void)resetPayPass {

    __weak __typeof(&*self) weakSelf = self;
    AccountInfo *loginUser = [[LKUserCenter shareCenter] currentLoginUser];

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LMLocalizedString(@"Set Enter Login Password", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.secureTextEntry = YES;
        weakSelf.passTextField = textField;
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {

        [GCDQueue executeInGlobalQueue:^{

            if (self.passTextField.text.length <= 0) {
                return;
            }
            self.navigationController.view.userInteractionEnabled = NO;

            NSDictionary *decodeDict = [KeyHandle decodePrikeyGetDict:loginUser.encryption_pri withPassword:weakSelf.passTextField.text];
            weakSelf.navigationController.view.userInteractionEnabled = YES;

            if (decodeDict) {
                NSString __block *firstPass = nil;
                [GCDQueue executeInMainQueue:^{
                    KQXPasswordInputController *passView = [[KQXPasswordInputController alloc] initWithPasswordInputStyle:KQXPasswordInputStyleWithoutMoney];
                    __weak __typeof(&*passView) weakPassView = passView;
                    passView.fillCompleteBlock = ^(NSString *password) {
                        if (password.length != 4) {
                            return;
                        }
                        if (GJCFStringIsNull(firstPass)) {
                            firstPass = password;
                            [weakPassView setTitleString:LMLocalizedString(@"Wallet Confirm PIN", nil) descriptionString:LMLocalizedString(@"Wallet Enter 4 Digits", nil) moneyString:nil];
                        } else {
                            [weakPassView dismissWithClosed:YES];
                            if ([firstPass isEqualToString:password]) {
                                // save and upload
                                [GCDQueue executeInBackgroundPriorityGlobalQueue:^{
                                    [SetGlobalHandler setpayPass:password compete:^(BOOL result) {
                                        if (result) {
                                            [weakSelf reload];
                                            [GCDQueue executeInMainQueue:^{
                                                [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Save successful", nil) withType:ToastTypeSuccess showInView:weakSelf.view complete:^{
                                                    if (weakSelf.poptoRoot) {
                                                        [GCDQueue executeInMainQueue:^{
                                                            [weakSelf.navigationController popToRootViewControllerAnimated:YES];
                                                        }             afterDelaySecs:1.f];
                                                    }
                                                }];
                                            }];
                                        }
                                    }];
                                }];
                            } else {
                                [GCDQueue executeInMainQueue:^{
                                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Password incorrect", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                                }];
                            }
                        }
                    };

                    [weakSelf presentViewController:passView animated:NO completion:nil];

                }];
            } else {
                [GCDQueue executeInMainQueue:^{
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Password incorrect", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                    }];
                    [weakSelf setupCellData];
                    [weakSelf.tableView reloadData];
                }];
            }
        }];

    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];

    alertController.automaticallyAdjustsScrollViewInsets = NO;


    [self presentViewController:alertController animated:YES completion:nil];

}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {


    CellGroup *group = self.groups[indexPath.section];
    CellItem *item = group.items[indexPath.row];
    BaseCell *cell;
    if (item.type == CellItemTypeSwitch) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NCellSwitcwID"];
        NCellSwitch *switchCell = (NCellSwitch *) cell;
        switchCell.switchIsOn = item.switchIsOn;
        switchCell.SwitchValueChangeCallBackBlock = ^(BOOL on) {
            item.operationWithInfo ? item.operationWithInfo(@(on)) : nil;
        };

        switchCell.customLable.text = item.title;
        return cell;
    } else if (item.type == CellItemTypeValue1) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NCellValue1ID"];
        NCellValue1 *value1Cell = (NCellValue1 *) cell;
        value1Cell.data = item;
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"SystemCellID"];
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return AUTO_HEIGHT(111);
}

#pragma mark - WJTouchIDDelegate

/**
 *  TouchID validation is successful
 *
 *  Authentication Successul  Authorize Success
 */
- (void)WJTouchIDAuthorizeSuccess {
    DDLogInfo(@"%@", WJNotice(@"TouchID验证成功", @"Authorize Success"));
    self.whiteButton.enabled = YES;
    BOOL fingerLock = [[MMAppSetting sharedSetting] needFingerPay];

    if (fingerLock) {
        [[MMAppSetting sharedSetting] cacelFingerPay];
        return;
    }

    [[MMAppSetting sharedSetting] setFingerPay];
}

/**
 *  TouchID validation failed
 *
 *  Authentication Failure
 */
- (void)WJTouchIDAuthorizeFailure {

    self.whiteButton.enabled = YES;
    DDLogInfo(@"%@", WJNotice(@"TouchID验证失败", @"Authorize Failure"));

    [self setupCellData];
    [self.tableView reloadData];

}

/**
 *   cancle touchID vertification
 *
 *  Authentication was canceled by user (e.g. tapped Cancel button).
 */
- (void)WJTouchIDAuthorizeErrorUserCancel {
    // all button can not click
    self.whiteButton.enabled = YES;
    [self setupCellData];
    [self.tableView reloadData];

}

/**
 *  In the TouchID dialog box, click the Enter Password button
 *
 *  User tapped the fallback button
 */
- (void)WJTouchIDAuthorizeErrorUserFallback {
    // Let the return button all be able to click
    self.whiteButton.enabled = YES;
    [self setupCellData];
    [self.tableView reloadData];

}

/**
 *  In the process of verifying the TouchID was canceled by the system, for example, suddenly call, press the Home button, lock screen .
 *
 *  Authentication was canceled by system (e.g. another application went to foreground).
 */
- (void)WJTouchIDAuthorizeErrorSystemCancel {
    // Let the return button all be able to click
    self.whiteButton.enabled = YES;
    [self setupCellData];
    [self.tableView reloadData];

}

/**
 *  Can not enable TouchID, the device does not have a password set
 *
 *  Authentication could not start, because passcode is not set on the device.
 */
- (void)WJTouchIDAuthorizeErrorPasscodeNotSet {
    // Let the return button all be able to click
    self.whiteButton.enabled = YES;
    [self setupCellData];
    [self.tableView reloadData];

}

/**
 *  The device does not have a TouchID entered, and TouchID can not be enabled
 *
 *  Authentication could not start, because Touch ID has no enrolled fingers
 */
- (void)WJTouchIDAuthorizeErrorTouchIDNotEnrolled {
    // Let the return button all be able to click
    self.whiteButton.enabled = YES;
    [self setupCellData];
    [self.tableView reloadData];

}

/**
 *  The device's TouchID is invalid
 *
 *  Authentication could not start, because Touch ID is not available on the device.
 */
- (void)WJTouchIDAuthorizeErrorTouchIDNotAvailable {
    // Let the return button all be able to click
    self.whiteButton.enabled = YES;
    [self setupCellData];
    [self.tableView reloadData];

}

/**
 * Repeatedly used Touch ID failed, Touch ID is locked, requires the user to enter the password to unlock
 *
 *  Authentication was not successful, because there were too many failed Touch ID attempts and Touch ID is now locked. Passcode is required to unlock Touch ID, e.g. evaluating LAPolicyDeviceOwnerAuthenticationWithBiometrics will ask for passcode as a prerequisite.
 *
 */
- (void)WJTouchIDAuthorizeLAErrorTouchIDLockout {
    self.whiteButton.enabled = YES;
    [self setupCellData];
    [self.tableView reloadData];

}

/**
 *  The current software is suspended to cancel the authorization (such as a sudden call, the application into the front desk)
 *
 *  Authentication was canceled by application (e.g. invalidate was called while authentication was inprogress).
 *
 */
- (void)WJTouchIDAuthorizeLAErrorAppCancel {
    self.whiteButton.enabled = YES;
    [self setupCellData];
    [self.tableView reloadData];

}

/**
 *  The current software is suspended to cancel the authorization (the LAContext object was released during authorization)
 *
 *  LAContext passed to this call has been previously invalidated.
 */
- (void)WJTouchIDAuthorizeLAErrorInvalidContext {
    self.whiteButton.enabled = YES;
    [self setupCellData];
    [self.tableView reloadData];

}

/**
 *  The current device does not support fingerprint recognition
 *
 *  The current device does not support fingerprint identification
 */
- (void)WJTouchIDIsNotSupport {
    self.whiteButton.enabled = YES;
    [self setupCellData];
    [self.tableView reloadData];
}


@end
