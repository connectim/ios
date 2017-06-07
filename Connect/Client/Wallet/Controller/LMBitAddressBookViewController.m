//
//  LMBitAddressBookViewController.m
//  Connect
//
//  Created by Edwin on 16/7/21.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMBitAddressBookViewController.h"
#import "LMBitAddressTableViewCell.h"
#import "NetWorkOperationTool.h"
#import "LMAddressBookManager.h"
#import "ScanAddPage.h"
#import "StringTool.h"

@interface LMBitAddressBookViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) NSMutableArray *dataArr;
@property(nonatomic, strong) UITextField *bitAddressTextField;
@property(nonatomic, strong) UIButton *addBtn;

@end

static NSString *address = @"address";

@implementation LMBitAddressBookViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = LMLocalizedString(@"Wallet Address Book", nil);
    [self addRightBarButtonItem];
    
    [self setUpUI];
}
- (void)setUpUI {
    self.addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.addBtn.frame = CGRectMake(AUTO_WIDTH(30), 84, VSIZE.width - AUTO_WIDTH(60), AUTO_HEIGHT(120));
    self.addBtn.layer.borderColor = LMBasicMiddleGray.CGColor;
    self.addBtn.layer.borderWidth = 1;
    [self.addBtn setImage:[UIImage imageNamed:@"add_black"] forState:UIControlStateNormal];
    self.addBtn.backgroundColor = LMBasicBackgroudGray;
    self.addBtn.layer.cornerRadius = 8;
    self.addBtn.layer.masksToBounds = YES;
    [self.addBtn addTarget:self action:@selector(addressBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.addBtn];
    
    
    self.bitAddressTextField = [[UITextField alloc] initWithFrame:CGRectMake(AUTO_WIDTH(30), 84, VSIZE.width - AUTO_WIDTH(60), AUTO_HEIGHT(120))];
    self.bitAddressTextField.placeholder = LMLocalizedString(@"Link Enter Bitcoin Address", nil);
    self.bitAddressTextField.font = [UIFont systemFontOfSize:FONT_SIZE(36)];
    self.bitAddressTextField.returnKeyType = UIReturnKeyDone;
    self.bitAddressTextField.keyboardType = UIKeyboardTypeAlphabet;
    self.bitAddressTextField.delegate = self;
    self.bitAddressTextField.hidden = YES;
    self.bitAddressTextField.backgroundColor = [UIColor whiteColor];
    self.bitAddressTextField.borderStyle = UITextBorderStyleRoundedRect;
    [self.view addSubview:self.bitAddressTextField];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.addBtn.frame), CGRectGetMaxY(self.addBtn.frame) + 5, CGRectGetWidth(self.addBtn.frame), VSIZE.height - self.addBtn.bottom) style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.tableFooterView = [[UIView alloc] init];
    [self.view addSubview:self.tableView];
    [self.tableView registerNib:[UINib nibWithNibName:@"LMBitAddressTableViewCell" bundle:nil] forCellReuseIdentifier:address];
    if (![[MMAppSetting sharedSetting] isHaveAddressbook]) {
        [self getBitAddressBooks];
    }
}
- (void)getBitAddressBooks {

    __weak __typeof(&*self) weakSelf = self;
    [NetWorkOperationTool POSTWithUrlString:Walletaddress_bookListUrl postProtoData:nil complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *) response;
        if (hResponse.code != successCode) {
            [GCDQueue executeInMainQueue:^{
              [MBProgressHUD showToastwithText:hResponse.message withType:ToastTypeFail showInView:self.view complete:nil];
            }];
            return;
        }
        NSData *data = [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            // data base clear all
            [[LMAddressBookManager sharedManager] clearAllAddress];
            [self.dataArr removeAllObjects];
            AddressBook *books = [AddressBook parseFromData:data error:nil];
            for (AddressBook_AddressInfo *book in books.addressInfoArray) {
                DDLogInfo(@"Address:%@,tag = %@", book.address, book.tag);
                AddressBookInfo *info = [[AddressBookInfo alloc] init];
                info.address = book.address;
                info.tag = book.tag;
                [self.dataArr addObject:info];
            }
            [[LMAddressBookManager sharedManager] saveBitchAddressBook:weakSelf.dataArr];
            [[MMAppSetting sharedSetting] haveSyncAddressbook];

            [GCDQueue executeInMainQueue:^{
                [weakSelf.tableView reloadData];
            }];
        }
    }                                  fail:^(NSError *error) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:self.view complete:nil];
        }];
        
    }];
}

