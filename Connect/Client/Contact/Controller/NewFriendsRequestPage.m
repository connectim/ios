//
//  NewFriendsRequestPage.m
//  Connect
//
//  Created by MoHuilin on 16/5/27.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "NewFriendsRequestPage.h"
#import "NewFriendCell.h"
#import "UserDetailPage.h"
#import "InviteUserPage.h"
#import "UserDBManager.h"
#import "IMService.h"
#import "TopImageBottomItem.h"
#import "ScanAddPage.h"
#import "NetWorkOperationTool.h"
#import "PhoneConatctPage.h"
#import "UIView+WZLBadge.h"
#import "KTSContactsManager.h"
#import "PhoneContactInfo.h"
#import "BadgeNumberManager.h"
#import "YYImageCache.h"
#import "LMHandleScanResultManager.h"
#import "LMRecommandFriendManager.h"
#import "LMAddMoreViewController.h"
#import "LMLinkManDataManager.h"
#import "LMHistoryCacheManager.h"

#define  MayKnowMaxCount  4

@interface NewFriendsRequestPage () <UITableViewDelegate, UITableViewDataSource, MGSwipeTableCellDelegate>

@property(nonatomic, strong) NSMutableArray *friendRequests;
@property(nonatomic, strong) NSMutableArray *recommandFriendArray;
@property(strong, nonatomic) NSMutableArray *titleArr;
@property(strong, nonatomic) NSMutableArray *allArray;
@property(assign, nonatomic) BOOL isLoading;
@property(nonatomic, strong) UIView *topView;
// Phone address book icon
@property(nonatomic, strong) TopImageBottomItem *contactItem;

@end

@implementation NewFriendsRequestPage
#pragma mark - lazy

- (NSMutableArray *)recommandFriendArray {
    if (_recommandFriendArray == nil) {
        self.recommandFriendArray = [NSMutableArray array];
    }
    return _recommandFriendArray;
}

- (NSMutableArray *)allArray {
    if (_allArray == nil) {
        self.allArray = [NSMutableArray array];
    }
    return _allArray;
}

- (NSMutableArray *)titleArr {
    if (_titleArr == nil) {
        self.titleArr = [NSMutableArray array];
        [self.titleArr objectAddObject:LMLocalizedString(@"Link People you may know", nil)];
        [self.titleArr objectAddObject:LMLocalizedString(@"Link Your invitation", nil)];
    }
    return _titleArr;
}
#pragma mark - begin

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LMLocalizedString(@"Link New friend", nil);

    if (!self.friendRequests) {
        self.friendRequests = [NSMutableArray array];
    }
    self.friendRequests = [[UserDBManager sharedManager] getAllNewFirendRequest].mutableCopy;
    

    __weak __typeof(&*self) weakSelf = self;
    for (AccountInfo *user in _friendRequests) {
        NSString *address = user.address;
        int source = user.source;
        if (user.status == RequestFriendStatusAccept) {
            user.customOperation = ^() {
                [weakSelf acceptRequest:address source:source];
            };
        }
    }

    [self configTableView];

    // set badge
    [[BadgeNumberManager shareManager] getBadgeNumber:ALTYPE_CategoryTwo_PhoneContact Completion:^(BadgeNumber *badgeNumber) {
        UIViewController *viewController = [weakSelf.navigationController.viewControllers lastObject];
        [GCDQueue executeInMainQueue:^{
            if (badgeNumber.count > 0 && [viewController isKindOfClass:[self class]]) {
                [weakSelf.contactItem showBadgeWithStyle:WBadgeStyleNumber value:badgeNumber.count animationType:WBadgeAnimTypeNone];
            }
        }];
    }];

    RegisterNotify(ConnnectSendAddRequestSuccennNotification, @selector(newFriendRequest:));
    RegisterNotify(kNewFriendRequestNotification, @selector(newFriendRequest:));
    RegisterNotify(kAcceptNewFriendRequestNotification, @selector(newFriendRequest:));


#if (TARGET_IPHONE_SIMULATOR)
    // In the case of simulators
#else
    // In the case of real machine
    if (YES) {
        // in the case of wifi
        if (![[MMAppSetting sharedSetting] isHavePhoneContactRegister]) {
            [GCDQueue executeInGlobalQueue:^{
                [self uploadContactAndGetNewPhoneFriends];
            }];
        }
    }
