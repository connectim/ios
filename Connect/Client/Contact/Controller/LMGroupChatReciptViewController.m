//
//  LMGroupChatReciptViewController.m
//  Connect
//
//  Created by Edwin on 16/8/24.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMGroupChatReciptViewController.h"
#import "PaddingTextField.h"
#import "WallteNetWorkTool.h"
#import "TransferInputView.h"
#import "CrowdfoundingHisPage.h"
#import "ConnectButton.h"
#import "LMMessageExtendManager.h"

@interface LMGroupChatReciptViewController () <UITextFieldDelegate>
/**
 *  总人数x
 */
@property(nonatomic, strong) PaddingTextField *totalPeTextField;
//groupID
@property(nonatomic, copy) NSString *groupIdentifer;
@property(nonatomic, strong) UILabel *totalAmountLabel;
//leave Money
@property(nonatomic, assign) float accoutMoney;
//photo
@property(nonatomic, strong) TransferInputView *inputAmountView;
//money
@property(nonatomic, strong) NSDecimalNumber *amount;

@property(nonatomic, strong) UIView *keyboardTopView;

@property(nonatomic, strong) UIButton *CrowdfundingHisButton;

@end

@implementation LMGroupChatReciptViewController

- (instancetype)initWithIdentifier:(NSString *)groupIdentifier {
    if (self = [super init]) {
        self.groupIdentifer = groupIdentifier;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LMLocalizedString(@"Chat Crowdfunding", nil);
    [self addNewCloseBarItem];
    [self addRightBarItem];
    [self creatView];
}

- (void)addRightBarItem {
    self.navigationItem.rightBarButtonItems = nil;
    self.CrowdfundingHisButton = [[UIButton alloc] init];
    [_CrowdfundingHisButton addTarget:self action:@selector(CrowdfoundindHis) forControlEvents:UIControlEventTouchUpInside];
    _CrowdfundingHisButton.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    [_CrowdfundingHisButton setTitle:LMLocalizedString(@"Chat Crowdfoundind History", nil) forState:UIControlStateNormal];
    [_CrowdfundingHisButton setTitleColor:LMBasicGreen forState:UIControlStateNormal];
    _CrowdfundingHisButton.width = AUTO_WIDTH(140);
    _CrowdfundingHisButton.height = AUTO_HEIGHT(15);
    UIBarButtonItem *rightBtnItem = [[UIBarButtonItem alloc] initWithCustomView:_CrowdfundingHisButton];
    self.navigationItem.rightBarButtonItem = rightBtnItem;
}

- (void)creatView {

    self.totalPeTextField = [[PaddingTextField alloc] initWithFrame:CGRectMake(20, AUTO_HEIGHT(60) + 64, DEVICE_SIZE.width - 40, AUTO_HEIGHT(96))];
    self.totalPeTextField.borderStyle = UITextBorderStyleRoundedRect;

    self.totalPeTextField.text = [NSString stringWithFormat:@"%d", (int) self.groupMemberCount];
    self.totalPeTextField.textAlignment = NSTextAlignmentLeft;
    self.totalPeTextField.font = [UIFont boldSystemFontOfSize:FONT_SIZE(48)];
    self.totalPeTextField.tintColor = [UIColor blackColor];
    self.totalPeTextField.returnKeyType = UIReturnKeyNext;
    self.totalPeTextField.keyboardType = UIKeyboardTypeNumberPad;
    self.totalPeTextField.delegate = self;
    [self.totalPeTextField addTarget:self action:@selector(TextFieldEditValueChanged) forControlEvents:UIControlEventEditingChanged];
    [self.totalPeTextField becomeFirstResponder];
    [self.view addSubview:self.totalPeTextField];
    //set placeholder middle
    [self.totalPeTextField setVerPlaceHolderWithName:LMLocalizedString(@"Wallet Enter number", nil)];

    UILabel *amountTipLabel = [[UILabel alloc] init];
    [self.totalPeTextField addSubview:amountTipLabel];
    amountTipLabel.textColor = LMBasicDarkGray;
    amountTipLabel.text = LMLocalizedString(@"Wallet Amount of member", nil);
    amountTipLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    [amountTipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.totalPeTextField).offset(-AUTO_WIDTH(20));
        make.centerY.equalTo(self.totalPeTextField);
    }];

    __weak __typeof(&*self) weakSelf = self;
    TransferInputView *view = [[TransferInputView alloc] init];
    self.inputAmountView = view;
    [self.view addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.totalPeTextField.mas_bottom).offset(AUTO_HEIGHT(30.4));
        make.width.equalTo(self.view);
        make.height.mas_equalTo(AUTO_HEIGHT(334));
        make.left.equalTo(self.view);
    }];
    view.topTipString = LMLocalizedString(@"Wallet Each", nil);
    view.isHidenFee = YES;
    view.resultBlock = ^(NSDecimalNumber *btcMoney, NSString *note) {
        weakSelf.amount = btcMoney;
        [weakSelf createTranscationWithMoney:btcMoney note:note];
    };
    view.lagelBlock = ^(BOOL enabled) {
        weakSelf.comfrimButton.enabled = enabled;
    };
    view.valueChangeBlock = ^(NSString *text, NSDecimalNumber *btcMoney) {
        weakSelf.amount = btcMoney;
        NSDecimalNumber *total = [NSDecimalNumber decimalNumberWithString:weakSelf.totalPeTextField.text];
        if ([total intValue] > 0 && btcMoney.doubleValue > 0) {
            [GCDQueue executeInMainQueue:^{

                NSString *totoalString = [NSString stringWithFormat:@"%f", [btcMoney decimalNumberByMultiplyingBy:total].doubleValue];
                weakSelf.totalAmountLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet BTC Total", nil), totoalString];
            }];
        }
    };
    [[PayTool sharedInstance] getRateComplete:^(NSDecimalNumber *rate, NSError *error) {
        if (!error) {
            weakSelf.rate = rate.floatValue;
            [[MMAppSetting sharedSetting] saveRate:[rate floatValue]];
            [weakSelf.inputAmountView reloadWithRate:rate.floatValue];
        } else {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Get rate failed", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
            }];
        }
    }];

    self.totalAmountLabel = [[UILabel alloc] init];
    NSString *memberString = [NSString stringWithFormat:@"%f", self.groupMemberCount * MIN_TRANSFER_AMOUNT];
    self.totalAmountLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet BTC Total", nil), memberString];
    self.totalAmountLabel.textColor = GJCFQuickHexColor(@"007AFF");
    self.totalAmountLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    [self.view addSubview:self.totalAmountLabel];
    [self.view sendSubviewToBack:self.totalAmountLabel];

    [self.totalAmountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.inputAmountView.mas_bottom).offset(AUTO_HEIGHT(60));
        make.centerX.equalTo(self.view);
    }];

    self.comfrimButton = [[ConnectButton alloc] initWithNormalTitle:LMLocalizedString(@"Chat Crowfunding", nil) disableTitle:LMLocalizedString(@"Chat Crowfunding", nil)];
    [self.comfrimButton addTarget:self action:@selector(tapConfrim) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.comfrimButton];
    [self.comfrimButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.totalAmountLabel.mas_bottom).offset(AUTO_HEIGHT(30));
        make.centerX.equalTo(self.view);
        make.height.mas_equalTo(self.comfrimButton.height);
        make.width.mas_equalTo(self.comfrimButton.width);
    }];
}

