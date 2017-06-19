//
//  LMFriendsViewController.m
//  Connect
//
//  Created by Edwin on 16/7/19.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMFriendsViewController.h"
#import "LMTransFriendsViewController.h"
#import "UserDBManager.h"
#import "LMSelectTableViewCell.h"
#import "NSString+Pinyin.h"
#import "UIImage+Color.h"
#import "NSString+Size.h"
#import "LMLinkManDataManager.h"


@interface LMFriendsViewController () <UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) NSMutableArray *selectedList;

@property(nonatomic, strong) NSMutableArray *dataArr;

@property(nonatomic, strong) NSMutableArray *sectionIndexArr;

@property(nonatomic, strong) UITableView *tableView;

@property(nonatomic, strong) TransferButton *transferBtn;

@end

static NSString *friends = @"friends";

@implementation LMFriendsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LMLocalizedString(@"Wallet Select friends", nil);
    [self.view addSubview:self.tableView];
    
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    [self setRightBarButtonItemWithEnable:NO withDispalyString:LMLocalizedString(@"Wallet Transfer", nil) withDisplayColor:[UIColor colorWithWhite:1.0 alpha:0.5]];

    // Get friends
    __weak typeof(self) weakSelf = self;
    [GCDQueue executeInMainQueue:^{
        [MBProgressHUD showLoadingMessageToView:weakSelf.view];
    }];
    
    [GCDQueue executeInGlobalQueue:^{
            self.dataArr = [[LMLinkManDataManager sharedManager] getFriendsArrWithNoConnect];
            self.sectionIndexArr = [MMGlobal getIndexArray:self.dataArr];
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD hideHUDForView:weakSelf.view];
                [weakSelf.tableView reloadData];
            }];
    }];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

#pragma mark - lazy
- (NSMutableArray *)dataArr {
    if (!_dataArr) {
        self.dataArr = [NSMutableArray array];
    }
    return _dataArr;
}
- (NSMutableArray *)sectionIndexArr {
    if (!_sectionIndexArr) {
        self.sectionIndexArr = [NSMutableArray array];
    }
    return _sectionIndexArr;
}

- (NSMutableArray *)selectedList {
    if (!_selectedList) {
        self.selectedList = [NSMutableArray array];
    }
    return _selectedList;
}
- (UITableView *)tableView {
    if (!_tableView) {
        self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, VSIZE.width, VSIZE.height - 64) style:UITableViewStylePlain];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.tableView.rowHeight = AUTO_HEIGHT(115);
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.tableFooterView = [[UIView alloc] init];
        self.tableView.sectionIndexColor = [UIColor lightGrayColor];
        self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
        [self.tableView registerNib:[UINib nibWithNibName:@"LMSelectTableViewCell" bundle:nil] forCellReuseIdentifier:friends];
    }
    return _tableView;

}
#pragma mark - method
- (void)setRightBarButtonItemWithEnable:(BOOL)enable withDispalyString:(NSString *)titleName withDisplayColor:(UIColor *)color {
    self.navigationItem.rightBarButtonItems = nil;

    self.transferBtn = [[TransferButton alloc] initWithNormalTitle:titleName disableTitle:titleName];
    self.transferBtn.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.transferBtn.width = [titleName widthWithFont:[UIFont systemFontOfSize:FONT_SIZE(28)] constrainedToHeight:MAXFLOAT];
    if (self.transferBtn.width >= 80) {
        self.transferBtn.width = 80;
    }
    self.transferBtn.height = 44;
    [self.transferBtn addTarget:self action:@selector(transferBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.transferBtn];
    [self.transferBtn setBackgroundImage:[UIImage imageWithColor:[UIColor clearColor]] forState:UIControlStateDisabled];
    [self.transferBtn setBackgroundImage:[UIImage imageWithColor:[UIColor clearColor]] forState:UIControlStateNormal];
    if (enable) {
        [self.transferBtn setTitleColor:color forState:UIControlStateNormal];
    } else {
        [self.transferBtn setTitleColor:color forState:UIControlStateDisabled];
    }

    self.transferBtn.enabled = enable;
}
#pragma mark -- Get friends

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.dataArr.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSMutableDictionary *dic = self.dataArr[section];
    NSMutableArray * temArray = dic[@"items"];
    return temArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return AUTO_HEIGHT(40);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VSIZE.width, AUTO_HEIGHT(40))];
    bgView.backgroundColor = LMBasicBackgroudGray;
    UILabel *titleOneLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, VSIZE.width - 20, AUTO_HEIGHT(40))];
    titleOneLabel.backgroundColor = LMBasicBackgroudGray;
    titleOneLabel.text = [self.dataArr[section] valueForKey:@"title"];
    titleOneLabel.font = [UIFont systemFontOfSize:FONT_SIZE(26)];
    titleOneLabel.textColor = [UIColor blackColor];
    titleOneLabel.textAlignment = NSTextAlignmentLeft;
    [bgView addSubview:titleOneLabel];
    return bgView;
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.sectionIndexArr;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    NSIndexPath *selectIndexPath = [NSIndexPath indexPathForRow:0 inSection:index];
    [tableView scrollToRowAtIndexPath:selectIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    return index;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    LMSelectTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:friends];
    if (!cell) {
        cell = [[LMSelectTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:friends];
    }
    NSMutableDictionary *dic = self.dataArr[indexPath.section];
    AccountInfo *info = dic[@"items"][indexPath.row];
    [cell setAccoutInfo:info];
    [cell.checkBox setOn:info.isSelected animated:YES];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    LMSelectTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSMutableDictionary *dic = self.dataArr[indexPath.section];
    AccountInfo *info = dic[@"items"][indexPath.row];
    info.isSelected = !info.isSelected;
    [cell.checkBox setOn:info.isSelected animated:YES];
    if ([self.selectedList containsObject:info]) {
        [self.selectedList removeObject:info];
    } else {
        [self.selectedList objectAddObject:info];
    }
    if (self.selectedList.count) {
        [self setRightBarButtonItemWithEnable:YES withDispalyString:[NSString stringWithFormat:LMLocalizedString(@"Wallet transfer man", nil), (int) self.selectedList.count] withDisplayColor:LMBasicGreen];

    } else {
        [self setRightBarButtonItemWithEnable:NO withDispalyString:LMLocalizedString(@"Wallet Transfer", nil) withDisplayColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
    }
}

- (void)transferBtnClicked:(UIButton *)btn {
    __weak typeof(self) weakSelf = self;
    if (self.selectedList.count == 0) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Select friends", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
        }];
        return;
    }
    LMTransFriendsViewController *transfer = [[LMTransFriendsViewController alloc] init];
    transfer.selectArr = self.selectedList;
    transfer.changeListBlock = ^() {
        if (weakSelf.selectedList.count > 0) {
            [weakSelf setRightBarButtonItemWithEnable:YES withDispalyString:[NSString stringWithFormat:LMLocalizedString(@"Wallet transfer man", nil), (int) self.selectedList.count] withDisplayColor:LMBasicGreen];
            [weakSelf.tableView reloadData];
        } else {
            [weakSelf setRightBarButtonItemWithEnable:NO withDispalyString:LMLocalizedString(@"Wallet Transfer", nil) withDisplayColor:[UIColor colorWithWhite:1.0 alpha:0.5]];

        }
    };
    [self.navigationController pushViewController:transfer animated:YES];
}
-(void)dealloc {
    [self.selectedList removeAllObjects];
    self.selectedList = nil;
    [self.sectionIndexArr removeAllObjects];
    self.sectionIndexArr = nil;
    [self.dataArr removeAllObjects];
    self.dataArr = nil;

}
@end
