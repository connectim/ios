//
//  LMGroupZChouTransViewController.m
//  Connect
//
//  Created by Edwin on 16/8/24.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMGroupZChouTransViewController.h"
#import "LMTableViewCell.h"
#import "WallteNetWorkTool.h"
#import "CommonClausePage.h"
#import "NetWorkOperationTool.h"
#import "LMPayCheck.h"
#import "LMMessageExtendManager.h"

@interface LMGroupZChouTransViewController () <UITableViewDelegate, UITableViewDataSource>
// userhead
@property(nonatomic, strong) UIImageView *userImageView;
// username
@property(nonatomic, strong) UILabel *userNameLabel;
// crowd reason
@property(nonatomic, strong) UILabel *noteLabel;
// crowd
@property(nonatomic, strong) UILabel *totalBalanceLabel;
// per money
@property(nonatomic, strong) UILabel *everyUserBalanceLabel;
// have money
@property(nonatomic, strong) UILabel *UserReciptLabel;
// balance
@property(nonatomic, strong) UILabel *userBalanceLabel;
@property(nonatomic, strong) UIButton *payBtn;
@property(nonatomic, strong) UITableView *tableView;
// table data
@property(nonatomic, strong) NSMutableArray *dataArray;
// crowd messaga
@property(nonatomic, strong) Crowdfunding *crowdfundingInfo;
// money
@property(nonatomic, assign) int long long amount;

@end

static NSString *identifier = @"cellIdentifier";

@implementation LMGroupZChouTransViewController