- (void)CrowdfoundindHis {
    CrowdfoundingHisPage *page = [[CrowdfoundingHisPage alloc] init];
    page.title = LMLocalizedString(@"Chat History", nil);
    [self.navigationController pushViewController:page animated:YES];
}

#pragma mark -  textfield - delegate

- (void)TextFieldEditValueChanged {
    NSDecimalNumber *total = [NSDecimalNumber decimalNumberWithString:self.totalPeTextField.text];
    if (GJCFStringIsNull(self.totalPeTextField.text)) {
        total = [[NSDecimalNumber alloc] initWithInt:0];
    }
    if (total.integerValue > self.groupMemberCount) {
        __weak typeof(self) weakSelf = self;
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet No more than group members", nil) withType:ToastTypeCommon showInView:weakSelf.view complete:nil];
        }];
        self.totalPeTextField.text = [NSString stringWithFormat:@"%d", (int) self.groupMemberCount];
        total = [[NSDecimalNumber alloc] initWithInteger:self.groupMemberCount];
    }
    if (self.amount.doubleValue > 0 && total.intValue >= 0) {
        NSDecimalNumber *totalAmount = [self.amount decimalNumberByMultiplyingBy:total];
        NSString *totalString = [NSString stringWithFormat:@"%f", totalAmount.doubleValue];
        self.totalAmountLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet BTC Total", nil), totalString];
        self.comfrimButton.enabled = totalAmount.doubleValue >= MIN_TRANSFER_AMOUNT && total.intValue <= self.groupMemberCount;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.totalPeTextField) {
        if ([string isEqualToString:@""] || string == nil) {
            return YES;
        }
        NSString *pattern = @"^[0-9]*\\d{1}$";
        NSRegularExpression *regular = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
        NSArray *results = [regular matchesInString:string options:0 range:NSMakeRange(0, string.length)];
        if (results.count == 0) {
            return NO;
        }
    }
    return YES;
}