#pragma mark --tableviewdialing

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 5;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.dataArr.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return AUTO_HEIGHT(120);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LMBitAddressTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:address];
    if (!cell) {
        cell = [[LMBitAddressTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:address];
    }
    AddressBookInfo *info = self.dataArr[indexPath.section];
    [cell setAddressWithAddressBookInfo:info];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AddressBookInfo *info = self.dataArr[indexPath.section];
    if (self.didGetBitAddress) {
        self.didGetBitAddress(info.address);
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {

    __weak typeof(self) weakself = self;
    AddressBookInfo *bitInfo = self.dataArr[indexPath.section];
    UITableViewRowAction *listAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:LMLocalizedString(@"Wallet Tags", nil) handler:^(UITableViewRowAction *_Nonnull action, NSIndexPath *_Nonnull indexPath) {

        UIAlertController *alertView = [UIAlertController alertControllerWithTitle:LMLocalizedString(@"Link Set Tag", nil) message:@"" preferredStyle:UIAlertControllerStyleAlert];
        [alertView addTextFieldWithConfigurationHandler:^(UITextField *_Nonnull textField) {
            textField.placeholder = LMLocalizedString(@"Wallet Tags", nil);
            [textField addTarget:self action:@selector(textFieldDidEndEditingValueChanged:) forControlEvents:UIControlEventEditingChanged];
        }];

        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:nil];

        UIAlertAction *okAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Set Save", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
            UITextField *textField = alertView.textFields.firstObject;
            textField.text = [StringTool filterStr:textField.text];
            AddressBook_AddressInfo *addressProtoData = [[AddressBook_AddressInfo alloc] init];
            addressProtoData.address = bitInfo.address;
            addressProtoData.tag = textField.text;

            [[LMAddressBookManager sharedManager] updateAddressTag:textField.text address:bitInfo.address];
            [NetWorkOperationTool POSTWithUrlString:Walletaddress_bookTagUrl postProtoData:addressProtoData.data complete:^(id response) {
                HttpResponse *respo = (HttpResponse *) response;
                NSLog(@"respo == %@", respo);
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Update successful", nil) withType:ToastTypeSuccess showInView:weakself.view complete:nil];
                }];
                bitInfo.tag = [NSString stringWithFormat:@"%@", textField.text];
                [GCDQueue executeInMainQueue:^{
                    [weakself.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                }];
            }                                  fail:^(NSError *error) {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Updated failed", nil) withType:ToastTypeFail showInView:weakself.view complete:nil];
                }];
            }];
        }];
        okAction.enabled = NO;
        [alertView addAction:cancelAction];
        [alertView addAction:okAction];
        [weakself presentViewController:alertView animated:YES completion:nil];
    }];
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:LMLocalizedString(@"Link Delete", nil) handler:^(UITableViewRowAction *_Nonnull action, NSIndexPath *_Nonnull indexPath) {

        AddressBook_AddressInfo *addressProtoData = [[AddressBook_AddressInfo alloc] init];
        addressProtoData.address = bitInfo.address;

        [NetWorkOperationTool POSTWithUrlString:Walletaddress_bookRemoveUrl postProtoData:addressProtoData.data complete:^(id response) {
            HttpResponse *respo = (HttpResponse *) response;
            DDLogInfo(@"respo == %@", respo);

            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Delete Successful", nil) withType:ToastTypeSuccess showInView:weakself.view complete:nil];
            }];

            [[LMAddressBookManager sharedManager] deleteAddressBookWithAddress:bitInfo.address];
            AddressBookInfo *info = weakself.dataArr[indexPath.section];

            [weakself.dataArr removeObject:info];
            [GCDQueue executeInMainQueue:^{
                [weakself.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationBottom];
            }];
        }                                  fail:^(NSError *error) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Delete Failed", nil) withType:ToastTypeFail showInView:weakself.view complete:nil];
            }];
        }];

    }];

    return @[deleteAction, listAction];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
       if (editingStyle == UITableViewCellEditingStyleDelete) {
    
           }
}
#pragma amrk -- Input box callback

