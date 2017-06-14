//
//  UserDetailPage.m
//  Connect
//
//  Created by MoHuilin on 16/7/21.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "UserDetailPage.h"
#import "UserDetailInfoCell.h"
#import "FriendSetPage.h"
#import "UIView+Toast.h"
#import "NetWorkOperationTool.h"
#import "ChatPage.h"
#import "UserDBManager.h"
#import "LMChatSingleTransferViewController.h"
#import "IMService.h"
#import "RecentChatDBManager.h"
#import "MessageDBManager.h"
#import "GroupDBManager.h"
#import "SearchPage.h"
#import "FriendTransactionHisPage.h"
#import "ReconmandChatListPage.h"
#import "UserCommonInfoSetCell.h"
#import "LMDeleteTableViewCell.h"
#import "AppDelegate.h"
#import "StringTool.h"
@interface UserDetailPage ()

@property(nonatomic, strong) AccountInfo *user;
// remark
@property(nonatomic, copy) NSString *updateRemark;


@end

@implementation UserDetailPage

- (instancetype)initWithUser:(AccountInfo *)user {
    if (self = [super init]) {
        self.user = user;
        user.stranger = ![[UserDBManager sharedManager] isFriendByAddress:user.address];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = LMLocalizedString(@"Link Profile", nil);
    __weak __typeof(&*self) weakSelf = self;
    // is friend synchroize basic information
    if (!self.user.stranger) {
        // update synchroize basic information
        [SetGlobalHandler syncUserBaseInfoWithAddress:self.user.address complete:^(AccountInfo *user) {
            weakSelf.user.username = user.username;
            weakSelf.user.avatar = user.avatar;
            [GCDQueue executeInMainQueue:^{
                // send notification
                SendNotify(ConnnectContactDidChangeNotification, user);
                [weakSelf setupCellData];
                [weakSelf.tableView reloadData];
            }];
        }];
    }

    self.tableView.contentInset = UIEdgeInsetsMake(-36, 0, 0, 0);
    self.tableView.backgroundColor = LMBasicBackgroundColor;
}


#pragma mark - set cell

- (void)configTableView {
    [super configTableView];

    [self.tableView registerNib:[UINib nibWithNibName:@"UserDetailInfoCell" bundle:nil] forCellReuseIdentifier:@"UserDetailInfoCellID"];

    [self.tableView registerClass:[NCellButton class] forCellReuseIdentifier:@"NCellButtonID"];
    [self.tableView registerClass:[UserCommonInfoSetCell class] forCellReuseIdentifier:@"UserCommonInfoSetCellID"];
    [self.tableView registerNib:[UINib nibWithNibName:@"LMDeleteTableViewCell" bundle:nil] forCellReuseIdentifier:@"LMDeleteTableViewCellID"];

}

- (void)setupCellData {

    __weak __typeof(&*self) weakSelf = self;

    [self.groups removeAllObjects];
    // zero group
    CellGroup *group = [[CellGroup alloc] init];
    CellItem *userDetailInfo = [[CellItem alloc] init];
    userDetailInfo.type = CellItemTypeUserDetailCell;
    group.items = @[userDetailInfo].copy;
    [self.groups objectAddObject:group];
    userDetailInfo.userInfo = self.user;

    if (self.user.stranger) {
        // not friend
        CellGroup *group2 = [[CellGroup alloc] init];

        CellItem *acceptRequest = [CellItem itemWithTitle:LMLocalizedString(@"Link Accept", nil) type:CellItemTypeButtonCell operation:^{

            [weakSelf acceptRequest];
        }];
        acceptRequest.buttonBackgroudColor = GJCFQuickHexColor(@"00C400");

        group2.items = @[acceptRequest].copy;
        [self.groups objectAddObject:group2];

    } else {
        CellGroup *group2 = [[CellGroup alloc] init];

        CellItem *setAlias = [CellItem itemWithTitle:LMLocalizedString(@"Link Set Remark and Tag", nil) type:CellItemTypeArrow operation:^{
            weakSelf.user.tags = [[UserDBManager sharedManager] getUserTags:weakSelf.user.address];

            FriendSetPage *page = [[FriendSetPage alloc] initWithUser:weakSelf.user];
            page.nickNameChageBlcock = ^(NSString *nickNamme) {
                weakSelf.user.remarks = nickNamme;
                 weakSelf.user.remarks = [StringTool filterStr: weakSelf.user.remarks];
                [weakSelf setupCellData];
                [weakSelf.tableView reloadData];
            };
            [weakSelf.navigationController pushViewController:page animated:YES];

        }];

        CellItem *trasferHistory = [CellItem itemWithTitle:LMLocalizedString(@"Link Tansfer Record", nil) type:CellItemTypeArrow operation:^{
            FriendTransactionHisPage *page = [[FriendTransactionHisPage alloc] initWithFriend:weakSelf.user];
            [weakSelf hidenTabbarWhenPushController:page];
        }];
        
        CellItem *addFavorite = [CellItem itemWithTitle:LMLocalizedString(@"Link Favorite Friend", nil) type:CellItemTypeSwitch operation:nil];
        addFavorite.operationWithInfo = ^(id info) {
            BOOL on = [info boolValue];
            [weakSelf addToOffencontact:on remark:!GJCFStringIsNull(weakSelf.updateRemark) ? weakSelf.updateRemark : weakSelf.user.remarks];
        };
       
        addFavorite.switchIsOn = self.user.isOffenContact;

        CellItem *addBlackList = [CellItem itemWithTitle:LMLocalizedString(@"Link Block", nil) type:CellItemTypeSwitch operation:nil];
        addBlackList.operationWithInfo = ^(id info) {
            [weakSelf addToBlackList:[info boolValue]];
        };
        addBlackList.switchIsOn = [[UserDBManager sharedManager] userIsInBlackList:self.user.address];
        addBlackList.titleColor = [UIColor blackColor];
        group2.items = @[setAlias, trasferHistory, addFavorite, addBlackList].copy;
        [self.groups objectAddObject:group2];
        CellGroup *group3 = [[CellGroup alloc] init];
        CellItem *deleteUser = [CellItem itemWithTitle:LMLocalizedString(@"Link Delete This Friend", nil) type:CellItemTypeCommonLbale operation:^{
            // delete contact man
            UIAlertController* actionController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            UIAlertAction* deleteAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Link Delete This Friend", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [weakSelf deleteUser];
            }];
            UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
            
            [actionController addAction:deleteAction];
            [actionController addAction:cancelAction];
            [weakSelf presentViewController:actionController animated:YES completion:nil];
        }];
        group3.items = @[deleteUser].copy;
        [self.groups objectAddObject:group3];

    }

}