- (void)tapConfrim {
    [self.inputAmountView executeBlock];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self hidenKeyBoard];
}

- (void)createTranscationWithMoney:(NSDecimalNumber *)money note:(NSString *)note {

    //Integer
    money = [money decimalNumberByMultiplyingBy:[[NSDecimalNumber alloc] initWithLong:pow(10, 8)]];
    NSDecimalNumber *totalPersions = [[NSDecimalNumber alloc] initWithString:self.totalPeTextField.text];
    __weak typeof(self) weakSelf = self;
    if ([totalPersions intValue] <= 0) {
        return;
    }
    if ([money longValue] <= 0) {
        return;
    }

    [GCDQueue executeInMainQueue:^{
        [MBProgressHUD showTransferLoadingViewtoView:self.view];
    }];
    NSDecimalNumber *totalMoney = [money decimalNumberByMultiplyingBy:totalPersions];
    [WallteNetWorkTool createCrowdfuningBillWithGroupId:self.groupIdentifer totalAmount:[totalMoney longLongValue] size:[self.totalPeTextField.text intValue] tips:note complete:^(NSError *erro, NSString *hashId) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:weakSelf.view];
        }];
        if (!erro) {
            //update status
            [[LMMessageExtendManager sharedManager] updateMessageExtendStatus:0 withHashId:hashId];
            
            
            [GCDQueue executeInMainQueue:^{
                if (weakSelf.didGetNumberAndMoney) {
                    int count = [totalPersions intValue];
                    weakSelf.didGetNumberAndMoney(count, money, hashId, note);
                }
                [weakSelf dismissViewControllerAnimated:YES completion:nil];
            }];
        } else {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"ErrorCode Error", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
            }];
        }
    }];
}

- (NSDecimalNumber *)amount {
    if (!_amount) {
        _amount = [[NSDecimalNumber alloc] initWithDouble:MIN_TRANSFER_AMOUNT];
    }
    return _amount;
}

- (UIView *)keyboardTopView {
    if (!_keyboardTopView) {
        _keyboardTopView = [[UIView alloc] init];
        _keyboardTopView.frame = CGRectMake(0, DEVICE_SIZE.height, DEVICE_SIZE.width, AUTO_HEIGHT(100));
        _keyboardTopView.backgroundColor = [UIColor whiteColor];
        UIButton *doneButton = [[UIButton alloc] init];
        [_keyboardTopView addSubview:doneButton];
        [doneButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
        [doneButton setTitle:LMLocalizedString(@"Chat Complete", nil) forState:UIControlStateNormal];
        [doneButton addTarget:self action:@selector(hidenKeyBoard) forControlEvents:UIControlEventTouchUpInside];
        [doneButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(_keyboardTopView).offset(-AUTO_WIDTH(20));
            make.centerY.equalTo(_keyboardTopView);
        }];
        UIView *line = [[UIView alloc] init];
        [_keyboardTopView addSubview:line];
        line.backgroundColor = [UIColor blackColor];
        line.alpha = 0.7;
        [line mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(_keyboardTopView);
            make.right.left.equalTo(_keyboardTopView);
            make.height.mas_equalTo(0.3);
        }];
    }

    return _keyboardTopView;
}

- (void)hidenKeyBoard {
    [self.inputAmountView hidenKeyBoard];
    [self.view endEditing:YES];
}

@end
