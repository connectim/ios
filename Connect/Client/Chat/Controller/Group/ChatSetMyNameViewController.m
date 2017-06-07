//
//  ChatSetMyNameViewController.m
//  Connect
//
//  Created by MoHuilin on 16/7/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "ChatSetMyNameViewController.h"
#import "StringTool.h"
#import "TextFieldRoundCell.h"

@interface ChatSetMyNameViewController ()

@property(nonatomic, copy) NSString *updateNickName;
@property(nonatomic, strong) AccountInfo *user;
@property(nonatomic, copy) NSString *groupID;

@end

@implementation ChatSetMyNameViewController

- (instancetype)initWithUpdateUser:(AccountInfo *)user groupIdentifier:(NSString *)groupid {
    if (self = [super init]) {
        self.user = user;
        self.groupID = groupid;
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
    self.tableView.separatorColor = self.tableView.backgroundColor;

    [self.tableView registerClass:[TextFieldRoundCell class] forCellReuseIdentifier:@"TextFieldRoundCellID"];
}

- (void)rightButtonPressed:(UIButton *)sender {

    if ([self.updateNickName isEqualToString:self.user.groupNickName]) {
        return;
    }
    if (GJCFStringIsNull(self.groupID) || GJCFStringIsNull(self.updateNickName)) {
        return;
    }
    self.updateNickName = [StringTool filterStr:self.updateNickName];
    [MBProgressHUD showMessage:LMLocalizedString(@"Common Loading", nil) toView:self.view];
    __weak __typeof(&*self) weakSelf = self;
    [SetGlobalHandler updateGroupMynameWithIdentifer:self.groupID myName:self.updateNickName complete:^(NSError *erro) {
        if (erro) {
            [UIAlertController showAlertInViewController:weakSelf withTitle:LMLocalizedString(@"Link An error occurred change nickname", nil) message:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@[LMLocalizedString(@"Common OK", nil)] tapBlock:^(UIAlertController *_Nonnull controller, UIAlertAction *_Nonnull action, NSInteger buttonIndex) {

            }];
        } else {
            [GCDQueue executeInMainQueue:^{
                SendNotify(ConnnectGroupInfoDidChangeNotification, weakSelf.groupID);
                [weakSelf.navigationController popViewControllerAnimated:YES];
            }];
        }
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:weakSelf.view];
        }];
    }];
}

- (void)setupCellData {
    CellItem *inputName = [[CellItem alloc] init];
    inputName.type = CellItemTypeRoundTextField;
    inputName.title = self.user.groupShowName;

    CellGroup *group0 = [[CellGroup alloc] init];
    group0.footTitle = LMLocalizedString(@"Link Set group nicknames only be in this group", nil);
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
            weakSelf.updateNickName = text;
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
    }

    return cell;
}


@end
