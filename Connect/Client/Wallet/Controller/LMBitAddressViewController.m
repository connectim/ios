
//
//  LMBitAddressViewController.m
//  Connect
//
//  Created by Edwin on 16/7/20.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMBitAddressViewController.h"
#import "LMBitAddressBookViewController.h"
#import "WallteNetWorkTool.h"
#import "TransferInputView.h"
#import "LMPayCheck.h"

@interface LMBitAddressViewController ()
// Enter the bit currency address
@property(nonatomic, strong) UITextField *addressTextField;
// money balance
@property(nonatomic, strong) UILabel *BalanceLabel;
// view
@property(nonatomic, strong) TransferInputView *inputAmountView;
@end

@implementation LMBitAddressViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = LMLocalizedString(@"Wallet Transfer", nil);
    self.ainfo = [[LKUserCenter shareCenter] currentLoginUser];
    [self addRightBarButtonItem];
    [self initTopView];
    [self initTabelViewCell];
    
}
#pragma mark -- method

- (void)addRightBarButtonItem {
    UIButton *rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    rightBtn.frame = CGRectMake(0, 0, AUTO_WIDTH(34.4), AUTO_HEIGHT(40));
    [rightBtn setImage:[UIImage imageNamed:@"address_book"] forState:UIControlStateNormal];
    [rightBtn addTarget:self action:@selector(rightBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:rightBtn];
    self.navigationItem.rightBarButtonItem = rightItem;
}
- (void)initTopView {
    self.addressTextField = [[UITextField alloc] init];
    self.addressTextField.textColor = LMBasicTextFieldeColor;
    self.addressTextField.returnKeyType = UIReturnKeyDone;
    self.addressTextField.adjustsFontSizeToFitWidth = YES;
    self.addressTextField.textAlignment = NSTextAlignmentCenter;
    self.addressTextField.placeholder = LMLocalizedString(@"Link Enter Bitcoin Address", nil);
    self.addressTextField.text = self.address;
    self.addressTextField.font = [UIFont systemFontOfSize:FONT_SIZE(36)];
    [self.view addSubview:self.addressTextField];
    [self.addressTextField becomeFirstResponder];
    
    [_addressTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(AUTO_HEIGHT(150));
        make.width.mas_equalTo(DEVICE_SIZE.width - AUTO_WIDTH(100));
        make.centerX.equalTo(self.view);
        make.height.mas_equalTo(AUTO_HEIGHT(80));
    }];
    
    [self.addressTextField addTarget:self
                              action:@selector(textFieldDidChange:)
                    forControlEvents:UIControlEventEditingChanged];
    
    
    __weak __typeof(&*self) weakSelf = self;
    TransferInputView *view = [[TransferInputView alloc] init];
    self.inputAmountView = view;
    if (self.amountString) {
        view.defaultAmountString = self.amountString;
    }
    [self.view addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.addressTextField.mas_bottom).offset(AUTO_HEIGHT(20));
        make.width.equalTo(self.view);
        make.height.mas_equalTo(AUTO_HEIGHT(334));
        make.left.equalTo(self.view);
    }];
    view.topTipString = LMLocalizedString(@"Wallet Amount", nil);
    view.resultBlock = ^(NSDecimalNumber *btcMoney, NSString *note) {
        [weakSelf createTranscationWithMoney:btcMoney note:note];
    };
    
    view.lagelBlock = ^(BOOL enabled) {
        weakSelf.comfrimButton.enabled = enabled;
    };
    
    [[PayTool sharedInstance] getRateComplete:^(NSDecimalNumber *rate, NSError *error) {
        if (!error) {
            weakSelf.rate = rate.floatValue;
            [weakSelf.inputAmountView reloadWithRate:rate.floatValue];
        } else {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Get rate failed", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
            }];
        }
    }];
    
    [NSNotificationCenter.defaultCenter addObserverForName:UIKeyboardWillChangeFrameNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        CGFloat duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
        CGRect keyboardFrame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        int distence = weakSelf.inputAmountView.bottom - (DEVICE_SIZE.height - keyboardFrame.size.height - AUTO_HEIGHT(100));
        [GCDQueue executeInMainQueue:^{
            [UIView animateWithDuration:duration animations:^{
                if (keyboardFrame.origin.y != DEVICE_SIZE.height) {
                    if (distence > 0) {
                        weakSelf.view.top -= distence;
                    }
                } else {
                    weakSelf.view.top = 0;
                }
            }];
        }];
    }];
    
}
- (void)initTabelViewCell {
    self.BalanceLabel = [[UILabel alloc] init];
    
    self.BalanceLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Balance", nil), [PayTool getBtcStringWithAmount:[[MMAppSetting sharedSetting] getBalance]]];
    self.BalanceLabel.textColor = LMBasicBlanceBtnTitleColor;
    self.BalanceLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.BalanceLabel.textAlignment = NSTextAlignmentCenter;
    self.BalanceLabel.backgroundColor = self.view.backgroundColor;
    [self.view addSubview:self.BalanceLabel];
    [self.view sendSubviewToBack:self.BalanceLabel];
    
    [self.BalanceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.inputAmountView.mas_bottom).offset(AUTO_HEIGHT(60));
        make.centerX.equalTo(self.view);
    }];
    // add gesture
    UITapGestureRecognizer *tapBalance = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapBalance)];
    [self.BalanceLabel addGestureRecognizer:tapBalance];
    self.BalanceLabel.userInteractionEnabled = YES;
    
    __weak __typeof(&*self) weakSelf = self;
    [[PayTool sharedInstance] getBlanceWithComplete:^(NSString *blance, UnspentAmount *unspentAmount, NSError *error) {
        weakSelf.blance = unspentAmount.avaliableAmount;
        weakSelf.BalanceLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Balance Credit", nil), [PayTool getBtcStringWithAmount:unspentAmount.avaliableAmount]];
    }];
    
    self.comfrimButton = [[ConnectButton alloc] initWithNormalTitle:LMLocalizedString(@"Wallet Transfer", nil) disableTitle:LMLocalizedString(@"Wallet Transfer", nil)];
    [self.comfrimButton addTarget:self action:@selector(tapConfrim) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.comfrimButton];
    [self.comfrimButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.BalanceLabel.mas_bottom).offset(AUTO_HEIGHT(30));
        make.centerX.equalTo(self.view);
        make.height.mas_equalTo(self.comfrimButton.height);
        make.width.mas_equalTo(self.comfrimButton.width);
    }];
}
- (void)tapBalance{
    if (![[MMAppSetting sharedSetting] canAutoCalculateTransactionFee]) {
        long long maxAmount = self.blance - [[MMAppSetting sharedSetting] getTranferFee];
        self.inputAmountView.defaultAmountString = [[[NSDecimalNumber alloc] initWithLongLong:maxAmount] decimalNumberByDividingBy:[[NSDecimalNumber alloc] initWithLongLong:pow(10, 8)]].stringValue;
    }
}
#pragma mark --rightBtnClick

