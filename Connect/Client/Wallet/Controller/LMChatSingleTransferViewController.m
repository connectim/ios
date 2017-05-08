//
//  LMChatSingleTransferViewController.m
//  Connect
//
//  Created by Edwin on 16/7/26.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMChatSingleTransferViewController.h"
#import "WallteNetWorkTool.h"
#import "TransferInputView.h"
#import "LMPayCheck.h"


@interface LMChatSingleTransferViewController ()
@property(nonatomic, strong) UIImageView *userImageView;
@property(nonatomic, strong) UILabel *usernameLabel;
// money balance
@property(nonatomic, strong) UILabel *BalanceLabel;
@property(nonatomic, strong) BitcoinInfo *binfo;
@property(nonatomic, assign) float accoutMoney;
// money
@property(nonatomic, strong) TransferInputView *inputAmountView;


@end

@implementation LMChatSingleTransferViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    __weak __typeof(&*self) weakSelf = self;

    self.title = LMLocalizedString(@"Wallet Transfer", nil);

    [self addNewCloseBarItem];
    // message
    [self initUserInfomation];
    // transfer money
    [self initTopView];
    // packet money
    [self initTabelViewCell];

    self.ainfo = [[LKUserCenter shareCenter] currentLoginUser];

    self.trasferComplete = ^{
        [GCDQueue executeInMainQueue:^{
            [weakSelf.navigationController popViewControllerAnimated:YES];
        }];
    };

}

- (void)initUserInfomation {
    self.userImageView = [[UIImageView alloc] initWithFrame:CGRectMake(AUTO_WIDTH(319), AUTO_HEIGHT(30) + 64, AUTO_WIDTH(100), AUTO_WIDTH(100))];
    [self.userImageView setPlaceholderImageWithAvatarUrl:self.info.avatar];
    self.userImageView.layer.cornerRadius = 5;
    self.userImageView.layer.masksToBounds = YES;
    [self.view addSubview:self.userImageView];

    self.usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(AUTO_WIDTH(100), CGRectGetMaxY(self.userImageView.frame) + AUTO_HEIGHT(10), VSIZE.width - AUTO_WIDTH(200), AUTO_HEIGHT(40))];
    self.usernameLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Transfer To User", nil), self.info.username];
    self.usernameLabel.textAlignment = NSTextAlignmentCenter;
    self.usernameLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.usernameLabel.textColor = [UIColor blackColor];
    [self.view addSubview:self.usernameLabel];
}

- (void)initTopView {

    __weak __typeof(&*self) weakSelf = self;
    TransferInputView *view = [[TransferInputView alloc] init];
    self.inputAmountView = view;
    [self.view addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.usernameLabel.mas_bottom).offset(AUTO_HEIGHT(20));
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
            [[MMAppSetting sharedSetting] saveRate:[rate floatValue]];
            [weakSelf.inputAmountView reloadWithRate:rate.floatValue];
        } else {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Fail to get rate.", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
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
    self.BalanceLabel.textColor = [UIColor colorWithHexString:@"38425F"];
    self.BalanceLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.BalanceLabel.textAlignment = NSTextAlignmentCenter;
    self.BalanceLabel.backgroundColor = self.view.backgroundColor;
    [self.view addSubview:self.BalanceLabel];
    [self.view sendSubviewToBack:self.BalanceLabel];

    [self.BalanceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.inputAmountView.mas_bottom).offset(AUTO_HEIGHT(60));
        make.centerX.equalTo(self.view);
    }];

    __weak __typeof(&*self) weakSelf = self;
    [[PayTool sharedInstance] getBlanceWithComplete:^(NSString *blance, UnspentAmount *unspentAmount, NSError *error) {
        weakSelf.blance = unspentAmount.avaliableAmount;
        weakSelf.BalanceLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Balance", nil), [PayTool getBtcStringWithAmount:unspentAmount.avaliableAmount]];
    }];

    self.comfrimButton = [[ConnectButton alloc] initWithNormalTitle:LMLocalizedString(@"Wallet Transfer", nil) disableTitle:LMLocalizedString(@"Wallet Transfer", nil)];
    [self.comfrimButton addTarget:self action:@selector(tapConfrim) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.comfrimButton];
    [self.comfrimButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.BalanceLabel.mas_bottom).offset(AUTO_HEIGHT(30));
        make.width.mas_equalTo(self.comfrimButton.width);
        make.height.mas_equalTo(self.comfrimButton.height);
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.inputAmountView hidenKeyBoard];
}

