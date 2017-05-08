//
//  CrowdfoundingHisPage.m
//  Connect
//
//  Created by MoHuilin on 2016/11/1.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "CrowdfoundingHisPage.h"
#import "NetWorkOperationTool.h"
#import "CrowdfoundingHisCell.h"
#import "GroupDBManager.h"
#import "WallteNetWorkTool.h"
#import "LMGroupZChouReciptViewController.h"
#import "LMHistoryCacheManager.h"

@interface CrowdfoundingHisPage () <UITableViewDelegate, UITableViewDataSource>
// type of data
@property(nonatomic, strong) NSMutableArray *dataArr;
@property(nonatomic, strong) UITableView *tableView;
// page
@property(nonatomic, assign) NSInteger page;
// page size
@property(nonatomic, assign) NSInteger pagesize;
// downPages
@property(nonatomic, strong) NSMutableArray *downPages;

@end

@implementation CrowdfoundingHisPage

- (void)dealloc {
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.page = 1;
    self.pagesize = 10;
    [self.view addSubview:self.tableView];
    __weak __typeof(&*self) weakSelf = self;
    // from ssdb get result
    NSData *data = [[LMHistoryCacheManager sharedManager] getPublicFinaincContactsCache];
    if (data) {
        Crowdfundings *crowdRecords = [Crowdfundings parseFromData:data error:nil];
        if (self.dataArr.count > 0) {
            [self.dataArr removeAllObjects];
        }
        [weakSelf.dataArr addObjectsFromArray:crowdRecords.listArray];
        [GCDQueue executeInMainQueue:^{
            [weakSelf.tableView reloadData];
        }];
    }
    // callback
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [weakSelf getDataWithUrl:WallteCrowdfuningUserRecordsUrl];
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

    // begin refresh status
    [header beginRefreshing];
    self.tableView.mj_header = header;
    self.tableView.mj_header.automaticallyChangeAlpha = YES;
    [self.tableView.mj_header beginRefreshing];
    // pull up load more
    self.tableView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
        // get address traction record
        weakSelf.page += 1;
        [weakSelf getDataWithUrl:WallteCrowdfuningUserRecordsUrl];
    }];
}

- (void)getDataWithUrl:(NSString *)recodsUrl {
    __weak __typeof(&*self) weakSelf = self;
    if ([self.downPages containsObject:@(self.page)]) {
        [GCDQueue executeInMainQueue:^{
            [weakSelf.tableView.mj_header endRefreshing];
            [weakSelf.tableView.mj_footer endRefreshing];
        }];
        return;
    }
    UserCrowdfundingInfo *crowd = [[UserCrowdfundingInfo alloc] init];
    crowd.pageSize = (int32_t) self.pagesize;
    crowd.pageIndex = (int32_t) self.page;
    [NetWorkOperationTool POSTWithUrlString:recodsUrl postProtoData:crowd.data complete:^(id response) {
        [weakSelf.downPages objectAddObject:@(weakSelf.page)];
        HttpResponse *hResponse = (HttpResponse *) response;
        if (hResponse.code != successCode) {
            return;
        }
        NSData *data = [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            Crowdfundings *crowdRecords = [Crowdfundings parseFromData:data error:nil];
            if (self.page == 1) {
                [weakSelf.dataArr removeAllObjects];
            }
            [weakSelf.dataArr addObjectsFromArray:crowdRecords.listArray];
            [[LMHistoryCacheManager sharedManager] cachePublicFinaincContacts:data];
            [GCDQueue executeInMainQueue:^{
                [weakSelf.tableView reloadData];
                [weakSelf.tableView.mj_header endRefreshing];
                if (weakSelf.page > 1) { //no More data
                    if (crowdRecords.listArray.count <= 0) {
                        [weakSelf.tableView.mj_footer endRefreshingWithNoMoreData];
                    } else {
                        [weakSelf.tableView.mj_footer endRefreshing];
                    }
                }
            }];
        }
    }                                  fail:^(NSError *error) {
        [GCDQueue executeInMainQueue:^{
            [weakSelf.tableView.mj_header endRefreshing];
            [weakSelf.tableView.mj_footer endRefreshing];
        }];
    }];
}

#pragma mark --tableView delegate method

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArr.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CrowdfoundingHisCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CrowdfoundingHisCellID" forIndexPath:indexPath];
    Crowdfunding *crowd = [self.dataArr objectAtIndexCheck:indexPath.row];
    cell.data = crowd;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    __weak typeof(self) weakSelf = self;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    Crowdfunding *crowd = [self.dataArr objectAtIndexCheck:indexPath.row];

    LMGroupZChouReciptViewController *reciptVc = [[LMGroupZChouReciptViewController alloc] initWithCrowdfundingInfo:crowd];
    [self.navigationController pushViewController:reciptVc animated:YES];
    return;

    [MBProgressHUD showLoadingMessageToView:weakSelf.view];
    // per check new data 
    [WallteNetWorkTool crowdfuningInfoWithHashID:crowd.hashId complete:^(NSError *erro, Crowdfunding *crowdInfo) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:self.view];
            if (erro) {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                }];
            } else {
                LMGroupZChouReciptViewController *reciptVc = [[LMGroupZChouReciptViewController alloc] initWithCrowdfundingInfo:crowdInfo];
                [self.navigationController pushViewController:reciptVc animated:YES];
            }
        }];
    }];
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
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = NO;
    }

    return _tableView;
}

@end
