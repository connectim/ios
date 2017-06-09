//
//  AccountAndSafetyPage.m
//  Connect
//
//  Created by MoHuilin on 16/7/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "AccountAndSafetyPage.h"
#import "BoundOrUnboundPhonePage.h"
#import "GestureOpneOrClosePage.h"
#import "ExportEncodePrivkeyPage.h"
#import "PaySetPage.h"
#import "ChangeLoginPassPage.h"


@interface AccountAndSafetyPage ()

@property(nonatomic, strong) UITextField *passTextField;

@property(nonatomic, strong) AccountInfo *loginUser;

@end

@implementation AccountAndSafetyPage

- (instancetype)init {
    if (self = [super init]) {
        self.loginUser = [[LKUserCenter shareCenter] currentLoginUser];
    }

    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupCellData];
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = LMLocalizedString(@"Set Account security", nil);
}

- (void)setupCellData {

   
    __weak __typeof(&*self) weakSelf = self;
    [self.groups removeAllObjects];
    // zero group
    CellGroup *group = [[CellGroup alloc] init];

    NSString *phoneTip = LMLocalizedString(@"Set Phone unbinded", nil);
    if (!GJCFStringIsNull(self.loginUser.bondingPhone)) {
        if ([self.loginUser.bondingPhone containsString:@"-"]) {
            phoneTip = [self.loginUser.bondingPhone substringFromIndex:[self.loginUser.bondingPhone rangeOfString:@"-"].location + 1];
        } else {
            phoneTip = self.loginUser.bondingPhone;
        }
    }
    if (self.loginUser.bonding) {
        phoneTip = LMLocalizedString(@"Login Phone binded", nil);
    }


    CellItem *phoneNum = [CellItem itemWithTitle:LMLocalizedString(@"Set Phone", nil) subTitle:phoneTip type:CellItemTypeValue1 operation:^{
        BoundOrUnboundPhonePage *page = [[BoundOrUnboundPhonePage alloc] init];
        page.UnBindBlock = ^(){
            [weakSelf setupCellData];
            [GCDQueue executeInMainQueue:^{
                [weakSelf.tableView reloadData];
            }];
        };
        [weakSelf.navigationController pushViewController:page animated:YES];

    }];

    CellItem *loginPass = [CellItem itemWithTitle:LMLocalizedString(@"Login Password", nil) type:CellItemTypeArrow operation:^{
        [weakSelf resetLoginPass];
    }];

    // first group
    CellGroup *group0 = [[CellGroup alloc] init];

    NSString *tip = LMLocalizedString(@"Set Off", nil);
    if ([[MMAppSetting sharedSetting] haveGesturePass]) {
        tip = LMLocalizedString(@"Set On", nil);
    }
    CellItem *lockGesture = [CellItem itemWithTitle:LMLocalizedString(@"Set Pattern Password", nil) subTitle:tip type:CellItemTypeValue1 operation:^{
        
        GestureOpneOrClosePage *page = [[GestureOpneOrClosePage alloc] init];
        [weakSelf hidenTabbarWhenPushController:page];
    }];
    CellItem *paymentSetting = [CellItem itemWithTitle:LMLocalizedString(@"Set Payment", nil) type:CellItemTypeArrow operation:^{

        PaySetPage *page = [[PaySetPage alloc] init];
        [weakSelf hidenTabbarWhenPushController:page];

    }];

    group.items = @[phoneNum, loginPass, paymentSetting, lockGesture].copy;
    [self.groups objectAddObject:group];


    group0.items = @[lockGesture, paymentSetting].copy;

    // second group
    CellGroup *group1 = [[CellGroup alloc] init];

    CellItem *encodePrikeyBackup = [CellItem itemWithTitle:LMLocalizedString(@"Set Private key backup", nil) type:CellItemTypeArrow operation:^{
        [weakSelf vertifyLoginPass];
    }];

    group1.items = @[encodePrikeyBackup].copy;
    [self.groups objectAddObject:group1];


}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {


    CellGroup *group = self.groups[indexPath.section];
    CellItem *item = group.items[indexPath.row];

    BaseCell *cell;
    if (item.type == CellItemTypeValue1) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NCellValue1ID"];
        NCellValue1 *value1Cell = (NCellValue1 *) cell;
        value1Cell.data = item;
    } else if (item.type == CellItemTypeArrow) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NCellArrowID"];
        NCellArrow *arrowCell = (NCellArrow *) cell;
        arrowCell.customTitleLabel.text = item.title;
    }

    return cell;
}


- (void)resetLoginPass {

    __weak __typeof(&*self) weakSelf = self;
    AccountInfo *loginUser = [[LKUserCenter shareCenter] currentLoginUser];

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LMLocalizedString(@"Set Enter Login Password", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.secureTextEntry = YES;
        weakSelf.passTextField = textField;
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *_Nonnull action) {
    }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {

        [GCDQueue executeInGlobalQueue:^{

            weakSelf.navigationController.view.userInteractionEnabled = NO;
            NSDictionary *decodeDict = [KeyHandle decodePrikeyGetDict:loginUser.encryption_pri withPassword:weakSelf.passTextField.text];
            weakSelf.navigationController.view.userInteractionEnabled = YES;

            if (decodeDict) {
                [GCDQueue executeInMainQueue:^{
                    ChangeLoginPassPage *page = [[ChangeLoginPassPage alloc] init];
                    [weakSelf hidenTabbarWhenPushController:page];
                }];
            } else {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Password incorrect", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                    [weakSelf setupCellData];
                    [weakSelf.tableView reloadData];
                }];
            }
        }];

    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];

}


- (void)vertifyLoginPass {

    __weak __typeof(&*self) weakSelf = self;
    AccountInfo *loginUser = [[LKUserCenter shareCenter] currentLoginUser];

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LMLocalizedString(@"Set Enter Login Password", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.secureTextEntry = YES;
        weakSelf.passTextField = textField;
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {

        [GCDQueue executeInGlobalQueue:^{

            if (weakSelf.passTextField.text.length <= 0) {
                return;
            }
            weakSelf.navigationController.view.userInteractionEnabled = NO;
            NSDictionary *decodeDict = [KeyHandle decodePrikeyGetDict:loginUser.encryption_pri withPassword:weakSelf.passTextField.text];
            weakSelf.navigationController.view.userInteractionEnabled = YES;

            if (decodeDict) {
                [GCDQueue executeInMainQueue:^{
                    ExportEncodePrivkeyPage *page = [[ExportEncodePrivkeyPage alloc] init];
                    [weakSelf hidenTabbarWhenPushController:page];
                }];
            } else {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Password incorrect", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                }];
            }
        }];

    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    alertController.automaticallyAdjustsScrollViewInsets = NO;
    [self presentViewController:alertController animated:YES completion:nil];
}


@end