#endif
    // creat recommond man
    [self getArrayFromNetWork];
}

#pragma mark - 数组添加的方法

- (void)getArrayFromNetWork {
    __weak typeof(self) weakSelf = self;
    self.isLoading = YES;
    // creat data source
    [weakSelf creatAllArray];
    [NetWorkOperationTool POSTWithUrlString:GetRecommandFriendUrl postProtoData:nil complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *) response;
        self.isLoading = NO;
        if (hResponse.code == successCode) {
            NSData *data = [ConnectTool decodeHttpResponse:hResponse];
            if (data) {
                NSError *error = nil;
                UsersInfo *usersInfo = [UsersInfo parseFromData:data error:&error];
                weakSelf.recommandFriendArray = [[LMRecommandFriendManager sharedManager] getRecommandFriendsWithPage:1].mutableCopy;
                if (weakSelf.recommandFriendArray.count <= 0) {
                    [[LMRecommandFriendManager sharedManager] saveRecommandFriend:usersInfo.usersArray];
                } else {
                    [weakSelf detailDBArrayWith:usersInfo.usersArray];
                }
                // creat data source
                [weakSelf creatAllArray];
            }
        } else {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:[LMErrorCodeTool showToastErrorType:ToastErrorTypeContact withErrorCode:hResponse.code withUrl:RecommendFindMe] withType:ToastTypeFail showInView:weakSelf.view complete:nil];

            }];
             // creat data source
            [weakSelf creatAllArray];
        }
    }                                  fail:^(NSError *error) {
        self.isLoading = NO;
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:[LMErrorCodeTool showToastErrorType:ToastErrorTypeContact withErrorCode:error.code withUrl:RecommendFindMe] withType:ToastTypeFail showInView:weakSelf.view complete:nil];
             // creat data source
            [weakSelf creatAllArray];
        }];
    }];
}

/**
 *  db action
 */
- (void)detailDBArrayWith:(NSArray *)array {
    NSMutableArray *tmpArray = [NSMutableArray array];

    for (UserInfo *user in array) {
        // set userinfo - accountInfo
        AccountInfo *accountInfo = [[AccountInfo alloc] init];
        accountInfo.username = user.username;
        accountInfo.avatar = user.avatar;
        accountInfo.pub_key = user.pubKey;
        accountInfo.address = user.address;
        accountInfo.recommandStatus = 1;
        if (![[LMRecommandFriendManager sharedManager] getUserInfoWith:accountInfo]) {
            [tmpArray objectAddObject:user];
        }
    }
    [[LMRecommandFriendManager sharedManager] saveRecommandFriend:tmpArray];
    self.recommandFriendArray = [[LMRecommandFriendManager sharedManager] getRecommandFriendsWithPage:1].mutableCopy;

}


- (void)creatAllArray {
    if (self.allArray.count > 0) {
        [self.allArray removeAllObjects];
    }
    [self setMaxArray];
    [self.allArray objectAddObject:self.recommandFriendArray];
    [self.allArray objectAddObject:self.friendRequests];
    [GCDQueue executeInMainQueue:^{
        [self.tableView reloadData];
    }];
}

- (void)setMaxArray {
    for (AccountInfo *user in self.friendRequests) {
        if ([[LMRecommandFriendManager sharedManager] getUserInfoWithAddress:user.address]) {
            [[LMRecommandFriendManager sharedManager] deleteRecommandFriendWithAddress:user.address];
        }
    }
    // filter contacts
    for (AccountInfo *user in [LMLinkManDataManager sharedManager].getListFriendsArr) {
        if ([[LMRecommandFriendManager sharedManager] getUserInfoWithAddress:user.address]) {
            [[LMRecommandFriendManager sharedManager] deleteRecommandFriendWithAddress:user.address];
        }
    }
    self.recommandFriendArray = [[LMRecommandFriendManager sharedManager] getRecommandFriendsWithPage:1 withStatus:1].mutableCopy;
    if (self.recommandFriendArray.count > MayKnowMaxCount) {
        NSMutableArray *tmpArray = [NSMutableArray array];
        for (NSInteger index = 0; index < MayKnowMaxCount; index++) {
            AccountInfo *userInfo = self.recommandFriendArray[index];
            [tmpArray objectAddObject:userInfo];
        }
        [self.recommandFriendArray removeAllObjects];
        self.recommandFriendArray = tmpArray;
    }
}

