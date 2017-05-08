//
//  LMGroupZChouReciptViewController.m
//  Connect
//
//  Created by Edwin on 16/8/24.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMGroupZChouReciptViewController.h"
#import "LMTableViewCell.h"
#import "CommonClausePage.h"

@interface LMGroupZChouReciptViewController () <UITableViewDelegate, UITableViewDataSource>
// user head
@property(nonatomic, strong) UIImageView *userImageView;
// username
@property(nonatomic, strong) UILabel *userNameLabel;
// crowd rason
@property(nonatomic, strong) UILabel *noteLabel;
// crowd status
@property(nonatomic, strong) UIButton *statusView;
// crowd money
@property(nonatomic, strong) UILabel *totalBalanceLabel;
// per money
@property(nonatomic, strong) UILabel *everyUserBalanceLabel;
@property(nonatomic, strong) UILabel *UserReciptLabel;
@property(nonatomic, strong) UITableView *tableView;

@property(nonatomic, strong) NSMutableArray *dataArr;
//crowd message
@property(nonatomic, strong) Crowdfunding *crowdfundingInfo;

@end

static NSString *identifier = @"cellIdentifier";

@implementation LMGroupZChouReciptViewController

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

    [self reloadViewStatus];
}

- (void)creatView {
    self.userImageView = [[UIImageView alloc] init];

    NSString *avatar = self.crowdfundingInfo.sender.avatar;
    [self.userImageView setPlaceholderImageWithAvatarUrl:avatar];
    self.userImageView.layer.cornerRadius = 3;
    self.userImageView.layer.masksToBounds = YES;
    [self.view addSubview:self.userImageView];
    [_userImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(AUTO_HEIGHT(150));
        make.size.mas_equalTo(CGSizeMake(AUTO_HEIGHT(100), AUTO_HEIGHT(100)));
        make.centerX.equalTo(self.view);
    }];
    self.userNameLabel = [[UILabel alloc] init];
    self.userNameLabel.textAlignment = NSTextAlignmentCenter;
    self.userNameLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.userNameLabel.textColor = [UIColor colorWithHexString:@"161A21"];
    NSString *senderName = self.crowdfundingInfo.sender.username;
    if ([self.crowdfundingInfo.sender.username isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].username]) {
        senderName = LMLocalizedString(@"Chat You", nil);
    }
    self.userNameLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Chat Crowd funding by who", nil), senderName];
    [self.view addSubview:self.userNameLabel];
    [_userNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.userImageView.mas_bottom).offset(AUTO_HEIGHT(10));
        make.centerX.equalTo(self.view);
    }];

    self.noteLabel = [[UILabel alloc] init];
    self.noteLabel.textColor = [UIColor colorWithHexString:@"B3B5BC"];
    self.noteLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.noteLabel.textAlignment = NSTextAlignmentCenter;
    self.noteLabel.text = GJCFStringIsNull(self.crowdfundingInfo.tips) ? nil : [NSString stringWithFormat:LMLocalizedString(@"Link Note", nil), self.crowdfundingInfo.tips];
    [self.view addSubview:self.noteLabel];
    [_noteLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.userNameLabel.mas_bottom).offset(AUTO_HEIGHT(10));
        make.centerX.equalTo(self.view);
    }];
    self.totalBalanceLabel = [[UILabel alloc] init];
    self.totalBalanceLabel.textAlignment = NSTextAlignmentCenter;
    self.totalBalanceLabel.textColor = [UIColor colorWithHexString:@"262626"];
    self.totalBalanceLabel.font = [UIFont systemFontOfSize:FONT_SIZE(48)];
    self.totalBalanceLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Goal", nil), [PayTool getBtcStringWithAmount:self.crowdfundingInfo.total]];
    [self.view addSubview:self.totalBalanceLabel];
    [_totalBalanceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.noteLabel.mas_bottom).offset(AUTO_HEIGHT(20));
        make.centerX.equalTo(self.view);
    }];

    self.everyUserBalanceLabel = [[UILabel alloc] init];
    self.everyUserBalanceLabel.textColor = [UIColor colorWithHexString:@"B3B5BC"];
    self.everyUserBalanceLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.everyUserBalanceLabel.textAlignment = NSTextAlignmentCenter;
    NSDecimalNumber *perAmount = [[[NSDecimalNumber alloc] initWithLongLong:self.crowdfundingInfo.total] decimalNumberByDividingBy:[[NSDecimalNumber alloc] initWithLong:self.crowdfundingInfo.size]];
    self.everyUserBalanceLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet BTC Each", nil), [PayTool getBtcStringWithDecimalAmount:perAmount]];
    [self.view addSubview:self.everyUserBalanceLabel];
    [_everyUserBalanceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.totalBalanceLabel.mas_bottom).offset(AUTO_HEIGHT(15));
        make.centerX.equalTo(self.view);
    }];

    self.statusView = [[UIButton alloc] init];
    [self.view addSubview:self.statusView];
    [self.statusView setImage:[UIImage imageNamed:@"transfer_success"] forState:UIControlStateNormal];
    self.statusView.enabled = NO;
    self.statusView.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(36)];
    [self.statusView setTitleColor:[UIColor colorWithHexString:@"161A21"] forState:UIControlStateNormal];

    [_statusView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.everyUserBalanceLabel.mas_bottom).offset(AUTO_HEIGHT(20));
        make.centerX.equalTo(self.view);
        make.height.mas_equalTo(0);
    }];


    self.UserReciptLabel = [[UILabel alloc] init];
    self.UserReciptLabel.textColor = [UIColor colorWithHexString:@"B3B5BC"];
    self.UserReciptLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.UserReciptLabel.textAlignment = NSTextAlignmentLeft;//CrowdfundingRecord
    int count = (int) (self.crowdfundingInfo.size - self.crowdfundingInfo.remainSize);

    self.UserReciptLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet members paid BTC", nil), count, self.crowdfundingInfo.size, [PayTool getBtcStringWithAmount:self.crowdfundingInfo.remainSize == 0 ? self.crowdfundingInfo.total : count * self.crowdfundingInfo.total / self.crowdfundingInfo.size]];
    [self.view addSubview:self.UserReciptLabel];
    [_UserReciptLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.statusView.mas_bottom).offset(AUTO_HEIGHT(30));
        make.left.equalTo(self.view).offset(AUTO_WIDTH(30));
    }];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.separatorColor = [UIColor clearColor];
    [self.view addSubview:self.tableView];
    self.tableView.rowHeight = AUTO_HEIGHT(130);

    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.UserReciptLabel.mas_bottom).offset(AUTO_HEIGHT(10));
        make.width.mas_equalTo(DEVICE_SIZE.width);
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];

    self.tableView.showsHorizontalScrollIndicator = NO;
    self.tableView.showsVerticalScrollIndicator = NO;
    [self.tableView registerNib:[UINib nibWithNibName:@"LMTableViewCell" bundle:nil] forCellReuseIdentifier:identifier];
}

