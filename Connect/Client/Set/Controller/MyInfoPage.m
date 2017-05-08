//
//  MyInfoPage.m
//  Connect
//
//  Created by MoHuilin on 16/7/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "MyInfoPage.h"
#import "SetMyNickViewController.h"
#import "BigAvatarViewController.h"
#import "UIView+Toast.h"
#import "LMUpdateIdViewController.h"

@interface MyInfoPage () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property(nonatomic, strong) AccountInfo *userInfo;

@end

@implementation MyInfoPage


- (instancetype)initWithUserInfo:(AccountInfo *)userInfo {
    if (self = [super init]) {
        self.userInfo = userInfo;
    }

    return self;
}

- (void)configTableView {

    self.tableView.separatorColor = self.tableView.backgroundColor;

    [self.tableView registerNib:[UINib nibWithNibName:@"NCellValue1" bundle:nil] forCellReuseIdentifier:@"NCellValue1ID"];

    [self.tableView registerNib:[UINib nibWithNibName:@"SetAvatarCell" bundle:nil] forCellReuseIdentifier:@"SetAvatarCellID"];

    [self.tableView registerNib:[UINib nibWithNibName:@"NSubTitleNoArrow" bundle:nil] forCellReuseIdentifier:@"NSubTitleNoArrowID"];

}

- (void)viewDidLoad {

    if (!self.userInfo) {
        self.userInfo = [[LKUserCenter shareCenter] currentLoginUser];
    }

    [super viewDidLoad];
    //注册通知
    RegisterNotify(LKUserCenterUserInfoUpdateNotification, @selector(updataUserInfo:));

    self.title = LMLocalizedString(@"Set My Profile", nil);
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
    CellItem *setAvatar = [CellItem itemWithTitle:LMLocalizedString(@"Set Profile Photo", nil) type:CellItemTypeSetAvatarCell operation:^{
        BigAvatarViewController *page = [[BigAvatarViewController alloc] init];
        [weakSelf.navigationController pushViewController:page animated:YES];
    }];
    setAvatar.userInfo = self.userInfo;

    CellItem *nickName = [CellItem itemWithTitle:LMLocalizedString(@"Set Name", nil) subTitle:self.userInfo.username type:CellItemTypeValue1 operation:^{
        SetMyNickViewController *page = [[SetMyNickViewController alloc] init];
        [weakSelf.navigationController pushViewController:page animated:YES];

    }];
    CellItem *ID = nil;
    // Safety measures
    if (self.userInfo.contentId.length <= 0) {
        self.userInfo.contentId = self.userInfo.address;
    }
    if (![self.userInfo.contentId isEqualToString:self.userInfo.address]) {
        ID = [CellItem itemWithTitle:LMLocalizedString(@"Set ID", nil) subTitle:self.userInfo.contentId type:CellItemTypeSubtitleNoArrow operation:nil];
        ID.operation = ^{
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = weakSelf.userInfo.contentId;
            [weakSelf.view makeToast:LMLocalizedString(@"Set Copied", nil) duration:0.8 position:CSToastPositionCenter];
        };
    } else {
        ID = [CellItem itemWithTitle:LMLocalizedString(@"Set ID", nil) subTitle:self.userInfo.contentId type:CellItemTypeValue1 operation:^{
            // join uodate page
            LMUpdateIdViewController *updateIdVc = [[LMUpdateIdViewController alloc] init];
            updateIdVc.updateIdBlock = ^(NSString *idString) {
                [GCDQueue executeInMainQueue:^{
                    [weakSelf.tableView reloadData];
                }];
                if (weakSelf.changeIdBlock) {
                    weakSelf.changeIdBlock();
                }
            };
            [weakSelf.navigationController pushViewController:updateIdVc animated:YES];
        }];
    }
    CellItem *address = [CellItem itemWithTitle:LMLocalizedString(@"Chat Address", nil) subTitle:self.userInfo.address type:CellItemTypeSubtitleNoArrow operation:nil];
    address.operation = ^{
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = weakSelf.userInfo.address;
        [weakSelf.view makeToast:LMLocalizedString(@"Set Copied", nil) duration:0.8 position:CSToastPositionCenter];
    };
    group.items = @[setAvatar, nickName, ID, address].copy;

    [self.groups objectAddObject:group];

}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {


    CellGroup *group = self.groups[indexPath.section];
    CellItem *item = group.items[indexPath.row];

    BaseCell *cell;
    if (item.type == CellItemTypeSetAvatarCell) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"SetAvatarCellID"];

        SetAvatarCell *setAvatar = (SetAvatarCell *) cell;
        setAvatar.data = item;

        return cell;
    } else if (item.type == CellItemTypeValue1) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NCellValue1ID"];
        NCellValue1 *value1Cell = (NCellValue1 *) cell;
        value1Cell.data = item;
    } else if (item.type == CellItemTypeSubtitleNoArrow) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NSubTitleNoArrowID"];
        cell.data = item;
    }


    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CellGroup *group = self.groups[indexPath.section];
    CellItem *item = group.items[indexPath.row];
    if (item.type == CellItemTypeSetAvatarCell) {
        return AUTO_HEIGHT(160);
    }
    return AUTO_HEIGHT(111);
}

@end
