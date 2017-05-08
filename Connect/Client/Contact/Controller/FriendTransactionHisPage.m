//
//  FriendTransactionHisPage.m
//  Connect
//
//  Created by MoHuilin on 16/9/19.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "FriendTransactionHisPage.h"
#import "NetWorkOperationTool.h"
#import "LMTableViewCell.h"
#import "CommonClausePage.h"
#import "UIScrollView+EmptyDataSet.h"
#import "LMHistoryCacheManager.h"


@interface FriendTransactionHisPage () <UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource>

@property(nonatomic, strong) UITableView *tableView;
//records
@property(nonatomic, strong) NSMutableArray *records;
//friend
@property(nonatomic, strong) AccountInfo *contact;
@property(nonatomic, assign) int pageIndex;
@property(nonatomic, assign) int pageSize;
//request page count
@property(nonatomic, strong) NSMutableArray *downPages;

@end

@implementation FriendTransactionHisPage

- (instancetype)initWithFriend:(AccountInfo *)contact {
    if (self = [super init]) {
        self.contact = contact;
    }
    return self;

}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = LMLocalizedString(@"Link Tansfer Record", nil);

    [self.view addSubview:self.tableView];
    NSData *data = [[LMHistoryCacheManager sharedManager] getPersonTransferContactsCache];
    FriendBillsMessage *bills = [FriendBillsMessage parseFromData:data error:nil];

    for (FriendBill *bill in bills.friendBillsArray) {
        LMUserInfo *info = [[LMUserInfo alloc] init];
        info.createdAt = [NSString stringWithFormat:@"%llu", bill.createdAt];
        info.category = bill.category;
        info.userName = self.contact.username;
        info.imageUrl = self.contact.avatar;
        info.txType = 1;
        if ([bill.category isEqualToString:@"sender"]) {
            info.balance = -bill.amount;
        } else {
            info.balance = bill.amount;
        }
        info.hashId = bill.txId;
        info.confirmation = bill.status;
        [self.records objectAddObject:info];
    }
    [self.tableView reloadData];


    //from network
    self.pageIndex = 1;
    self.pageSize = 10;

    __weak __typeof(&*self) weakSelf = self;
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [weakSelf getRecords];
    }];

    // set lable
    [header setTitle:LMLocalizedString(@"Common Pull down to refresh", nil) forState:MJRefreshStateIdle];
    [header setTitle:LMLocalizedString(@"Common Release to refresh", nil) forState:MJRefreshStatePulling];
    [header setTitle:LMLocalizedString(@"Common Loading", nil) forState:MJRefreshStateRefreshing];

    // set font
    header.stateLabel.font = [UIFont systemFontOfSize:15];
    header.lastUpdatedTimeLabel.font = [UIFont systemFontOfSize:14];

    // set color
    header.stateLabel.textColor = [UIColor grayColor];
    header.lastUpdatedTimeLabel.textColor = [UIColor grayColor];
    self.tableView.mj_header = header;
    self.tableView.mj_header.automaticallyChangeAlpha = YES;
    [self.tableView.mj_header beginRefreshing];
    // Pull-up loads more
    self.tableView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
        weakSelf.pageIndex += 1;
        [weakSelf getRecords];
    }];
}

