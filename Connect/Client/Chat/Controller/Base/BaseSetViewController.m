//
//  BaseSetViewController.m
//  Connect
//
//  Created by MoHuilin on 16/7/14.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseSetViewController.h"


@implementation BaseSetViewController

- (void)setupCellData {

}

- (void)hidenTabbarWhenPushController:(UIViewController *)page {
    page.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:page animated:YES];
}

- (void)configTableView {

    self.tableView.separatorColor = self.tableView.backgroundColor;

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"SystemCellID"];
    [self.tableView registerClass:[NCellSwitch class] forCellReuseIdentifier:@"NCellSwitcwID"];
    [self.tableView registerClass:[GroupMembersCell class] forCellReuseIdentifier:@"GroupMembersCellID"];
    [self.tableView registerClass:[NCellTextField class] forCellReuseIdentifier:@"NCellTextFieldID"];

    [self.tableView registerNib:[UINib nibWithNibName:@"MyInfoCell" bundle:nil] forCellReuseIdentifier:@"MyInfoCellID"];

    [self.tableView registerNib:[UINib nibWithNibName:@"NCellValue1" bundle:nil] forCellReuseIdentifier:@"NCellValue1ID"];

    [self.tableView registerNib:[UINib nibWithNibName:@"SetAvatarCell" bundle:nil] forCellReuseIdentifier:@"SetAvatarCellID"];

    [self.tableView registerClass:[NCellArrow class] forCellReuseIdentifier:@"NCellArrowID"];

    [self.tableView registerClass:[MainSetLogoutCell class] forCellReuseIdentifier:@"MainSetLogoutCellID"];

    [self.tableView registerNib:[UINib nibWithNibName:@"NCellImageValue1" bundle:nil] forCellReuseIdentifier:@"NCellImageValue1ID"];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupCellData];

    [self.view addSubview:self.tableView];


    [self configTableView];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark -UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.groups.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    CellGroup *group = self.groups[section];
    return group.items.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    CellGroup *group = self.groups[section];
    return group.headTitle;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    CellGroup *group = self.groups[section];
    return group.footTitle;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CellGroup *group = self.groups[indexPath.section];
    CellItem *item = group.items[indexPath.row];
    if (item.type == CellItemTypeGroupMemberCell) {
//        BaseCell *cell = [tableView ceell:indexPath];
//        
//        return cell.height;

        return 100;
    }
    if (item.type == CellItemTypeMyInfoCell) {
        return 115;
    }

    if (item.type == CellItemTypeLogoutCell) {
        return 50;
    }

    if (item.type == CellItemTypeSetAvatarCell) {
        return 80;
    }

    return AUTO_HEIGHT(111);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CellGroup *group = self.groups[indexPath.section];
    CellItem *item = group.items[indexPath.row];
    if (item.operation) {
        item.operation();
    }
}
//设置section的字体

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return AUTO_HEIGHT(40);
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *tableViewHeaderFooterView = (UITableViewHeaderFooterView *) view;
        tableViewHeaderFooterView.textLabel.text = [tableViewHeaderFooterView.textLabel.text capitalizedString];
        tableViewHeaderFooterView.textLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
    }
}

//- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
//{
//    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
//        UITableViewHeaderFooterView* footer = (UITableViewHeaderFooterView*)view;
//        footer.textLabel.text = [footer.textLabel.text capitalizedString];
//        footer.textLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
//    }
//}
#pragma mark -getter

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}

- (NSMutableArray *)groups {
    if (!_groups) {
        _groups = @[].mutableCopy;
    }
    return _groups;
}

@end