- (void)textFieldDidEndEditingValueChanged:(UITextField *)textField {
    DDLogInfo(@"textfiled:%@", textField.text);
    if (textField.text.length >= 20) {
        textField.text = [textField.text substringToIndex:20];
    }
    UIAlertController *alertView = (UIAlertController *) self.presentedViewController;
    if (alertView) {
        UITextField *textField = alertView.textFields.firstObject;
        UIAlertAction *okAction = alertView.actions.lastObject;
        okAction.enabled = textField.text.length >= 2;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    __weak typeof(self) weakSelf = self;
    NSString *text = textField.text;
    textField.text = nil; //clear
    [self.bitAddressTextField resignFirstResponder];
    self.bitAddressTextField.hidden = YES;
    self.addBtn.hidden = NO;
    if ([KeyHandle checkAddress:text]) {
        [self postAddressToServer:text];
    } else {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Result is not a bitcoin address", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
        }];
        return NO;
    }
    return YES;
}

- (void)postAddressToServer:(NSString *)address {

    // Traverse the array
    for (AddressBookInfo *bookInfo  in self.dataArr) {
        if ([bookInfo.address isEqualToString:address]) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Chat Address already exists", nil) withType:ToastTypeCommon showInView:self.view complete:nil];
            }];
            return;
        }
    }
    // Hide the keyboard
    [GCDQueue executeInMainQueue:^{
        [self.view endEditing:YES];
    }];

    // Server add address
    AddressBook_AddressInfo *addressProtoData = [[AddressBook_AddressInfo alloc] init];
    addressProtoData.address = address;

    __weak typeof(self) weakSelf = self;
    [NetWorkOperationTool POSTWithUrlString:Walletaddress_bookAddUrl postProtoData:addressProtoData.data complete:^(id response) {
        HttpResponse *respo = (HttpResponse *) response;

        if (respo.code != successCode) {
            return;
        }
        AddressBookInfo *info = [[AddressBookInfo alloc] init];
        info.address = address;
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Add Successful", nil) withType:ToastTypeSuccess showInView:weakSelf.view complete:nil];
        }];
        [self.dataArr addObject:info];
        // Save the new address
        [[LMAddressBookManager sharedManager] saveAddress:address];
        [GCDQueue executeInMainQueue:^{
            [self.tableView reloadData];
        }];

    }                                  fail:^(NSError *error) {
        [GCDQueue executeInMainQueue:^{
            [GCDQueue executeInMainQueue:^{
               [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Add Failed", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
            }];
            
        }];
    }];
}

#pragma mark -- Right button

- (void)addRightBarButtonItem {
    UIButton *rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    rightBtn.frame = CGRectMake(0, 0, AUTO_WIDTH(49), AUTO_HEIGHT(42));
    [rightBtn setImage:[UIImage imageNamed:@"camera"] forState:UIControlStateNormal];
    [rightBtn addTarget:self action:@selector(rightBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:rightBtn];
    self.navigationItem.rightBarButtonItem = rightItem;
}

#pragma mark -- Button click method

- (void)addressBtnClick:(UIButton *)btn {

    self.bitAddressTextField.hidden = NO;
    self.addBtn.hidden = YES;
    [self.bitAddressTextField setNeedsDisplay];
    [self.bitAddressTextField becomeFirstResponder];

}

#pragma mark --rightBtnClick

- (void)rightBtnClick:(UIButton *)btn {
    __weak typeof(self) weakSelf = self;
    ScanAddPage *scanPage = [[ScanAddPage alloc] initWithScanComplete:^(NSString *result) {
        result = [result stringByReplacingOccurrencesOfString:@"bitcoin:" withString:@""];
        if ([KeyHandle checkAddress:result]) {// Adapt the rules of the btc platform
            [self postAddressToServer:result];
        } else {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Result is not a bitcoin address", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
            }];
        }
    }];
    scanPage.isFromBook = YES;
    scanPage.title = LMLocalizedString(@"Link Scan", nil);
    [self presentViewController:scanPage animated:NO completion:nil];
}


#pragma mark --lazy

- (NSMutableArray *)dataArr {
    if (_dataArr == nil) {
        _dataArr = [[NSMutableArray alloc] init];
        [_dataArr addObjectsFromArray:[[LMAddressBookManager sharedManager] getAllAddressBooks]];
    }
    return _dataArr;
}
@end
