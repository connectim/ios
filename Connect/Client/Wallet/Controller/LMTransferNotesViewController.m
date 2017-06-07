//
//  LMTransferNotesViewController.m
//  Connect
//  Payment Request
//  Created by Edwin on 16/8/10.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMTransferNotesViewController.h"
#import "WallteNetWorkTool.h"
#import "NSString+Size.h"
#import "CommonClausePage.h"
#import "LMPayCheck.h"
#import "LMMessageExtendManager.h"

typedef NS_ENUM(NSInteger, LMTransactionStatusType) {
    TransactionStatusTypeUnconfirmed = 1,
    TransactionStatusTypeConfirmed

};

@interface LMTransferNotesViewController ()
@property(nonatomic, strong) UIImageView *sendImageView;
@property(nonatomic, strong) UILabel *sendUsernameLabel;
@property(nonatomic, strong) UIImageView *receiveImageView;
@property(nonatomic, strong) UIImageView *categoryImageView;
@property(nonatomic, strong) UILabel *receiveUsernameLabel;
@property(nonatomic, strong) UILabel *reciptReasonLabel;
@property(nonatomic, strong) UILabel *bitNumLabel;
// status
@property(nonatomic, strong) UIButton *payStatusViewButton;
// Trading serial number
@property(nonatomic, strong) UILabel *notesTitle;
// Water bill information
@property(nonatomic, strong) UILabel *notesContentLabel;
// Serial number time
@property(nonatomic, strong) UILabel *timeLabel;
// Confirmation of information
@property(nonatomic, strong) UILabel *checkLabel;
// cell back
@property(nonatomic, strong) UIView *tableViewCell;
// Bitcoin icon
@property(nonatomic, strong) UIImageView *bitcoinImageView;
// money blance
@property(nonatomic, strong) UILabel *BalanceLabel;
// transfer balance
@property(nonatomic, strong) TransferButton *transferBtn;
@property(nonatomic, strong) AccountInfo *senderUser;

@end

@implementation LMTransferNotesViewController

#pragma mark --lazy

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LMLocalizedString(@"Wallet Detail", nil);
    NSLog(@"bill === %lld", self.bill.amount);

    if (self.bill.status > 0) {
        self.PayStatus = YES;
    }

    [self displayTransferInfo];
    [self payStatusInformation];

    [[PayTool sharedInstance] getBlanceWithComplete:^(NSString *blance, UnspentAmount *unspentAmount, NSError *error) {
        if (error) {
            // address is nil
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Failed to obtain the balance", nil) withType:ToastTypeFail showInView:self.view complete:nil];
            }];
            return;
        }
        self.blance = unspentAmount.avaliableAmount;
        self.blanceString = blance;
        [GCDQueue executeInMainQueue:^{
            self.BalanceLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Balance Credit", nil), [PayTool getBtcStringWithAmount:self.blance]];
        }];
    }];

    __weak __typeof(&*self)weakSelf = self;
    self.trasferComplete = ^{
        [GCDQueue executeInMainQueue:^{
            [weakSelf.navigationController popViewControllerAnimated:YES];
        }];
    };
}


