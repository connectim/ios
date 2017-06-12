//
//  MainSetPage.m
//  Connect
//
//  Created by MoHuilin on 16/5/22.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "MainSetPage.h"
#import "MyInfoPage.h"
#import "AccountAndSafetyPage.h"
#import "AboutViewController.h"
#import "MyAddressQRPage.h"
#import "CommonSetPage.h"
#import "PrivacyPage.h"
#import "IMService.h"
#import "CommonClausePage.h"


@interface MainSetPage () <UITableViewDelegate>

@property(nonatomic, strong) AccountInfo *userInfo;

@end

@implementation MainSetPage
- (instancetype)init {
    if (self = [super init]) {
        self.userInfo = [[LKUserCenter shareCenter] currentLoginUser];
    }
    
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
 
    self.navigationItem.leftBarButtonItems = nil;
    self.userInfo = [[LKUserCenter shareCenter] currentLoginUser];
    self.tableView.contentInset = UIEdgeInsetsMake(-36, 0, 0, 0);
    RegisterNotify(LKUserCenterUserInfoUpdateNotification, @selector(updataUserInfo:));
}

- (void)updataUserInfo:(NSNotification *)note {
    self.userInfo = (AccountInfo *) note.object;
    [self reloadTableView];
}

- (void)dealloc {
    RemoveNofify;
}

- (void)reloadTableView {
    [GCDQueue executeInMainQueue:^{
        [self setupCellData];
        [self.tableView reloadData];
    }];
}


- (void)setupCellData {

    [self.groups removeAllObjects];
    __weak __typeof(&*self) weakSelf = self;
    // zero group
    CellGroup *group = [[CellGroup alloc] init];
    CellItem *myInfoItem = [[CellItem alloc] init];
    myInfoItem.type = CellItemTypeMyInfoCell;
    myInfoItem.userInfo = self.userInfo;

    myInfoItem.operation = ^{
        MyInfoPage *page = [[MyInfoPage alloc] initWithUserInfo:weakSelf.userInfo];
        page.changeIdBlock = ^() {
            [GCDQueue executeInMainQueue:^{
                [weakSelf.tableView reloadData];
            }];
        };
        [weakSelf pushControllerHideBar:page];
    };
    group.items = @[myInfoItem].copy;
    [self.groups objectAddObject:group];

    // first group
    CellItem *accountAndSaft = [CellItem itemWithTitle:LMLocalizedString(@"Set Account security", nil) type:CellItemTypeArrow operation:^{
        AccountAndSafetyPage *page = [[AccountAndSafetyPage alloc] init];

        [weakSelf pushControllerHideBar:page];

    }];
    CellItem *pricy = [CellItem itemWithTitle:LMLocalizedString(@"Set Privacy", nil) type:CellItemTypeArrow operation:^{
        PrivacyPage *page = [[PrivacyPage alloc] init];
        [weakSelf pushControllerHideBar:page];
    }];

    CellItem *common = [CellItem itemWithTitle:LMLocalizedString(@"Set General", nil) type:CellItemTypeArrow operation:^{
        CommonSetPage *page = [[CommonSetPage alloc] init];
        [weakSelf pushControllerHideBar:page];
    }];

    CellGroup *group0 = [[CellGroup alloc] init];
    group0.items = @[accountAndSaft, pricy, common].copy;
    [self.groups objectAddObject:group0];

    // second group
    CellGroup *group1 = [[CellGroup alloc] init];

    CellItem *helpAndSupport = [CellItem itemWithTitle:LMLocalizedString(@"Set Help and feedback", nil) type:CellItemTypeArrow operation:^{
        CommonClausePage *page = [[CommonClausePage alloc] initWithUrl:FAQUrl];
        page.title = LMLocalizedString(@"Set Help and feedback", nil);
        page.sourceType = SourceTypeHelp;
        [weakSelf hidenTabbarWhenPushController:page];
    }];

    CellItem *about = [CellItem itemWithTitle:LMLocalizedString(@"Set About", nil) type:CellItemTypeArrow operation:^{
        AboutViewController *page = [[AboutViewController alloc] init];
        [weakSelf pushControllerHideBar:page];
    }];
    group1.items = @[helpAndSupport, about].copy;
    [self.groups objectAddObject:group1];

    // quit

    CellGroup *group2 = [[CellGroup alloc] init];
    CellItem *logout = [CellItem itemWithTitle:LMLocalizedString(@"Set Log Out", nil) type:CellItemTypeLogoutCell operation:^{

        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:LMLocalizedString(@"Set Logout delete login data still log", nil) preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Set Log Out", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
            [weakSelf logOut];
        }];
        [alertController addAction:cancelAction];
        [alertController addAction:okAction];
        [GCDQueue executeInMainQueue:^{
            [weakSelf presentViewController:alertController animated:YES completion:nil];
        }];
    }];

    group2.items = @[logout].copy;
    [self.groups objectAddObject:group2];


}

- (void)logOut {
    __weak typeof(&*self) weakSelf = self;
#if (TARGET_IPHONE_SIMULATOR)
    // in the case of simulator
    [[LKUserCenter shareCenter] loginOutByServerWithInfo:nil];
#else
    [MBProgressHUD showMessage:LMLocalizedString(@"Set Logging out", nil) toView:self.view];
    [[IMService instance] unBindDeviceTokenWithDeviceToken:[IMService instance].deviceToken complete:^(NSError *error, id data) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:weakSelf.view];
        }];
        if (!error) {
            [[LKUserCenter shareCenter] loginOutByServerWithInfo:nil];
        } else {
            if (error.code == OVER_TIME_CODE) {
                [[LKUserCenter shareCenter] loginOutByServerWithInfo:nil];
            } else{
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Set Log Out Fail", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                }];
            }
        }
    }];
#endif
}


- (void)pushControllerHideBar:(UIViewController *)controller {
    controller.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - deleagate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 0;
    } else {
        return AUTO_HEIGHT(5);
    }
}

#pragma mark - datasource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {


    CellGroup *group = self.groups[indexPath.section];
    CellItem *item = group.items[indexPath.row];

    BaseCell *cell;
    __weak __typeof(&*self) weakSelf = self;
    if (item.type == CellItemTypeMyInfoCell) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"MyInfoCellID"];

        MyInfoCell *myInfo = (MyInfoCell *) cell;

        myInfo.qrBtnClickBlock = ^{
            MyAddressQRPage *page = [[MyAddressQRPage alloc] initWithUser:weakSelf.userInfo];
            page.hidesBottomBarWhenPushed = YES;
            [weakSelf.navigationController pushViewController:page animated:YES];
        };
        myInfo.data = item.userInfo;
        return cell;
    } else if (item.type == CellItemTypeArrow) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NCellArrowID"];
        NCellArrow *arrowCell = (NCellArrow *) cell;
        arrowCell.customTitleLabel.text = item.title;
    } else if (item.type == CellItemTypeLogoutCell) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"MainSetLogoutCellID"];
        MainSetLogoutCell *loginOutCell = (MainSetLogoutCell *) cell;
        loginOutCell.data = item;
    }

    return cell;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    CellGroup *group = self.groups[indexPath.section];
    CellItem *item = group.items[indexPath.row];
    if (item.type == CellItemTypeLogoutCell) {
        cell.separatorInset = UIEdgeInsetsMake(0.f, cell.bounds.size.width, 0.f, 0.f);
    }
}

@end