- (void)dealloc {
    RemoveNofify;
    [self.tableView removeFromSuperview];
    self.tableView = nil;
    self.recommandFriendArray = nil;
    self.allArray = nil;
    self.friendRequests = nil;
    self.titleArr = nil;
}

- (void)uploadContactAndGetNewPhoneFriends {
    __weak __typeof(&*self) weakSelf = self;
    [[KTSContactsManager sharedManager] importContacts:^(NSArray *contacts, BOOL reject) {
        if (reject) {
            [GCDQueue executeInGlobalQueue:^{
                [MBProgressHUD hideHUDForView:weakSelf.view];
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LMLocalizedString(@"Link Address Book Access Denied", nil) message:LMLocalizedString(@"Link access to your Address Book in Settings", nil) preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common OK", nil) style:UIAlertActionStyleDefault handler:nil];
                [alertController addAction:okAction];
                [weakSelf presentViewController:alertController animated:YES completion:nil];
            }];
            return;
        }
        NSMutableArray *hashMobiles = [NSMutableArray array];
        NSMutableArray *phoneContacts = [PhoneContactInfo mj_objectArrayWithKeyValuesArray:contacts];
        for (PhoneContactInfo *info in phoneContacts) {
            for (Phone *phone in info.phones) {
                NSString *phoneStr = phone.phoneNum;
                phoneStr = [phoneStr stringByReplacingOccurrencesOfString:@"+" withString:@""];
                phoneStr = [phoneStr stringByReplacingOccurrencesOfString:@"-" withString:@""];
                phoneStr = [phoneStr stringByReplacingOccurrencesOfString:@" " withString:@""];
                if ([phoneStr hasPrefix:[[RegexKit phoneCode] stringValue]]) {
                    phoneStr = [phoneStr substringFromIndex:2];
                }
                PhoneInfo *phoneInfo = [[PhoneInfo alloc] init];
                phoneInfo.code = [[RegexKit phoneCode] intValue];
                phoneInfo.mobile = [phoneStr hmacSHA512StringWithKey:hmacSHA512Key];
                [hashMobiles objectAddObject:phoneInfo];
            }
        }
#if (TARGET_IPHONE_SIMULATOR)
        // in the case of simulator
        PhoneInfo *phoneInfo = [[PhoneInfo alloc] init];
        phoneInfo.code = [[RegexKit phoneCode] intValue];
        phoneInfo.mobile = [KeyHandle getHash256:@"13281226591"];

        [hashMobiles objectAddObject:phoneInfo];
#else

#endif
        [SetGlobalHandler syncPhoneContactWithHashContact:hashMobiles complete:^(NSTimeInterval time) {
            if (time) {
                [weakSelf getRegisterUserByNet];
            }
        }];
    }];

}

