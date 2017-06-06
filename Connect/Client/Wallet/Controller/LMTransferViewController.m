//
//  LMTransferViewController.m
//  Connect
//
//  Created by Edwin on 16/7/14.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMTransferViewController.h"
#import "LMFriendTableViewCell.h"
#import "LMaddTableViewCell.h"
#import "LMFriendsViewController.h"
#import "LMBitAddressViewController.h"
#import "LMUnSetMoneyResultViewController.h"
#import "OuterTransferViewController.h"
#import "LMHistoryCacheManager.h"

@interface LMTransferViewController () <UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) NSMutableArray *dataArr;
@property(nonatomic, strong) UITableView *tableView;
@end

static NSString *identifier = @"friends";
static NSString *transIdentifier = @"transfer";

@implementation LMTransferViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = LMLocalizedString(@"Wallet Transfer", nil);
    [self.view addSubview:self.tableView];
}
#pragma mark - lazy
- (UITableView *)tableView {
    if (!_tableView) {
        self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, AUTO_HEIGHT(30), VSIZE.width, VSIZE.height - AUTO_HEIGHT(30)) style:UITableViewStylePlain];
        self.tableView.backgroundColor = LMBasicBackgroudGray;
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.tableView.tableFooterView = [[UIView alloc] init];
        [self.tableView registerNib:[UINib nibWithNibName:@"LMFriendTableViewCell" bundle:nil] forCellReuseIdentifier:identifier];
        [self.tableView registerNib:[UINib nibWithNibName:@"LMaddTableViewCell" bundle:nil] forCellReuseIdentifier:transIdentifier];
    }
    return _tableView;

}
#pragma mark --tableview delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 3;
    } else {
        return self.dataArr.count;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.section == 0) {
        LMaddTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:transIdentifier];
        if (!cell) {
            cell = [[LMaddTableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:transIdentifier];
        }
        if (indexPath.row == 0) {
            cell.iconImageView.image = [UIImage imageNamed:@"wallet_sendto_friends"];
            cell.titleLabel.text = LMLocalizedString(@"Wallet Transfer to Friends", nil);
        } else if (indexPath.row == 1) {
            cell.iconImageView.image = [UIImage imageNamed:@"wallet_sendto_bitcoin"];
            cell.titleLabel.text = LMLocalizedString(@"Wallet Transfer to Bitcoin Address", nil);
        } else {
            cell.iconImageView.image = [UIImage imageNamed:@"wallet_sendto_messages"];
            cell.titleLabel.text = LMLocalizedString(@"Wallet Transfer via other APP messges", nil);
        }
        return cell;
    } else {
        LMFriendTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (!cell) {
            cell = [[LMFriendTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        }
        AccountInfo *info = self.dataArr[indexPath.row];
        [cell setAccoutInfoFriends:info];
        return cell;
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return AUTO_HEIGHT(110);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 0;
    } else {
        return AUTO_HEIGHT(40);
    }

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {// transfer to friends
            LMFriendsViewController *friends = [[LMFriendsViewController alloc] init];
            [self.navigationController pushViewController:friends animated:YES];
        } else if (indexPath.row == 1) { // transfer to address
            LMBitAddressViewController *bitAddVc = [[LMBitAddressViewController alloc] init];
            [self.navigationController pushViewController:bitAddVc animated:YES];
        } else { // out transfer
            OuterTransferViewController *page = [[OuterTransferViewController alloc] init];
            [self.navigationController pushViewController:page animated:YES];
        }
    } else {
        // transfer to single
        AccountInfo *info = self.dataArr[indexPath.row];
        LMUnSetMoneyResultViewController *page = [[LMUnSetMoneyResultViewController alloc] init];
        page.info = info;
        [self.navigationController pushViewController:page animated:YES];
    }
}


- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VSIZE.width, AUTO_HEIGHT(40))];
        bgView.backgroundColor = LMBasicBackgroudGray;
        UILabel *titleOneLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, VSIZE.width - 20, AUTO_HEIGHT(40))];
        titleOneLabel.backgroundColor = LMBasicBackgroudGray;
        titleOneLabel.text = LMLocalizedString(@"Wallet Recent transfer", nil);
        titleOneLabel.font = [UIFont systemFontOfSize:FONT_SIZE(22)];
        titleOneLabel.textColor = LMBasicBlack;
        titleOneLabel.textAlignment = NSTextAlignmentLeft;
        [bgView addSubview:titleOneLabel];
        return bgView;
    } else {
        return nil;
    }
}

#pragma lazy

- (NSMutableArray *)dataArr {
    if (_dataArr == nil) {
        _dataArr = [NSMutableArray array];
        [_dataArr addObjectsFromArray:[[LMHistoryCacheManager sharedManager] getTransferHistory]];
    }
    return _dataArr;
}

@end
