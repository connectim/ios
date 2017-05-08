//
//  GestureOpneOrClosePage.m
//  Connect
//
//  Created by MoHuilin on 16/7/30.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "GestureOpneOrClosePage.h"
#import "GestureSetPage.h"

@implementation GestureOpneOrClosePage

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self setupCellData];

    [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = LMLocalizedString(@"Set Pattern Password", nil);

    self.view.backgroundColor = XCColor(241, 241, 241);

}

- (void)configTableView {

    self.tableView.separatorColor = self.tableView.backgroundColor;

    [self.tableView registerClass:[NCellSwitch class] forCellReuseIdentifier:@"NCellSwitcwID"];
    [self.tableView registerClass:[NCellArrow class] forCellReuseIdentifier:@"NCellArrowID"];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"SystemCellID"];


    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"setting_gesture_password"]];
    [self.view addSubview:imageView];
    imageView.frame = AUTO_RECT(0, 0, 750, 508);
    imageView.contentMode = UIViewContentModeCenter;

    self.tableView.tableHeaderView = imageView;

}


- (void)setupCellData {


    [self.groups removeAllObjects];

    __weak __typeof(&*self) weakSelf = self;


    // zero group
    CellGroup *group0 = [[CellGroup alloc] init];

    group0.footTitle = LMLocalizedString(@"Set Patten can prevent access data required when entering", nil);

    CellItem *lockGesture = [CellItem itemWithTitle:LMLocalizedString(@"Set Pattern Password", nil) type:CellItemTypeSwitch operation:nil];
    lockGesture.operationWithInfo = ^(id userInfo) {

        if ([userInfo boolValue]) { // Need to open the gesture password
            GestureSetPage *page = [[GestureSetPage alloc] init];
            [weakSelf hidenTabbarWhenPushController:page];
        } else { // Need to close the gesture password
            GestureSetPage *page = [[GestureSetPage alloc] initWithAction:GestureActionTypeCancel];
            [weakSelf hidenTabbarWhenPushController:page];
        }

    };

    if ([[MMAppSetting sharedSetting] haveGesturePass]) {
        lockGesture.switchIsOn = YES;
        CellItem *changeGesture = [CellItem itemWithTitle:LMLocalizedString(@"Set Change Pattern", nil) type:CellItemTypeArrow operation:^{
            GestureSetPage *page = [[GestureSetPage alloc] initWithAction:GestureActionTypeChange];
            page.isChangeGesture = YES;
            [weakSelf hidenTabbarWhenPushController:page];
        }];
        group0.items = @[lockGesture, changeGesture];

    } else {
        lockGesture.switchIsOn = NO;
        group0.items = @[lockGesture];
    }


    [self.groups objectAddObject:group0];


}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {


    CellGroup *group = self.groups[indexPath.section];
    CellItem *item = group.items[indexPath.row];
    BaseCell *cell;
    if (item.type == CellItemTypeSwitch) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NCellSwitcwID"];
        NCellSwitch *switchCell = (NCellSwitch *) cell;
        switchCell.switchIsOn = item.switchIsOn;
        switchCell.SwitchValueChangeCallBackBlock = ^(BOOL on) {
            item.operationWithInfo ? item.operationWithInfo(@(on)) : nil;
        };

        switchCell.customLable.text = item.title;
        return cell;
    } else if (item.type == CellItemTypeArrow) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NCellArrowID"];
        NCellArrow *arrowCell = (NCellArrow *) cell;
        arrowCell.customTitleLabel.text = item.title;
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"SystemCellID"];
    }
    return cell;
}


- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    CellGroup *group = self.groups[section];

    return group.footTitle;

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return AUTO_HEIGHT(111);
}


@end