- (void)deleteUser{
    [MBProgressHUD showLoadingMessageToView:self.view];
    [[IMService instance] deleteFriendWithAddress:self.user.address comlete:^(NSError *error, id data) {
        // delete head cache
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:self.view];
            if (!error) {
                [self.navigationController popToRootViewControllerAnimated:YES];
            } else {
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Network equest failed please try again later", nil) withType:ToastTypeFail showInView:self.view complete:nil];
            }
        }];
    }];
}

#pragma mark - click cell action

/**
 *  join black list
 */
- (void)addToBlackList:(BOOL)isAddToBlackList {
    if (GJCFStringIsNull(self.user.address)) {
        DDLogError(@"数据异常");
        return;
    }
    self.user.isBlackMan = isAddToBlackList;
    if (isAddToBlackList) {
        [SetGlobalHandler addToBlackListWithAddress:self.user.address];
    } else {
        [SetGlobalHandler removeBlackListWithAddress:self.user.address];
    }
}

/**
 *  join common man
 */
- (void)addToOffencontact:(BOOL)isAddOffencontact remark:(NSString *)remark {
    if (GJCFStringIsNull(self.user.address)) {
        DDLogError(@"数据异常");
        return;
    }
    self.user.isOffenContact = isAddOffencontact;
    if (isAddOffencontact) {
        [SetGlobalHandler addToCommonContactListWithAddress:self.user.address remark:remark];
    } else {
        [SetGlobalHandler removeCommonContactListWithAddress:self.user.address remark:remark];
    }
}

- (void)trasferWithMoney:(NSString *)money hashId:(NSString *)hashId {

    NSString *ecdhKey = [KeyHandle getECDHkeyUsePrivkey:[[LKUserCenter shareCenter] currentLoginUser].prikey PublicKey:self.user.pub_key];

    MMMessage *message = [[MessageDBManager sharedManager] createTransactionMessageWithUserInfo:self.user hashId:hashId monney:money];
    // creat session
    [[RecentChatDBManager sharedManager] createNewChatWithIdentifier:self.user.pub_key groupChat:NO lastContentShowType:0 lastContent:[GJGCChatFriendConstans lastContentMessageWithType:message.type textMessage:message.content] ecdhKey:ecdhKey talkName:self.user.username];
    UIViewController *rootViewController = [self.navigationController.viewControllers firstObject];
    [self.navigationController popToRootViewControllerAnimated:NO];
    if ([rootViewController isKindOfClass:[SearchPage class]]) {
        [rootViewController dismissViewControllerAnimated:NO completion:nil];
    }
    // Interface jump
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [[appDelegate shareMainTabController] chatWithFriend:self.user];
    [[IMService instance] asyncSendMessageMessage:message onQueue:nil completion:nil onQueue:nil];
}

/**
 *  accept add request
 */
- (void)acceptRequest {
    [[IMService instance] acceptAddRequestWithAddress:self.user.address source:self.user.source comlete:^(NSError *error, id data) {
        if (error) {
            [GCDQueue executeInMainQueue:^{
                if (error.code == 4) {
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Network The request has expired", nil) withType:ToastTypeFail showInView:self.view complete:nil];
                } else {
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:self.view complete:nil];
                }
            }];
        } else{
            if ([data isEqualToString:self.user.address]) {
                [GCDQueue executeInMainQueue:^{
                    self.user.stranger = NO;
                    [self setupCellData];
                    [self.tableView reloadData];
                }];
            }
        }
    }];
}