- (void)reloadViewStatus {
    if (self.crowdfundingInfo.status == 1) {
        [self.statusView setTitle:LMLocalizedString(@"Chat Complete", nil) forState:UIControlStateNormal];
        [self.statusView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(AUTO_HEIGHT(100));
        }];
        //refresh
        [self.view layoutIfNeeded];
    }
}

#pragma mark --tableView代理方法

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LMTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[LMTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    LMUserInfo *userInfo = self.dataArr[indexPath.row];
    [cell setUserInfo:userInfo];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    LMUserInfo *info = self.dataArr[indexPath.row];

    NSString *url = [NSString stringWithFormat:@"%@%@", txDetailBaseUrl, info.hashId];
    CommonClausePage *page = [[CommonClausePage alloc] initWithUrl:url];
    [self.navigationController pushViewController:page animated:YES];

}

#pragma mark --lazy

- (NSMutableArray *)dataArr {
    if (_dataArr == nil) {
        _dataArr = [NSMutableArray array];
        for (CrowdfundingRecord *record in self.crowdfundingInfo.records.listArray) {
            LMUserInfo *info = [[LMUserInfo alloc] init];
            info.imageUrl = record.user.avatar;
            info.userName = record.user.username;
            info.txType = 1;
            info.balance = record.amount;
            info.hashId = record.txid;
            info.confirmation = record.status == 2;
            info.createdAt = [NSString stringWithFormat:@"%llu", record.createdAt];
            [_dataArr objectAddObject:info];
        }
    }
    return _dataArr;
}

@end
