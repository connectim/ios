//
//  ChatGroupSetGroupNameViewController.m
//  Connect
//
//  Created by MoHuilin on 16/7/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "ChatGroupSetGroupNameViewController.h"
#import "NetWorkOperationTool.h"

#import "GroupDBManager.h"
#import "TextFieldRoundCell.h"
#import "StringTool.h"


@interface ChatGroupSetGroupNameViewController ()

@property(nonatomic, copy) NSString *currentGroupName;

@property(nonatomic, copy) NSString *updataGroupName;

@property(nonatomic, copy) NSString *groupid;

@end

@implementation ChatGroupSetGroupNameViewController


- (instancetype)initWithCurrentName:(NSString *)name groupid:(NSString *)groupid {
    if (self = [super init]) {
        self.currentGroupName = name;
        self.groupid = groupid;
    }

    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = LMLocalizedString(@"Link Group", nil);

    [self setRightButtonWithTitle:LMLocalizedString(@"Chat Complete", nil)];
    self.rightBarBtn.enabled = NO;

    [self.rightBarBtn setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor greenColor]} forState:UIControlStateNormal];
    [self.rightBarBtn setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor grayColor]} forState:UIControlStateDisabled];
}

- (void)configTableView {

    self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
    self.tableView.separatorColor = self.tableView.backgroundColor;
    [self.tableView registerClass:[TextFieldRoundCell class] forCellReuseIdentifier:@"TextFieldRoundCellID"];
}


- (void)rightButtonPressed:(UIButton *)sender {

    if ([self.currentGroupName isEqualToString:self.updataGroupName]) {
        return;
    }

    if (GJCFStringIsNull(self.groupid) || GJCFStringIsNull(self.updataGroupName)) {
        return;
    }

    UpdateGroupInfo *updataGroup = [[UpdateGroupInfo alloc] init];
    updataGroup.name = self.updataGroupName;
    updataGroup.identifier = self.groupid;
    self.updataGroupName = [StringTool filterStr:self.updataGroupName];
    [[GroupDBManager sharedManager] updateGroupName:self.updataGroupName groupId:self.groupid];

    __weak __typeof(&*self) weakSelf = self;
    [MBProgressHUD showMessage:LMLocalizedString(@"Common Loading", nil) toView:self.view];

    [NetWorkOperationTool POSTWithUrlString:GroupUpdateGroupInfoUrl postProtoData:updataGroup.data complete:^(id response) {

        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:weakSelf.view];
        }];

        HttpNotSignResponse *nosignResponse = (HttpNotSignResponse *) response;

        if (nosignResponse.code != successCode) {
            [UIAlertController showAlertInViewController:self withTitle:LMLocalizedString(@"Link Update Group Name Failed", nil) message:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@[LMLocalizedString(@"Common OK", nil)] tapBlock:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action, NSInteger buttonIndex) {
                
            }];
            return;
        }
        [[GroupDBManager sharedManager] updateGroupName:weakSelf.updataGroupName groupId:self.groupid];
        [GCDQueue executeInMainQueue:^{
            [weakSelf.navigationController popViewControllerAnimated:YES];
            SendNotify(ConnnectGroupInfoDidChangeNotification, weakSelf.groupid);
        }];

    }                                  fail:^(NSError *error) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:weakSelf.view];
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Update Group Name Failed", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
        }];
        [UIAlertController showAlertInViewController:self withTitle:LMLocalizedString(@"Link Update Group Name Failed", nil) message:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@[LMLocalizedString(@"Common OK", nil)] tapBlock:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action, NSInteger buttonIndex) {
            
        }];
    }];

}

- (void)setupCellData {
    
    CellItem *inputGroupName = [[CellItem alloc] init];
    inputGroupName.type = CellItemTypeRoundTextField;
    inputGroupName.title = self.currentGroupName;


    CellGroup *group0 = [[CellGroup alloc] init];
    group0.headTitle = LMLocalizedString(@"Link Group Name", nil);
    group0.items = @[inputGroupName].copy;
    [self.groups objectAddObject:group0];


}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {


    CellGroup *group = self.groups[indexPath.section];
    CellItem *item = group.items[indexPath.row];

    __weak __typeof(&*self) weakSelf = self;
    BaseCell *cell;
    if (item.type == CellItemTypeRoundTextField) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"TextFieldRoundCellID"];
        TextFieldRoundCell *textFieldCell = (TextFieldRoundCell *) cell;

        textFieldCell.TextValueChangeBlock = ^(UITextField *textFiled, NSString *text) {
            weakSelf.updataGroupName = text;
            if (text.length <= 30 && text.length >= 4) {
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
    }
    return cell;
}


@end
