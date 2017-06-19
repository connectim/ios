//
//  SelectContactCardController.m
//  Connect
//
//  Created by MoHuilin on 16/7/28.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "SelectContactCardController.h"
#include "NSString+Pinyin.h"
#import "ConnectTableHeaderView.h"
#import "LinkmanFriendCell.h"
#import "UserDBManager.h"
#import "LMLinkManDataManager.h"


@interface SelectContactCardController ()

@property(nonatomic, strong) NSMutableArray *groupsFriend;
@property(nonatomic, strong) NSMutableArray *indexs;
@property(nonatomic, copy) void (^SelectContactComplete)(AccountInfo *user);
@property(nonatomic, copy) void (^Cancel)();

@property(nonatomic, copy) NSString *publicKey;


@end

@implementation SelectContactCardController


- (instancetype)initWihtTalkName:(NSString *)name complete:(void (^)(AccountInfo *user))complete cancel:(void (^)())cancel {
    if (self = [super init]) {
        self.SelectContactComplete = complete;
        self.Cancel = cancel;

        self.publicKey = name;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItems = nil;
    [self setNavigationLeftWithTitle:LMLocalizedString(@"Common Cancel", nil)];
    [self configTableView];

    self.title = LMLocalizedString(@"Chat Send a namecard", nil);
    [GCDQueue executeInMainQueue:^{
        [MBProgressHUD showLoadingMessageToView:self.view];
    }];
    [GCDQueue executeInGlobalQueue:^{
        AccountInfo* info = [[UserDBManager sharedManager] getUserByPublickey:self.publicKey];
        self.groupsFriend = [[LMLinkManDataManager sharedManager] getListGroupsFriend:info withTag:YES];
        self.indexs = [MMGlobal getIndexArray:self.groupsFriend];
       [GCDQueue executeInMainQueue:^{
           [MBProgressHUD hideHUDForView:self.view];
           [self.tableView reloadData];
       }];
    }];
}

- (void)doLeft:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)configTableView {
    [self.tableView registerNib:[UINib nibWithNibName:@"LinkmanFriendCell" bundle:nil] forCellReuseIdentifier:@"LinkmanFriendCellID"];
    [self.tableView registerClass:[ConnectTableHeaderView class] forHeaderFooterViewReuseIdentifier:@"ConnectTableHeaderViewID"];
    self.tableView.rowHeight = 50;
    self.tableView.sectionIndexColor = [UIColor lightGrayColor];
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}


#pragma mark - Table view data source

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.indexs;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *items = self.groupsFriend[section][@"items"];
    return items.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.groupsFriend.count;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 20;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    ConnectTableHeaderView *hearderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"ConnectTableHeaderViewID"];

    hearderView.customTitle.text = [self.groupsFriend[section] valueForKey:@"title"];
    NSString *titleIcon = [self.groupsFriend[section] valueForKey:@"titleicon"];
    hearderView.customIcon = titleIcon;
    return hearderView;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LinkmanFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LinkmanFriendCellID" forIndexPath:indexPath];
    AccountInfo *user = self.groupsFriend[indexPath.section][@"items"][indexPath.row];
    cell.data = user;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    AccountInfo *user = self.groupsFriend[indexPath.section][@"items"][indexPath.row];

    __weak __typeof(&*self) weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        if (weakSelf.SelectContactComplete) {
            weakSelf.SelectContactComplete(user);
        }

    }];
}
#pragma mark - getter setter
- (NSMutableArray *)groupsFriend {
    if (!_groupsFriend) {
        self.groupsFriend = [NSMutableArray array];
    }
    return _groupsFriend;
}
- (NSMutableArray *)indexs {
    if (!_indexs) {
        self.indexs = [NSMutableArray array];
    }
    return _indexs;
}
-(void)dealloc {
    [self.groupsFriend removeAllObjects];
    self.groupsFriend = nil;
    [self.indexs removeAllObjects];
    self.indexs = nil;
}
@end