- (void)getRegisterUserByNet {

    __weak __typeof(&*self) weakSelf = self;

    [NetWorkOperationTool POSTWithUrlString:ContactPhoneBookUrl signNoEncryptPostData:nil
                                   complete:^(id response) {
                                       HttpResponse *hResponse = (HttpResponse *) response;
                                       
                                       [[MMAppSetting sharedSetting] haveSyncPhoneContactRegister];
                                       if (hResponse.code != successCode) {
                                           return;
                                       }
                                       NSData *data = [ConnectTool decodeHttpResponse:hResponse];
                                       if (data) {
                                           // cache
                                           [[LMHistoryCacheManager sharedManager] cacheRegisterContacts:data];
                                           
                                           PhoneBookUsersInfo *users = [PhoneBookUsersInfo parseFromData:data error:nil];
                                           NSData *notedData = [[LMHistoryCacheManager sharedManager] getNotificatedContact];
                                           ContactsNotificatedAddress *noteAddress;
                                           if (notedData) {
                                               noteAddress = [ContactsNotificatedAddress parseFromData:[[LMHistoryCacheManager sharedManager] getNotificatedContact] error:nil];
                                           } else{
                                               noteAddress = [ContactsNotificatedAddress new];
                                           }
                                           NSMutableArray *notedAddress = [NSMutableArray arrayWithArray:noteAddress.addressesArray];
                                           NSInteger count = 0;
                                           for (PhoneBookUserInfo *phoneBookUser in users.usersArray) {
                                               UserInfo *user = phoneBookUser.user;
                                               AccountInfo *userInfo = [[AccountInfo alloc] init];
                                               userInfo.avatar = user.avatar;
                                               userInfo.address = user.address;
                                               userInfo.stranger = ![[UserDBManager sharedManager] isFriendByAddress:userInfo.address];
                                               if (!userInfo.stranger) {
                                                   continue;
                                               } else {
                                                   AccountInfo *requestUser = [[UserDBManager sharedManager] getFriendRequestBy:user.address];
                                                   // request no
                                                   if (!requestUser && ![noteAddress.addressesArray containsObject:user.address]) {
                                                       count++;
                                                       if (![notedAddress containsObject:user.address]) {
                                                           [notedAddress objectAddObject:user.address];
                                                       }
                                                   }
                                               }
                                           }
                                           // save Notice
                                           noteAddress.addressesArray = notedAddress;
                                           [[LMHistoryCacheManager sharedManager] cacheNotificatedContacts:noteAddress.data];

                                           if (count > 0) {
                                               BadgeNumber *createBadge = [[BadgeNumber alloc] init];
                                               createBadge.type = ALTYPE_CategoryTwo_PhoneContact;
                                               createBadge.count = count;
                                               createBadge.displayMode = ALDisplayMode_Number;
                                               [[BadgeNumberManager shareManager] setBadgeNumber:createBadge Completion:^(BOOL result) {
                                                   if (result) {

                                                   }
                                               }];
                                               [GCDQueue executeInMainQueue:^{
                                                   [weakSelf.contactItem showBadgeWithStyle:WBadgeStyleNumber value:count animationType:WBadgeAnimTypeNone];
                                               }];
                                           }
                                       }
                                   } fail:^(NSError *error) {

            }];
}


- (void)newFriendRequest:(NSNotification *)note {

    self.friendRequests = [[UserDBManager sharedManager] getAllNewFirendRequest].mutableCopy;
    if (!self.friendRequests) {
        self.friendRequests = [NSMutableArray array];
    }
    __weak __typeof(&*self) weakSelf = self;
    for (AccountInfo *user in _friendRequests) {
        NSString *address = user.address;
        int source = user.source;
        if (user.status == RequestFriendStatusAccept) {
            user.customOperation = ^() {
                DDLogInfo(@"Accept request operation");
                [weakSelf acceptRequest:address source:source];
            };
        }
    }
    [self creatAllArray];
}


- (void)acceptRequest:(NSString *)address source:(int)source {
    // Clear a reminder
    [[BadgeNumberManager shareManager] getBadgeNumber:ALTYPE_CategoryTwo_NewFriend Completion:^(BadgeNumber *badgeNumber) {
        if (badgeNumber) {
            badgeNumber.count--;
            [[BadgeNumberManager shareManager] setBadgeNumber:badgeNumber Completion:^(BOOL result) {

            }];
        }
    }];

    //accept new friend request
    [MBProgressHUD showLoadingMessageToView:self.view];
    [[IMService instance] acceptAddRequestWithAddress:address source:source comlete:^(NSError *error, id data) {
        [GCDQueue executeInMainQueue:^{
            if (error) {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:self.view complete:nil];
                }];
            } else {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD hideHUDForView:self.view];
                }];
                [self reloadCellWithAddress:data];
            }
        }];
    }];
}

- (void)reloadCellWithAddress:(NSString *)address {
    for (AccountInfo *findUser in self.friendRequests) {
        if ([address isEqualToString:findUser.address]) {
            findUser.status = RequestFriendStatusAdded;
            break;
        }
    }
    [self.tableView reloadData];
}

- (void)configTableView {
    [self.tableView registerNib:[UINib nibWithNibName:@"NewFriendCell" bundle:nil] forCellReuseIdentifier:@"NewFriendCellID"];
    self.tableView.sectionIndexColor = [UIColor lightGrayColor];
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = LMBasicBackgroundColor;
    // head
    self.tableView.tableHeaderView = self.topView;
    self.tableView.tableFooterView = [[UIView alloc] init];//http://ios.jobbole.com/84377/
    self.tableView.rowHeight = AUTO_HEIGHT(111);
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
}

