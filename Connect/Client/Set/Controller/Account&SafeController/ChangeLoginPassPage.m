//
//  ChangeLoginPassPage.m
//  Connect
//
//  Created by MoHuilin on 16/7/30.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "ChangeLoginPassPage.h"
#import "TextFieldRoundCell.h"
#import "Protofile.pbobjc.h"
#import "NetWorkOperationTool.h"

@interface ChangeLoginPassPage ()
// new pass
@property(copy, nonatomic) NSString *passNew;
// pass tips
@property(nonatomic, copy) NSString *passTip;

@end

@implementation ChangeLoginPassPage

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = LMLocalizedString(@"Set Change password", nil);
    [self setRightButtonWithTitle:LMLocalizedString(@"Set Save", nil)];
    self.rightBarBtn.enabled = NO;

}

- (void)rightButtonPressed:(UIButton *)sender {

    if (GJCFStringIsNull(self.passNew)) {
        return;
    }

    NSString *encodePrivkey = [KeyHandle getEncodePrikey:[[LKUserCenter shareCenter] currentLoginUser].prikey withBitAddress:[[LKUserCenter shareCenter] currentLoginUser].address password:self.passNew];
    [[LKUserCenter shareCenter] currentLoginUser].encryption_pri = encodePrivkey;
    ChangeLoginPassword *changePass = [[ChangeLoginPassword alloc] init];
    changePass.encryptionPri = encodePrivkey;
    changePass.passwordHint = self.passTip;
    
    [MBProgressHUD showLoadingMessageToView:self.view];
    [NetWorkOperationTool POSTWithUrlString:SetChangeLoginPass postProtoData:changePass.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *) response;
        if (hResponse.code == successCode) {
            [LKUserCenter shareCenter].currentLoginUser.password_hint = self.passTip;
            [[MMAppSetting sharedSetting] saveUserToKeyChain:[[LKUserCenter shareCenter] currentLoginUser]];
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Save successful", nil) withType:ToastTypeSuccess showInView:self.view complete:^{
                    [self.navigationController popViewControllerAnimated:YES];
                }];
            }];
        } else {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:self.view complete:nil];
            }];
        }
    }                                  fail:^(NSError *error) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:self.view complete:nil];
        }];
    }];
}

- (void)configTableView {
    self.tableView.separatorColor = self.tableView.backgroundColor;
    [self.tableView registerClass:[TextFieldRoundCell class] forCellReuseIdentifier:@"TextFieldRoundCellID"];
    self.tableView.contentInset = UIEdgeInsetsMake(AUTO_HEIGHT(70), 0, 0, 0);
}


- (void)setupCellData {
    // zero group 
    CellItem *newPass = [CellItem itemWithTitle:nil type:CellItemTypeRoundTextField operation:nil];
    newPass.placeholder = LMLocalizedString(@"Set Enter new password", nil);
    newPass.tag = 2;

    CellGroup *group0 = [[CellGroup alloc] init];

    group0.headTitle = LMLocalizedString(@"Set Your private key will be encrypted with new password", nil);

    group0.items = @[newPass].copy;
    [self.groups objectAddObject:group0];
    // first group
    CellItem *passTip = [CellItem itemWithTitle:nil type:CellItemTypeRoundTextField operation:nil];
    passTip.tag = 3;
    passTip.placeholder = nil;
    passTip.userInfo = self.passTip;
    CellGroup *group1 = [[CellGroup alloc] init];

    group1.headTitle = LMLocalizedString(@"Login Login Password Hint Title", nil);

    group1.items = @[passTip].copy;
    [self.groups objectAddObject:group1];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    __weak __typeof(&*self) weakSelf = self;
    CellGroup *group = self.groups[indexPath.section];
    CellItem *item = group.items[indexPath.row];
    BaseCell *cell;
    if (item.type == CellItemTypeRoundTextField) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"TextFieldRoundCellID"];
        TextFieldRoundCell *textFieldCell = (TextFieldRoundCell *) cell;
        textFieldCell.placeholder = item.placeholder;
        textFieldCell.type = item.tag;
        textFieldCell.sourceType = SourceTypeSetChnagePass;
        textFieldCell.TextValueChangeBlock = ^(UITextField *textFiled, NSString *text) {
            if (item.tag == 2) {
                weakSelf.passNew = text;
                if (!GJCFStringIsNull(text)) {
                    [GCDQueue executeInMainQueue:^{
                        weakSelf.rightBarBtn.enabled = [RegexKit vilidatePassword:text];
                        [weakSelf.rightBarBtn setTintColor:LMBasicGreen];
                    }];
                } else {
                    [GCDQueue executeInMainQueue:^{
                        weakSelf.rightBarBtn.enabled = NO;
                    }];
                }
            } else if (item.tag == 3) {
                weakSelf.passTip = text;
            }
        };
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
        return AUTO_HEIGHT(96);
    }
    return 44;
}
@end
