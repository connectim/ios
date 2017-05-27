//
//  PhoneConatctPage.m
//  Connect
//
//  Created by MoHuilin on 16/5/27.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "PhoneConatctPage.h"
#import "KTSContactsManager.h"
#import "PhoneContactInfo.h"
#import "PhoneContactCell.h"
#import "ConnectTableHeaderView.h"
#import "NSString+DictionaryValue.h"
#import "NCellHeader.h"
#import "NSString+Pinyin.h"
#import "PhoneRegisterCell.h"
#import <MessageUI/MessageUI.h>
#import "NetWorkOperationTool.h"
#import "UserDBManager.h"
#import "UserDetailPage.h"
#import "InviteUserPage.h"
#import "NetWorkTool.h"
#import "ShareMessageModel.h"
#import "LMHistoryCacheManager.h"


@interface PhoneConatctPage () <UITableViewDelegate, UITableViewDataSource, MFMessageComposeViewControllerDelegate>

@property(nonatomic, strong) NSArray *phoneContacts;

@property(nonatomic, strong) NSMutableDictionary *hashMobilesName;

@property(nonatomic, strong) NSMutableArray *registerContacts;

@property(nonatomic, strong) NSMutableArray *groups;
@property(nonatomic, strong) NSMutableArray *indexs;

@property(nonatomic, strong) UITableView *tableView;

@property(nonatomic, strong) NSMutableArray *invitePhoneContacts;

@property(nonatomic, strong) ShareMessageModel *shareModel;

@end

@implementation PhoneConatctPage

- (void)viewDidLoad {
    [super viewDidLoad];
    // invie
    self.title = LMLocalizedString(@"Link Contacts", nil);
    [self setNavigationRightWithTitle:LMLocalizedString(@"Link Invite", nil)];
    self.rightBarBtn.enabled = NO;
    // add font color
    [self.rightBarBtn setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor greenColor]} forState:UIControlStateNormal];
    [self.rightBarBtn setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor grayColor]} forState:UIControlStateDisabled];
    [self.view addSubview:self.tableView];
    
    [self configTableView];
    [GCDQueue executeInGlobalQueue:^{
        [self getRegister];
    }];

    [self getIviteMessage];

    RegisterNotify(ConnnectSendAddRequestSuccennNotification, @selector(sendAddRequestSuccess:));
    RegisterNotify(kAcceptNewFriendRequestNotification, @selector(acceptFriendSuccess:));
    
}

- (void)doRight:(id)sender {
    [self inviteFriends];
}

- (void)dealloc {
    RemoveNofify;
}

- (void)getIviteMessage {
    __weak __typeof(&*self) weakSelf = self;
    [NetWorkTool getWithUrl:ShareAppUrl refreshCache:YES params:nil success:^(id response) {
        NSDictionary *dict = [response mj_JSONObject];
        NSDictionary *data = [dict valueForKey:@"data"];
        ShareMessageModel *shareModel = [ShareMessageModel mj_objectWithKeyValues:data];
        weakSelf.shareModel = shareModel;
    }                  fail:^(NSError *error) {

    }];
}