- (instancetype)initWithCrowdfundingInfo:(Crowdfunding *)crowdfunding {
    if (self = [super init]) {
        self.crowdfundingInfo = crowdfunding;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = LMLocalizedString(@"Chat Crowdfunding", nil);

    [self creatView];
}

- (void)creatView {

    __weak __typeof(&*self) weakSelf = self;

    self.userImageView = [[UIImageView alloc] initWithFrame:CGRectMake(AUTO_WIDTH(325), AUTO_HEIGHT(47) + 64, VSIZE.width - AUTO_WIDTH(650), VSIZE.width - AUTO_WIDTH(650))];

    NSString *avatar = self.crowdfundingInfo.sender.avatar;
    [self.userImageView setPlaceholderImageWithAvatarUrl:avatar];
    self.userImageView.layer.cornerRadius = 3;
    self.userImageView.layer.masksToBounds = YES;
    [self.view addSubview:self.userImageView];

    self.userNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(AUTO_WIDTH(100), CGRectGetMaxY(self.userImageView.frame) + AUTO_HEIGHT(10), VSIZE.width - AUTO_WIDTH(200), AUTO_HEIGHT(40))];
    self.userNameLabel.textAlignment = NSTextAlignmentCenter;
    self.userNameLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.userNameLabel.textColor = [UIColor colorWithHexString:@"161A21"];
    self.userNameLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Chat Crowd funding by who", nil), self.crowdfundingInfo.sender.username];
    [self.view addSubview:self.userNameLabel];

    self.noteLabel = [[UILabel alloc] initWithFrame:CGRectMake(AUTO_WIDTH(130), CGRectGetMaxY(self.userNameLabel.frame) + AUTO_HEIGHT(10), VSIZE.width - AUTO_WIDTH(260), AUTO_HEIGHT(40))];
    self.noteLabel.textColor = [UIColor colorWithHexString:@"B3B5BC"];
    self.noteLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.noteLabel.textAlignment = NSTextAlignmentCenter;
    self.noteLabel.text = GJCFStringIsNull(self.crowdfundingInfo.tips) ? nil : [NSString stringWithFormat:LMLocalizedString(@"Link Note", nil), self.crowdfundingInfo.tips];
    [self.view addSubview:self.noteLabel];

    self.totalBalanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(AUTO_WIDTH(50), CGRectGetMaxY(self.noteLabel.frame) + AUTO_HEIGHT(15), VSIZE.width - AUTO_WIDTH(100), AUTO_HEIGHT(67))];
    self.totalBalanceLabel.textAlignment = NSTextAlignmentCenter;
    self.totalBalanceLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Goal", nil), [PayTool getBtcStringWithAmount:self.crowdfundingInfo.total]];
    self.totalBalanceLabel.font = [UIFont systemFontOfSize:FONT_SIZE(48)];
    self.totalBalanceLabel.textColor = [UIColor colorWithHexString:@"161A21"];
    [self.view addSubview:self.totalBalanceLabel];

    self.everyUserBalanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(AUTO_WIDTH(50), CGRectGetMaxY(self.totalBalanceLabel.frame) + AUTO_HEIGHT(13), VSIZE.width - AUTO_WIDTH(100), AUTO_HEIGHT(40))];
    self.everyUserBalanceLabel.textColor = [UIColor colorWithHexString:@"B3B5BC"];
    self.everyUserBalanceLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.everyUserBalanceLabel.textAlignment = NSTextAlignmentCenter;
    self.everyUserBalanceLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet crowdfunding each", nil), [PayTool getBtcStringWithAmount:self.crowdfundingInfo.total / self.crowdfundingInfo.size]];
    [self.view addSubview:self.everyUserBalanceLabel];

    self.UserReciptLabel = [[UILabel alloc] initWithFrame:CGRectMake(AUTO_WIDTH(35), CGRectGetMaxY(self.everyUserBalanceLabel.frame) + AUTO_HEIGHT(32), VSIZE.width - AUTO_WIDTH(70), AUTO_HEIGHT(33))];
    self.UserReciptLabel.textColor = [UIColor colorWithHexString:@"B3B5BC"];
    self.UserReciptLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
    self.UserReciptLabel.textAlignment = NSTextAlignmentLeft;

    int count = (int) (self.crowdfundingInfo.size - self.crowdfundingInfo.remainSize);
    self.UserReciptLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet members paid BTC", nil), count, self.crowdfundingInfo.size, [PayTool getBtcStringWithAmount:count * self.crowdfundingInfo.total / self.crowdfundingInfo.size]];
    [self.view addSubview:self.UserReciptLabel];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(AUTO_WIDTH(15), CGRectGetMaxY(self.UserReciptLabel.frame) + AUTO_HEIGHT(10), VSIZE.width - AUTO_WIDTH(30), AUTO_HEIGHT(563)) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.rowHeight = AUTO_HEIGHT(130);
    [self.view addSubview:self.tableView];
    self.tableView.showsHorizontalScrollIndicator = NO;
    self.tableView.showsVerticalScrollIndicator = NO;
    [self.tableView registerNib:[UINib nibWithNibName:@"LMTableViewCell" bundle:nil] forCellReuseIdentifier:identifier];
    self.ainfo = [[LKUserCenter shareCenter] currentLoginUser];
    BOOL payed = NO;
    for (CrowdfundingRecord *record in self.crowdfundingInfo.records.listArray) {
        if ([record.user.address isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
            payed = YES;
            break;
        }
    }
    if (self.crowdfundingInfo.remainSize > 0 && !payed) {
        self.payBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.payBtn setBackgroundColor:[UIColor colorWithHexString:@"37C65C"]];
        [self.payBtn setTitle:LMLocalizedString(@"Set Payment", nil) forState:UIControlStateNormal];
        [self.payBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.payBtn.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(36)];
        self.payBtn.layer.cornerRadius = 3;
        self.payBtn.layer.masksToBounds = YES;
        [self.payBtn addTarget:self action:@selector(payBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.payBtn];
        [_payBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.view);
            make.width.mas_equalTo(AUTO_WIDTH(700));
            make.height.mas_equalTo(AUTO_WIDTH(100));
            make.bottom.equalTo(self.view).offset(-AUTO_HEIGHT(25));
        }];
        self.userBalanceLabel = [[UILabel alloc] init];
        self.amount = [[MMAppSetting sharedSetting] getBalance];
        self.userBalanceLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Balance", nil), [PayTool getBtcStringWithAmount:self.amount]];
        self.userBalanceLabel.textColor = [UIColor colorWithHexString:@"38425F"];
        self.userBalanceLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
        self.userBalanceLabel.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:self.userBalanceLabel];
        // get packet message
        [[PayTool sharedInstance] getBlanceWithComplete:^(NSString *blance, UnspentAmount *unspentAmount, NSError *error) {
            [GCDQueue executeInMainQueue:^{
                weakSelf.userBalanceLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Balance", nil), [PayTool getBtcStringWithAmount:unspentAmount.avaliableAmount]];
                weakSelf.amount = unspentAmount.avaliableAmount;
            }];
        }];
        [_userBalanceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.payBtn.mas_top).offset(-AUTO_HEIGHT(40));
            make.centerX.equalTo(self.view);
        }];

        [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.UserReciptLabel.mas_bottom);
            make.left.right.equalTo(self.view);
            make.bottom.equalTo(self.userBalanceLabel.mas_top);
        }];
    } else {
        //Has been paid
        [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.UserReciptLabel.mas_bottom);
            make.left.right.equalTo(self.view);
            make.bottom.equalTo(self.view);
        }];
    }

}