- (void)displayTransferInfo {
    self.sendImageView = [[UIImageView alloc] initWithFrame:CGRectMake(DEVICE_SIZE.width / 2 - AUTO_WIDTH(232), AUTO_HEIGHT(34) + 64, AUTO_WIDTH(112), AUTO_WIDTH(112))];
    [self.sendImageView setPlaceholderImageWithAvatarUrl:self.reciverUser.avatar];
    self.sendImageView.layer.cornerRadius = 5;
    self.sendImageView.layer.masksToBounds = YES;

    [self.view addSubview:self.sendImageView];

    self.sendUsernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.sendImageView.frame) + AUTO_HEIGHT(10), VSIZE.width - AUTO_WIDTH(80), AUTO_HEIGHT(40))];
    self.sendUsernameLabel.centerX = self.sendImageView.centerX;
    self.sendUsernameLabel.textAlignment = NSTextAlignmentCenter;
    self.sendUsernameLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.sendUsernameLabel.textColor = [UIColor blackColor];
    [self.view addSubview:self.sendUsernameLabel];

    if (self.bill.status == 1) { // pay finish
        self.senderUser = [[LKUserCenter shareCenter] currentLoginUser];
        self.sendUsernameLabel.text = self.senderUser.username;
        [self.sendImageView setPlaceholderImageWithAvatarUrl:self.senderUser.avatar];
        self.categoryImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, AUTO_WIDTH(100), AUTO_HEIGHT(37))];
        self.categoryImageView.centerX = DEVICE_SIZE.width / 2;
        self.categoryImageView.centerY = self.sendImageView.centerY;
        [self.categoryImageView setImage:[UIImage imageNamed:@"transfer_to"]];
        [self.view addSubview:self.categoryImageView];

        self.receiveImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.categoryImageView.left + AUTO_WIDTH(170), AUTO_HEIGHT(34) + 64, AUTO_WIDTH(112), AUTO_WIDTH(112))];
        [self.receiveImageView setPlaceholderImageWithAvatarUrl:self.reciverUser.avatar];
        self.receiveImageView.layer.cornerRadius = 5;
        self.receiveImageView.layer.masksToBounds = YES;
        [self.view addSubview:self.receiveImageView];

        self.receiveUsernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.receiveImageView.frame) + AUTO_HEIGHT(10), VSIZE.width - AUTO_WIDTH(80), AUTO_HEIGHT(40))];
        self.receiveUsernameLabel.centerX = self.receiveImageView.centerX;
        self.receiveUsernameLabel.text = self.reciverUser.username;

        self.receiveUsernameLabel.textAlignment = NSTextAlignmentCenter;
        self.receiveUsernameLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
        self.receiveUsernameLabel.textColor = [UIColor blackColor];
        [self.view addSubview:self.receiveUsernameLabel];
    } else {
        self.sendImageView.centerX = DEVICE_SIZE.width / 2;
        self.sendUsernameLabel.centerX = DEVICE_SIZE.width / 2;
        self.sendUsernameLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet has requested for payment", nil), self.reciverUser.username];
    }


    self.reciptReasonLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.sendUsernameLabel.frame) + AUTO_HEIGHT(26), VSIZE.width - AUTO_WIDTH(200), AUTO_HEIGHT(40))];
    self.reciptReasonLabel.centerX = DEVICE_SIZE.width / 2;
    self.reciptReasonLabel.numberOfLines = 0;
    self.reciptReasonLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.reciptReasonLabel.text = GJCFStringIsNull(self.bill.tips) ? nil : [NSString stringWithFormat:LMLocalizedString(@"Link Note", nil), self.bill.tips];
    self.reciptReasonLabel.textAlignment = NSTextAlignmentCenter;
    self.reciptReasonLabel.textColor = [UIColor colorWithHexString:@"767A82"];
    [self.view addSubview:self.reciptReasonLabel];

    NSString *eightNum = [PayTool getBtcStringWithAmount:self.bill.amount];
    self.bitNumLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.reciptReasonLabel.frame) + AUTO_HEIGHT(21), VSIZE.width - AUTO_WIDTH(300), AUTO_HEIGHT(80))];
    self.bitNumLabel.centerX = DEVICE_SIZE.width / 2;
    self.bitNumLabel.text = [NSString stringWithFormat:@"฿%@", eightNum];
    self.bitNumLabel.font = [UIFont systemFontOfSize:FONT_SIZE(64)];
    self.bitNumLabel.textAlignment = NSTextAlignmentCenter;
    self.bitNumLabel.textColor = [UIColor colorWithHexString:@"161A21"];
    [self.view addSubview:self.bitNumLabel];
}

