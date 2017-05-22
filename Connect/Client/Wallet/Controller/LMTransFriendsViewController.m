//
//  LMTransFriendsViewController.m
//  Connect
//
//  Created by Edwin on 16/7/20.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMTransFriendsViewController.h"
#import "LMTranFriendLsitViewController.h"
#import "LMTransFriendsListCell.h"
#import "WallteNetWorkTool.h"
#import "TransferInputView.h"
#import "LMPayCheck.h"

static NSString *const identifier = @"cellIdentifier";

@interface LMTransFriendsViewController () <UICollectionViewDelegate, UICollectionViewDataSource>


@property(nonatomic, strong) UIView *sectionTitleView;
@property(nonatomic, strong) UIView *topContentView;
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UIImageView *transIcon;
@property(nonatomic, strong) UICollectionView *friendsListCollection;
@property(nonatomic, strong) NSMutableArray *btnArr;
@property(nonatomic, strong) UIImageView *cellMoreImageView;
@property(nonatomic, strong) UIButton *rmbBtn;
@property(nonatomic, strong) UILabel *BalanceLabel;
@property(nonatomic, strong) NSMutableDictionary *addressDic;
@property(nonatomic, strong) TransferInputView *inputAmountView;

@end

@implementation LMTransFriendsViewController

- (NSMutableDictionary *)addressDic {
    if (!_addressDic) {
        _addressDic = [NSMutableDictionary dictionary];
    }
    return _addressDic;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LMLocalizedString(@"Wallet Transfer", nil);
    [self addTopBtns];
    [self initTopView];
    [self initTabelViewCell];
}


- (void)initTopView {

    __weak __typeof(&*self) weakSelf = self;
    TransferInputView *view = [[TransferInputView alloc] init];
    self.inputAmountView = view;
    [self.view addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topContentView.mas_bottom).offset(AUTO_HEIGHT(20));
        make.width.equalTo(self.view);
        make.height.mas_equalTo(AUTO_HEIGHT(334));
        make.left.equalTo(self.view);
    }];
    view.topTipString = LMLocalizedString(@"Wallet Amount Each", nil);
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


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.inputAmountView hidenKeyBoard];
}


- (void)addTopBtns {
    self.sectionTitleView = [[UIView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, AUTO_HEIGHT(40))];
    self.sectionTitleView.backgroundColor = [UIColor colorWithHexString:@"F1F1F1"];
    [self.view addSubview:self.sectionTitleView];
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(AUTO_WIDTH(30), 0, AUTO_WIDTH(300), AUTO_HEIGHT(40))];
    self.titleLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Transfer Count", nil), (int) self.selectArr.count];
    self.titleLabel.textColor = [UIColor blackColor];
    self.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(22)];
    self.titleLabel.textAlignment = NSTextAlignmentLeft;
    [self.sectionTitleView addSubview:self.titleLabel];

    self.topContentView = [[UIView alloc] initWithFrame:CGRectMake(0.f, self.sectionTitleView.bottom, VIEW_WIDTH, AUTO_HEIGHT(148))];
    [self.topContentView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.topContentView];

    UIButton *more = [UIButton buttonWithType:UIButtonTypeCustom];
    [more setImage:[UIImage imageNamed:@"set_grey_right_arrow"] forState:UIControlStateNormal];
    [more addTarget:self action:@selector(goFriendsTransferListController) forControlEvents:UIControlEventTouchUpInside];
    [self.topContentView addSubview:more];
    [more mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.topContentView.mas_centerY);
        make.right.equalTo(self.topContentView);
        make.size.mas_offset(CGSizeMake(AUTO_WIDTH(100), AUTO_HEIGHT(148)));
    }];

    UICollectionViewFlowLayout *flow = [[UICollectionViewFlowLayout alloc] init];
    [flow setItemSize:CGSizeMake(AUTO_WIDTH(100), AUTO_WIDTH(148))];
    [flow setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    [flow setHeaderReferenceSize:CGSizeMake(AUTO_WIDTH(38), AUTO_HEIGHT(100))];
    flow.minimumInteritemSpacing = AUTO_WIDTH(77);
    _friendsListCollection = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH - AUTO_WIDTH(100), AUTO_HEIGHT(148)) collectionViewLayout:flow];
    [_friendsListCollection setDelegate:self];
    [_friendsListCollection setDataSource:self];
    [_friendsListCollection setBackgroundColor:[UIColor whiteColor]];
    [_friendsListCollection setShowsHorizontalScrollIndicator:NO];
    [_friendsListCollection registerNib:[UINib nibWithNibName:@"LMTransFriendsListCell" bundle:nil] forCellWithReuseIdentifier:identifier];
    [self.topContentView addSubview:_friendsListCollection];

}

