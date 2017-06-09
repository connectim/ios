//
//  PrivacyPage.m
//  Connect
//
//  Created by MoHuilin on 16/7/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "PrivacyPage.h"
#import "SyscContactCell.h"
#import "BlackListPage.h"
#import "KTSContactsManager.h"
#import "PhoneContactInfo.h"


@interface PrivacyPage ()

@end

@implementation PrivacyPage

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = LMLocalizedString(@"Set Privacy", nil);


    __weak __typeof(&*self) weakSelf = self;
    if (![[MMAppSetting sharedSetting] isHaveSyncPrivacy]) {
        // Synchronize privacy settings
        [SetGlobalHandler syncPrivacyComplete:^{
            [GCDQueue executeInMainQueue:^{
                [weakSelf setupCellData];
                [weakSelf.tableView reloadData];
            }];
        }];
    }
}
- (void)configTableView {

    self.tableView.separatorColor = self.tableView.backgroundColor;
    
    [self.tableView registerClass:[NCellLabel class] forCellReuseIdentifier:@"NCellLabelID"];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"SystemCellID"];
    [self.tableView registerClass:[NCellSwitch class] forCellReuseIdentifier:@"NCellSwitcwID"];
    [self.tableView registerClass:[NCellArrow class] forCellReuseIdentifier:@"NCellArrowID"];

    [self.tableView registerNib:[UINib nibWithNibName:@"SyscContactCell" bundle:nil] forCellReuseIdentifier:@"SyscContactCellID"];

}