- (void)getRegister {
    [GCDQueue executeInMainQueue:^{
        [MBProgressHUD showLoadingMessageToView:self.view];
    }];
    __weak __typeof(&*self) weakSelf = self;
    self.hashMobilesName = [NSMutableDictionary dictionary];
    [[KTSContactsManager sharedManager] importContacts:^(NSArray *contacts, BOOL reject) {

        if (reject) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD hideHUDForView:weakSelf.view];
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LMLocalizedString(@"Link Address Book Access Denied", nil) message:LMLocalizedString(@"Link access to your Address Book in Settings", nil) preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common OK", nil) style:UIAlertActionStyleDefault handler:nil];
                [alertController addAction:okAction];
                [weakSelf presentViewController:alertController animated:YES completion:nil];
            }];

            return;
        }

        weakSelf.phoneContacts = [PhoneContactInfo mj_objectArrayWithKeyValuesArray:contacts];

        for (PhoneContactInfo *phoneBook in _phoneContacts) {
            NSString *name = [NSString stringWithFormat:@"%@%@", phoneBook.firstName, phoneBook.lastName];
            for (Phone *phone in phoneBook.phones) {
                NSString *phoneStr = phone.phoneNum;
                phoneStr = [phoneStr stringByReplacingOccurrencesOfString:@"+" withString:@""];
                phoneStr = [phoneStr stringByReplacingOccurrencesOfString:@"-" withString:@""];
                phoneStr = [phoneStr stringByReplacingOccurrencesOfString:@" " withString:@""];
                phoneStr = [phoneStr stringByReplacingOccurrencesOfString:@"(" withString:@""];
                phoneStr = [phoneStr stringByReplacingOccurrencesOfString:@")" withString:@""];
                if ([phoneStr hasPrefix:[[RegexKit phoneCode] stringValue]]) {
                    phoneStr = [phoneStr substringFromIndex:2];
                }
                NSString *hashString = [phoneStr hmacSHA512StringWithKey:hmacSHA512Key];
                [self.hashMobilesName setObject:name forKey:hashString];
            }
        }


        NSMutableArray *items = nil;
        for (NSString *prex in self.indexs) {
            CellGroup *group = [[CellGroup alloc] init];
            group.headTitle = prex;
            items = [NSMutableArray array];
            for (PhoneContactInfo *phoneContact in weakSelf.phoneContacts) {
                NSString *name = [NSString stringWithFormat:@"%@%@", phoneContact.lastName, phoneContact.firstName];
                NSString *namePiny = [[name transformToPinyin] uppercaseString];
                if (namePiny.length <= 0) {
                    continue;
                }
                NSString *pinYPrex = [namePiny substringToIndex:1];
                if (![weakSelf preIsInAtoZ:pinYPrex]) {
                    namePiny = [namePiny stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@"#"];
                }
                if ([namePiny hasPrefix:prex]) {
                    [items objectAddObject:phoneContact];
                }
            }
            group.items = [NSArray arrayWithArray:items];
            [weakSelf.groups objectAddObject:group];
        }

        NSData *data = [[LMHistoryCacheManager sharedManager] getRegisterContactsCache];
        if (data) {
            [weakSelf reloadTableViewWithData:data fromNet:NO];
        }
        [GCDQueue executeInMainQueue:^{
            [weakSelf.tableView reloadData];
        }];
        [weakSelf getRegisterUserByNet];
    }];

}

- (void)acceptFriendSuccess:(NSNotification *)note {
    AccountInfo *user = note.object;

    if (!user) {
        return;
    }

    AccountInfo *findUser = nil;
    NSInteger index = NSNotFound;

    for (AccountInfo *userInfo in self.registerContacts) {
        if ([userInfo.address isEqualToString:user.address]) {
            findUser = userInfo;
            index = [self.registerContacts indexOfObject:userInfo];
            break;
        }
    }
    if (index != NSNotFound && findUser) {
        findUser.stranger = NO;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }

}

- (void)sendAddRequestSuccess:(NSNotification *)note {
    AccountInfo *user = note.object;

    if (!user) {
        return;
    }

    AccountInfo *findUser = nil;
    NSInteger index = NSNotFound;

    for (AccountInfo *userInfo in self.registerContacts) {
        if ([userInfo.address isEqualToString:user.address]) {
            findUser = userInfo;
            index = [self.registerContacts indexOfObject:userInfo];
            break;
        }
    }

    if (index != NSNotFound && findUser) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}


- (void)configTableView {
    [self.tableView registerNib:[UINib nibWithNibName:@"PhoneContactCell" bundle:nil] forCellReuseIdentifier:@"PhoneContactCellID"];
    [self.tableView registerNib:[UINib nibWithNibName:@"PhoneRegisterCell" bundle:nil] forCellReuseIdentifier:@"PhoneRegisterCellID"];
    [self.tableView registerClass:[ConnectTableHeaderView class] forHeaderFooterViewReuseIdentifier:@"ConnectTableHeaderViewID"];
    self.tableView.rowHeight = AUTO_HEIGHT(110);
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.sectionIndexColor = [UIColor lightGrayColor];
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    self.tableView.tableFooterView = [[UIView alloc] init];
}

#pragma mark - 

- (void)getRegisterUserByNet {

    __weak __typeof(&*self) weakSelf = self;

    [NetWorkOperationTool POSTWithUrlString:ContactPhoneBookUrl signNoEncryptPostData:nil
                                   complete:^(id response) {
                                       HttpResponse *hResponse = (HttpResponse *) response;
                                       [GCDQueue executeInMainQueue:^{
                                           [MBProgressHUD hideHUDForView:weakSelf.view];
                                       }];
                                       if (hResponse.code != successCode) {
                                           return;
                                       }
                                       NSData *data = [ConnectTool decodeHttpResponse:hResponse];
                                       if (data) {
                                           // cache
                                           [[LMHistoryCacheManager sharedManager] cacheRegisterContacts:data];

                                           [weakSelf reloadTableViewWithData:data fromNet:YES];

                                       }
                                   } fail:^(NSError *error) {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD hideHUDForView:weakSelf.view];
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                }];
            }];

}

