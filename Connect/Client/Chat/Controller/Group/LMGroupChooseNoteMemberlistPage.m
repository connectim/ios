//
//  LMGroupChooseNoteMemberlistPage.m
//  Connect
//
//  Created by MoHuilin on 2017/3/10.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMGroupChooseNoteMemberlistPage.h"
#import "NCellHeader.h"
#import "NSString+Pinyin.h"
#import "ConnectTableHeaderView.h"
#import "GroupMemberListCell.h"

@interface LMGroupChooseNoteMemberlistPage ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic ,strong) NSMutableArray *groupMembers;
@property (nonatomic ,strong) UITableView *tableView;

@property(nonatomic, strong) NSMutableArray *groups;
@property(nonatomic, strong) NSMutableArray *indexs;

@end

@implementation LMGroupChooseNoteMemberlistPage

- (instancetype)initWithMembers:(NSArray *)members {
    if (self = [super init]) {
        self.groupMembers = [NSMutableArray arrayWithArray:members];
        for (AccountInfo *user in self.groupMembers) {
            if ([user.address isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                [self.groupMembers removeObject:user];
                break;
            }
        }
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.tableView];
    [self configTableView];
    [self addCloseBarItem];
    
    self.title = LMLocalizedString(@"Chat Choose Members", nil);
}

- (void)closeBtnClicked:(id)sender{
    if (self.ChooseGroupMemberCallBack) {
        self.ChooseGroupMemberCallBack(nil);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
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
    GroupMemberListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GroupMemberListCellID" forIndexPath:indexPath];
    AccountInfo *contact = group.items[indexPath.row];
    cell.data = contact;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CellGroup *group = self.groups[indexPath.section];
    AccountInfo *contact = group.items[indexPath.row];
    if (self.ChooseGroupMemberCallBack) {
        self.ChooseGroupMemberCallBack(contact);
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}



- (void)configTableView {
    
    [self.tableView registerNib:[UINib nibWithNibName:@"GroupMemberListCell" bundle:nil] forCellReuseIdentifier:@"GroupMemberListCellID"];
    [self.tableView registerClass:[ConnectTableHeaderView class] forHeaderFooterViewReuseIdentifier:@"ConnectTableHeaderViewID"];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = AUTO_HEIGHT(111);
    self.tableView.sectionIndexColor = [UIColor lightGrayColor];
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}


- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    }
    return _tableView;
}

- (NSMutableArray *)groups {
    if (self.groupMembers.count <= 0) {
        return nil;
    }
    if (!_groups) {
        _groups = [NSMutableArray array];
        NSMutableArray *items = nil;
        
        for (NSString *prex in self.indexs) {
            CellGroup *group = [[CellGroup alloc] init];
            group.headTitle = prex;
            items = [NSMutableArray array];
            for (AccountInfo *contact in self.groupMembers) {
                NSString *name = contact.groupShowName;
                NSString *namePiny = [[name transformToPinyin] uppercaseString];
                if (namePiny.length <= 0) {
                    continue;
                }
                NSString *pinYPrex = [namePiny substringToIndex:1];
                if (![pinYPrex preIsInAtoZ]) {
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
    if (self.groupMembers.count <= 0) {
        return nil;
    }
    if (!_indexs) {
        _indexs = [NSMutableArray array];
        for (AccountInfo *contact in self.groupMembers) {
            NSString *prex = @"";
            NSString *name = contact.groupShowName;
            if (name.length <= 0) {
                continue;
            }
            prex = [[name transformToPinyin] substringToIndex:1];
            if ([prex preIsInAtoZ]) {
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


@end