#pragma mark - collection view delegate && datasource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.selectArr count] + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    LMTransFriendsListCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {

    LMTransFriendsListCell *lCell = (LMTransFriendsListCell *) cell;
    if (indexPath.row == self.selectArr.count) {
        // add button
        lCell.avatarIcon.image = [UIImage imageNamed:@"message_add_friends"];
        lCell.nameLabel.text = nil;
    } else {
        AccountInfo *info = [self.selectArr objectAtIndexCheck:indexPath.row];
        [lCell.nameLabel setText:info.username];
        [lCell.avatarIcon setPlaceholderImageWithAvatarUrl:info.avatar];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.selectArr.count) {
        [self goChooseFriends];
    }
}

- (void)goFriendsTransferListController {
    __weak typeof(self) weakSelf = self;
    LMTranFriendLsitViewController *friendsList = [[LMTranFriendLsitViewController alloc] init];
    friendsList.dataArr = self.selectArr;
    friendsList.title = LMLocalizedString(@"Wallet Select friends", nil);
    friendsList.friendsHandler = ^(NSMutableArray *friends) {
        if (self.selectArr.count <= 0) {
            self.comfrimButton.enabled = NO;
        }
        self.titleLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Transfer Count", nil), (int) self.selectArr.count];
        [self.friendsListCollection reloadData];
        if (weakSelf.changeListBlock) {
            weakSelf.changeListBlock();
        }
    };
    [self.navigationController pushViewController:friendsList animated:YES];
}

#pragma mark --

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
        weakSelf.BalanceLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Balance", nil), [PayTool getBtcStringWithAmount:weakSelf.blance]];
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

- (void)goChooseFriends {
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)tapConfrim {
    [self.inputAmountView executeBlock];
}

- (void)createTranscationWithMoney:(NSDecimalNumber *)money note:(NSString *)note {
    __weak __typeof(&*self) weakSelf = self;
    // Whether the balance is sufficient
    if (([PayTool getPOW8Amount:money] * self.selectArr.count + [[MMAppSetting sharedSetting] getTranferFee]) > self.blance) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Insufficient balance", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
        }];
        return;
    }

    [GCDQueue executeInMainQueue:^{
        [MBProgressHUD showTransferLoadingViewtoView:self.view];
        [self.view endEditing:YES];
    }];

    // dictory array
    NSMutableArray *addresses = [NSMutableArray array];
    for (AccountInfo *info in self.selectArr) {
        [addresses objectAddObject:info.address];
    }

    [WallteNetWorkTool MuiltTransferWithAddress:[[LKUserCenter shareCenter] currentLoginUser].address privkey:[[LKUserCenter shareCenter] currentLoginUser].prikey fee:[[MMAppSetting sharedSetting] getTranferFee] toAddress:addresses amount:[PayTool getPOW8Amount:money] tips:note complete:^(UnspentOrderResponse *unspent, NSArray *toAddresses, NSError *error) {
        [LMPayCheck payCheck:nil withVc:weakSelf withTransferType:TransferTypeTransFriend unSpent:unspent withArray:toAddresses withMoney:money withNote:note withType:0 withRedPackage:nil withError:error];

    }];
}


