//
//  CommonSetPage.m
//  Connect
//
//  Created by MoHuilin on 16/7/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "CommonSetPage.h"
#import "MessageDBManager.h"
#import "SetCurrencyPage.h"
#import "LMSetLanguagePage.h"
#import "RecentChatDBManager.h"

@interface CommonSetPage ()

@end

@implementation CommonSetPage

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LMLocalizedString(@"Set General", nil);
}

- (void)configTableView {

    self.tableView.separatorColor = self.tableView.backgroundColor;
    [self.tableView registerClass:[NCellLabel class] forCellReuseIdentifier:@"NCellLabelID"];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"SystemCellID"];
    [self.tableView registerClass:[NCellSwitch class] forCellReuseIdentifier:@"NCellSwitcwID"];
    [self.tableView registerClass:[NCellArrow class] forCellReuseIdentifier:@"NCellArrowID"];
}


- (void)setupCellData {

    [self.groups removeAllObjects];

    __weak __typeof(&*self) weakSelf = self;

    // language group
    CellGroup *languageGroup = [[CellGroup alloc] init];
    CellItem *language = [CellItem itemWithTitle:LMLocalizedString(@"Set Language", nil) type:CellItemTypeArrow operation:^{
        LMSetLanguagePage *page = [[LMSetLanguagePage alloc] init];
        [weakSelf hidenTabbarWhenPushController:page];
    }];
    languageGroup.items = @[language].copy;
    [self.groups objectAddObject:languageGroup];


    // zero group
    CellGroup *group = [[CellGroup alloc] init];
    CellItem *currency = [CellItem itemWithTitle:LMLocalizedString(@"Set Currency", nil) type:CellItemTypeArrow operation:^{
        SetCurrencyPage *page = [[SetCurrencyPage alloc] init];
        [weakSelf hidenTabbarWhenPushController:page];
    }];
    group.items = @[currency].copy;
    [self.groups objectAddObject:group];
    // first group
    CellGroup *group1 = [[CellGroup alloc] init];
    group1.headTitle = LMLocalizedString(@"Chat New message notification", nil);
    group1.footTitle = LMLocalizedString(@"Set Enable or disable Connect Notification via", nil);


    CellItem *voiceNoti = [CellItem itemWithTitle:LMLocalizedString(@"Set Sound", nil) type:CellItemTypeSwitch operation:nil];
    voiceNoti.switchIsOn = [[MMAppSetting sharedSetting] canVoiceNoti];
    voiceNoti.operationWithInfo = ^(id userInfo) {
        if ([userInfo boolValue]) {
            [[MMAppSetting sharedSetting] openVoiceNoti];
        } else {
            [[MMAppSetting sharedSetting] closeVoiceNoti];

            if (![[MMAppSetting sharedSetting] canVibrateNoti]) {
                [GCDQueue executeInMainQueue:^{
                    [weakSelf setupCellData];
                    [weakSelf.tableView reloadData];
                }];
            }

        }
    };

    CellItem *vibrateNoti = [CellItem itemWithTitle:LMLocalizedString(@"Set Vibrate", nil) type:CellItemTypeSwitch operation:nil];
    vibrateNoti.switchIsOn = [[MMAppSetting sharedSetting] canVibrateNoti];
    vibrateNoti.operationWithInfo = ^(id userInfo) {
        if ([userInfo boolValue]) {
            [[MMAppSetting sharedSetting] openVibrateNoti];
        } else {
            [[MMAppSetting sharedSetting] closeVibrateNoti];
            if (![[MMAppSetting sharedSetting] canVoiceNoti]) {
                [GCDQueue executeInMainQueue:^{
                    [weakSelf setupCellData];
                    [weakSelf.tableView reloadData];
                }];
            }
        }
    };

    group1.items = @[voiceNoti, vibrateNoti].copy;
    [self.groups objectAddObject:group1];

    // second group
    CellGroup *group2 = [[CellGroup alloc] init];
    CellItem *clearAllHistory = [CellItem itemWithTitle:LMLocalizedString(@"Link Clear All Chat History", nil) type:CellItemTypeLabel operation:^{

        UIAlertController *actionController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Link Clear All Chat History", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
            [weakSelf clearAllChatHistory];

        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:nil];

        [actionController addAction:deleteAction];
        [actionController addAction:cancelAction];
        [weakSelf presentViewController:actionController animated:YES completion:nil];


    }];
    clearAllHistory.textAlignment = NSTextAlignmentCenter;
    clearAllHistory.titleColor = [UIColor redColor];
    group2.items = @[clearAllHistory].copy;
    [self.groups objectAddObject:group2];


}

// clear records
- (void)clearAllChatHistory {

    [ChatMessageFileManager deleteAllMessageFile];
    [[MessageDBManager sharedManager] deleteAllMessages];

    //remeve all chat last message
    [[RecentChatDBManager sharedManager] removeAllLastContent];
    
    [GCDQueue executeInMainQueue:^{
        SendNotify(DeleteMessageHistoryNotification, nil);
    }];
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
    } else if (item.type == CellItemTypeNone) {

        cell = [tableView dequeueReusableCellWithIdentifier:@"SystemCellID"];

        cell.textLabel.text = item.title;
        cell.detailTextLabel.text = item.subTitle;
        cell.textLabel.font = [UIFont systemFontOfSize:FONT_SIZE(32)];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:FONT_SIZE(32)];
    } else if (item.type == CellItemTypeLabel) {

        cell = [tableView dequeueReusableCellWithIdentifier:@"NCellLabelID"];
        NCellLabel *labelCell = (NCellLabel *) cell;
        labelCell.textAlignment = item.textAlignment;
        labelCell.titleLabel.text = item.title;
        labelCell.titleLabel.textColor = item.titleColor;
    } else if (item.type == CellItemTypeArrow) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NCellArrowID"];
        NCellArrow *arrowCell = (NCellArrow *) cell;
        arrowCell.customTitleLabel.text = item.title;
    }
    return cell;
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
    return AUTO_HEIGHT(111);
}
@end