- (void)rightBtnClick:(UIButton *)btn {
    LMBitAddressBookViewController *addressBook = [[LMBitAddressBookViewController alloc] init];
    addressBook.mainBitAddress = self.ainfo.address;
    addressBook.didGetBitAddress = ^(NSString *address) {
        self.addressTextField.text = address;
    };
    [self.view layoutIfNeeded];
    [self.navigationController pushViewController:addressBook animated:YES];
}
- (void)tapConfrim {
    [self.inputAmountView executeBlock];
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.inputAmountView hidenKeyBoard];
}
#pragma amrk -- Input box proxy method

- (void)textFieldDidChange:(UITextField *)textField {
    __weak typeof(self) weakSelf = self;
    if (textField.text.length > 30) {
        if (![KeyHandle checkAddress:self.addressTextField.text]) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Result is not a bitcoin address", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
            }];
        }
    }
}

- (void)createTranscationWithMoney:(NSDecimalNumber *)money note:(NSString *)note {
    __weak typeof(self) weakSelf = self;
    if (GJCFStringIsNull(self.addressTextField.text)) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Enter Bitcoin Address", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
        }];
        return;
    }

    if (![KeyHandle checkAddress:self.addressTextField.text]) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Result is not a bitcoin address", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
        }];
        return;
    }
    // Whether the balance is sufficient
    if ([PayTool getPOW8Amount:money] > self.blance) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Insufficient balance", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
        }];
        return;
    }

    [GCDQueue executeInMainQueue:^{
        [MBProgressHUD showTransferLoadingViewtoView:self.view];
        [self.view endEditing:YES];
    }];

    NSArray *toAddresses = @[@{@"address": self.addressTextField.text, @"amount": money.stringValue}];
    
    BOOL isDusk = [LMPayCheck dirtyAlertWithAddress:toAddresses withController:self];
    if (isDusk) {
        self.comfrimButton.enabled = YES;
        return;
    }
    [WallteNetWorkTool unspentV2WithAddress:self.ainfo.address fee:[[MMAppSetting sharedSetting] getTranferFee] toAddress:toAddresses createRawTranscationModelComplete:^(UnspentOrderResponse *unspent, NSError *error) {
        [LMPayCheck payCheck:nil withVc:weakSelf withTransferType:TransferTypeBitAddress unSpent:unspent withArray:toAddresses withMoney:money withNote:note withType:0 withRedPackage:nil withError:error];
    }];
}

