//
//  LMTranFriendLsitViewController.m
//  Connect
//
//  Created by Edwin on 16/7/23.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMTranFriendLsitViewController.h"
#import "LMFriendTableViewCell.h"

@interface LMTranFriendLsitViewController () <UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) UITableView *tableView;

@property(nonatomic, assign) BOOL isEditing;

@end

static NSString *identifier = @"tranferFriends";

@implementation LMTranFriendLsitViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor colorWithRed:236 / 255.0 green:236 / 255.0 blue:236 / 255.0 alpha:1.0];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [UIView new];
    [self.view addSubview:self.tableView];

    [self.tableView registerNib:[UINib nibWithNibName:@"LMFriendTableViewCell" bundle:nil] forCellReuseIdentifier:identifier];
    [self setNavigationRightWithTitle:LMLocalizedString(@"Login Edit", nil)];
}

- (void)doRight:(id)sender {
    if (self.isEditing) {
        [self setNavigationRightWithTitle:LMLocalizedString(@"Login Edit", nil)];
        [self.tableView setEditing:NO animated:YES];
    } else {
        [self setNavigationRightWithTitle:LMLocalizedString(@"Chat Complete", nil)];
        [self.tableView setEditing:YES animated:YES];
    }
    self.isEditing = !self.isEditing;
}

- (void)viewWillDisappear:(BOOL)animated {

    if (self.friendsHandler) {
        self.friendsHandler(self.dataArr);
    }
    [super viewWillDisappear:animated];
}

- (void)viewDidLayoutSubviews {

    if ([_tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        _tableView.separatorInset = UIEdgeInsetsZero;
    }

    if ([_tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        _tableView.layoutMargins = UIEdgeInsetsZero;
    }
}

#pragma mark --Tableview proxy method

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    LMFriendTableViewCell *lCell = (LMFriendTableViewCell *) cell;
    AccountInfo *info = self.dataArr[indexPath.row];
    [lCell setAccoutInfoFriends:info];

    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        cell.separatorInset = UIEdgeInsetsZero;
    }

    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        cell.layoutMargins = UIEdgeInsetsZero;
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return LMLocalizedString(@"Link Delete", nil);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) return;
    AccountInfo *info = [self.dataArr objectAtIndexCheck:indexPath.row];
    info.isSelected = NO;
    [self.dataArr removeObjectAtIndexCheck:indexPath.row];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return AUTO_HEIGHT(130);
}

@end
