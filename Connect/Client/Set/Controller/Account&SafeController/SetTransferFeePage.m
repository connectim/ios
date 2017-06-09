//
//  SetTransferFeePage.m
//  Connect
//
//  Created by MoHuilin on 16/7/30.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "SetTransferFeePage.h"
#import "TextFieldViewButtomCell.h"

#define  GROUP_DETAIL LMLocalizedString(@"Set miner fee explain", nil)


@interface SetTransferFeePage () <UITableViewDelegate>

@property(nonatomic, copy) NSString *transferNewFee; // new transferFee


@end

@implementation SetTransferFeePage

- (instancetype)initWithChangeBlock:(void (^)(BOOL result, long long displayValue))changeBlock {
    if (self = [super init]) {
        self.changeCallBack = changeBlock;
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = LMLocalizedString(@"Set Miner fee", nil);

}

- (void)saveTransferFee {
    __weak __typeof(&*self) weakSelf = self;
    NSString *fee = [self.transferNewFee stringByReplacingOccurrencesOfString:@"฿" withString:@""];
    long long setNewFee = [PayTool getPOW8AmountWithText:fee];
    if (setNewFee > 1000000) { //0.01
        [UIAlertController showAlertInViewController:self withTitle:LMLocalizedString(@"Set Transaction fee is to large", nil) message:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@[LMLocalizedString(@"Common OK", nil)] tapBlock:^(UIAlertController *_Nonnull controller, UIAlertAction *_Nonnull action, NSInteger buttonIndex) {
            [weakSelf updateNewTransactionFee:setNewFee];
        }];
    } else {
        [self updateNewTransactionFee:setNewFee];
    }
}


- (void)updateNewTransactionFee:(long long)setNewFee {
    if ([[MMAppSetting sharedSetting] getTranferFee] == setNewFee) {
        return;
    }
    [MBProgressHUD showLoadingMessageToView:self.view];
    [SetGlobalHandler setPaySetNoPass:[[MMAppSetting sharedSetting] isCanNoPassPay] payPass:[[MMAppSetting sharedSetting] getPayPass] fee:setNewFee compete:^(BOOL result) {
        if (result) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Save successful", nil) withType:ToastTypeSuccess showInView:self.view complete:^{
                    [self.navigationController popViewControllerAnimated:YES];
                }];
            }];
            if (self.changeCallBack) {
                self.changeCallBack(NO, setNewFee);
            }
            [[MMAppSetting sharedSetting] setAutoCalculateTransactionFee:NO];
        } else {
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Server error Try later", nil) withType:ToastTypeFail showInView:self.view complete:nil];
        }
    }];
}

- (void)saveMaxTransferFee {
    __weak typeof(self) weakSelf = self;
    NSString *fee = [self.transferNewFee stringByReplacingOccurrencesOfString:@"฿" withString:@""];
    if ([[MMAppSetting sharedSetting] getMaxTranferFee] == [fee doubleValue]) {
        return;
    }
    [GCDQueue executeInMainQueue:^{
        [MBProgressHUD showToastwithText:LMLocalizedString(@"Set Set max trasfer fee successful", nil) withType:ToastTypeSuccess showInView:weakSelf.view complete:^{
            if (weakSelf.changeCallBack) {
                weakSelf.changeCallBack(YES, [PayTool getPOW8AmountWithText:fee]);
            }
            [[MMAppSetting sharedSetting] setAutoCalculateTransactionFee:YES];
            [self.navigationController popViewControllerAnimated:YES];


        }];
    }];
    [[MMAppSetting sharedSetting] setMaxTransferFee:[NSString stringWithFormat:@"%lld", [PayTool getPOW8AmountWithText:fee]]];

}


- (void)configTableView {

    self.tableView.separatorColor = self.tableView.backgroundColor;

    [self.tableView registerClass:[TextFieldViewButtomCell class] forCellReuseIdentifier:@"TextFieldViewButtomCellID"];
    [self.tableView registerClass:[NCellSwitch class] forCellReuseIdentifier:@"NCellSwitcwID"];
    UITapGestureRecognizer *tapGester = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyBoardAction)];
    [self.tableView addGestureRecognizer:tapGester];
}


