//
//  OuterPacketHisPage.m
//  Connect
//
//  Created by MoHuilin on 2016/11/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "OuterPacketHisPage.h"
#import "WallteNetWorkTool.h"
#import "RedPacketHistoryCell.h"
#import "LMChatRedLuckyDetailController.h"
#import "UIScrollView+EmptyDataSet.h"
#import "LMHistoryCacheManager.h"

@interface OuterPacketHisPage () <UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property(nonatomic, strong) NSMutableArray *dataArr;
@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, assign) int page;
@property(nonatomic, assign) int pagesize;
@property(nonatomic, strong) NSMutableArray *downPages;


@end

@implementation OuterPacketHisPage

- (void)dealloc {
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"luckbag_backgroud"] forBarMetrics:UIBarMetricsDefault];

    [super viewWillAppear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.page = 1;
    self.pagesize = 10;

    self.title = LMLocalizedString(@"Chat History", nil);

    NSData *data = [[LMHistoryCacheManager sharedManager] getRedbagContactsCache];
    RedPackageInfos *redPackages = [RedPackageInfos parseFromData:data error:nil];
    [self.dataArr addObjectsFromArray:redPackages.redPackageInfosArray];

    [self.view addSubview:self.tableView];
    __weak __typeof(&*self) weakSelf = self;
    // get traansfer recodes
    // Set the callback (once into the refresh state, call the target action, that is, call the self loadNewData method)
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [weakSelf getData];
    }];

    // set title
    [header setTitle:LMLocalizedString(@"Common Pull down to refresh", nil) forState:MJRefreshStateIdle];
    [header setTitle:LMLocalizedString(@"Common Release to refresh", nil) forState:MJRefreshStatePulling];
    [header setTitle:LMLocalizedString(@"Common Loading", nil) forState:MJRefreshStateRefreshing];

    // set text
    header.stateLabel.font = [UIFont systemFontOfSize:15];
    header.lastUpdatedTimeLabel.font = [UIFont systemFontOfSize:14];

    // set color
    header.stateLabel.textColor = [UIColor grayColor];
    header.lastUpdatedTimeLabel.textColor = [UIColor grayColor];

    // Immediately enter the refresh state
    [header beginRefreshing];
    self.tableView.mj_header = header;
    self.tableView.mj_header.automaticallyChangeAlpha = YES;
    [self.tableView.mj_header beginRefreshing];
    // Pull-up loads more
    self.tableView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
        // Get the address transaction record
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
    [WallteNetWorkTool externalRedPacketHistoryWithPageIndex:self.page size:self.pagesize complete:^(NSError *error, RedPackageInfos *redPackages) {
        [GCDQueue executeInMainQueue:^{
            if (!error) {
                if (weakSelf.page == 1) {
                    [[LMHistoryCacheManager sharedManager] cacheRedbagContacts:redPackages.data];
                    [weakSelf.dataArr removeAllObjects];
                }
                [weakSelf.dataArr addObjectsFromArray:redPackages.redPackageInfosArray];
                [weakSelf.tableView reloadData];
                [weakSelf.tableView.mj_header endRefreshing];
                if (weakSelf.page > 1) { //no More data
                    if (redPackages.redPackageInfosArray.count <= 0) {
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

#pragma mark --TableView proxy method

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArr.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    RedPacketHistoryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RedPacketHistoryCellID" forIndexPath:indexPath];
    RedPackageInfo *redPackgeInfo = [self.dataArr objectAtIndexCheck:indexPath.row];
    cell.data = redPackgeInfo.redpackage;
    return cell;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    RedPackageInfo *redPackgeInfo = [self.dataArr objectAtIndexCheck:indexPath.row];
    LMChatRedLuckyDetailController *page = [[LMChatRedLuckyDetailController alloc] initWithUserInfo:[[LKUserCenter shareCenter] currentLoginUser] redLuckyInfo:redPackgeInfo isFromHistory:YES];
    [self.navigationController pushViewController:page animated:YES];

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
        [_tableView registerNib:[UINib nibWithNibName:@"RedPacketHistoryCell" bundle:nil] forCellReuseIdentifier:@"RedPacketHistoryCellID"];
        _tableView.rowHeight = AUTO_HEIGHT(140);
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.emptyDataSetSource = self;
        _tableView.emptyDataSetDelegate = self;
        _tableView.tableFooterView = [[UIView alloc] init];
    }

    return _tableView;
}


@end
