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
@property(nonatomic, strong) NSMutableArray *friendsArr;
@property(nonatomic, copy) void (^SelectContactComplete)(AccountInfo *user);
@property(nonatomic, copy) void (^Cancel)();

@property(nonatomic, copy) NSString *publicKey;
@property(nonatomic, copy) NSString *name;

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
    
    __weak typeof(self)weakSelf = self;
    [GCDQueue executeInMainQueue:^{
        [MBProgressHUD showLoadingMessageToView:weakSelf.view];
    }];
    [[UserDBManager sharedManager] getAllUsersNoConnectWithComplete:^(NSArray *contacts) {
        NSMutableArray *users = [NSMutableArray arrayWithArray:contacts];
        if (weakSelf.publicKey) {
            AccountInfo *currentUser = nil;
            for (AccountInfo *user in users) {
                if ([user.pub_key isEqualToString:weakSelf.publicKey]) {
                    currentUser = user;
                    weakSelf.name = user.username;
                    break;
                }
            }
            if (currentUser) {
                [users removeObject:currentUser];
            }
        }
        _friendsArr = users;
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:weakSelf.view];
            [weakSelf.tableView reloadData];
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
- (NSMutableArray *)groupsFriend {
    if (self.friendsArr.count <= 0) {
        return nil;
    }
    if (!_groupsFriend) {
        _groupsFriend = [NSMutableArray array];
        NSMutableDictionary *group = nil;
        NSMutableArray *items = nil;
        for (NSString *prex in self.indexs) {
            group = [NSMutableDictionary dictionary];
            items = @[].mutableCopy;
            group[@"title"] = prex;
            for (AccountInfo *info in self.friendsArr) {
                NSString *name = @"";
                if (info.remarks && info.remarks.length > 0) {
                    name = info.remarks;
                } else {
                    name = info.username;
                }
                NSString *pinY = [name transformToPinyin];
                NSString *pinYPrex = [pinY substringToIndex:1];
                if (![MMGlobal preIsInAtoZ:pinYPrex]) {
                    pinY = [pinY stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@"#"];
                }
                if ([[pinY uppercaseString] hasPrefix:prex]) {
                    [items objectAddObject:info];
                }
            }
            group[@"items"] = items;
            [_groupsFriend objectAddObject:group];
        }
    }
    return _groupsFriend;
}
- (NSMutableArray *)indexs {
    if (self.friendsArr.count <= 0) {
        return nil;
    }
    if (!_indexs) {
        
        _indexs = [NSMutableArray array];
        
        for (AccountInfo *info in self.friendsArr) {
            NSString *prex = @"";
            NSString *name = @"";
            if (info.remarks && info.remarks.length > 0) {
                name = info.remarks;
            } else {
                name = info.username;
            }
            prex = [[name transformToPinyin] substringToIndex:1];
            if ([MMGlobal preIsInAtoZ:prex]) {
                [_indexs addObject:[prex uppercaseString]];
            } else {
                [_indexs addObject:@"#"];
            }
            NSMutableSet *set = [NSMutableSet set];
            for (NSObject *obj in _indexs) {
                [set addObject:obj];
            }
            [_indexs removeAllObjects];
            for (NSObject *obj in set) {
                [_indexs addObject:obj];
            }
            [_indexs sortUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
                NSString *str1 = obj1;
                NSString *str2 = obj2;
                return [str1 compare:str2];
            }];
        }
        
    }
    
    return _indexs;
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
- (NSMutableArray *)friendsArr {
    if (!_friendsArr) {
        _friendsArr = [NSMutableArray array];
    }
    return _friendsArr;
}
-(void)dealloc {
    [self.groupsFriend removeAllObjects];
    self.groupsFriend = nil;
    [self.indexs removeAllObjects];
    self.indexs = nil;
    [self.friendsArr removeAllObjects];
    self.friendsArr = nil;
}
@end
