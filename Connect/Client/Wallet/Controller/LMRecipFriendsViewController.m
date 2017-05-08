//
//  LMRecipFriendsViewController.m
//  Connect
//
//  Created by Edwin on 16/7/23.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMRecipFriendsViewController.h"
#import "GJGCChatFriendTalkModel.h"
#import "GJGCChatFriendViewController.h"
#import "NetWorkOperationTool.h"
#import "TransferInputView.h"
#import "LMMessageExtendManager.h"

@interface LMRecipFriendsViewController ()

@property(nonatomic, strong) UIImageView *userImageView;
@property(nonatomic, strong) UILabel *usernameLabel;
@property(nonatomic, strong) TransferInputView *inputAmountView;

@end

@implementation LMRecipFriendsViewController


- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = LMLocalizedString(@"Wallet Receipt", nil);
    [self addNewCloseBarItem];
    [self initUserInfomation];

    __weak __typeof(&*self) weakSelf = self;
    TransferInputView *view = [[TransferInputView alloc] init];
    self.inputAmountView = view;
    [self.view addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.usernameLabel.mas_bottom).offset(AUTO_HEIGHT(10));
        make.width.equalTo(self.view);
        make.height.mas_equalTo(AUTO_HEIGHT(334));
        make.left.equalTo(self.view);
    }];
    view.topTipString = LMLocalizedString(@"Wallet Amount", nil);
    view.hidenFeeLabel = YES;
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
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Get rate failed", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
            }];
        }
    }];

    [NSNotificationCenter.defaultCenter addObserverForName:UIKeyboardWillChangeFrameNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        CGFloat duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
        CGRect keyboardFrame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        int distence = weakSelf.inputAmountView.bottom - (DEVICE_SIZE.height - keyboardFrame.size.height - AUTO_HEIGHT(100));

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
    self.comfrimButton = [[ConnectButton alloc] initWithNormalTitle:LMLocalizedString(@"Wallet Receipt", nil) disableTitle:LMLocalizedString(@"Wallet Receipt", nil)];
    [self.comfrimButton addTarget:self action:@selector(tapConfrim) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.comfrimButton];
    [self.comfrimButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.inputAmountView.mas_bottom).offset(AUTO_HEIGHT(30));
        make.width.mas_equalTo(self.comfrimButton.width);
        make.height.mas_equalTo(self.comfrimButton.height);
    }];

}

- (void)initUserInfomation {
    self.userImageView = [[UIImageView alloc] initWithFrame:CGRectMake(AUTO_WIDTH(319), AUTO_HEIGHT(30) + 64, AUTO_WIDTH(112), AUTO_WIDTH(112))];
    [self.userImageView setPlaceholderImageWithAvatarUrl:self.info.avatar];
    self.userImageView.layer.cornerRadius = 5;
    self.userImageView.layer.masksToBounds = YES;
    [self.view addSubview:self.userImageView];

    self.usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(AUTO_WIDTH(50), CGRectGetMaxY(self.userImageView.frame) + AUTO_HEIGHT(10), VSIZE.width - AUTO_WIDTH(100), AUTO_HEIGHT(40))];
    self.usernameLabel.text = _info.username;
    self.usernameLabel.textAlignment = NSTextAlignmentCenter;
    self.usernameLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.usernameLabel.textColor = [UIColor blackColor];
    [self.view addSubview:self.usernameLabel];
}

- (void)tapConfrim {
    self.comfrimButton.enabled = NO;
    [self.inputAmountView executeBlock];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.inputAmountView hidenKeyBoard];
}

#pragma mark -- 收款

- (void)createTranscationWithMoney:(NSDecimalNumber *)money note:(NSString *)note {

    [GCDQueue executeInMainQueue:^{
        [self.view endEditing:YES];
        [MBProgressHUD showTransferLoadingViewtoView:self.view];
    }];

    NSDecimalNumber *amount = [money decimalNumberByMultiplyingBy:[[NSDecimalNumber alloc] initWithLong:pow(10, 8)]];

    ReceiveBill *bill = [[ReceiveBill alloc] init];
    bill.sender = self.info.address;
    bill.amount = amount.longValue;
    bill.tips = note;
    __weak typeof(self) weakSelf = self;
    [NetWorkOperationTool POSTWithUrlString:WallteBillingReciveUrl postProtoData:bill.data complete:^(id response) {
        weakSelf.comfrimButton.enabled = YES;

        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:weakSelf.view];
        }];

        HttpResponse *respo = (HttpResponse *) response;
        if (respo.code != successCode) {
            DDLogInfo(@"Network Server error");
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Transfer failed", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
            }];
            return;
        }

        NSData *data = [ConnectTool decodeHttpResponse:respo];
        NSError *error = nil;
        BillHashId *hashid = [BillHashId parseFromData:data error:&error];
        if (error) {
            DDLogInfo(@"error === %@", [error localizedDescription]);
        } else {
            DDLogInfo(@"hasid == %@", hashid.hash_p);

            [[LMMessageExtendManager sharedManager] updateMessageExtendStatus:0 withHashId:hashid.hash_p];

            if (weakSelf.didGetMoneyAndWithAccountID) {
                weakSelf.didGetMoneyAndWithAccountID(amount, hashid.hash_p, note);
            }
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
        }
    }                                  fail:^(NSError *error) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:weakSelf.view];
            weakSelf.comfrimButton.enabled = YES;
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Server Error", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
        }];
    }];
}

@end
