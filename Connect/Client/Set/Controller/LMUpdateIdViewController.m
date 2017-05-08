//
//  LMUpdateIdViewController.m
//  Connect
//
//  Created by bitmain on 2017/1/19.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMUpdateIdViewController.h"
#import "TextFieldRoundCell.h"
#import "NetWorkOperationTool.h"
#import "Protofile.pbobjc.h"
#import "StringTool.h"

@interface LMUpdateIdViewController () <UITableViewDelegate>

@property(copy, nonatomic) NSString *updateIdName;
@end

@implementation LMUpdateIdViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LMLocalizedString(@"CONNECT ID", nil);
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
    if (GJCFStringIsNull(self.updateIdName)) {
        return;
    }
    if ([[self.updateIdName uppercaseString] isEqualToString:@"CONNECT"]) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Login User name can not be Connect", nil) withType:ToastTypeCommon showInView:weakSelf.view complete:nil];
        }];
        return;
    }
    self.updateIdName = [StringTool filterStr:self.updateIdName];

    ConnectId *conID = [[ConnectId alloc] init];
    conID.connectId = self.updateIdName;
    // request network
    [NetWorkOperationTool POSTWithUrlString:UpdateUserID postProtoData:conID.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *) response;

        if (hResponse.code != successCode) {
            DDLogInfo(@"Network Server error");
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:hResponse.message withType:ToastTypeFail showInView:weakSelf.view complete:nil];
            }];
            return;
        }
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Update successful", nil) withType:ToastTypeSuccess showInView:weakSelf.view complete:^{
                [weakSelf detailSuccess];
            }];
        }];
    }                                  fail:^(NSError *error) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:[LMErrorCodeTool showToastErrorType:ToastErrorTypeSet withErrorCode:error.code withUrl:UpdateUserID] withType:ToastTypeFail showInView:weakSelf.view complete:nil];
        }];
    }];
}

- (void)detailSuccess {
    // request success callback
    [[LKUserCenter shareCenter] currentLoginUser].contentId = self.updateIdName;
    [[LKUserCenter shareCenter] updateUserInfo:[[LKUserCenter shareCenter] currentLoginUser]];
    if (self.updateIdBlock) {
        self.updateIdBlock(self.updateIdName);
    }
    [self.navigationController popViewControllerAnimated:YES];

}

- (void)setupCellData {
    // zero group
    CellItem *inputName = [[CellItem alloc] init];
    inputName.type = CellItemTypeRoundTextField;
    inputName.title = [[LKUserCenter shareCenter] currentLoginUser].contentId;

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
        textFieldCell.sourceType = SourceTypeSetChnagePass;
        textFieldCell.type = 2;
        textFieldCell.TextValueChangeBlock = ^(UITextField *textFiled, NSString *text) {
            weakSelf.updateIdName = text;
            if ([RegexKit updateIdLengthLimit:text]) {
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

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return AUTO_HEIGHT(150);
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VSIZE.width, AUTO_HEIGHT(40))];
    bgView.backgroundColor = LMBasicBackgroundColor;
    UILabel *titleOneLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, VSIZE.width - 20, AUTO_HEIGHT(40))];
    titleOneLabel.backgroundColor = LMBasicBackgroundColor;
    titleOneLabel.text = LMLocalizedString(@"Set CONNECT ID can only be set once", nil);
    titleOneLabel.font = [UIFont systemFontOfSize:FONT_SIZE(22)];
    titleOneLabel.textColor = LMBasicDarkGray;
    titleOneLabel.textAlignment = NSTextAlignmentLeft;
    [bgView addSubview:titleOneLabel];
    return bgView;
}

- (void)dealloc {
    [self.tableView removeFromSuperview];
    self.tableView = nil;
}


@end
