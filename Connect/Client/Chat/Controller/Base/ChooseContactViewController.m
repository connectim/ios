//
//  ChooseContactViewController.m
//  Connect
//
//  Created by MoHuilin on 16/7/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "ChooseContactViewController.h"
#import "ChooseContactCell.h"
#import "NCellHeader.h"
#import "ConnectTableHeaderView.h"
#import "UserDBManager.h"
#import "NSString+Pinyin.h"
#import "LMLinkManDataManager.h"


@interface ChooseContactViewController () <UITableViewDelegate, UITableViewDataSource>

@property(copy, nonatomic) ChooseContactComplete complete;

@property(nonatomic, strong) NSMutableArray *groups;
@property(nonatomic, strong) NSMutableArray *indexs;
@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) NSMutableArray *selectedContacts;
@property(nonatomic, strong) NSArray *selectedUsers;


@end

@implementation ChooseContactViewController

- (instancetype)initWithChooseComplete:(ChooseContactComplete)complete defaultSelectedUser:(AccountInfo *)selectedUser {
    if (self = [super init]) {
        self.complete = complete;
        self.selectedUsers = @[selectedUser];
    }
    return self;
}

- (instancetype)initWithChooseComplete:(ChooseContactComplete)complete defaultSelectedUsers:(NSArray *)selectedUsers {
    if (self = [super init]) {
        self.complete = complete;
        self.selectedUsers = selectedUsers;
    }

    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpUI];
    
    [MBProgressHUD showLoadingMessageToView:self.view];
    [GCDQueue executeInGlobalQueue:^{
        self.groups = [[LMLinkManDataManager sharedManager] getFriendsArrWithArray:self.selectedUsers];
        self.indexs = [MMGlobal getIndexArray:self.groups];
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:self.view];
            [self.tableView reloadData];
        }];
    }];
    
}
- (void)setUpUI {
    
    self.title = LMLocalizedString(@"Chat Choose contact", nil);
    self.navigationItem.leftBarButtonItems = nil;
    [self setNavigationRight:LMLocalizedString(@"Chat Complete", nil) titleColor:LMBasicGreen];
    self.rightTitleButton.enabled = NO;
    //title color
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{NSForegroundColorAttributeName: LMBasicGreen} forState:UIControlStateNormal];
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor grayColor]} forState:UIControlStateDisabled];
    [self setNavigationLeftWithTitle:LMLocalizedString(@"Common Cancel", nil)];
    
    [self.view addSubview:self.tableView];
}
- (void)doLeft:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)doRight:(id)sender {
    if (self.complete) {
        self.complete(self.selectedContacts);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - Table view data source


- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.indexs;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSMutableDictionary *dic = self.groups[section];
    NSMutableArray *array = dic[@"items"];
    return array.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.groups.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 20;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    ConnectTableHeaderView *hearderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"ConnectTableHeaderViewID"];
    hearderView.customTitle.text = [self.groups[section] valueForKey:@"title"];
    NSString *titleIcon = [self.groups[section] valueForKey:@"titleicon"];
    hearderView.customIcon = titleIcon;
    return hearderView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    ChooseContactCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChooseContactCellID" forIndexPath:indexPath];
    AccountInfo *contact = self.groups[indexPath.section][@"items"][indexPath.row];
    cell.checkBoxView.on = contact.isThisGroupMember;
    cell.userInteractionEnabled = !contact.isThisGroupMember;
    cell.data = contact;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ChooseContactCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [cell.checkBoxView setOn:!cell.checkBoxView.on animated:YES];
    AccountInfo *contact = self.groups[indexPath.section][@"items"][indexPath.row];
    contact.isThisGroupMember = !contact.isThisGroupMember;
    if (cell.checkBoxView.on) {
        if (![self.selectedContacts containsObject:contact]) {
            [self.selectedContacts objectAddObject:contact];
        }
    } else {
        [self.selectedContacts removeObject:contact];
    }
    //set right button
    if (self.selectedContacts.count > 0) {
        [self setNavigationRightWithTitle:[NSString stringWithFormat:LMLocalizedString(@"Link Add man", nil), self.selectedContacts.count]];
        self.rightTitleButton.enabled = YES;
    } else {
        [self setNavigationRight:LMLocalizedString(@"Chat Complete", nil) titleColor:LMBasicGreen];
        self.rightTitleButton.enabled = NO;
    }
}
#pragma mark -lazy

- (NSMutableArray *)groups {
    if (!_groups) {
        self.groups = [NSMutableArray array];
    }
    return _groups;
}

- (NSMutableArray *)indexs {
    if (!_indexs) {
        self.indexs = [NSMutableArray array];
    }
    return _indexs;
}
- (NSArray *)selectedUsers {
    if (!_selectedUsers) {
        self.selectedUsers = [NSArray array];
    }
    return _selectedUsers;
}
- (UITableView *)tableView {
    if (!_tableView) {
        self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        [self.tableView registerNib:[UINib nibWithNibName:@"ChooseContactCell" bundle:nil] forCellReuseIdentifier:@"ChooseContactCellID"];
        [self.tableView registerClass:[ConnectTableHeaderView class] forHeaderFooterViewReuseIdentifier:@"ConnectTableHeaderViewID"];
        self.tableView.rowHeight = 58;
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.tableView.sectionIndexColor = [UIColor lightGrayColor];
        self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return _tableView;
}

- (NSMutableArray *)selectedContacts {
    if (!_selectedContacts) {
        _selectedContacts = [NSMutableArray array];
    }
    return _selectedContacts;
}
-(void)dealloc {
    [self.groups removeAllObjects];
    self.groups = nil;
    [self.indexs removeAllObjects];
    self.indexs = nil;
    self.selectedUsers = nil;
    [self.selectedContacts removeAllObjects];
    self.selectedContacts = nil;
}

@end
