//
//  MainWalletPage.m
//  Connect
//
//  Created by MoHuilin on 16/8/24.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "MainWalletPage.h"
#import "LMCustomBtn.h"
#import "LMTranHisViewController.h"
#import "LMTransferViewController.h"
#import "LMReceiptViewController.h"
#import "LMChatRedLuckyViewController.h"
#import "WalletItemCell.h"
#import "ScanAddPage.h"
#import "LMHandleScanResultManager.h"

#define isPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

@interface WalletItem : NSObject

@property(nonatomic, copy) NSString *icon;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, assign) int type;

@end

@implementation WalletItem

@end

@interface MainWalletPage () <UICollectionViewDelegate, UICollectionViewDataSource>

@property(nonatomic, strong) LMCustomBtn *qrcodeBtn;
@property(nonatomic, strong) LMCustomBtn *transferBtn;
@property(nonatomic, strong) LMCustomBtn *historyBtn;
@property(nonatomic, strong) UIButton *walletBlanceButton;

@property(nonatomic, strong) AccountInfo *loginUser;

@property(nonatomic, strong) UICollectionView *collectionView;
@property(nonatomic, strong) UIView *headerView;
@property(nonatomic, assign) CGFloat headerHeight;

@property(nonatomic, strong) NSMutableArray *walletItems;
@property(nonatomic, copy) NSString *resultContent;
@property(nonatomic, strong) NSDecimalNumber *money;

@end

@implementation MainWalletPage

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupSubView];
    self.navigationItem.leftBarButtonItems = nil;
    [self addRightBarButtonItem];
    [self addLeftBarButtonItem];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self queryBlance];
}

- (void)currencyChange {
    [super currencyChange];
    __weak __typeof(&*self) weakSelf = self;
    [[PayTool sharedInstance] getRateComplete:^(NSDecimalNumber *rate, NSError *error) {
        if (error) {

        } else {
            [GCDQueue executeInMainQueue:^{
                [weakSelf.walletBlanceButton setTitle:[NSString stringWithFormat:@"%@ %.2f", weakSelf.symbol, rate.doubleValue * [[MMAppSetting sharedSetting] getBalance] * pow(10, -8)] forState:UIControlStateSelected];
            }];
        }
    }];
}

#pragma mark -- add button

- (void)addRightBarButtonItem {
    UIButton *rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    rightBtn.frame = CGRectMake(0, 0, AUTO_WIDTH(49), AUTO_HEIGHT(42));
    [rightBtn setImage:[UIImage imageNamed:@"camera"] forState:UIControlStateNormal];
    [rightBtn addTarget:self action:@selector(rightBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:rightBtn];
    self.navigationItem.rightBarButtonItem = rightItem;
}

- (void)addLeftBarButtonItem {
    UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    leftBtn.frame = CGRectMake(0, 0, AUTO_WIDTH(49), AUTO_HEIGHT(42));
    [leftBtn setImage:[UIImage imageNamed:@"wallet_transactioons_icon_left"] forState:UIControlStateNormal];
    [leftBtn addTarget:self action:@selector(leftButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithCustomView:leftBtn];
    self.navigationItem.leftBarButtonItem = leftItem;

}

#pragma mark --rightBtnClick

- (void)rightBtnClick:(UIButton *)btn {
    __weak __typeof(&*self) weakSelf = self;
    ScanAddPage *scanPage = [[ScanAddPage alloc] initWithScanComplete:^(NSString *result) {
        __strong __typeof(&*weakSelf) strongSelf = weakSelf;
        [[LMHandleScanResultManager sharedManager] handleScanResult:result controller:strongSelf];
    }];
    [self presentViewController:scanPage animated:NO completion:nil];
}

- (void)leftButtonClick:(UIButton *)leftButton {
    LMTranHisViewController *HistoryVc = [[LMTranHisViewController alloc] init];
    HistoryVc.address = self.loginUser.address;
    HistoryVc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:HistoryVc animated:YES];
}

- (AccountInfo *)loginUser {
    if (!_loginUser) {
        _loginUser = [[LKUserCenter shareCenter] currentLoginUser];
    }

    return _loginUser;
}


- (void)setupSubView {

    self.view.backgroundColor = GJCFQuickHexColor(@"F1F1F1");
    UIImageView *logImageView = [[UIImageView alloc] init];
    logImageView.image = [UIImage imageNamed:@"wallet_bitcoin_icon"];
    [self.headerView addSubview:logImageView];
    [logImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.headerView);
        make.size.mas_equalTo(CGSizeMake(AUTO_WIDTH(200), AUTO_HEIGHT(200)));
        make.top.equalTo(self.headerView).offset(AUTO_HEIGHT(60));
    }];

    UILabel *tipLabel = [[UILabel alloc] init];
    [self.headerView addSubview:tipLabel];
    [tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(logImageView.mas_bottom).offset(AUTO_HEIGHT(90));
        make.centerX.equalTo(self.headerView);
    }];
    tipLabel.text = LMLocalizedString(@"Wallet My Balance", nil);
    tipLabel.font = [UIFont systemFontOfSize:FONT_SIZE(32)];
    tipLabel.textColor = GJCFQuickHexColor(@"161A21");
    [tipLabel sizeToFit];
    tipLabel.center = self.view.center;
    tipLabel.textAlignment = NSTextAlignmentCenter;

    self.walletBlanceButton = [[UIButton alloc] init];
    [self.walletBlanceButton addTarget:self action:@selector(changeRage) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:self.walletBlanceButton];
    self.walletBlanceButton.titleLabel.font = [UIFont boldSystemFontOfSize:FONT_SIZE(48)];
    [self.walletBlanceButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(tipLabel.mas_bottom).offset(AUTO_HEIGHT(25));
        make.centerX.equalTo(self.headerView);
    }];
    [self.walletBlanceButton setTitleColor:GJCFQuickHexColor(@"38425F") forState:UIControlStateNormal];
    [self.walletBlanceButton setTitle:[NSString stringWithFormat:@"฿ %@", [PayTool getBtcStringWithAmount:[[MMAppSetting sharedSetting] getBalance]]] forState:UIControlStateNormal];
    [self.walletBlanceButton setTitle:[NSString stringWithFormat:@"%@ %.2f", self.symbol, [[MMAppSetting sharedSetting] getBalance] * pow(10, -8) * [[MMAppSetting sharedSetting] getRate]] forState:UIControlStateSelected];

    [self.headerView layoutIfNeeded];
    self.headerHeight = self.walletBlanceButton.bottom;
    self.headerView.height = self.headerHeight;

    NSMutableArray *icons = @[@"wallet_request", @"wallet_transfer_icon", @"wallet_packet_icon"].mutableCopy;
    NSMutableArray *titles = @[LMLocalizedString(@"Wallet Receipt", nil), LMLocalizedString(@"Wallet Transfer", nil), LMLocalizedString(@"Wallet Packet", nil)].mutableCopy;
    self.walletItems = [NSMutableArray array];
    for (int i = 0; i < icons.count; i++) {
        WalletItem *item = [[WalletItem alloc] init];
        item.icon = [icons objectAtIndexCheck:i];;
        item.title = [titles objectAtIndexCheck:i];
        item.type = i;
        [self.walletItems objectAddObject:item];
    }
    [self.view addSubview:self.collectionView];
}