- (void)payStatusInformation {
    if (self.PayStatus == YES) {
        self.payStatusViewButton = [[UIButton alloc] init];
        self.payStatusViewButton.enabled = NO;
        [self.payStatusViewButton setImage:[UIImage imageNamed:@"transfer_success"] forState:UIControlStateNormal];
        [self.payStatusViewButton setTitle:LMLocalizedString(@"Wallet Payment Successful", nil) forState:UIControlStateNormal];
        self.payStatusViewButton.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(36)];
        [self.payStatusViewButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.view addSubview:self.payStatusViewButton];

        CGSize statusBtnSize = [self.payStatusViewButton.titleLabel.text sizeWithFont:self.payStatusViewButton.titleLabel.font constrainedToHeight:AUTO_HEIGHT(100)];

        self.payStatusViewButton.size = CGSizeMake(statusBtnSize.width + AUTO_HEIGHT(55), AUTO_HEIGHT(55));
        self.payStatusViewButton.top = self.bitNumLabel.bottom + AUTO_HEIGHT(80);
        self.payStatusViewButton.centerX = self.view.centerX;

        UIView *backView = [UIView new];
        [self.view addSubview:backView];
        backView.backgroundColor = [UIColor whiteColor];
        backView.layer.cornerRadius = 8;
        backView.layer.borderWidth = 0.5;
        backView.layer.borderColor = GJCFQuickHexColor(@"b3b5bd").CGColor;


        self.notesTitle = [[UILabel alloc] initWithFrame:CGRectMake(AUTO_WIDTH(55), CGRectGetMaxY(self.payStatusViewButton.frame) + AUTO_HEIGHT(92), AUTO_WIDTH(240), AUTO_HEIGHT(40))];
        self.notesTitle.textAlignment = NSTextAlignmentLeft;
        self.notesTitle.text = LMLocalizedString(@"Wallet Transcation", nil);
        self.notesTitle.textColor = [UIColor colorWithHexString:@"161A21"];
        self.notesTitle.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
        [self.view addSubview:self.notesTitle];

        backView.top = self.payStatusViewButton.bottom + AUTO_HEIGHT(50);
        CGFloat maginToView = 10;
        backView.width = DEVICE_SIZE.width - maginToView * 2;
        backView.left = maginToView;

        self.notesContentLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.notesTitle.frame), CGRectGetMaxY(self.notesTitle.frame) + AUTO_HEIGHT(12), VSIZE.width - AUTO_WIDTH(110), AUTO_HEIGHT(70))];
        self.notesContentLabel.numberOfLines = 0;
        self.notesContentLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
        self.notesContentLabel.text = self.bill.txid;
        self.notesContentLabel.textAlignment = NSTextAlignmentLeft;
        self.notesContentLabel.textColor = [UIColor colorWithHexString:@"161A21"];
        self.notesContentLabel.userInteractionEnabled = YES;
        [self.view addSubview:self.notesContentLabel];


        UIButton *notesBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        notesBtn.frame = CGRectMake(CGRectGetMinX(self.notesTitle.frame), CGRectGetMaxY(self.notesTitle.frame) + AUTO_HEIGHT(12), VSIZE.width - AUTO_WIDTH(110), AUTO_HEIGHT(70));
        notesBtn.userInteractionEnabled = YES;
        notesBtn.backgroundColor = [UIColor clearColor];
        [notesBtn addTarget:self action:@selector(noteBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:notesBtn];

        self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.notesTitle.frame), CGRectGetMaxY(self.notesContentLabel.frame) + AUTO_HEIGHT(22), VSIZE.width - AUTO_WIDTH(244), AUTO_HEIGHT(30))];
        self.timeLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
        self.timeLabel.textAlignment = NSTextAlignmentLeft;
        self.timeLabel.textColor = [UIColor colorWithHexString:@"858998"];

        NSDate *date = [NSDate date];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm";
        NSString *res = [formatter stringFromDate:date];
        self.timeLabel.text = res;
        [self.view addSubview:self.timeLabel];

        self.checkLabel = [[UILabel alloc] initWithFrame:CGRectMake(AUTO_WIDTH(537), CGRectGetMaxY(self.timeLabel.frame) + AUTO_HEIGHT(5), AUTO_WIDTH(158), AUTO_HEIGHT(67))];
        self.checkLabel.font = [UIFont systemFontOfSize:FONT_SIZE(32)];
        self.checkLabel.textAlignment = NSTextAlignmentCenter;
        self.checkLabel.backgroundColor = [UIColor colorWithHexString:@"FF6C5A"];
        self.checkLabel.layer.cornerRadius = 5;
        self.checkLabel.layer.masksToBounds = YES;
        self.checkLabel.textColor = [UIColor whiteColor];
        if (self.bill.status == TransactionStatusTypeConfirmed) {
            self.checkLabel.text = LMLocalizedString(@"Wallet Confirmed", nil);
            self.checkLabel.backgroundColor = [UIColor colorWithHexString:@"37C65C"];
        } else {
            self.checkLabel.text = LMLocalizedString(@"Wallet Unconfirmed", nil);
        }
        CGSize size = [self.checkLabel.text sizeWithFont:self.checkLabel.font constrainedToHeight:AUTO_HEIGHT(67)];
        self.checkLabel.left -= size.width + 20 - self.checkLabel.width;
        self.checkLabel.width = size.width + 20;
        [self.view addSubview:self.checkLabel];

        backView.height = self.checkLabel.bottom + 10 - backView.top;

    } else {
        self.tableViewCell = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.bitNumLabel.frame) + AUTO_HEIGHT(330), VSIZE.width, AUTO_HEIGHT(100))];
        [self.view addSubview:self.tableViewCell];

        self.BalanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.tableViewCell.frame) + AUTO_WIDTH(30), 0, CGRectGetWidth(self.tableViewCell.frame) - AUTO_WIDTH(60), CGRectGetHeight(self.tableViewCell.frame))];
        self.BalanceLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
        self.BalanceLabel.textColor = [UIColor blackColor];
        self.BalanceLabel.textAlignment = NSTextAlignmentCenter;
        self.BalanceLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Balance Credit", nil), [PayTool getBtcStringWithAmount:[[MMAppSetting sharedSetting] getAvaliableAmount]]];
        self.BalanceLabel.textColor = [UIColor colorWithHexString:@"38425F"];
        [self.tableViewCell addSubview:self.BalanceLabel];

        // transfer button
        self.transferBtn = [[TransferButton alloc] initWithNormalTitle:LMLocalizedString(@"Set Payment", nil) disableTitle:LMLocalizedString(@"Set Payment", nil)];
        self.transferBtn.frame = CGRectMake(AUTO_WIDTH(30), CGRectGetMaxY(self.tableViewCell.frame) + AUTO_HEIGHT(5), VSIZE.width - AUTO_WIDTH(60), AUTO_HEIGHT(100));
        self.transferBtn.layer.cornerRadius = 3;
        self.transferBtn.layer.masksToBounds = YES;
        [self.transferBtn addTarget:self action:@selector(transferBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.transferBtn];
    }
}