- (void)tapConfrim {
    self.comfrimButton.enabled = NO;
    [self.inputAmountView executeBlock];
}


- (void)createTranscationWithMoney:(NSDecimalNumber *)money note:(NSString *)note {
    __weak typeof(&*self) weakSelf = self;
    // balance
    if ([PayTool getPOW8Amount:money] > self.blance) {
        [MBProgressHUD hideHUDForView:self.view];
        [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Insufficient balance", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];

        self.comfrimButton.enabled = YES;
        return;
    }
    [MBProgressHUD showTransferLoadingViewtoView:self.view];
    [self.view endEditing:YES];

    NSArray *toAddresses = @[@{@"address": self.info.address, @"amount": money.stringValue}];
    AccountInfo *ainfo = [[LKUserCenter shareCenter] currentLoginUser];
    [WallteNetWorkTool unspentV2WithAddress:ainfo.address fee:[[MMAppSetting sharedSetting] getTranferFee] toAddress:toAddresses createRawTranscationModelComplete:^(UnspentOrderResponse *unspent, NSError *error) {
        [LMPayCheck payCheck:nil withVc:weakSelf withTransferType:TransferTypeChatSingle unSpent:unspent withArray:toAddresses withMoney:money withNote:note withType:0 withRedPackage:nil withError:error];

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
    self.rawTransaction = rawModel.rawTrancation;
    self.vtsArray = rawModel.vtsArray;
    __weak __typeof(&*self) weakSelf = self;
    [[PayTool sharedInstance] payVerfifyFingerWithComplete:^(BOOL result, NSString *errorMsg) {
        if (result) {
            [weakSelf transferToAddress:weakSelf.info.address decimalMoney:amount tips:note complete:^(NSString *hashId, NSError *error) {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD hideHUDForView:weakSelf.view];
                }];
                if (error) {
                    weakSelf.comfrimButton.enabled = YES;
                } else {
                    // update money blance
                    [[PayTool sharedInstance] getBlanceWithComplete:^(NSString *blance, UnspentAmount *unspentAmount, NSError *error) {
                        [GCDQueue executeInMainQueue:^{
                            weakSelf.blance = unspentAmount.avaliableAmount;
                            weakSelf.BalanceLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Balance", nil), [PayTool getBtcStringWithAmount:unspentAmount.avaliableAmount]];
                        }];
                    }];
                    if (weakSelf.didGetTransferMoney) {
                        weakSelf.didGetTransferMoney(amount.stringValue, hashId, note);
                        [weakSelf dismissViewControllerAnimated:YES completion:nil];
                    }
                }
            }];
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
                    [weakSelf transferToAddress:weakSelf.info.address decimalMoney:amount tips:note complete:^(NSString *hashId, NSError *error) {
                        if (error) {
                            weakSelf.comfrimButton.enabled = YES;
                            if (passView.requestCallBack) {
                                passView.requestCallBack(error);
                            }
                        } else {
                            if (passView.requestCallBack) {
                                passView.requestCallBack(nil);
                            }
                            // update money blance
                            [[PayTool sharedInstance] getBlanceWithComplete:^(NSString *blance, UnspentAmount *unspentAmount, NSError *error) {
                                [GCDQueue executeInMainQueue:^{
                                    weakSelf.blance = unspentAmount.avaliableAmount;
                                    weakSelf.BalanceLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Balance", nil), [PayTool getBtcStringWithAmount:unspentAmount.avaliableAmount]];
                                }];
                            }];
                            if (weakSelf.didGetTransferMoney) {
                                weakSelf.didGetTransferMoney(amount.stringValue, hashId, note);
                                [weakSelf dismissViewControllerAnimated:YES completion:nil];
                            }
                        }
                    }];
                } else {
                    weakSelf.comfrimButton.enabled = YES;
                    [MBProgressHUD hideHUDForView:weakSelf.view];
                    if (![errorMsg isEqualToString:@"NO"]) {
                        [GCDQueue executeInMainQueue:^{
                            [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Transfer Failed", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                        }];
                    }
                }
            }                              forgetPassBlock:^{
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD hideHUDForView:weakSelf.view];
                    weakSelf.comfrimButton.enabled = YES;
                    PaySetPage *page = [[PaySetPage alloc] initIsNeedPoptoRoot:YES];
                    [weakSelf.navigationController pushViewController:page animated:YES];
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

@end
