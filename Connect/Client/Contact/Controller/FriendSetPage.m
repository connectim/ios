//
//  FriendSetPage.m
//  Connect
//
//  Created by MoHuilin on 16/7/21.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "FriendSetPage.h"
#import "UserCommonInfoSetCell.h"
#import "UserDBManager.h"
#import "TextFieldViewButtomCell.h"
#import "StringTool.h"


@interface FriendSetPage ()

@property(nonatomic, strong) AccountInfo *user;

@property(nonatomic, copy) NSString *updateRemark; //remark

@property(copy, nonatomic) NSString *remark;


@end

@implementation FriendSetPage

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = LMLocalizedString(@"Set Setting", nil);

    //update tag
    __weak __typeof(&*self) weakSelf = self;
    if (self.user.tags.count <= 0 && ![[MMAppSetting sharedSetting] isHaveSyncUserTags]) {
        //download tag
        [SetGlobalHandler tagListDownCompelete:^(NSArray *tags) {
            if (tags.count <= 0) {
                return;
            }
            [GCDQueue executeInMainQueue:^{
                [weakSelf setupCellData];
                [weakSelf.tableView reloadData];
            }];
        }];
    }
    //get users all tag from user address
    if ([[UserDBManager sharedManager] getUserTags:self.user.address].count <= 0) {
        [SetGlobalHandler Userstag:self.user.address downTags:^(NSArray *tags) {
            for (NSString *tag in tags) {
                [[UserDBManager sharedManager] saveAddress:self.user.address toTag:tag];
                weakSelf.user.tags = tags.copy;
            }
            [GCDQueue executeInMainQueue:^{
                [weakSelf setupCellData];
                [weakSelf.tableView reloadData];
            }];
        }];
    }

}


- (instancetype)initWithUser:(AccountInfo *)user {

    if (self = [super init]) {
        self.user = user;
    }
    return self;
}

#pragma mark - 配置cell

- (void)configTableView {
    [super configTableView];

    [self.tableView registerClass:[UserCommonInfoSetCell class] forCellReuseIdentifier:@"UserCommonInfoSetCellID"];

    [self.tableView registerClass:[TextFieldViewButtomCell class] forCellReuseIdentifier:@"TextFieldViewButtomCellID"];
}

- (void)setupCellData {

    [self.groups removeAllObjects];
    //zero group
    CellGroup *group = [[CellGroup alloc] init];
    CellItem *nickNameItem = [CellItem itemWithTitle:nil type:CellItemTypeTextFieldWithButton operation:nil];
    nickNameItem.tag = 1;
    group.items = @[nickNameItem].copy;
    [self.groups objectAddObject:group];
    //first group
    __weak typeof(self) weakSelf = self;
    CellGroup *group1 = [[CellGroup alloc] init];
    CellItem *userDetailInfo = [[CellItem alloc] init];
    userDetailInfo.type = CellItemTypeUserSetAliasCell;
    userDetailInfo.userInfo = self.user;
    userDetailInfo.operationWithInfo = ^(NSString *newTag) {
        [weakSelf savaTags:newTag];
    };
    group1.items = @[userDetailInfo].copy;

    [self.groups objectAddObject:group1];

}

#pragma mark - UIAlertViewDatasource


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    __weak __typeof(&*self) weakSelf = self;
    CellGroup *group = self.groups[indexPath.section];
    CellItem *item = group.items[indexPath.row];

    //cell creat
    BaseCell *cell;
    if (item.type == CellItemTypeTextFieldWithButton) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"TextFieldViewButtomCellID"];
        TextFieldViewButtomCell *textFieldCell = (TextFieldViewButtomCell *) cell;
        textFieldCell.actonButton.enabled = NO;
        textFieldCell.actonButton.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
        textFieldCell.text = item.title;
        textFieldCell.placeholder = LMLocalizedString(@"Wallet Nick name", nil);
        textFieldCell.text = self.user.remarks;
        [textFieldCell setButtonTitle:LMLocalizedString(@"Set Save", nil)];
        if (item.tag == 1) {
            textFieldCell.ButtonTapBlock = ^() {
                [self.view endEditing:YES];
                [weakSelf saveNickName];
            };
        }
        __weak __typeof(&*textFieldCell) weakCell = textFieldCell;
        textFieldCell.TextValueChangeBlock = ^(UITextField *textFiled, NSString *text) {
            weakSelf.remark = text;
            if (text.length < 15) {
                __strong __typeof(&*weakCell) strongCell = weakCell;
                strongCell.actonButton.enabled = YES;
            }
        };
        return cell;
    } else if (item.type == CellItemTypeUserSetAliasCell) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"UserCommonInfoSetCellID"];
        UserCommonInfoSetCell *commonCell = (UserCommonInfoSetCell *) cell;
        commonCell.TextValueChangeBlock = ^(NSString *text) {
            weakSelf.updateRemark = text;
            weakSelf.updateRemark = [StringTool filterStr:weakSelf.updateRemark];
            [weakSelf savaTags:weakSelf.updateRemark];
        };
        cell.data = item;
        return cell;
    }
    return cell;
}

#pragma mark - keep nickname

- (void)saveNickName {
    
    if (self.remark.length) {
        self.remark = [StringTool filterStr:self.remark];
        [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Remark change successfull", nil) withType:ToastTypeSuccess showInView:self.view complete:^{
            [self.navigationController popViewControllerAnimated:YES];
            if (self.nickNameChageBlcock) {
                self.nickNameChageBlcock(self.remark);
            }
        }];
    } else {
        [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Delete Remark successfully", nil) withType:ToastTypeSuccess showInView:self.view complete:^{
            [self.navigationController popViewControllerAnimated:YES];
            if (self.nickNameChageBlcock) {
                self.nickNameChageBlcock(nil);
            }
        }];
    }
    [self addToOffencontact:self.user.isOffenContact remark:self.remark];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CellGroup *group = self.groups[indexPath.section];
    CellItem *item = group.items[indexPath.row];

    if (item.type == CellItemTypeUserSetAliasCell) {
        return AUTO_HEIGHT(380);
    } else if (item.type == CellItemTypeButtonCell) {
        return AUTO_HEIGHT(100);
    }
    return AUTO_HEIGHT(100);
}

/**
 *  join black list
 */
- (void)addToBlackList:(BOOL)isAddToBlackList {
    self.user.isBlackMan = isAddToBlackList;
    if (isAddToBlackList) {
        [SetGlobalHandler addToBlackListWithAddress:self.user.address];
    } else {
        [SetGlobalHandler removeBlackListWithAddress:self.user.address];
    }
}

/**
 *  join Frequent contacts
 */
- (void)addToOffencontact:(BOOL)isAddOffencontact remark:(NSString *)remark {
    if (GJCFStringIsNull(self.user.address)) {
        DDLogError(@"data error");
        return;
    }
    if (isAddOffencontact) {
        [SetGlobalHandler addToCommonContactListWithAddress:self.user.address remark:remark];
    } else {
        [SetGlobalHandler removeCommonContactListWithAddress:self.user.address remark:remark];
    }

}

- (void)savaTags:(NSString *)newTag {
    if (GJCFStringIsNull(newTag)) {
        return;
    }
    [SetGlobalHandler addNewTag:newTag withAddress:self.user.address];
    [GCDQueue executeInMainQueue:^{
        [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Save tag successfully", nil) withType:ToastTypeSuccess showInView:self.view complete:nil];
    }];
}


- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}
@end
