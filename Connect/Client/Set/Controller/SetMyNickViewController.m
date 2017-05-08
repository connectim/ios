//
//  SetMyNickViewController.m
//  Connect
//
//  Created by MoHuilin on 16/7/28.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "SetMyNickViewController.h"
#import "TextFieldRoundCell.h"
#import "Protofile.pbobjc.h"
#import "GroupDBManager.h"
#import "NetWorkOperationTool.h"
#import "StringTool.h"

@interface SetMyNickViewController ()

@property(nonatomic, copy) NSString *updataName;

@end

@implementation SetMyNickViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LMLocalizedString(@"Set Name", nil);
    [self setRightButtonWithTitle:LMLocalizedString(@"Set Save", nil)];
    self.rightBarBtn.enabled = NO;
    // add color
    [self.rightBarBtn setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor greenColor]} forState:UIControlStateNormal];
    [self.rightBarBtn setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor grayColor]} forState:UIControlStateDisabled];
}

- (void)configTableView {

    self.tableView.separatorColor = self.tableView.backgroundColor;

    [self.tableView registerClass:[TextFieldRoundCell class] forCellReuseIdentifier:@"TextFieldRoundCellID"];
}

- (void)rightButtonPressed:(UIButton *)sender {

    __weak __typeof(&*self) weakSelf = self;
    if ([[[LKUserCenter shareCenter] currentLoginUser].username isEqualToString:self.updataName]) {
        return;
    }
    if (GJCFStringIsNull(self.updataName)) {
        return;
    }
    self.updataName = [StringTool filterStr:self.updataName];
    if ([[self.updataName uppercaseString] isEqualToString:@"CONNECT"]) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Login User name can not be Connect", nil) withType:ToastTypeCommon showInView:weakSelf.view complete:nil];
        }];
        return;
    }
    [[LKUserCenter shareCenter] currentLoginUser].username = self.updataName;
    SettingUserInfo *updateUser = [[SettingUserInfo alloc] init];
    updateUser.avatar = [[LKUserCenter shareCenter] currentLoginUser].avatar;
    updateUser.username = [[LKUserCenter shareCenter] currentLoginUser].username;
    [[LKUserCenter shareCenter] updateUserInfo:[[LKUserCenter shareCenter] currentLoginUser]];
    [NetWorkOperationTool POSTWithUrlString:SetUpdataUserInfo postProtoData:updateUser.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *) response;

        if (hResponse.code != successCode) {
            DDLogInfo(@"Server error");
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:hResponse.message withType:ToastTypeFail showInView:weakSelf.view complete:nil];
            }];
            return;
        }

        [weakSelf updateGroupMyNickName];
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Update successful", nil) withType:ToastTypeSuccess showInView:weakSelf.view complete:^{
                [weakSelf.navigationController popViewControllerAnimated:YES];
            }];
        }];
    }                                  fail:^(NSError *error) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Updated failed", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
        }];
    }];
}

- (void)updateGroupMyNickName {
    // update group
    [GCDQueue executeInGlobalQueue:^{
        NSArray *groups = [[GroupDBManager sharedManager] getAllgroups];
        int updateCount = 0;
        for (LMGroupInfo *group in groups) {
            for (AccountInfo *member in group.groupMembers) {
                if ([member.address isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                    // update data
                    [[GroupDBManager sharedManager] updateGroupMembserUsername:self.updataName address:member.address groupId:group.groupIdentifer];
                    updateCount++;
                    break;
                }
            }
        }
        if (updateCount > 0) {
            [GCDQueue executeInMainQueue:^{
                SendNotify(ConnectUpdateMyNickNameNotification, nil);
            }];
        }
    }];
}

- (void)setupCellData {
    // zero group
    CellItem *inputName = [[CellItem alloc] init];
    inputName.type = CellItemTypeRoundTextField;
    inputName.title = [[LKUserCenter shareCenter] currentLoginUser].username;

    CellGroup *group0 = [[CellGroup alloc] init];
    group0.items = @[inputName].copy;
    [self.groups objectAddObject:group0];


}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    __weak __typeof(&*self) weakSelf = self;
    CellGroup *group = self.groups[indexPath.section];
    CellItem *item = group.items[indexPath.row];

    BaseCell *cell;
    if (item.type == CellItemTypeRoundTextField) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"TextFieldRoundCellID"];
        TextFieldRoundCell *textFieldCell = (TextFieldRoundCell *) cell;

        textFieldCell.TextValueChangeBlock = ^(UITextField *textFiled, NSString *text) {
            weakSelf.updataName = text;
            if ([RegexKit nameLengthLimit:text]) {
                [GCDQueue executeInMainQueue:^{
                    weakSelf.rightBarBtn.enabled = YES;
                }];
            } else {
                [GCDQueue executeInMainQueue:^{
                    weakSelf.rightBarBtn.enabled = NO;
                }];
            }
        };

        textFieldCell.text = item.title;
        return cell;
    } else if (item.type == CellItemTypeNone) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"SystemCellID"];
        cell.textLabel.text = LMLocalizedString(@"Set Nothing", nil);
    }

    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    CellGroup *group = self.groups[indexPath.section];
    CellItem *item = group.items[indexPath.row];
    if (item.type == CellItemTypeRoundTextField) {
        if (GJCFSystemiPhone5) {
            return AUTO_HEIGHT(105);
        } else {
            return AUTO_HEIGHT(96);
        }
    }
    return 44;
}


@end
