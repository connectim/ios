//
//  InviteUserPage.m
//  Connect
//
//  Created by MoHuilin on 16/7/21.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "InviteUserPage.h"
#import "UserDetailInfoCell.h"
#import "IMService.h"
#import "LMBitAddressViewController.h"
#import "UIView+Toast.h"
#import "LMRecommandFriendManager.h"
#import "StringTool.h"


@interface InviteUserPage ()

@property(nonatomic, strong) AccountInfo *user;
//invite lable
@property(nonatomic, copy) NSString *inviteMessage;



@end

@implementation InviteUserPage

- (instancetype)initWithUser:(AccountInfo *)user {

    if (self = [super init]) {
        self.user = user;
        self.inviteMessage = [NSString stringWithFormat:LMLocalizedString(@"Link Hello I am", nil), [[LKUserCenter shareCenter] currentLoginUser].username];
    }

    return self;

}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LMLocalizedString(@"Link Profile", nil);
    self.tableView.contentInset = UIEdgeInsetsMake(-36, 0, 0, 0);
}

- (void)addfriendAction {
    __weak __typeof(&*self) weakSelf = self;
    if (self.sourceType == 0) {
        self.sourceType = self.user.source;
    }
    self.inviteMessage =  [StringTool filterStr:self.inviteMessage];
    [[IMService instance] addNewFiendWithInviteUser:self.user tips:self.inviteMessage source:self.sourceType comlete:^(NSError *erro, id data) {
        if (!erro) {
            NSString *adress = (NSString *)data;
            if (![adress isEqualToString:weakSelf.user.address]) {
                return;
            }
            [GCDQueue executeInMainQueue:^{
                // data delete
                if (weakSelf.sourceType == UserSourceTypeRecommend) {
                    weakSelf.user.recommandStatus = 2;
                    [[LMRecommandFriendManager sharedManager] updateRecommandFriendStatus:2 withAddress:weakSelf.user.address];
                }
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Add Successful", nil) withType:ToastTypeSuccess showInView:weakSelf.view complete:^{
                    [weakSelf.navigationController popViewControllerAnimated:YES];
                }];
                SendNotify(ConnnectSendAddRequestSuccennNotification, weakSelf.user);
            }];
        } else {
            if (erro.code == 1) {
                //owner add owner
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet You are a narcissism", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                }];
            } else {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeCommon showInView:weakSelf.view complete:nil];
                }];
            }
        }
    }];

}

- (void)configTableView {
    [super configTableView];

    [self.tableView registerNib:[UINib nibWithNibName:@"UserDetailInfoCell" bundle:nil] forCellReuseIdentifier:@"UserDetailInfoCellID"];

    [self.tableView registerClass:[NCellButton class] forCellReuseIdentifier:@"NCellButtonID"];
}

- (void)setupCellData {


    __weak __typeof(&*self) weakSelf = self;
    //zero group
    CellGroup *group = [[CellGroup alloc] init];
    CellItem *userDetailInfo = [[CellItem alloc] init];
    userDetailInfo.userInfo = self.user;
    userDetailInfo.type = CellItemTypeUserDetailCell;
    group.items = @[userDetailInfo].copy;
    [self.groups objectAddObject:group];


    CellGroup *group2 = [[CellGroup alloc] init];

    CellItem *chat = [CellItem itemWithTitle:LMLocalizedString(@"Link Add to Contacts", nil) type:CellItemTypeButtonCell operation:^{

        [weakSelf allertController];

    }];


    chat.buttonBackgroudColor = GJCFQuickHexColor(@"00C400");

    group2.items = @[chat].copy;
    [self.groups objectAddObject:group2];


    CellGroup *group3 = [[CellGroup alloc] init];


    CellItem *transfer = [CellItem itemWithTitle:LMLocalizedString(@"Wallet Transfer", nil) type:CellItemTypeButtonCell operation:^{
        [weakSelf transferToAddress:weakSelf.user];
    }];
    transfer.buttonBackgroudColor = GJCFQuickHexColor(@"5554D5");

    group3.items = @[transfer].copy;
    [self.groups objectAddObject:group3];

}

#pragma mark - 弹出弹框的提示

- (void)allertController {
    __weak typeof(self) weakSelf = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LMLocalizedString(@"Link Send friend request", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *_Nonnull textField) {

        textField.text = [NSString stringWithFormat:LMLocalizedString(@"Link Hello I am", nil), [[LKUserCenter shareCenter] currentLoginUser].username];
        [textField addTarget:self action:@selector(tectFieldChange:) forControlEvents:UIControlEventEditingChanged];

        weakSelf.inviteMessage = textField.text;
    }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Link Send", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        [weakSelf addfriendAction];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:nil];

    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [weakSelf presentViewController:alertController animated:YES completion:nil];


}

- (void)tectFieldChange:(UITextField *)textField {
    self.inviteMessage = textField.text;
}

- (void)transferToAddress:(AccountInfo *)userInfo {
    LMBitAddressViewController *page = [[LMBitAddressViewController alloc] init];
    page.address = userInfo.address;
    [self.navigationController pushViewController:page animated:YES];
}


#pragma mark - UIAlertViewDelegate


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    __weak __typeof(&*self) weakSelf = self;
    CellGroup *group = self.groups[indexPath.section];
    CellItem *item = group.items[indexPath.row];
    BaseCell *cell;
    if (item.type == CellItemTypeUserDetailCell) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"UserDetailInfoCellID"];
        UserDetailInfoCell *detailCell = (UserDetailInfoCell *) cell;
        detailCell.TextValueChangeBlock = ^(NSString *text) {
            weakSelf.inviteMessage = text;
        };
        detailCell.inviteBlock = ^(NSString *message) {
            weakSelf.inviteMessage = message;
            [weakSelf addfriendAction];
        };
        detailCell.copyBlock = ^{
            [GCDQueue executeInMainQueue:^{
                [weakSelf.view makeToast:LMLocalizedString(@"Set Copied", nil) duration:0.8 position:CSToastPositionCenter];
            }];
        };
        detailCell.data = item;
        return cell;
    } else if (item.type == CellItemTypeButtonCell) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NCellButtonID"];
        cell.data = item;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CellGroup *group = self.groups[indexPath.section];
    CellItem *item = group.items[indexPath.row];

    if (item.type == CellItemTypeUserDetailCell) {
        return 260;
    } else if (item.type == CellItemTypeButtonCell) {
        return AUTO_HEIGHT(100);
    }
    return AUTO_HEIGHT(42);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 0;
    } else if (section == 1) {
        return AUTO_HEIGHT(168);
    } else {
        return AUTO_HEIGHT(10);
    }
    return 0;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}

@end
