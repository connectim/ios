//
//  OuterTransferHisPage.m
//  Connect
//
//  Created by MoHuilin on 2016/11/16.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "OuterTransferHisPage.h"
#import "CrowdfoundingHisCell.h"
#import "WallteNetWorkTool.h"
#import "OuterTransferDetailController.h"
#import "UIScrollView+EmptyDataSet.h"
#import "LMHistoryCacheManager.h"


@interface OuterTransferHisPage () <UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property(nonatomic, strong) NSMutableArray *dataArr;
@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, assign) int page;
@property(nonatomic, assign) int pagesize;
@property(nonatomic, strong) NSMutableArray *downPages;

@end

@implementation OuterTransferHisPage

- (void)dealloc {
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.page = 1;
    self.pagesize = 10;

    self.title = LMLocalizedString(@"Chat History", nil);

    NSData *data = [[LMHistoryCacheManager sharedManager] getOutContactsCache];
    ExternalBillingInfos *externalBillInfos = [ExternalBillingInfos parseFromData:data error:nil];
    [self.dataArr addObjectsFromArray:externalBillInfos.externalBillingInfosArray];
    [self timeSort];

    [self.view addSubview:self.tableView];
    __weak __typeof(&*self) weakSelf = self;
    // Set the callback (once into the refresh state, call the target action, that is, call the self loadNewData method)
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [weakSelf getData];
    }];

    // Set the text
    [header setTitle:LMLocalizedString(@"Common Pull down to refresh", nil) forState:MJRefreshStateIdle];
    [header setTitle:LMLocalizedString(@"Common Release to refresh", nil) forState:MJRefreshStatePulling];
    [header setTitle:LMLocalizedString(@"Common Loading", nil) forState:MJRefreshStateRefreshing];

    // Set the font
    header.stateLabel.font = [UIFont systemFontOfSize:15];
    header.lastUpdatedTimeLabel.font = [UIFont systemFontOfSize:14];

    // set color
    header.stateLabel.textColor = LMBasicDarkGray;
    header.lastUpdatedTimeLabel.textColor = LMBasicDarkGray;

    // Immediately enter the refresh state
    [header beginRefreshing];
    self.tableView.mj_header = header;
    self.tableView.mj_header.automaticallyChangeAlpha = YES;
    [self.tableView.mj_header beginRefreshing];
    // Pull-up loads more
    self.tableView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
        weakSelf.page += 1;
        [weakSelf getData];
    }];
}

- (void)getData {
    __weak __typeof(&*self) weakSelf = self;
    if ([self.downPages containsObject:@(self.page)]) {
        [GCDQueue executeInMainQueue:^{
            [weakSelf.tableView.mj_header endRefreshing];
            [weakSelf.tableView.mj_footer endRefreshing];
        }];
        return;
    }
    [WallteNetWorkTool externalTransferHistoryWithPageIndex:self.page size:self.pagesize complete:^(NSError *error, ExternalBillingInfos *externalBillInfos) {
        [self.downPages addObject:@(weakSelf.page)];
        [GCDQueue executeInMainQueue:^{
            if (!error) {
                if (weakSelf.page == 1) {
                    [[LMHistoryCacheManager sharedManager] cacheOutContacts:externalBillInfos.data];
                    [weakSelf.dataArr removeAllObjects];
                }
                [weakSelf.dataArr addObjectsFromArray:externalBillInfos.externalBillingInfosArray];
                [weakSelf timeSort];
                [weakSelf.tableView reloadData];
                [weakSelf.tableView.mj_header endRefreshing];
                if (weakSelf.page > 1) { //no More data
                    if (externalBillInfos.externalBillingInfosArray.count <= 0) {
                        [weakSelf.tableView.mj_footer endRefreshingWithNoMoreData];
                    } else {
                        [weakSelf.tableView.mj_footer endRefreshing];
                    }
                }
            } else {
                [weakSelf.tableView.mj_header endRefreshing];
                [weakSelf.tableView.mj_footer endRefreshing];
            }
        }];
    }];
}

#pragma mark -- TableView proxy method

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArr.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CrowdfoundingHisCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CrowdfoundingHisCellID" forIndexPath:indexPath];
    ExternalBillingInfo *billInfo = [self.dataArr objectAtIndexCheck:indexPath.row];
    cell.data = billInfo;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ExternalBillingInfo *billInfo = [self.dataArr objectAtIndexCheck:indexPath.row];
    OuterTransferDetailController *reciptVc = [[OuterTransferDetailController alloc] init];
    reciptVc.billInfo = billInfo;
    [self.navigationController pushViewController:reciptVc animated:YES];
    return;
}

// Sort the array by time
- (void)timeSort {
    for (NSInteger i = 0; i < self.dataArr.count; i++) {
        for (NSInteger j = 0; j < self.dataArr.count - i - 1; j++) {
            ExternalBillingInfo *billInfo1 = (ExternalBillingInfo *) self.dataArr[j];
            NSTimeInterval second1 = billInfo1.createdAt;
            NSDate *date1 = [NSDate dateWithTimeIntervalSince1970:second1];

            ExternalBillingInfo *billInfo2 = (ExternalBillingInfo *) self.dataArr[j + 1];
            NSTimeInterval second2 = billInfo2.createdAt;
            NSDate *date2 = [NSDate dateWithTimeIntervalSince1970:second2];
            if (date1 == [date1 earlierDate:date2]) {
                ExternalBillingInfo *billInfo = [self.dataArr objectAtIndexCheck:j + 1];
                [self.dataArr exchangeObjectAtIndex:j + 1 withObjectAtIndex:j];
                [self.dataArr replaceObjectAtIndex:j withObject:billInfo];
            }
        }
    }
}

#pragma -mark  DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *title = LMLocalizedString(@"Network No data", nil);
    return [[NSAttributedString alloc] initWithString:title];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *title = LMLocalizedString(@"Wallet don not have any Transactions", nil);
    return [[NSAttributedString alloc] initWithString:title];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
//    return [UIImage imageNamed:@"no_data"];
    return nil;
}

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView {
    return YES;
}


#pragma mark --lazy

- (NSMutableArray *)dataArr {
    if (_dataArr == nil) {
        _dataArr = [NSMutableArray array];
    }
    return _dataArr;
}

- (NSMutableArray *)downPages {
    if (!_downPages) {
        _downPages = [NSMutableArray array];
    }
    return _downPages;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        [_tableView registerNib:[UINib nibWithNibName:@"CrowdfoundingHisCell" bundle:nil] forCellReuseIdentifier:@"CrowdfoundingHisCellID"];
        _tableView.rowHeight = AUTO_HEIGHT(140);
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.emptyDataSetSource = self;
        _tableView.emptyDataSetDelegate = self;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = NO;
    }

    return _tableView;
}
@end