- (void)itemClick:(int)type {
    switch (type) {
        case 0: {
            LMReceiptViewController *bigReVc = [[LMReceiptViewController alloc] init];
            bigReVc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:bigReVc animated:YES];
            LMLocalizedString(@"Wallet Transfer", nil);
        }
            break;
        case 1: {
            LMTransferViewController *transVc = [[LMTransferViewController alloc] init];
            transVc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:transVc animated:YES];
        }
            break;
        case 2: {
            LMChatRedLuckyViewController *HistoryVc = [[LMChatRedLuckyViewController alloc] init];
            HistoryVc.style = LMChatRedLuckyStyleOutRedBag;
            HistoryVc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:HistoryVc animated:YES];
        }
            break;
    }
}


- (void)changeRage {
    self.walletBlanceButton.selected = !self.walletBlanceButton.selected;
}

- (void)queryBlance {
    __weak __typeof(&*self) weakSelf = self;
    [[PayTool sharedInstance] getBlanceWithComplete:^(NSString *blance, UnspentAmount *unspentAmount, NSError *error) {
        [weakSelf.walletBlanceButton setTitle:[NSString stringWithFormat:@"฿ %@", [PayTool getBtcStringWithAmount:unspentAmount.amount]] forState:UIControlStateNormal];
    }];

    [[PayTool sharedInstance] getRateComplete:^(NSDecimalNumber *rate, NSError *error) {
        if (!error) {
            [weakSelf.walletBlanceButton setTitle:[NSString stringWithFormat:@"%@ %.2f", weakSelf.symbol, rate.doubleValue * [[MMAppSetting sharedSetting] getBalance] * pow(10, -8)] forState:UIControlStateSelected];
        }
    }];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.walletItems.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WalletItemCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"WalletItemCellID" forIndexPath:indexPath];
    WalletItem *item = [self.walletItems objectAtIndexCheck:indexPath.row];
    cell.iconImageView.image = [UIImage imageNamed:item.icon];
    cell.titleLabel.text = item.title;
    return cell;
}

/**
 *  This method is to return the size of the header size
 */
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (GJCFSystemiPhone5) {
        return CGSizeMake(DEVICE_SIZE.width, self.headerHeight + AUTO_HEIGHT(30));
    } else {
        return CGSizeMake(DEVICE_SIZE.width, self.headerHeight + AUTO_HEIGHT(120));
    }
}

/**
 *  This is also the most important way to get the Header method
 */
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *cell = (UICollectionReusableView *) [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"UICollectionReusableViewID" forIndexPath:indexPath];
    [cell addSubview:self.headerView];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    WalletItem *item = [self.walletItems objectAtIndexCheck:indexPath.row];
    [self itemClick:item.type];
}

- (void)dealloc {
    RemoveNofify;
}


- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        CGFloat w = DEVICE_SIZE.width / 3;
        if (GJCFSystemiPhone5 || GJCFSystemiPhone6 || ([UIScreen mainScreen].bounds.size.width >= 390 && [UIScreen mainScreen].bounds.size.width <= 444)) {
            layout.itemSize = CGSizeMake(w, AUTO_HEIGHT(165));
        } else {
            layout.itemSize = CGSizeMake(w, 80);
        }
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;
        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = [UIColor clearColor];
        [_collectionView registerNib:[UINib nibWithNibName:@"WalletItemCell" bundle:nil] forCellWithReuseIdentifier:@"WalletItemCellID"];
        [_collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"UICollectionReusableViewID"];
        _collectionView.contentInset = UIEdgeInsetsMake(64, 0, 49, 0);
    }
    return _collectionView;
}

- (UIView *)headerView {
    if (!_headerView) {
        _headerView = [[UIView alloc] init];
        _headerView.frame = CGRectMake(0, 0, DEVICE_SIZE.width, self.headerHeight);
    }


    return _headerView;
}

#pragma mark -

@end