- (void)checkChangeWithRawTrancationModel:(LMRawTransactionModel *)rawModel
                                   amount:(NSDecimalNumber *)amount
                                     note:(NSString *)note {
    // Check for change
    __weak __typeof(&*self) weakSelf = self;
    rawModel = [LMUnspentCheckTool checkChangeDustWithRawTrancation:rawModel];
    switch (rawModel.unspentErrorType) {
        case UnspentErrorTypeChangeDust: {
            [MBProgressHUD hideHUDForView:self.view];
            NSString *tips = [NSString stringWithFormat:LMLocalizedString(@"Wallet Charge small calculate to the poundage", nil),
                                                        [PayTool getBtcStringWithAmount:rawModel.change]];
            [UIAlertController showAlertInViewController:self withTitle:LMLocalizedString(@"Set tip title", nil) message:tips cancelButtonTitle:LMLocalizedString(@"Common Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:@[LMLocalizedString(@"Common OK", nil)] tapBlock:^(UIAlertController *_Nonnull controller, UIAlertAction *_Nonnull action, NSInteger buttonIndex) {
                self.comfrimButton.enabled = YES;
                switch (buttonIndex) {
                    case 0: {
                        self.comfrimButton.enabled = YES;
                    }
                        break;
                    case 2: // click ok
                    {
                        LMRawTransactionModel *rawModelNew = [LMUnspentCheckTool createRawTransactionWithRawTrancation:rawModel addDustToFee:YES];
                        // pay money
                        [weakSelf makeTransfer:rawModelNew decimalMoney:amount note:note];
                    }
                        break;
                    default:
                        break;
                }
            }];
        }
            break;
        case UnspentErrorTypeNoError: {
            LMRawTransactionModel *rawModelNew = [LMUnspentCheckTool createRawTransactionWithRawTrancation:rawModel addDustToFee:NO];
            // pay money
            [weakSelf makeTransfer:rawModelNew decimalMoney:amount note:note];
        }
            break;
        default:
            break;
    }
}

- (void)makeTransfer:(LMRawTransactionModel *)rawModel decimalMoney:(NSDecimalNumber *)amount note:(NSString *)note {

    [MBProgressHUD showTransferLoadingViewtoView:self.view];
    self.vtsArray = rawModel.vtsArray;
    self.rawTransaction = rawModel.rawTrancation;

    __weak __typeof(&*self) weakSelf = self;
    [[PayTool sharedInstance] payVerfifyFingerWithComplete:^(BOOL result, NSString *errorMsg) {
        if (result) {
            [self successAction:rawModel decimalMoney:amount note:note passView:nil];
        } else {
            if ([errorMsg isEqualToString:@"NO"]) {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD hideHUDForView:weakSelf.view];
                    weakSelf.comfrimButton.enabled = YES;
                }];
                return;
            }
            [InputPayPassView showInputPayPassWithComplete:^(InputPayPassView *passView, NSError *error, BOOL result) {
                if (result) {
                    [weakSelf successAction:rawModel decimalMoney:amount note:note passView:passView];
                    
                }
            }                              forgetPassBlock:^{
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD hideHUDForView:weakSelf.view];
                    weakSelf.comfrimButton.enabled = YES;
                    PaySetPage *page = [[PaySetPage alloc] initIsNeedPoptoRoot:YES];
                    [self.navigationController pushViewController:page animated:YES];
                }];
            }                                   closeBlock:^{
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD hideHUDForView:weakSelf.view];
                    weakSelf.comfrimButton.enabled = YES;
                }];
            }];
        }
    }];
}
- (void)successAction:(LMRawTransactionModel *)rawModel decimalMoney:(NSDecimalNumber *)amount note:(NSString *)note passView:(InputPayPassView *)passView {
    __weak __typeof(&*self) weakSelf = self;
    [self transferToAddress:self.addressTextField.text decimalMoney:amount tips:note complete:^(NSString *hashId, NSError *error) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:weakSelf.view];
        }];
        if (error) {
            if (passView.requestCallBack) {
                passView.requestCallBack(error);
            }
        } else {
            
            if (passView.requestCallBack) {
                passView.requestCallBack(error);
            }
        
            // Update the purse balance
            [[PayTool sharedInstance] getBlanceWithComplete:^(NSString *blance, UnspentAmount *unspentAmount, NSError *error) {
                [GCDQueue executeInMainQueue:^{
                    weakSelf.blance = unspentAmount.avaliableAmount;
                    weakSelf.BalanceLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Balance Credit", nil), [PayTool getBtcStringWithAmount:unspentAmount.avaliableAmount]];
                }];
            }];
            [weakSelf createChatWithHashId:hashId address:weakSelf.addressTextField.text Amount:amount.stringValue];
            [GCDQueue executeInMainQueue:^{
                [weakSelf.navigationController popToRootViewControllerAnimated:YES];
            }];
        }
    }];

}

@end