/**
 *  pay success refresh
 */
- (void)reloadView {
    int count = (int) (self.crowdfundingInfo.size - self.crowdfundingInfo.remainSize);
    self.UserReciptLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet members paid BTC", nil), count, self.crowdfundingInfo.size, [PayTool getBtcStringWithAmount:count * self.crowdfundingInfo.total / self.crowdfundingInfo.size]];
    self.userBalanceLabel.hidden = YES;
    self.payBtn.hidden = YES;
    [self.dataArray removeAllObjects];
    _dataArray = nil;
    [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.UserReciptLabel.mas_bottom);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
    [self.view layoutIfNeeded];
    [self.tableView reloadData];
}

#pragma mark -- payBtnClick

- (void)payBtnClick:(UIButton *)btn {
    // Whether the balance is sufficient
    long long amount = [[[[NSDecimalNumber alloc] initWithLongLong:self.crowdfundingInfo.total] decimalNumberByDividingBy:[[NSDecimalNumber alloc] initWithLongLong:self.crowdfundingInfo.size]] longValue];
    [self payWithAmount:amount];
}

- (void)payWithAmount:(long long)amount {
    __weak typeof(self) weakSelf = self;
    // Whether the balance is sufficient
    if (amount > self.amount) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Insufficient balance", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
        }];
        return;
    }

    [MBProgressHUD showTransferLoadingViewtoView:self.view];
    [WallteNetWorkTool payWithHashID:self.crowdfundingInfo.hashId amount:amount
                           toAddress:self.crowdfundingInfo.sender.address
                            complete:^(UnspentOrderResponse *unspent, NSArray *toAddresses, NSError *error) {
                                NSDecimalNumber * num = [[NSDecimalNumber alloc] initWithLongLong:amount];
                                [LMPayCheck payCheck:nil withVc:weakSelf withTransferType:TransferTypezChouTransfer unSpent:unspent withArray:toAddresses withMoney:num withNote:nil withType:0 withRedPackage:nil withError:error];
                            }];
}

- (void)checkChangeWithRawTrancationModel:(LMRawTransactionModel *)rawModel
                                   amount:(double)amount {
    // Change to zero
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
                        [weakSelf payMentWithAmount:amount vtsArray:rawModelNew.vtsArray rawTransaction:rawModelNew.rawTrancation];
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
            //pay money
            [weakSelf payMentWithAmount:amount vtsArray:rawModelNew.vtsArray rawTransaction:rawModelNew.rawTrancation];
        }
            break;
        default:
            break;
    }
}