- (void)noteBtnClick:(UIButton *)pan {
    NSString *url = [NSString stringWithFormat:@"%@%@", txDetailBaseUrl, self.notesContentLabel.text];
    CommonClausePage *page = [[CommonClausePage alloc] initWithUrl:url];
    [self.navigationController pushViewController:page animated:YES];
}

- (void)updateBalanceLabelWithBitInfo:(BitcoinInfo *)info {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.BalanceLabel setText:[NSString stringWithFormat:LMLocalizedString(@"Wallet Balance", nil), [info.bitcoinAccout floatValue]]];
    });
}

- (void)transferBtnClick:(UIButton *)btn {
    __weak typeof(self) weakSelf = self;
    NSDecimalNumber *amount = [[NSDecimalNumber alloc] initWithLongLong:self.bill.amount];
    if (amount.longLongValue > self.blance) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Insufficient balance", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
        }];
        return;
    }

    [MBProgressHUD showTransferLoadingViewtoView:self.view];
    [self.view endEditing:YES];

    NSArray *toAddresses = @[@{@"address": self.bill.receiver, @"amount": [amount
            decimalNumberByDividingBy:
                    [[NSDecimalNumber alloc] initWithLongLong:pow(10, 8)]].stringValue}];
    BOOL isDusk = [LMPayCheck dirtyAlertWithAddress:toAddresses withController:self];
    if (isDusk) {
        btn.enabled = YES;
        return;
    }
    AccountInfo *ainfo = [[LKUserCenter shareCenter] currentLoginUser];
    [WallteNetWorkTool unspentV2WithAddress:ainfo.address fee:[[MMAppSetting sharedSetting] getTranferFee] toAddress:toAddresses createRawTranscationModelComplete:^(UnspentOrderResponse *unspent, NSError *error) {
        [LMPayCheck payCheck:nil withVc:weakSelf withTransferType:TransferTypeNotes unSpent:unspent withArray:toAddresses withMoney:amount withNote:nil withType:0 withRedPackage:nil withError:error];
    }];
}