#pragma mark - tableview - 头部

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NSArray *array = (NSArray *) self.allArray[section];
    if (array.count) {
        return AUTO_HEIGHT(40);
    }
    return 0;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    CGFloat offsetWidth = 80;
    NSArray *array = (NSArray *) self.allArray[section];
    if (array.count) {
        if (self.recommandFriendArray.count > 0 && section == 0) {
            UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VSIZE.width, AUTO_HEIGHT(40))];
            bgView.backgroundColor = LMBasicBackgroundColor;
            UILabel *titleOneLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, VSIZE.width - 20 - offsetWidth, AUTO_HEIGHT(40))];
            titleOneLabel.backgroundColor = LMBasicBackgroundColor;
            titleOneLabel.text = [NSString stringWithFormat:@"%@", self.titleArr[section]];
            titleOneLabel.font = [UIFont systemFontOfSize:FONT_SIZE(22)];
            titleOneLabel.textColor = [UIColor blackColor];
            titleOneLabel.textAlignment = NSTextAlignmentLeft;
            [bgView addSubview:titleOneLabel];
            // creat button
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.frame = CGRectMake(VSIZE.width - offsetWidth, 0, offsetWidth, AUTO_HEIGHT(40));
            [button setTitleColor:LMBasicBlack forState:UIControlStateNormal];
            if (self.isLoading) {
                [button setTitle:LMLocalizedString(@"Common Loading", nil) forState:UIControlStateNormal];
            } else {
                if ([self isShowDisplayMoreWithSection:0]) {
                    // load more
                    [button setTitle:LMLocalizedString(@"Link More", nil) forState:UIControlStateNormal];
                    [button setTitleColor:LMBasicBlue forState:UIControlStateNormal];
                    [button addTarget:self action:@selector(moreButtonClick) forControlEvents:UIControlEventTouchUpInside];
                } else
                {
                    [button setTitle:nil forState:UIControlStateNormal];
                }
            }
            button.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(22)];
            [bgView addSubview:button];
            return bgView;
        } else {
            UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VSIZE.width, AUTO_HEIGHT(40))];
            bgView.backgroundColor = LMBasicBackgroundColor;
            UILabel *titleOneLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, VSIZE.width - 20, AUTO_HEIGHT(40))];
            titleOneLabel.backgroundColor = LMBasicBackgroundColor;
            titleOneLabel.text = [NSString stringWithFormat:@"%@", self.titleArr[section]];
            titleOneLabel.font = [UIFont systemFontOfSize:FONT_SIZE(22)];
            titleOneLabel.textColor = [UIColor blackColor];
            titleOneLabel.textAlignment = NSTextAlignmentLeft;
            [bgView addSubview:titleOneLabel];
            return bgView;
        }
    } else {
        return nil;
    }
}

#pragma mark - 更多按钮的点击事件

- (void)moreButtonClick {
    LMAddMoreViewController *addMoreVc = [[LMAddMoreViewController alloc] init];
    [self.navigationController pushViewController:addMoreVc animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *array = (NSArray *) self.allArray[section];
    return array.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.allArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    __weak typeof(self) weakSelf = self;
    NSArray *array = (NSArray *) self.allArray[indexPath.section];
    NewFriendCell *fcell = [tableView dequeueReusableCellWithIdentifier:@"NewFriendCellID" forIndexPath:indexPath];
    fcell.addButtonBlock = ^(AccountInfo *userInfo) {
        [weakSelf clickMayKnowManWithUserInfo:userInfo];
    };
    fcell.delegate = self;
    fcell.data = array[indexPath.row];
    return fcell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}


#pragma mark - MGSwipeTableCellDelegate

- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell canSwipe:(MGSwipeDirection)direction; {
    return YES;
}

- (NSArray *)swipeTableCell:(MGSwipeTableCell *)cell swipeButtonsForDirection:(MGSwipeDirection)direction
              swipeSettings:(MGSwipeSettings *)swipeSettings expansionSettings:(MGSwipeExpansionSettings *)expansionSettings {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    __weak __typeof(&*self) weakSelf = self;
    CGFloat padding = AUTO_WIDTH(50);
    if (direction == MGSwipeDirectionRightToLeft) {
        MGSwipeButton *trashButton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"message_trash"] backgroundColor:[UIColor whiteColor] padding:padding callback:^BOOL(MGSwipeTableCell *sender) {
            if (weakSelf.allArray.count == 1) {
                if (weakSelf.recommandFriendArray.count > 0) {
                    UserInfo *userInfo = weakSelf.recommandFriendArray[indexPath.row];
                    // not interested
                    [weakSelf NotInterestedWithAddress:userInfo.address];
                } else {
                    // delete data
                    [weakSelf deleteYourInvitationWithIndexPath:indexPath];
                }
            } else {
                if (indexPath.section == 0) {
                    UserInfo *userInfo = weakSelf.recommandFriendArray[indexPath.row];
                    // not interested
                    [weakSelf NotInterestedWithAddress:userInfo.address];
                } else {
                    // delete data
                    [weakSelf deleteYourInvitationWithIndexPath:indexPath];
                }
            }
            return YES;
        }];
        return @[trashButton];
    }
    return nil;
}