- (void)payMentWithAmount:(long long)amount vtsArray:(NSArray *)vtsArray rawTransaction:(NSString *)rawTransaction {

    __weak __typeof(&*self) weakSelf = self;
    [[PayTool sharedInstance] payVerfifyFingerWithComplete:^(BOOL result, NSString *errorMsg) {
        if (result) {
            [self successAction:amount vtsArray:vtsArray rawTransaction:rawTransaction passView:nil];
        } else {
            if ([errorMsg isEqualToString:@"NO"]) {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"验证失败（fanyi ）", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                }];
            } else {
                [InputPayPassView showInputPayPassWithComplete:^(InputPayPassView *passView, NSError *error, BOOL result) {
                    [weakSelf successAction:amount vtsArray:vtsArray rawTransaction:rawTransaction passView:passView];
                    
                }                              forgetPassBlock:^{
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD hideHUDForView:weakSelf.view];
                        PaySetPage *page = [[PaySetPage alloc] initIsNeedPoptoRoot:YES];
                        [self.navigationController pushViewController:page animated:YES];
                    }];
                }                                   closeBlock:^{
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD hideHUDForView:weakSelf.view];
                    }];
                }];
            }
        }
    }];
}
- (void)successAction:(long long)amount vtsArray:(NSArray *)vtsArray rawTransaction:(NSString *)rawTransaction passView:(InputPayPassView *)passView{
    
    __weak __typeof(&*self) weakSelf = self;
    [MBProgressHUD showTransferLoadingViewtoView:self.view];
    NSString *sign = [KeyHandle signRawTranscationWithTvsArray:vtsArray privkeys:@[[[LKUserCenter shareCenter] currentLoginUser].prikey] rawTranscation:rawTransaction];
    PayCrowdfunding *crowdFunding = [[PayCrowdfunding alloc] init];
    crowdFunding.amount = amount;
    crowdFunding.rawTx = sign;
    crowdFunding.hashId = self.crowdfundingInfo.hashId;
    
    [NetWorkOperationTool POSTWithUrlString:WalltePayCrowdfuningUrl postProtoData:crowdFunding.data complete:^(id response) {
        [MBProgressHUD hideHUDForView:self.view];
        HttpResponse *hResponse = (HttpResponse *) response;
        if (hResponse.code != successCode) {
            
        if (passView.requestCallBack) {
            passView.requestCallBack([NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
        }
            
            return;
        }
       
        if (passView.requestCallBack) {
            passView.requestCallBack(nil);
        }
        
        NSData *data = [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            NSError *error = nil;
            Crowdfunding *crowdInfo = [Crowdfunding parseFromData:data error:&error];
            [[LMMessageExtendManager sharedManager]updateMessageExtendPayCount:(int)(crowdInfo.size - crowdInfo.remainSize)status:(int)crowdInfo.status withHashId:crowdInfo.hashId];
            if (!error) {
                //update packet balance
                [[PayTool sharedInstance] getBlanceWithComplete:^(NSString *blance, UnspentAmount *unspentAmount, NSError *error) {
                    [GCDQueue executeInMainQueue:^{
                        weakSelf.blance = unspentAmount.avaliableAmount;
                        weakSelf.userBalanceLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Balance", nil), [PayTool getBtcStringWithAmount:unspentAmount.avaliableAmount]];
                    }];
                }];
                
                weakSelf.crowdfundingInfo = crowdInfo;
                //refresh list
                [weakSelf reloadView];
                if (weakSelf.PaySuccessCallBack) {
                    weakSelf.PaySuccessCallBack(crowdInfo);
                }
            }
        }
    }                                  fail:^(NSError *error) {
       
        if (passView.requestCallBack) {
            passView.requestCallBack(error);
        }
       
    }];

}

- (void)updateBalanceLabelWithBitInfo:(BitcoinInfo *)info {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.userBalanceLabel setText:[NSString stringWithFormat:LMLocalizedString(@"Wallet Balance", nil), [info.bitcoinAccout floatValue]]];
    });
}

#pragma mark --tableView代理方法

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LMTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[LMTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    LMUserInfo *info = self.dataArray[indexPath.row];
    [cell setUserInfo:info];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    LMUserInfo *info = self.dataArray[indexPath.row];

    NSString *url = [NSString stringWithFormat:@"%@%@", txDetailBaseUrl, info.hashId];
    CommonClausePage *page = [[CommonClausePage alloc] initWithUrl:url];
    [self.navigationController pushViewController:page animated:YES];
}

- (NSMutableArray *)dataArray {
    if (!_dataArray) {
        _dataArray = @[].mutableCopy;
        for (CrowdfundingRecord *record in self.crowdfundingInfo.records.listArray) {
            LMUserInfo *info = [[LMUserInfo alloc] init];
            info.imageUrl = record.user.avatar;
            info.userName = record.user.username;
            info.balance = record.amount;
            info.hashId = record.txid;
            info.txType = 1;
            info.confirmation = record.status == 2;
            info.createdAt = [NSString stringWithFormat:@"%llu", record.createdAt];
            [_dataArray objectAddObject:info];
        }
    }
    return _dataArray;
}


@end