- (void)checkChangeWithRawTrancationModel:(LMRawTransactionModel *)rawModel
                                     note:(NSString *)note
                                    money:(NSDecimalNumber *)money {
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
                    case 2: // click sure
                    {
                        LMRawTransactionModel *rawModelNew = [LMUnspentCheckTool createRawTransactionWithRawTrancation:rawModel addDustToFee:YES];
                        // pay money
                        [weakSelf createTransferWithToAddresses:rawModel.toAddresses money:money note:note rawModel:rawModelNew];
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
            [weakSelf createTransferWithToAddresses:rawModel.toAddresses money:money note:note rawModel:rawModelNew];
        }
            break;
        default:
            break;
    }
}

- (void)createTransferWithToAddresses:(NSArray *)toAddresses
                                money:(NSDecimalNumber *)money
                                 note:(NSString *)note
                             rawModel:(LMRawTransactionModel *)rawModel {
    __weak __typeof(&*self) weakSelf = self;
    [[PayTool sharedInstance] payVerfifyFingerWithComplete:^(BOOL result, NSString *errorMsg) {
        if (result) {
    
            [self successAction:toAddresses money:money note:note rawModel:rawModel passView:nil];

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
                    [weakSelf successAction:toAddresses money:money note:note rawModel:rawModel passView:passView];
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
- (void)successAction:(NSArray *)toAddresses money:(NSDecimalNumber *)money note:(NSString *)note rawModel:(LMRawTransactionModel *)rawModel passView:(InputPayPassView *)passView{
    
     __weak __typeof(&*self) weakSelf = self;
    MuiltSendBill *muiltBill = [MuiltSendBill new];
    NSMutableArray *addressesArray = [NSMutableArray array];
    for (NSDictionary *addressAmount in toAddresses) {
        [addressesArray objectAddObject:[addressAmount valueForKey:@"address"]];
    }
    muiltBill.addressesArray = addressesArray;
    muiltBill.amount = [[[NSDecimalNumber alloc] initWithLongLong:pow(10, 8)]
                        decimalNumberByMultiplyingBy:money].longLongValue;
    muiltBill.tips = note;
    NSString *signTransaction = [KeyHandle signRawTranscationWithTvsArray:rawModel.vtsArray privkeys:@[[[LKUserCenter shareCenter] currentLoginUser].prikey] rawTranscation:rawModel.rawTrancation];
    muiltBill.txData = signTransaction;
    
    [WallteNetWorkTool doMuiltTransfer:muiltBill complete:^(NSData *response, NSError *error) {
        if (error) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Transfer failed", nil) withType:ToastTypeFail showInView:self.view complete:nil];
            }];
            
            if (passView.requestCallBack) {
                passView.requestCallBack(error);
            }
            
        } else {
            // update blance
            [[PayTool sharedInstance] getBlanceWithComplete:^(NSString *blance, UnspentAmount *unspentAmount, NSError *error) {
                [GCDQueue executeInMainQueue:^{
                    weakSelf.blance = unspentAmount.avaliableAmount;
                    weakSelf.BalanceLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Balance", nil), [PayTool getBtcStringWithAmount:unspentAmount.avaliableAmount]];
                }];
            }];
            
            if (passView.requestCallBack) {
                passView.requestCallBack(nil);
            }
            
            NSError *errors;
            MuiltSendBillResp *muiltBill = [[MuiltSendBillResp alloc] initWithData:response error:&errors];
            for (Bill *bill in muiltBill.billsArray) {
                // send message
                [weakSelf createChatWithHashId:bill.hash_p address:bill.receiver Amount:[NSString stringWithFormat:@"%@", [PayTool getBtcStringWithAmount:bill.amount]]];
            }
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Transfer Successful", nil) withType:ToastTypeSuccess showInView:weakSelf.view complete:^{
                    [weakSelf.navigationController popToRootViewControllerAnimated:YES];
                }];
            }];
        }
    }];
}
@end