- (void)reloadTableViewWithData:(NSData *)data fromNet:(BOOL)fromNet {
    PhoneBookUsersInfo *users = [PhoneBookUsersInfo parseFromData:data error:nil];
    NSMutableArray *temUsers = [NSMutableArray array];
    for (PhoneBookUserInfo *phoneBookUser in users.usersArray) {
        UserInfo *user = phoneBookUser.user;
        AccountInfo *userInfo = [[AccountInfo alloc] init];
        userInfo.avatar = user.avatar;
        userInfo.address = user.address;
        userInfo.username = user.username;
        userInfo.pub_key = user.pubKey;
        userInfo.stranger = ![[UserDBManager sharedManager] isFriendByAddress:userInfo.address];
        if (userInfo.stranger) {
            userInfo.status = [[UserDBManager sharedManager] getFriendRequestStatusByAddress:user.address];
        } else {
            userInfo.status = RequestFriendStatusAdded;
        }
        userInfo.phoneContactName = [self.hashMobilesName valueForKey:phoneBookUser.phoneHash];
        if (!GJCFStringIsNull(phoneBookUser.phoneHash)) {
             [temUsers objectAddObject:userInfo];
        }
    }
    NSStringCompareOptions comparisonOptions = NSCaseInsensitiveSearch | NSNumericSearch |
            NSWidthInsensitiveSearch | NSForcedOrderingSearch;
    // sort
    [temUsers sortUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
        AccountInfo *user1 = obj1;
        AccountInfo *user2 = obj2;
        NSRange range = NSMakeRange(0, user1.address.length);
        return [user1.address compare:user2.address options:comparisonOptions range:range];
    }];

    if (fromNet) {
        BOOL haveRegister = self.registerContacts.count > 0;
        if (haveRegister) {
            [self.registerContacts removeAllObjects];
            [self.registerContacts addObjectsFromArray:temUsers];
        } else {
            [self.registerContacts addObjectsFromArray:temUsers];
            CellGroup *installedGroup = installedGroup = [[CellGroup alloc] init];
            installedGroup.items = [NSArray arrayWithArray:self.registerContacts];
            installedGroup.headTitle = LMLocalizedString(@"Common Installed", nil);
            [self.groups objectInsert:installedGroup atIndex:0];
        }
    } else {
        [self.registerContacts addObjectsFromArray:temUsers];
        if (temUsers.count > 0) {
            CellGroup *installedGroup = installedGroup = [[CellGroup alloc] init];
            installedGroup.items = [NSArray arrayWithArray:self.registerContacts];
            installedGroup.headTitle = LMLocalizedString(@"Common Installed", nil);
            [self.groups objectInsert:installedGroup atIndex:0];
        }
    }
    [GCDQueue executeInMainQueue:^{
        // refresh ui
        [self.tableView reloadData];
    }];
}

- (void)inviteFriends {
    if (![MFMessageComposeViewController canSendText]) {
        DDLogInfo(@"Message services are not available.");
        return;
    }

    MFMessageComposeViewController *composeVC = [[MFMessageComposeViewController alloc] init];
    composeVC.messageComposeDelegate = self;

    // Configure the fields of the interface.
    composeVC.recipients = self.invitePhoneContacts;
    composeVC.body = [NSString stringWithFormat:LMLocalizedString(@"Link invite encrypted chat with APP Download", nil), [LKUserCenter shareCenter].currentLoginUser.username];
    if (self.shareModel) {
        composeVC.body = [NSString stringWithFormat:@"%@ %@", self.shareModel.desc, self.shareModel.url];
    }

    // Present the view controller modally.
    [self presentViewController:composeVC animated:YES completion:nil];
}

#pragma mark - MFMessageComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [controller dismissViewControllerAnimated:YES completion:nil];
    switch (result) {
        case MessageComposeResultCancelled:
            DDLogInfo(@"MessageComposeResultCancelled");
            break;
        case MessageComposeResultSent:
            DDLogInfo(@"MessageComposeResultSent");

            break;
        case MessageComposeResultFailed:
            DDLogInfo(@"MessageComposeResultFailed");
            break;

        default:
            break;
    }
}

#pragma mark - Table view data source


- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.indexs;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    CellGroup *group = self.groups[section];
    return group.items.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.groups.count;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
     CellGroup *group = self.groups[section];
    if (section == 0) {
        if (group.items.count && [group.items[0] isKindOfClass:[AccountInfo class]]) {
            return 20;
        }else
        {
            return 0;
        }
    }
    return 20;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    ConnectTableHeaderView *hearderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"ConnectTableHeaderViewID"];
    CellGroup *group = self.groups[section];
    hearderView.customTitle.text = group.headTitle;
    if (section == 0) {
        if (group.items.count && [group.items[0] isKindOfClass:[AccountInfo class]]) {
            return hearderView;
        }else
        {
            return nil;
        }
    }

    return hearderView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CellGroup *group = self.groups[indexPath.section];

    if (indexPath.section == 0 && group.items.count && [group.items[0] isKindOfClass:[AccountInfo class]]) {
        PhoneRegisterCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PhoneRegisterCellID" forIndexPath:indexPath];
        cell.data = group.items[indexPath.row];
        return cell;
    }
    PhoneContactCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PhoneContactCellID" forIndexPath:indexPath];
    PhoneContactInfo *phoneContact = group.items[indexPath.row];
    cell.data = phoneContact;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CellGroup *group = self.groups[indexPath.section];
    PhoneContactCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell isKindOfClass:[PhoneRegisterCell class]]) { // installed
        AccountInfo *user = group.items[indexPath.row];
        if (!user.stranger) {
            UserDetailPage *page = [[UserDetailPage alloc] initWithUser:user];
            [self.navigationController pushViewController:page animated:YES];
            return;
        }
        if (user.status == RequestFriendStatusAdd) {
            InviteUserPage *page = [[InviteUserPage alloc] initWithUser:user];
            page.sourceType = UserSourceTypeContact;
            [self.navigationController pushViewController:page animated:YES];
        }

        if (user.status == RequestFriendStatusVerfing) {
            InviteUserPage *page = [[InviteUserPage alloc] initWithUser:user];
            [self.navigationController pushViewController:page animated:YES];
        }
        if (user.status == RequestFriendStatusAdded) {
            UserDetailPage *page = [[UserDetailPage alloc] initWithUser:user];
            [self.navigationController pushViewController:page animated:YES];
        }
        return;
    }
    PhoneContactInfo *phoneContact = group.items[indexPath.row];
    phoneContact.isSelected = !phoneContact.isSelected;
    [cell.checkBox setOn:phoneContact.isSelected animated:YES];
    if (phoneContact.isSelected) {
        for (Phone *phone in phoneContact.phones) {
            NSString *phoneString = phone.phoneNum;
            [self.invitePhoneContacts objectAddObject:phoneString];
        }

    } else {
        for (Phone *phone in phoneContact.phones) {
            NSString *phoneString = phone.phoneNum;
            [self.invitePhoneContacts removeObject:phoneString];
        }
    }
    if (self.invitePhoneContacts.count) {
        self.rightBarBtn.enabled = YES;
    } else {
        self.rightBarBtn.enabled = NO;
    }
}

- (NSMutableArray *)groups {
    if (!_groups) {
        _groups = [NSMutableArray array];
    }
    return _groups;
}

- (NSMutableArray *)indexs {
    if (self.phoneContacts.count <= 0) {
        return nil;
    }
    if (!_indexs) {
        _indexs = [NSMutableArray array];
        for (PhoneContactInfo *phoneContact in self.phoneContacts) {
            NSString *prex = @"";
            NSString *name = [NSString stringWithFormat:@"%@%@", phoneContact.lastName, phoneContact.firstName];
            if (name.length <= 0) {
                continue;
            }
            prex = [[name transformToPinyin] substringToIndex:1];
            if ([self preIsInAtoZ:prex]) {
                [_indexs objectAddObject:[prex uppercaseString]];
            } else {
                [_indexs addObject:@"#"];
            }
            // to leave
            NSMutableSet *set = [NSMutableSet set];
            for (NSObject *obj in _indexs) {
                [set addObject:obj];
            }
            [_indexs removeAllObjects];
            for (NSObject *obj in set) {
                [_indexs objectAddObject:obj];
            }
            // sort 
            [_indexs sortUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
                NSString *str1 = obj1;
                NSString *str2 = obj2;
                return [str1 compare:str2];
            }];
        }
        if (_indexs.count <= 0) {
            _indexs = nil;
        }
    }
    return _indexs;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    }

    return _tableView;
}

- (NSMutableArray *)invitePhoneContacts {
    if (!_invitePhoneContacts) {
        _invitePhoneContacts = [NSMutableArray array];
    }

    return _invitePhoneContacts;
}

- (NSMutableArray *)registerContacts {
    if (!_registerContacts) {
        _registerContacts = [NSMutableArray array];
    }
    return _registerContacts;
}
- (NSArray *)phoneContacts {
    if (!_phoneContacts) {
        _phoneContacts = [NSArray array];
    }
    return _phoneContacts;
}
#pragma mark - privkey Method

- (BOOL)preIsInAtoZ:(NSString *)str {
    return [@"QWERTYUIOPLKJHGFDSAZXCVBNM" containsString:str] || [[@"QWERTYUIOPLKJHGFDSAZXCVBNM" lowercaseString] containsString:str];
}
@end
