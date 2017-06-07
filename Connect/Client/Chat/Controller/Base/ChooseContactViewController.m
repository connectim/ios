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

@interface ChooseContactViewController () <UITableViewDelegate, UITableViewDataSource>

@property(copy, nonatomic) ChooseContactComplete complete;
@property(copy, nonatomic) ChooseContactComplete dynamicComplete;


@property(nonatomic, strong) NSArray *contacts;

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


- (instancetype)initWithChooseComplete:(ChooseContactComplete)complete {
    if (self = [super init]) {
        self.complete = complete;
    }

    return self;
}

- (instancetype)initWithDynamicComplete:(ChooseContactComplete)complete {
    if (self = [super init]) {
        self.dynamicComplete = complete;
    }

    return self;

}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LMLocalizedString(@"Chat Choose contact", nil);

    self.navigationItem.leftBarButtonItems = nil;
    [self setNavigationRight:LMLocalizedString(@"Chat Complete", nil) titleColor:LMBasicGreen];
    self.rightTitleButton.enabled = NO;

    //title color
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{NSForegroundColorAttributeName: LMBasicGreen} forState:UIControlStateNormal];
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor grayColor]} forState:UIControlStateDisabled];

    [self setNavigationLeftWithTitle:LMLocalizedString(@"Common Cancel", nil)];

    [self.view addSubview:self.tableView];
    [self configTableView];
    [GCDQueue executeInMainQueue:^{
        [MBProgressHUD showLoadingMessageToView:self.view];
    }];

    [[UserDBManager sharedManager] getAllUsersNoConnectWithComplete:^(NSArray *contacts) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:self.view];
        }];

        self.contacts = contacts;
        //set data
        for (AccountInfo *selectedInfo in self.selectedUsers) {
            for (AccountInfo *info in self.contacts) {
                if ([selectedInfo.address isEqualToString:info.address]) {
                    info.isThisGroupMember = YES;
                    break;
                }
            }
        }
        [GCDQueue executeInMainQueue:^{
            [self.tableView reloadData];
        }];

    }];
}

- (void)doLeft:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)doRight:(id)sender {
    if (self.complete) {
        self.complete(self.selectedContacts);
    }
    if (self.dynamicComplete) {
        self.dynamicComplete(self.selectedContacts);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)configTableView {
    [self.tableView registerNib:[UINib nibWithNibName:@"ChooseContactCell" bundle:nil] forCellReuseIdentifier:@"ChooseContactCellID"];
    [self.tableView registerClass:[ConnectTableHeaderView class] forHeaderFooterViewReuseIdentifier:@"ConnectTableHeaderViewID"];
    self.tableView.rowHeight = 58;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.sectionIndexColor = [UIColor lightGrayColor];
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}


#pragma mark - Table view data source


- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.indexs;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    CellGroup *group = self.groups[section];
    return group.items.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.groups.count;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 20;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    ConnectTableHeaderView *hearderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"ConnectTableHeaderViewID"];
    CellGroup *group = self.groups[section];
    hearderView.customTitle.text = group.headTitle;
    return hearderView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CellGroup *group = self.groups[indexPath.section];
    ChooseContactCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChooseContactCellID" forIndexPath:indexPath];
    AccountInfo *contact = group.items[indexPath.row];

    cell.checkBoxView.on = contact.isThisGroupMember;
    cell.userInteractionEnabled = !contact.isThisGroupMember;

    cell.data = contact;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ChooseContactCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [cell.checkBoxView setOn:!cell.checkBoxView.on animated:YES];
    CellGroup *group = self.groups[indexPath.section];
    AccountInfo *contact = group.items[indexPath.row];
    contact.isThisGroupMember = !contact.isThisGroupMember;

    if (cell.checkBoxView.on) {
        if (![self.selectedContacts containsObject:contact]) {
            [self.selectedContacts objectAddObject:contact];
        }
    } else {
        [self.selectedContacts removeObject:contact];
    }

    //callback
    if (self.dynamicComplete) {
        self.dynamicComplete(self.selectedContacts);
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

- (NSMutableArray *)groups {
    if (self.contacts.count <= 0) {
        return nil;
    }
    if (!_groups) {
        _groups = [NSMutableArray array];
        NSMutableArray *items = nil;

        for (NSString *prex in self.indexs) {
            CellGroup *group = [[CellGroup alloc] init];
            group.headTitle = prex;
            items = [NSMutableArray array];
            for (AccountInfo *contact in self.contacts) {
                NSString *name = contact.username;
                NSString *namePiny = [[name transformToPinyin] uppercaseString];
                if (namePiny.length <= 0) {
                    continue;
                }
                NSString *pinYPrex = [namePiny substringToIndex:1];
                if (![self preIsInAtoZ:pinYPrex]) {
                    namePiny = [namePiny stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@"#"];
                }
                if ([namePiny hasPrefix:prex]) {
                    [items objectAddObject:contact];
                }
            }
            group.items = [NSArray arrayWithArray:items];
            [_groups objectAddObject:group];
        }
    }
    return _groups;
}

- (NSMutableArray *)indexs {
    if (self.contacts.count <= 0) {
        return nil;
    }
    if (!_indexs) {
        _indexs = [NSMutableArray array];
        for (AccountInfo *contact in self.contacts) {
            NSString *prex = @"";
            NSString *name = contact.username;
            if (name.length <= 0) {
                continue;
            }
            prex = [[name transformToPinyin] substringToIndex:1];
            if ([self preIsInAtoZ:prex]) {
                [_indexs objectAddObject:[prex uppercaseString]];
            } else {
                [_indexs addObject:@"#"];
            }
            NSMutableSet *set = [NSMutableSet set];
            for (NSObject *obj in _indexs) {
                [set addObject:obj];
            }
            [_indexs removeAllObjects];
            for (NSObject *obj in set) {
                [_indexs objectAddObject:obj];
            }
            [_indexs sortUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
                NSString *str1 = obj1;
                NSString *str2 = obj2;
                return [str1 compare:str2];
            }];
        }
        if (_indexs.count <= 0) {
            _indexs = nil;
        }
    }
    return _indexs;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    }

    return _tableView;
}

- (NSMutableArray *)selectedContacts {
    if (!_selectedContacts) {
        _selectedContacts = [NSMutableArray array];
    }

    return _selectedContacts;
}

#pragma mark - privkey Method

- (BOOL)preIsInAtoZ:(NSString *)str {
    return [@"QWERTYUIOPLKJHGFDSAZXCVBNM" containsString:str] || [[@"QWERTYUIOPLKJHGFDSAZXCVBNM" lowercaseString] containsString:str];
}

@end