- (void)setupCellData {
    // zero group
    __weak __typeof(&*self) weakSelf = self;
    CellGroup *group0 = [[CellGroup alloc] init];
    CellItem *autoCalculateFee = [CellItem itemWithTitle:LMLocalizedString(@"Wallet Auto Calculate Miner Fee", nil) type:CellItemTypeSwitch operation:nil];
    __weak __typeof(&*autoCalculateFee) weakAutoCalculateFee = autoCalculateFee;
    autoCalculateFee.switchIsOn = [[MMAppSetting sharedSetting] canAutoCalculateTransactionFee];
    autoCalculateFee.operationWithInfo = ^(id userInfo) {
        BOOL flag = [userInfo boolValue];
        if (weakSelf.changeCallBack) {
            weakSelf.changeCallBack(flag, 0);
        }
        weakAutoCalculateFee.switchIsOn = flag;
        [[MMAppSetting sharedSetting] setAutoCalculateTransactionFee:flag];
        if (flag) {
            [weakSelf.groups removeLastObject];
            [weakSelf.tableView reloadData];

            CellGroup *group1 = [[CellGroup alloc] init];
            group1.footTitle = GROUP_DETAIL;
            group1.headTitle = LMLocalizedString(@"Wallet Set max trasfer fee", nil);//
            NSString *fee = [NSString stringWithFormat:@"฿ %@", [PayTool getBtcStringWithAmount:[[MMAppSetting sharedSetting] getMaxTranferFee]]];
            CellItem *transferfee = [CellItem itemWithTitle:fee type:CellItemTypeTextFieldWithButton operation:nil];
            transferfee.tag = 2;
            group1.items = @[transferfee].copy;
            [weakSelf.groups objectAddObject:group1];
            [weakSelf.tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationBottom];
        } else {
            [weakSelf.groups removeLastObject];
            [weakSelf.tableView reloadData];

            CellGroup *group1 = [[CellGroup alloc] init];
            group1.footTitle = GROUP_DETAIL;
            group1.headTitle = LMLocalizedString(@"Wallet Set transaction fee specified", nil);
            NSString *fee = [NSString stringWithFormat:@"฿ %@", [PayTool getBtcStringWithAmount:[[MMAppSetting sharedSetting] getTranferFee]]];
            CellItem *transferfee = [CellItem itemWithTitle:fee type:CellItemTypeTextFieldWithButton operation:nil];
            transferfee.tag = 1;
            group1.items = @[transferfee].copy;
            [weakSelf.groups objectAddObject:group1];
            [weakSelf.tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationBottom];
        }
    };
    group0.items = @[autoCalculateFee].copy;
    [self.groups objectAddObject:group0];

    if (autoCalculateFee.switchIsOn) {
        CellGroup *group1 = [[CellGroup alloc] init];
        group1.headTitle = LMLocalizedString(@"Wallet Set max trasfer fee", nil);
        group1.footTitle = GROUP_DETAIL;
        NSString *fee = [NSString stringWithFormat:@"฿ %@", [PayTool getBtcStringWithAmount:[[MMAppSetting sharedSetting] getMaxTranferFee]]];
        CellItem *transferfee = [CellItem itemWithTitle:fee type:CellItemTypeTextFieldWithButton operation:nil];
        transferfee.tag = 2;
        group1.items = @[transferfee].copy;
        [self.groups objectAddObject:group1];
    } else {
        CellGroup *group1 = [[CellGroup alloc] init];
        group1.headTitle = LMLocalizedString(@"Wallet Set transaction fee specified", nil);
        group1.footTitle = GROUP_DETAIL;
        NSString *fee = [NSString stringWithFormat:@"฿ %@", [PayTool getBtcStringWithAmount:[[MMAppSetting sharedSetting] getTranferFee]]];
        CellItem *transferfee = [CellItem itemWithTitle:fee type:CellItemTypeTextFieldWithButton operation:nil];
        transferfee.tag = 1;
        group1.items = @[transferfee].copy;
        [self.groups objectAddObject:group1];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    __weak __typeof(&*self) weakSelf = self;
    CellGroup *group = self.groups[indexPath.section];
    CellItem *item = group.items[indexPath.row];
    BaseCell *cell;
    if (item.type == CellItemTypeSwitch) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NCellSwitcwID"];
        NCellSwitch *switchCell = (NCellSwitch *) cell;
        switchCell.switchIsOn = item.switchIsOn;
        switchCell.SwitchValueChangeCallBackBlock = ^(BOOL on) {
            item.operationWithInfo ? item.operationWithInfo(@(on)) : nil;
        };
        switchCell.customLable.text = item.title;
        return cell;
    } else if (item.type == CellItemTypeTextFieldWithButton) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"TextFieldViewButtomCellID"];
        TextFieldViewButtomCell *textFieldCell = (TextFieldViewButtomCell *) cell;
        textFieldCell.sourceType = SourceTypeSet;
        textFieldCell.textFiled.keyboardType = UIKeyboardTypeDecimalPad;
        textFieldCell.TextValueChangeBlock = ^(UITextField *textFiled, NSString *text) {
            if (textFiled.text.length == 1) {
                textFiled.text = [textFiled.text substringToIndex:1];
            } else if (textFiled.text.length < 1) {
                textFiled.text = @"฿";
            }
            weakSelf.transferNewFee = text;
        };
        textFieldCell.text = item.title;
        [textFieldCell setButtonTitle:LMLocalizedString(@"Set Save", nil)];
        [textFieldCell.actonButton setTitleColor:LMBasicBlue forState:UIControlStateNormal];
        if (item.tag == 1) {
            textFieldCell.ButtonTapBlock = ^() {
                [weakSelf saveTransferFee];
            };
        } else if (item.tag == 2) {
            textFieldCell.ButtonTapBlock = ^() {
                [weakSelf saveMaxTransferFee];
            };
        }
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
    return AUTO_HEIGHT(90);
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    CellGroup *group = self.groups[section];

    return group.footTitle;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 1) {
        return AUTO_HEIGHT(200);
    }
    return 0;
}

#pragma mark - hide keyboard

- (void)hideKeyBoardAction {
    [self.view endEditing:YES];
}
@end
