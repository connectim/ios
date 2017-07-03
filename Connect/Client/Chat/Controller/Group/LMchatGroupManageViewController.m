//
//  LMchatGroupManageViewController.m
//  Connect
//
//  Created by bitmain on 2016/12/27.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import "LMchatGroupManageViewController.h"
#import "LMGroupIntroductionViewController.h"
#import "GroupMembersListViewController.h"
#import "GroupDBManager.h"
#import "NetWorkOperationTool.h"


@interface LMchatGroupManageViewController ()

@property(nonatomic, strong) CellItem *publicInvite;

@end

@implementation LMchatGroupManageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.titleName) {
        self.title = self.titleName;
    }
    [self reloadMainQueueData];

}

- (void)reloadMainQueueData {
    __weak typeof(self) weakSelf = self;
    [GCDQueue executeInMainQueue:^{
        [weakSelf setupData];
        [weakSelf.tableView reloadData];
    }];
}

- (void)setupData {
    __weak typeof(self) weakSelf = self;

    CellItem *publicInvite = [CellItem itemWithTitle:LMLocalizedString(@"Link Whether Public", nil) type:CellItemTypeSwitch operation:nil];
    self.publicInvite = publicInvite;
    publicInvite.switchIsOn = [[GroupDBManager sharedManager] isGroupPublic:weakSelf.talkModel.chatIdendifier];
    publicInvite.operationWithInfo = ^(id userInfo) {
        BOOL flag = [userInfo boolValue];
        [weakSelf changeGroupPublic:flag];
    };
    CellGroup *group0 = [[CellGroup alloc] init];
    group0.items = @[publicInvite].copy;
    group0.footTitle = LMLocalizedString(@"Link the group member can see the QR", nil);
    [weakSelf.groups objectAddObject:group0];

    CellItem *groupIntroduction = [CellItem itemWithTitle:LMLocalizedString(@"Link Group Introduction", nil) type:CellItemTypeArrow operation:^{
        LMGroupIntroductionViewController *introductionVc = [[LMGroupIntroductionViewController alloc] initWithNibName:@"LMGroupIntroductionViewController" bundle:nil];
        introductionVc.titleName = LMLocalizedString(@"Link Group Introduction", nil);
        introductionVc.talkModel = weakSelf.talkModel;
        [weakSelf.navigationController pushViewController:introductionVc animated:YES];
    }];
    CellItem *ownershipTransfer = [CellItem itemWithTitle:LMLocalizedString(@"Link Ownership Transfer", nil) type:CellItemTypeArrow operation:^{
        [weakSelf ownershipTransferMethod];
    }];

    CellGroup *group1 = [[CellGroup alloc] init];
    group1.items = @[groupIntroduction, ownershipTransfer].copy;
    [weakSelf.groups objectAddObject:group1];

}

#pragma mark -ownershipTransfer

- (void)ownershipTransferMethod {
    __weak typeof(self) weakSelf = self;
    if (GJCFStringIsNull(weakSelf.talkModel.chatIdendifier) || GJCFStringIsNull(weakSelf.talkModel.group_ecdhKey)) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Unknown error", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
        }];
        return;
    }

    NSMutableArray *temArray = [weakSelf.talkModel.chatGroupInfo.groupMembers mutableCopy];
    for (AccountInfo *contract in temArray) {
        if ([contract.address isEqualToString:weakSelf.groupMasterInfo.address]) {
            [temArray removeObject:contract];
            break;
        }
    }
    GroupMembersListViewController *page1 = [[GroupMembersListViewController alloc] initWithMemberInfos:temArray groupIdentifer:weakSelf.talkModel.chatIdendifier groupEchhKey:weakSelf.talkModel.group_ecdhKey];
    page1.fromSource = FromSourceTypeGroupManager;
    page1.talkInfo = self.talkModel;
    page1.SuccessAttornAdminCallback = ^(NSString *address) {
        if (weakSelf.groupAdminChangeCallBack) {
            weakSelf.groupAdminChangeCallBack(address);
        }
        [weakSelf.navigationController popViewControllerAnimated:YES];
    };

    [self.navigationController pushViewController:page1 animated:YES];
}

#pragma mark - tableview datasource

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
        cell.textLabel.text = item.title;
        return cell;
    } else if (item.type == CellItemTypeArrow) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NCellArrowID"];
        NCellArrow *arrowCell = (NCellArrow *) cell;
        arrowCell.customTitleLabel.text = item.title;
    }
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    CellGroup *group = self.groups[section];
    return group.footTitle;
}

#pragma mark - tableview delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return 10;
    }
    return 10;
}

- (void)dealloc {
    [self.tableView removeFromSuperview];
    self.tableView = nil;
    self.talkModel = nil;

}

- (void)changeGroupPublic:(BOOL)isPublic {

    GroupSetting *groupSet = [GroupSetting new];
    groupSet.identifier = self.talkModel.chatGroupInfo.groupIdentifer;
    groupSet.summary = GJCFStringIsNull(self.talkModel.chatGroupInfo.summary) ? self.talkModel.chatGroupInfo.groupName : self.talkModel.chatGroupInfo.summary;
    groupSet.public_p = isPublic;
    groupSet.reviewed = YES;

    [NetWorkOperationTool POSTWithUrlString:GroupSettingUrl postProtoData:groupSet.data complete:^(id response) {
        HttpResponse *hReponse = (HttpResponse *) response;
        if (hReponse.code == successCode) {
            if (isPublic) {
                [[GroupDBManager sharedManager] setGroupNeedPublic:self.talkModel.chatIdendifier];
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Open Successful", nil) withType:ToastTypeSuccess showInView:self.view complete:nil];
                }];

                if (self.switchChangeBlock) {
                    self.switchChangeBlock(isPublic);
                }
            } else {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Close Successful", nil) withType:ToastTypeSuccess showInView:self.view complete:nil];
                }];
                [[GroupDBManager sharedManager] setGroupNeedNotPublic:self.talkModel.chatIdendifier];

                if (self.switchChangeBlock) {
                    self.switchChangeBlock(isPublic);
                }
            }
        } else {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:hReponse.message withType:ToastTypeFail showInView:self.view complete:nil];
            }];
        }
    }                                  fail:^(NSError *error) {
        [GCDQueue executeInMainQueue:^{
            self.publicInvite.switchIsOn = !self.publicInvite.switchIsOn;
            [self.tableView reloadData];
            [MBProgressHUD showToastwithText:[LMErrorCodeTool showToastErrorType:ToastErrorTypeContact withErrorCode:error.code withUrl:GroupSettingUrl] withType:ToastTypeFail showInView:self.view complete:nil];
        }];
    }];
}

@end