- (void)getRecords {
    __weak __typeof(&*self) weakSelf = self;
    if ([self.downPages containsObject:@(self.pageIndex)]) {
        [GCDQueue executeInMainQueue:^{
            [self.tableView.mj_header endRefreshing];
            [self.tableView.mj_footer endRefreshing];
            [self.tableView reloadData];
        }];
        return;
    }
    //download data
    FriendRecords *record = [[FriendRecords alloc] init];
    record.selfAddress = [[LKUserCenter shareCenter] currentLoginUser].address;
    record.friendAddress = self.contact.address;
    record.pageSize = self.pageSize;
    record.pageIndex = self.pageIndex;
    [NetWorkOperationTool POSTWithUrlString:WallteFriendRecordsUrl postProtoData:record.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *) response;
        if (hResponse.code != successCode) {
            return;
        }
        [weakSelf.downPages objectAddObject:@(weakSelf.pageIndex)];
        NSData *data = [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            NSError *error = nil;
            FriendBillsMessage *bills = [FriendBillsMessage parseFromData:data error:&error];
            if (weakSelf.pageIndex == 1) {
                [[LMHistoryCacheManager sharedManager] cachePersonTransferContacts:bills.data];
                [weakSelf.records removeAllObjects];
            }


            if (error) {
                [GCDQueue executeInMainQueue:^{
                    [weakSelf.tableView.mj_header endRefreshing];
                    [weakSelf.tableView.mj_footer endRefreshing];
                    [weakSelf.tableView reloadData];
                }];
            } else {
                for (FriendBill *bill in bills.friendBillsArray) {
                    LMUserInfo *info = [[LMUserInfo alloc] init];
                    info.createdAt = [NSString stringWithFormat:@"%llu", bill.createdAt];
                    info.category = bill.category;
                    info.userName = weakSelf.contact.username;
                    info.imageUrl = weakSelf.contact.avatar;
                    info.txType = 1;
                    if ([bill.category isEqualToString:@"sender"]) {
                        info.balance = -bill.amount;
                    } else {
                        info.balance = bill.amount;
                    }
                    info.hashId = bill.txId;
                    info.confirmation = bill.status;
                    [weakSelf.records objectAddObject:info];
                }
                if (weakSelf.records.count) {
                    [GCDQueue executeInMainQueue:^{
                        [weakSelf.tableView reloadData];
                        [weakSelf.tableView.mj_header endRefreshing];
                        if (weakSelf.pageIndex > 1) { //no More data
                            if (bills.friendBillsArray.count <= 0) {
                                [weakSelf.tableView.mj_footer endRefreshingWithNoMoreData];
                            } else {
                                [weakSelf.tableView.mj_footer endRefreshing];
                            }
                        }
                    }];
                } else {
                    [GCDQueue executeInMainQueue:^{
                        [weakSelf.tableView.mj_header endRefreshing];
                        [weakSelf.tableView.mj_footer endRefreshing];
                    }];
                }
            }
        }
    }                                  fail:^(NSError *error) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:[LMErrorCodeTool showToastErrorType:ToastErrorTypeContact withErrorCode:error.code withUrl:WallteFriendRecordsUrl] withType:ToastTypeFail showInView:weakSelf.view complete:^{
                [weakSelf.tableView reloadData];
            }];
            [weakSelf.tableView.mj_header endRefreshing];
            [weakSelf.tableView.mj_footer endRefreshing];
        }];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.records.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LMTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LMTableViewCellID" forIndexPath:indexPath];

    LMUserInfo *userInfo = self.records[indexPath.row];
    [cell setUserInfo:userInfo];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    LMUserInfo *info = self.records[indexPath.row];

    NSString *url = [NSString stringWithFormat:@"%@%@", txDetailBaseUrl, info.hashId];
    CommonClausePage *page = [[CommonClausePage alloc] initWithUrl:url];
    [self.navigationController pushViewController:page animated:YES];
}


- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *title = LMLocalizedString(@"Wallet You do not have any Transactions", nil);
    return [[NSAttributedString alloc] initWithString:title];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    return nil;
}

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView {
    return YES;
}


- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        [_tableView registerNib:[UINib nibWithNibName:@"LMTableViewCell" bundle:nil] forCellReuseIdentifier:@"LMTableViewCellID"];
        _tableView.rowHeight = AUTO_HEIGHT(132);
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.emptyDataSetDelegate = self;
        _tableView.emptyDataSetSource = self;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = NO;
    }

    return _tableView;
}

- (NSMutableArray *)records {
    if (!_records) {
        _records = [NSMutableArray array];
    }
    return _records;
}

- (NSMutableArray *)downPages {
    if (!_downPages) {
        _downPages = [NSMutableArray array];
    }
    return _downPages;
}


@end