- (void)checkChangeWithRawTrancationModel:(LMRawTransactionModel *)rawModel
                             decimalMoney:(NSDecimalNumber *)amount {
    // Check for change
    __weak __typeof(&*self) weakSelf = self;
    rawModel = [LMUnspentCheckTool checkChangeDustWithRawTrancation:rawModel];
    switch (rawModel.unspentErrorType) {
        case UnspentErrorTypeChangeDust: {
            [MBProgressHUD hideHUDForView:self.view];
            NSString *tips = [NSString stringWithFormat:LMLocalizedString(@"Wallet Charge small calculate to the poundage", nil),
                                                        [PayTool getBtcStringWithAmount:rawModel.change]];
            [UIAlertController showAlertInViewController:self withTitle:LMLocalizedString(@"Set tip title", nil) message:tips cancelButtonTitle:LMLocalizedString(@"Common Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:@[LMLocalizedString(@"Common OK", nil)] tapBlock:^(UIAlertController *_Nonnull controller, UIAlertAction *_Nonnull action, NSInteger buttonIndex) {
                switch (buttonIndex) {
                    case 0: {
                    }
                        break;
                    case 2: // click sure
                    {
                        LMRawTransactionModel *rawModelNew = [LMUnspentCheckTool createRawTransactionWithRawTrancation:rawModel addDustToFee:YES];
                        // pay money
                        [weakSelf createTransferWithRawTransactionModel:rawModelNew decimalMoney:amount];
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
            [weakSelf createTransferWithRawTransactionModel:rawModelNew decimalMoney:amount];
        }
            break;
        default:
            break;
    }
}


- (void)createTransferWithRawTransactionModel:(LMRawTransactionModel *)rawModel decimalMoney:(NSDecimalNumber *)money {
    self.rawTransaction = rawModel.rawTrancation;
    self.vtsArray = rawModel.vtsArray;
    __weak __typeof(&*self) weakSelf = self;
    [[PayTool sharedInstance] payVerfifyFingerWithComplete:^(BOOL result, NSString *errorMsg) {
        if (result) {
            [self successAction:rawModel decimalMoney:money passView:nil];
        } else {
            if ([errorMsg isEqualToString:@"NO"]) {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD hideHUDForView:weakSelf.view];
                }];
                return;
            }
            [InputPayPassView showInputPayPassWithComplete:^(InputPayPassView *passView, NSError *error, BOOL result) {
                if (result) {
                    [weakSelf successAction:rawModel decimalMoney:money passView:passView];
                }
            }                              forgetPassBlock:^{
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD hideHUDForView:weakSelf.view];
                    PaySetPage *page = [[PaySetPage alloc] initIsNeedPoptoRoot:YES];
                    [weakSelf.navigationController pushViewController:page animated:YES];
                }];
            }                                   closeBlock:^{
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD hideHUDForView:weakSelf.view];
                }];
            }];
        }
    }];

}
- (void)successAction:(LMRawTransactionModel *)rawModel decimalMoney:(NSDecimalNumber *)money passView:(InputPayPassView *)passView {
    __weak __typeof(&*self) weakSelf = self;
    [self paymentToAddress:self.bill.receiver decimalMoney:money hashID:self.bill.hash_p complete:^(NSString *hashId, NSError *error) {
        if (!error) {
            if (passView.requestCallBack) {
                passView.requestCallBack(nil);
            }
            // update db status
            [[LMMessageExtendManager sharedManager] updateMessageExtendStatus:1 withHashId:self.bill.hash_p];
            // call back
            if (weakSelf.PayResultBlock) {
                weakSelf.PayResultBlock(YES);
            }
        } else {
            if (passView.requestCallBack) {
                passView.requestCallBack(error);
            }
        }
    }];
}

@end