- (void)swipeTableCell:(MGSwipeTableCell *)cell didChangeSwipeState:(MGSwipeState)state gestureIsActive:(BOOL)gestureIsActive {
    if (state == MGSwipeStateNone) {
        self.tableView.scrollEnabled = YES;
    } else {
        self.tableView.scrollEnabled = NO;
    }
}

#pragma mark - not intereste any more

- (void)NotInterestedWithAddress:(NSString *)oldAddress {
    [MBProgressHUD showLoadingMessageToView:self.view];
    [[IMService instance] setRecommandUserNoInterestAdress:oldAddress comlete:^(NSError *error, id data) {
        if (error == nil) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD hideHUDForView:self.view];
            }];
            NSString *address = (NSString *) data;
            [[LMRecommandFriendManager sharedManager] updateRecommandFriendStatus:3 withAddress:address];
            [self creatAllArray];
        } else {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Operation failed", nil) withType:ToastTypeFail showInView:self.view complete:nil];
            }];
        }
    }];
}
/**
 * delete recommand data
 */
- (void)deleteYourInvitationWithIndexPath:(NSIndexPath *)indexPath {
    // delete data
    AccountInfo *user = self.friendRequests[indexPath.row];
    [[UserDBManager sharedManager] deleteRequestUserByAddress:user.address];
    [self.friendRequests removeObject:user];
    [GCDQueue executeInMainQueue:^{
        [self.tableView reloadData];
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSArray *array = (NSArray *) self.allArray[indexPath.section];
    id data = array[indexPath.row];

    AccountInfo *user = (AccountInfo *) data;
    if (user.recommandStatus != 1) {
        // my invite
        AccountInfo *user = (AccountInfo *) data;
        
        switch (user.status) {
            case RequestFriendStatusAccept: // other add me accept
            {
                user.stranger = YES;
                UserDetailPage *page = [[UserDetailPage alloc] initWithUser:user];
                [self.navigationController pushViewController:page animated:YES];
                
            }
                break;
            case RequestFriendStatusAdded:// other add me accept , dispaly name card
            {
                user.stranger = NO;
                UserDetailPage *page = [[UserDetailPage alloc] initWithUser:user];
                [self.navigationController pushViewController:page animated:YES];
            }
                break;
                
            case RequestFriendStatusVerfing:// me add other Verification
            {
                InviteUserPage *page = [[InviteUserPage alloc] initWithUser:user];
                [self.navigationController pushViewController:page animated:YES];
                
            }
                break;
            default:
                break;
        }
    } else           // recommand man
    {
        [self clickMayKnowManWithUserInfo:user];
    }
}

- (void)clickMayKnowManWithUserInfo:(AccountInfo *)userInfo {
    userInfo.source = UserSourceTypeRecommend;
    userInfo.stranger = YES;
    InviteUserPage *page = [[InviteUserPage alloc] initWithUser:userInfo];
    page.sourceType = UserSourceTypeRecommend;
    [self.navigationController pushViewController:page animated:YES];
}

- (UIView *)topView {
    if (!_topView) {
        _topView = [UIView new];

        UIView *contentView = [[UIView alloc] init];
        _topView.frame = CGRectMake(0, 0, DEVICE_SIZE.width, AUTO_HEIGHT(225));
        contentView.frame = CGRectMake(0, 0, DEVICE_SIZE.width, AUTO_HEIGHT(225));
        [_topView addSubview:contentView];
        _topView.backgroundColor = [UIColor whiteColor];

        NSMutableArray *icons = @[@"contract_add_scan", @"contract_add_contacts", @"contract_add_more"].mutableCopy;
        NSMutableArray *titles = @[LMLocalizedString(@"Link Scan", nil), LMLocalizedString(@"Link Contacts", nil), LMLocalizedString(@"Link More", nil)].mutableCopy;
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10")) {
            icons = @[@"contract_add_scan", @"contract_add_contacts", @"contract_add_more"].mutableCopy;
            titles = @[LMLocalizedString(@"Link Scan", nil), LMLocalizedString(@"Link Contacts", nil), LMLocalizedString(@"Link More", nil)].mutableCopy;
        }
        CGFloat marginY = AUTO_HEIGHT(45);
        CGFloat itemW = AUTO_HEIGHT(100);
        CGFloat margin = (DEVICE_SIZE.width - 3 * itemW) / 6;
        CGFloat itemH = _topView.height - marginY * 2;
        CGFloat baseY = marginY;
        int col = 0;
        for (int i = 0; i < icons.count; i++) {
            TopImageBottomItem *item = [TopImageBottomItem itemWihtIcon:[icons objectAtIndexCheck:i] title:[titles objectAtIndexCheck:i]];
            item.margin = 2;
            item.tag = i;
            if (i == 1) {
                self.contactItem = item;
            }
            col = i % 3;

            item.frame = CGRectMake(col * (margin * 2 + itemW) + margin, baseY, itemW, itemH);
            [item addTarget:self action:@selector(itemClick:) forControlEvents:UIControlEventTouchUpInside];
            [contentView addSubview:item];
        }
    }

    return _topView;
}

- (void)itemClick:(UIButton *)btn {
    __weak __typeof(&*self) weakSelf = self;
    switch (btn.tag) {
        case 0: {
            ScanAddPage *scanPage = [[ScanAddPage alloc] initWithScanComplete:^(NSString *scanString) {
                __strong __typeof(&*weakSelf) strongSelf = weakSelf;
                [[LMHandleScanResultManager sharedManager] handleScanResult:scanString controller:strongSelf];
            }];
            scanPage.showMyQrCode = YES;
            [self presentViewController:scanPage animated:NO completion:nil];
        }
            break;
        case 1: {
            // clear
            [[BadgeNumberManager shareManager] clearBadgeNumber:ALTYPE_CategoryTwo_PhoneContact Completion:^{

            }];
            [self.contactItem clearBadge];
            PhoneConatctPage *contactPage = [[PhoneConatctPage alloc] init];
            [self.navigationController pushViewController:contactPage animated:YES];
        }
            break;
        case 2: {
            NSString *title = [NSString stringWithFormat:
                    LMLocalizedString(@"Link invite you to start encrypted chat with Connect", nil), [[LKUserCenter shareCenter] currentLoginUser].username];
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?address=%@", H5ShareServerUrl, [[LKUserCenter shareCenter] currentLoginUser].address]];
            UIImage * avatar = [[YYImageCache sharedCache] getImageForKey:[[LKUserCenter shareCenter] currentLoginUser].avatar];
            if (!avatar) {
                avatar = [UIImage imageNamed:@"default_user_avatar"];
            }
            UIActivityViewController *activeViewController = [[UIActivityViewController alloc] initWithActivityItems:@[title, url, avatar] applicationActivities:nil];
            activeViewController.excludedActivityTypes = @[UIActivityTypeAirDrop, UIActivityTypeCopyToPasteboard, UIActivityTypeAddToReadingList];
            [self presentViewController:activeViewController animated:YES completion:nil];
            UIActivityViewControllerCompletionWithItemsHandler myblock = ^(NSString *__nullable activityType, BOOL completed, NSArray *__nullable returnedItems, NSError *__nullable activityError) {
                NSLog(@"%d %@", completed, activityType);
            };
            activeViewController.completionWithItemsHandler = myblock;
        }
            break;
        default:
            break;
    }
}

#pragma mark - display more is weather

- (BOOL)isShowDisplayMoreWithSection:(NSInteger)section {
    NSArray *tmpArray = [[LMRecommandFriendManager sharedManager] getRecommandFriendsWithPage:1 withStatus:1].mutableCopy;
    if ((section == 0) && (tmpArray.count > MayKnowMaxCount)) {
        return YES;
    } else {
        return NO;
    }
}
@end
