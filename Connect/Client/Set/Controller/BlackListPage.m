//
//  BlackListPage.m
//  Connect
//
//  Created by MoHuilin on 16/8/1.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BlackListPage.h"
#import "ConnectTableHeaderView.h"
#import "LinkmanFriendCell.h"
#import "NSString+Pinyin.h"
#import "UserDBManager.h"
#import "UIScrollView+EmptyDataSet.h"


@interface BlackListPage () <DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

// all friends
@property(nonatomic, strong) NSMutableArray *blackManArray;

// sort list
@property(nonatomic, strong) NSMutableArray *groupsFriend;

// indexs
@property(nonatomic, strong) NSMutableArray *indexs;


@end


@implementation BlackListPage


- (void)viewDidLoad {
    [super viewDidLoad];

    [self configTableView];

    self.title = LMLocalizedString(@"Link Black List", nil);
    __weak __typeof(&*self) weakSelf = self;

    if (![[MMAppSetting sharedSetting] isHaveSyncBlickMan]) {
        [SetGlobalHandler blackListDownComplete:^(NSArray *blackList) {
            [weakSelf.blackManArray removeAllObjects];
            [weakSelf.blackManArray objectAddObject:blackList];
            [GCDQueue executeInMainQueue:^{
                [weakSelf.tableView reloadData];
            }];
        }];
    }
}


- (void)configTableView {

    self.tableView.separatorColor = self.tableView.backgroundColor;

    [self.tableView registerNib:[UINib nibWithNibName:@"LinkmanFriendCell" bundle:nil] forCellReuseIdentifier:@"LinkmanFriendCellID"];
    [self.tableView registerClass:[ConnectTableHeaderView class] forHeaderFooterViewReuseIdentifier:@"ConnectTableHeaderViewID"];
    self.tableView.rowHeight = 50;
    self.tableView.sectionIndexColor = [UIColor lightGrayColor];
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
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


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        AccountInfo *user = self.groupsFriend[indexPath.section][@"items"][indexPath.row];
        [SetGlobalHandler removeBlackListWithAddress:user.address];
        // ui remove
        NSMutableArray *items = self.groupsFriend[indexPath.section][@"items"];
        [items removeObject:user];
        if (items.count == 0) {
            [self.groupsFriend removeObjectAtIndexCheck:indexPath.section];
            [self.indexs removeObjectAtIndexCheck:indexPath.section];
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationBottom];
        } else {
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationBottom];
        }

        // no data
        if (self.groupsFriend.count == 0) {
            [tableView reloadData];
        }
    }
}


- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *title = LMLocalizedString(@"Wallet Without a blacklist", nil);
    return [[NSAttributedString alloc] initWithString:title];
}

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView {
    return YES;
}


#pragma mark - getter setter

- (NSMutableArray *)indexs {
    if (!_indexs) {

        _indexs = [NSMutableArray array];

        for (AccountInfo *info in self.blackManArray) {
            NSString *prex = @"";
            NSString *name = @"";
            if (info.remarks && info.remarks.length > 0) { // use remark
                name = info.remarks;
            } else {
                name = info.username;
            }
            prex = [[name transformToPinyin] substringToIndex:1];
            if ([self preIsInAtoZ:prex]) {
                [_indexs objectAddObject:[prex uppercaseString]];
            } else {
                [_indexs addObject:@"#"];
            }
            // to leave
            NSMutableSet *set = [NSMutableSet set];
            for (NSObject *obj in _indexs) {
                [set addObject:obj];
            }
            [_indexs removeAllObjects];
            for (NSObject *obj in set) {
                [_indexs objectAddObject:obj];
            }
            // sort array
            [_indexs sortUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
                NSString *str1 = obj1;
                NSString *str2 = obj2;
                return [str1 compare:str2];
            }];
        }

    }

    return _indexs;
}


- (NSMutableArray *)groupsFriend {
    if (!_groupsFriend) {
        _groupsFriend = [NSMutableArray array];

        NSMutableDictionary *group = nil;
        NSMutableArray *items = nil;
        for (NSString *prex in self.indexs) {
            group = [NSMutableDictionary dictionary];
            items = @[].mutableCopy;
            group[@"title"] = prex;
            for (AccountInfo *info in self.blackManArray) {
                NSString *name = @"";
                if (info.remarks && info.remarks.length > 0) { // use remark
                    name = info.remarks;
                } else {
                    name = info.username;
                }
                NSString *pinY = [name transformToPinyin];
                NSString *pinYPrex = [pinY substringToIndex:1];
                if (![self preIsInAtoZ:pinYPrex]) {
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

- (NSMutableArray *)blackManArray {
    if (!_blackManArray) {
        NSMutableArray *users = [NSMutableArray arrayWithArray:[[UserDBManager sharedManager] blackManList]];
        _blackManArray = users;
    }

    return _blackManArray;
}


#pragma mark - privkey Method

- (BOOL)preIsInAtoZ:(NSString *)str {
    return [@"QWERTYUIOPLKJHGFDSAZXCVBNM" containsString:str] || [[@"QWERTYUIOPLKJHGFDSAZXCVBNM" lowercaseString] containsString:str];
}

@end