#pragma mark - UIAlertViewDelegate


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    __weak __typeof(&*self) weakSelf = self;
    CellGroup *group = self.groups[indexPath.section];
    CellItem *item = group.items[indexPath.row];
    BaseCell *cell;

    if (item.type == CellItemTypeUserDetailCell) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"UserDetailInfoCellID"];
        UserDetailInfoCell *userDetailCell = (UserDetailInfoCell *) cell;
        userDetailCell.switchValueChangeBlock = ^(BOOL on) {
            [weakSelf addToBlackList:on];
        };
        userDetailCell.copyBlock = ^{
            [GCDQueue executeInMainQueue:^{
                [weakSelf.view makeToast:LMLocalizedString(@"Set Copied", nil) duration:0.8 position:CSToastPositionCenter];
            }];
        };
        cell.data = item;
        if (!self.user.stranger) {
            userDetailCell.friendButtonBlock = ^(ButtonType buttonType) {
                [weakSelf detailButtonAction:buttonType];
            };
        }
        return cell;
    } else if (item.type == CellItemTypeButtonCell) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NCellButtonID"];
        cell.data = item;
    } else if (item.type == CellItemTypeArrow) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NCellArrowID"];
        NCellArrow *arrowCell = (NCellArrow *) cell;
        arrowCell.customTitleLabel.text = item.title;
    } else if (item.type == CellItemTypeSwitch) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NCellSwitcwID"];
        NCellSwitch *switchCell = (NCellSwitch *) cell;
        switchCell.switchIsOn = item.switchIsOn;
        switchCell.SwitchValueChangeCallBackBlock = ^(BOOL on) {
            if (item.operationWithInfo) {
                item.operationWithInfo(@(on));
            }
        };
        switchCell.customLable.text = item.title;
        switchCell.customLable.textColor = item.titleColor;
        return cell;
    } else if (item.type == CellItemTypeUserSetAliasCell) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"UserCommonInfoSetCellID"];
        UserCommonInfoSetCell *commonCell = (UserCommonInfoSetCell *) cell;
        commonCell.TextValueChangeBlock = ^(NSString *text) {
            weakSelf.updateRemark = text;

            [GCDQueue executeInMainQueue:^{
                if (text.length) {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Remark change successfull", nil) withType:ToastTypeSuccess showInView:weakSelf.view complete:nil];
                    }];
                } else {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Delete Remark successfully", nil) withType:ToastTypeSuccess showInView:weakSelf.view complete:nil];
                    }];
                }
            }];

            [weakSelf addToOffencontact:weakSelf.user.isOffenContact remark:text];

        };
        cell.data = item;
        return cell;
    } else if (item.type == CellItemTypeCommonLbale) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"LMDeleteTableViewCellID"];
        LMDeleteTableViewCell *deleteCell = (LMDeleteTableViewCell *) cell;
        deleteCell.deleteTable.text = item.title;
        return deleteCell;
    }
    return cell;
}

#pragma mark - action of click

- (void)detailButtonAction:(ButtonType)buttonType {
    switch (buttonType) {
        case ButtonTypeChat:   // message
        {
            UIViewController *rootViewController = [self.navigationController.viewControllers firstObject];
            [self.navigationController popToRootViewControllerAnimated:NO];
            if ([rootViewController isKindOfClass:[SearchPage class]]) {
                [rootViewController dismissViewControllerAnimated:NO completion:nil];
            }
            // inteface jump
            AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
            [[appDelegate shareMainTabController] chatWithFriend:self.user];
        }
            break;
        case ButtonTypeTransfer:  // transfer
        {
            LMChatSingleTransferViewController *transferVc = [[LMChatSingleTransferViewController alloc] init];
            transferVc.didGetTransferMoney = ^(NSString *money, NSString *hashId, NSString *notes) {
                [self trasferWithMoney:money hashId:hashId];
            };
            AccountInfo *info = [[UserDBManager sharedManager] getUserByPublickey:self.user.pub_key];
            transferVc.info = info;

            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:transferVc];
            [self presentViewController:nav animated:YES completion:nil];

        }
            break;
        case ButtonTypeShare:  // share
        {
            ReconmandChatListPage *page = [[ReconmandChatListPage alloc] initWithRecommandContact:self.user];
            [self presentViewController:[[UINavigationController alloc] initWithRootViewController:page] animated:YES completion:nil];
        }
            break;
        default:
            break;
    }


}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CellGroup *group = self.groups[indexPath.section];
    CellItem *item = group.items[indexPath.row];

    if (item.type == CellItemTypeUserDetailCell) {
        return 260;
    } else if (item.type == CellItemTypeButtonCell) {
        return AUTO_HEIGHT(100);
    }
    return 50;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 0;
    } else if (section == 1) {
        if (self.user.stranger) {
            return AUTO_HEIGHT(168);
        } else {
            return 0.5;
        }
    } else if (section == 2) {
        if (!self.user.stranger) {
            return 0.5;
        }
    }
    return 0;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {

    if (section == 1 || section == 2) {
        if (!self.user.stranger) {
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, DEVICE_SIZE.width, 1)];
            view.backgroundColor = LMBasicBackgroundColor;
            return nil;
        }
    }
    return nil;
}

@end