- (void)setupCellData {

    [self.groups removeAllObjects];
    __weak __typeof(&*self) weakSelf = self;
    // zero group
    CellGroup *group0 = [[CellGroup alloc] init];

    group0.footTitle = LMLocalizedString(@"Link HASH match contact firends The server does not keep", nil);
    CellItem *asycContact = [CellItem itemWithTitle:nil type:CellItemTypeContactSyscCell operation:nil];
    asycContact.title = [NSString stringWithFormat:@"%f", [[MMAppSetting sharedSetting] getLastSyncContactTime]];
    asycContact.icon = @"set_privcy_refresh";
    group0.items = @[asycContact].copy;
    [self.groups objectAddObject:group0];


    // second group
    CellGroup *group1 = [[CellGroup alloc] init];
    
    CellItem *searchByPhoto = [CellItem itemWithTitle:LMLocalizedString(@"Link Find me by phone number", nil) type:CellItemTypeSwitch operation:nil];
    searchByPhoto.switchIsOn = [[MMAppSetting sharedSetting] isAllowPhone];
    searchByPhoto.operationWithInfo = ^(id userInfo) {
        [SetGlobalHandler privacySetAllowSearchAddress:[[MMAppSetting sharedSetting] isAllowAddress] AllowSearchPhone:[userInfo boolValue] needVerify:[[MMAppSetting sharedSetting] isAllowVerfiy] syncPhonebook:[[MMAppSetting sharedSetting] isAutoSysBook] findMe:[[MMAppSetting sharedSetting] isAllowRecomand]];
    };

    CellItem *searchByAddress = [CellItem itemWithTitle:LMLocalizedString(@"Link Find me by bitcoin address", nil) type:CellItemTypeSwitch operation:nil];
    searchByAddress.switchIsOn = [[MMAppSetting sharedSetting] isAllowAddress];
    searchByAddress.operationWithInfo = ^(id userInfo) {
        [SetGlobalHandler privacySetAllowSearchAddress:[userInfo boolValue] AllowSearchPhone:[[MMAppSetting sharedSetting] isAllowPhone] needVerify:[[MMAppSetting sharedSetting] isAllowVerfiy] syncPhonebook:[[MMAppSetting sharedSetting] isAutoSysBook] findMe:[[MMAppSetting sharedSetting] isAllowRecomand]];
    };

    CellItem *recommendFindMe = [CellItem itemWithTitle:LMLocalizedString(@"Chat Find me from the recommendation", nil) type:CellItemTypeSwitch operation:nil];
    recommendFindMe.switchIsOn = [[MMAppSetting sharedSetting] isAllowRecomand];
    recommendFindMe.operationWithInfo = ^(id userInfo) {
        [SetGlobalHandler privacySetAllowSearchAddress:[[MMAppSetting sharedSetting] isAllowAddress] AllowSearchPhone:[[MMAppSetting sharedSetting] isAllowPhone] needVerify:[[MMAppSetting sharedSetting] isAllowVerfiy] syncPhonebook:[[MMAppSetting sharedSetting] isAutoSysBook] findMe:[userInfo boolValue]];

    };

    group1.items = @[searchByPhoto, searchByAddress, recommendFindMe].copy;
    [self.groups objectAddObject:group1];


    // third group
    CellGroup *group3 = [[CellGroup alloc] init];

    CellItem *blackList = [CellItem itemWithTitle:LMLocalizedString(@"Link Black List", nil) type:CellItemTypeArrow operation:^{
        BlackListPage *page = [[BlackListPage alloc] init];

        [weakSelf hidenTabbarWhenPushController:page];
    }];
    group3.items = @[blackList].copy;

    [self.groups objectAddObject:group3];


}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    __weak __typeof(&*self) weakSelf = self;
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
        labelCell.textAlignment = NSTextAlignmentCenter;
        labelCell.textLabel.text = item.title;
    } else if (item.type == CellItemTypeArrow) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NCellArrowID"];
        NCellArrow *arrowCell = (NCellArrow *) cell;
        arrowCell.customTitleLabel.text = item.title;
    } else if (item.type == CellItemTypeContactSyscCell) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"SyscContactCellID"];

        SyscContactCell *sysCell = (SyscContactCell *) cell;
        sysCell.data = item;
        sysCell.SyscContactBlock = ^{

            [[KTSContactsManager sharedManager] importContacts:^(NSArray *contacts, BOOL reject) {

                if (reject) {
                    [GCDQueue executeInGlobalQueue:^{
                        [GCDQueue executeInMainQueue:^{
                            [MBProgressHUD hideHUDForView:weakSelf.view];
                        }];
                       
                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LMLocalizedString(@"Link Address Book Access Denied", nil) message:LMLocalizedString(@"Link access to your Address Book in Settings", nil) preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *okAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common OK", nil) style:UIAlertActionStyleDefault handler:nil];
                        [alertController addAction:okAction];
                        [weakSelf presentViewController:alertController animated:YES completion:nil];
                    }];
                    return;
                }

                NSMutableArray *hashMobiles = [NSMutableArray array];
                NSMutableArray *phoneContacts = [PhoneContactInfo mj_objectArrayWithKeyValuesArray:contacts];
                for (PhoneContactInfo *info in phoneContacts) {
                    for (Phone *phone in info.phones) {
                        NSString *phoneStr = phone.phoneNum;
                        phoneStr = [phoneStr stringByReplacingOccurrencesOfString:@"+" withString:@""];
                        phoneStr = [phoneStr stringByReplacingOccurrencesOfString:@"-" withString:@""];
                        phoneStr = [phoneStr stringByReplacingOccurrencesOfString:@" " withString:@""];
                        if ([phoneStr hasPrefix:[[RegexKit phoneCode] stringValue]]) {
                            phoneStr = [phoneStr substringFromIndex:2];
                        }
                        PhoneInfo *phoneInfo = [[PhoneInfo alloc] init];
                        phoneInfo.code = [[RegexKit phoneCode] intValue];
                        phoneInfo.mobile = [phoneStr hmacSHA512StringWithKey:hmacSHA512Key];
                        [hashMobiles objectAddObject:phoneInfo];
                    }
                }
                [SetGlobalHandler syncPhoneContactWithHashContact:hashMobiles complete:nil];
            }];
            return [[NSDate date] timeIntervalSince1970];
        };

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
