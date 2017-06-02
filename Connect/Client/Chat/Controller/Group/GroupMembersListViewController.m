//
//  GroupMembersListViewController.m
//  Connect
//
//  Created by MoHuilin on 16/7/19.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "GroupMembersListViewController.h"
#import "GroupMemberListCell.h"
#import "NCellHeader.h"
#import "ConnectTableHeaderView.h"
#import "NSString+Pinyin.h"
#import "NetWorkOperationTool.h"
#import "IMService.h"
#import "UserDBManager.h"
#import "UserDetailPage.h"
#import "InviteUserPage.h"
#import "ChooseContactViewController.h"
#import "GroupDBManager.h"
#import "MessageDBManager.h"
#import "MyInfoPage.h"
#include "RecentChatDBManager.h"


@interface GroupMembersListViewController () <UITableViewDelegate, UITableViewDataSource, MGSwipeTableCellDelegate> {
    AccountInfo *currentUser;
}

@property(nonatomic, strong) NSMutableArray *groupMembers;
@property(nonatomic, strong) NSMutableArray *groups;
@property(nonatomic, strong) NSMutableArray *indexs;
@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, assign) BOOL isGroupAdmin;
@property(nonatomic, copy) NSString *groupid;
@property(nonatomic, copy) NSString *groupEcdhKey;
@property(nonatomic, strong) NSArray *addMembers;
@property(nonatomic, strong) AccountInfo *adminAttron;

@end

@implementation GroupMembersListViewController

- (instancetype)initWithMembers:(NSArray *)members currentIsGroupAdmin:(BOOL)isGroupAdmin {
    if (self = [super init]) {
        self.groupMembers = [NSMutableArray arrayWithArray:members];
        self.isGroupAdmin = isGroupAdmin;
        currentUser = [[LKUserCenter shareCenter] currentLoginUser];
    }
    return self;
}

- (instancetype)initWithMemberInfos:(NSArray *)members groupIdentifer:(NSString *)groupid groupEchhKey:(NSString *)groupEcdhKey {
    if (self = [super init]) {
        self.groupMembers = [NSMutableArray arrayWithArray:members];
        self.groupid = groupid;
        self.groupEcdhKey = groupEcdhKey;
        NSAssert(!GJCFStringIsNull(groupEcdhKey), @"群组密钥不能为空");
        NSAssert(!GJCFStringIsNull(groupid), @"群组ID不能为空");
        currentUser = [[LKUserCenter shareCenter] currentLoginUser];
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.fromSource == FromSourceTypeGroupManager) {
        self.title = LMLocalizedString(@"Link Select new owner", nil);
    } else {
        [self setNavigationRightWithTitle:LMLocalizedString(@"Link Invite", nil)];
        self.title = [NSString stringWithFormat:LMLocalizedString(@"Chat Group Members", nil), self.groupMembers.count];
    }
    [self configTableView];
    [self.view addSubview:self.tableView];

}

#pragma mark - invite new group member

- (void)doRight:(id)sender {
    ChooseContactViewController *page = [[ChooseContactViewController alloc] initWithChooseComplete:^(NSArray *selectContactArray) {
        DDLogInfo(@"%@", selectContactArray);
        [self addNewGroupMembers:selectContactArray];
    }                                                                          defaultSelectedUsers:self.groupMembers];

    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:page] animated:YES completion:nil];


}

- (void)addNewGroupMembers:(NSArray *)contacts {
    __weak __typeof(&*self) weakSelf = self;
    [GCDQueue executeInMainQueue:^{
        [MBProgressHUD showMessage:LMLocalizedString(@"Invite...", nil) toView:weakSelf.view];
    }];
    [self verifyWith:contacts];
}

- (void)verifyWith:(NSArray *)contacts {
    NSMutableDictionary *userDict = [NSMutableDictionary dictionary];
    NSMutableArray *addresses = [NSMutableArray array];
    for (AccountInfo *user in contacts) {
        [addresses objectAddObject:user.address];
        [userDict setObject:user forKey:user.address];
    }

    GroupInviteUser *inviteUser = [GroupInviteUser new];
    inviteUser.identifier = self.talkInfo.chatGroupInfo.groupIdentifer;
    inviteUser.addressesArray = addresses;
    [NetWorkOperationTool POSTWithUrlString:GroupInviteTokenUrl postProtoData:inviteUser.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *) response;
        if (hResponse.code != successCode) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:hResponse.message withType:ToastTypeFail showInView:self.view complete:nil];
            }];
            return;
        }
        NSData *data = [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            GroupInviteResponseList *tokenList = [GroupInviteResponseList parseFromData:data error:nil];
            for (GroupInviteResponse *tokenResponse in tokenList.listArray) {
                AccountInfo *info = [userDict valueForKey:tokenResponse.address];
                if (GJCFStringIsNull(info.address)) {
                    continue;
                }
                if ([info.pub_key isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].pub_key]) {
                    continue;
                }

                NSString *msgId = [ConnectTool generateMessageId];
                ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
                chatMessage.messageId = msgId;
                chatMessage.messageOwer = info.pub_key;
                chatMessage.createTime = [[NSDate date] timeIntervalSince1970] * 1000;
                MMMessage *message = [[MMMessage alloc] init];
                message.type = GJGCChatInviteToGroup;
                message.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
                message.message_id = msgId;
                message.publicKey = info.pub_key;
                message.user_id = info.address;
                message.ext1 = @{@"avatar": self.talkInfo.chatGroupInfo.avatarUrl ? self.talkInfo.chatGroupInfo.avatarUrl : @"",
                        @"groupname": self.talkInfo.chatGroupInfo.groupName,
                        @"groupidentifier": self.talkInfo.chatGroupInfo.groupIdentifer,
                        @"inviteToken": tokenResponse.token};
                message.senderInfoExt = @{@"username": [[LKUserCenter shareCenter] currentLoginUser].username,
                        @"address": [[LKUserCenter shareCenter] currentLoginUser].address,
                        @"publickey": [[LKUserCenter shareCenter] currentLoginUser].pub_key,
                        @"avatar": [[LKUserCenter shareCenter] currentLoginUser].avatar};
                message.sendstatus = GJGCChatFriendSendMessageStatusSending;
                chatMessage.message = message;
                [[MessageDBManager sharedManager] saveMessage:chatMessage];

                [[RecentChatDBManager sharedManager] createNewChatWithIdentifier:info.pub_key groupChat:NO lastContentShowType:0 lastContent:[GJGCChatFriendConstans lastContentMessageWithType:message.type textMessage:nil]];

                [[IMService instance] asyncSendMessageMessage:message onQueue:nil completion:^(MMMessage *message, NSError *error) {

                    ChatMessageInfo *chatMessage = [[MessageDBManager sharedManager] getMessageInfoByMessageid:message.message_id messageOwer:message.publicKey];
                    chatMessage.message = message;
                    chatMessage.sendstatus = message.sendstatus;
                    [[MessageDBManager sharedManager] updataMessage:chatMessage];
                    if (message.sendstatus == GJGCChatFriendSendMessageStatusSuccess) {
                        [GCDQueue executeInMainQueue:^{
                            [MBProgressHUD showToastwithText:LMLocalizedString(@"Group invitation has been sent", nil) withType:ToastTypeSuccess showInView:self.view complete:^{

                            }];
                        }];
                    } else {
                        [GCDQueue executeInMainQueue:^{
                            [MBProgressHUD showToastwithText:LMLocalizedString(@"Group invitation sent failed", nil) withType:ToastTypeFail showInView:self.view complete:^{

                            }];
                        }];
                    }
                }                                     onQueue:nil];
            }
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD hideHUDForView:self.view];
            }];
        }
    }                                  fail:^(NSError *error) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Server error,Try later", nil) withType:ToastTypeFail showInView:self.view complete:nil];
        }];
    }];
}

- (void)reloadView {
    [self.groupMembers addObjectsFromArray:self.addMembers];
    [self.groups removeAllObjects];
    self.groups = nil;

    [self.indexs removeAllObjects];
    self.indexs = nil;

    [GCDQueue executeInMainQueue:^{
        self.title = [NSString stringWithFormat:LMLocalizedString(@"Chat Group Members", nil), self.groupMembers.count];
        [self.tableView reloadData];
    }];
}

- (void)inviteNewMembers:(NSArray *)membsers {

    self.addMembers = membsers.copy;

    [self reloadView];
    NSMutableString *welcomeTip = [NSMutableString string];
    CreateGroupMessage *groupMessage = [[CreateGroupMessage alloc] init];
    groupMessage.secretKey = self.groupEcdhKey;
    groupMessage.identifier = self.groupid;

    for (AccountInfo *info in membsers) {

        if ([info.pub_key isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].pub_key]) {
            continue;
        }

        [welcomeTip appendString:info.username];
        if (info != [membsers lastObject]) {
            [welcomeTip appendString:@"、"];
        }

        GcmData *groupInfoGcmData = [ConnectTool createGcmWithData:groupMessage.data publickey:info.pub_key needEmptySalt:YES];
        NSString *messageID = [ConnectTool generateMessageId];

        MessageData *messageData = [[MessageData alloc] init];
        messageData.cipherData = groupInfoGcmData;
        messageData.receiverAddress = info.address;
        messageData.msgId = messageID;
        NSString *sign = [ConnectTool signWithData:messageData.data];
        MessagePost *messagePost = [[MessagePost alloc] init];
        messagePost.sign = sign;
        messagePost.pubKey = [[LKUserCenter shareCenter] currentLoginUser].pub_key;
        messagePost.msgData = messageData;
        [[IMService instance] asyncSendGroupInfo:messagePost];
    }
    //create local message
    NSString *myChatTip = [NSString stringWithFormat:LMLocalizedString(@"Link invited to the group chat", nil), LMLocalizedString(@"Chat You", nil), welcomeTip];
    SendNotify(ConnnectGroupInfoDidAddMembers, myChatTip);
    NSString *msgId = [ConnectTool generateMessageId];
    ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
    chatMessage.messageId = msgId;
    chatMessage.messageOwer = self.groupid;
    chatMessage.createTime = [[NSDate date] timeIntervalSince1970] * 1000;
    MMMessage *message1 = [[MMMessage alloc] init];
    message1.type = GJGCChatFriendContentTypeStatusTip;
    message1.content = myChatTip;
    message1.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
    message1.message_id = msgId;
    message1.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
    chatMessage.message = message1;
    [[MessageDBManager sharedManager] saveMessage:chatMessage];

    MMMessage *message = [[MMMessage alloc] init];
    message.user_name = @"";
    message.type = GJGCChatFriendContentTypeStatusTip;
    message.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
    message.message_id = [ConnectTool generateMessageId];
    message.content = [NSString stringWithFormat:LMLocalizedString(@"Link invited to the group chat", nil), [[LKUserCenter shareCenter] currentLoginUser].username, welcomeTip];
    message.senderInfoExt = @{@"username": [[LKUserCenter shareCenter] currentLoginUser].username,
            @"address": [[LKUserCenter shareCenter] currentLoginUser].address,
            @"avatar": [[LKUserCenter shareCenter] currentLoginUser].avatar};
    message.publicKey = self.groupid;
    message.user_id = self.groupid;
    message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
    __weak __typeof(&*self) weakSelf = self;
    [[IMService instance] asyncSendGroupMessage:message withGroupEckhKey:self.groupEcdhKey onQueue:nil completion:^(MMMessage *message, NSError *error) {
        [GCDQueue executeInMainQueue:^{
            SendNotify(ConnnectSendMessageSuccessNotification, weakSelf.groupid);
        }];
    }                                   onQueue:nil];
}


- (void)configTableView {

    [self.tableView registerNib:[UINib nibWithNibName:@"GroupMemberListCell" bundle:nil] forCellReuseIdentifier:@"GroupMemberListCellID"];
    [self.tableView registerClass:[ConnectTableHeaderView class] forHeaderFooterViewReuseIdentifier:@"ConnectTableHeaderViewID"];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = AUTO_HEIGHT(111);
    self.tableView.sectionIndexColor = [UIColor lightGrayColor];
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
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
    return 20;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    ConnectTableHeaderView *hearderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"ConnectTableHeaderViewID"];
    CellGroup *group = self.groups[section];
    hearderView.customTitle.text = group.headTitle;
    return hearderView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CellGroup *group = self.groups[indexPath.section];
    GroupMemberListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GroupMemberListCellID" forIndexPath:indexPath];
    cell.delegate = self;

    AccountInfo *contact = group.items[indexPath.row];

    cell.data = contact;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CellGroup *group = self.groups[indexPath.section];
    AccountInfo *contact = group.items[indexPath.row];
    DDLogInfo(@"%@", [contact mj_JSONObject]);
    if (self.fromSource == FromSourceTypeGroupManager) {
        self.adminAttron = contact;
        [self detailManageWithAlert:contact];
    } else {
        [self showUserDetailPageWithUser:contact];
    }
}

#pragma mark - group manage

- (void)detailManageWithAlert:(AccountInfo *)contact {
    __weak typeof(self) weakSelf = self;
    NSString *disPlayName = [NSString stringWithFormat:LMLocalizedString(@"Link Selecting  new owner  release your ownership", nil), contact.username];
    UIAlertController *alertControl = [UIAlertController alertControllerWithTitle:nil message:disPlayName preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {

        [weakSelf groupAttornWithNewAdmin];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleDefault handler:nil];
    [alertControl addAction:cancelAction];
    [alertControl addAction:okAction];
    [self presentViewController:alertControl animated:YES completion:nil];


}

- (void)showUserDetailPageWithUser:(AccountInfo *)user {
    if ([user.address isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
        MyInfoPage *page = [[MyInfoPage alloc] init];

        [self.navigationController pushViewController:page animated:YES];

        return;
    }

    AccountInfo *localUser = [[UserDBManager sharedManager] getUserByAddress:user.address];
    if (localUser) {
        user = localUser;
    }

    if (!user.stranger) {
        UserDetailPage *page = [[UserDetailPage alloc] initWithUser:user];
        [self.navigationController pushViewController:page animated:YES];
    } else {
        InviteUserPage *page = [[InviteUserPage alloc] initWithUser:user];
        page.sourceType = UserSourceTypeGroup;
        [self.navigationController pushViewController:page animated:YES];
    }
}


- (NSMutableArray *)groups {
    if (self.groupMembers.count <= 0) {
        return nil;
    }
    if (!_groups) {
        _groups = [NSMutableArray array];
        NSMutableArray *items = nil;

        for (NSString *prex in self.indexs) {
            CellGroup *group = [[CellGroup alloc] init];
            group.headTitle = prex;
            items = [NSMutableArray array];
            for (AccountInfo *contact in self.groupMembers) {
                NSString *name = contact.groupShowName;
                NSString *namePiny = [[name transformToPinyin] uppercaseString];
                if (namePiny.length <= 0) {
                    continue;
                }
                NSString *pinYPrex = [namePiny substringToIndex:1];
                if (![self preIsInAtoZ:pinYPrex]) {
                    namePiny = [namePiny stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@"#"];
                }
                if ([namePiny hasPrefix:prex]) {
                    [items objectAddObject:contact];
                }
            }
            group.items = [NSArray arrayWithArray:items];
            [_groups objectAddObject:group];
        }
    }
    return _groups;
}

- (NSMutableArray *)indexs {
    if (self.groupMembers.count <= 0) {
        return nil;
    }
    if (!_indexs) {
        _indexs = [NSMutableArray array];
        for (AccountInfo *contact in self.groupMembers) {
            NSString *prex = @"";
            NSString *name = contact.groupShowName;
            if (name.length <= 0) {
                continue;
            }
            prex = [[name transformToPinyin] substringToIndex:1];
            if ([self preIsInAtoZ:prex]) {
                [_indexs objectAddObject:[prex uppercaseString]];
            } else {
                [_indexs objectAddObject:@"#"];
            }
            NSMutableSet *set = [NSMutableSet set];
            for (NSObject *obj in _indexs) {
                [set addObject:obj];
            }
            [_indexs removeAllObjects];
            for (NSObject *obj in set) {
                [_indexs objectAddObject:obj];
            }
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


#pragma mark - privkey Method

- (BOOL)preIsInAtoZ:(NSString *)str {
    return [@"QWERTYUIOPLKJHGFDSAZXCVBNM" containsString:str] || [[@"QWERTYUIOPLKJHGFDSAZXCVBNM" lowercaseString] containsString:str];
}


#pragma mark Swipe Delegate

- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell canSwipe:(MGSwipeDirection)direction {

    AccountInfo *admin = [self.groupMembers firstObject];
    if ([currentUser.address isEqualToString:admin.address]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

        CellGroup *group = [self.groups objectAtIndexCheck:indexPath.section];
        AccountInfo *willRemoveUser = group.items[indexPath.row];

        if (willRemoveUser.isGroupAdmin) {
            return NO;
        } else {
            return YES;
        }

    } else {
        return NO;
    }
}

- (NSArray *)swipeTableCell:(MGSwipeTableCell *)cell swipeButtonsForDirection:(MGSwipeDirection)direction
              swipeSettings:(MGSwipeSettings *)swipeSettings expansionSettings:(MGSwipeExpansionSettings *)expansionSettings {

    __weak __typeof(&*self) weakSelf = self;

    swipeSettings.transition = MGSwipeTransitionStatic;

    if (direction == MGSwipeDirectionRightToLeft) {

        CGFloat padding = 20;
        MGSwipeButton *setButton = [MGSwipeButton buttonWithTitle:LMLocalizedString(@"Link Delete", nil) backgroundColor:[UIColor redColor] padding:padding callback:^BOOL(MGSwipeTableCell *sender) {
            [weakSelf removeUserFromThisGroup:cell];
            return YES;
        }];
        return @[setButton];
    }

    return nil;

}

- (void)swipeTableCell:(MGSwipeTableCell *)cell didChangeSwipeState:(MGSwipeState)state gestureIsActive:(BOOL)gestureIsActive {
    if (state == MGSwipeStateNone) {
        self.tableView.scrollEnabled = YES;
    } else {
        self.tableView.scrollEnabled = NO;
    }
    NSString *str;
    switch (state) {
        case
            MGSwipeStateNone:
            str = @"None";
            break;
        case MGSwipeStateSwippingLeftToRight:
            str = @"SwippingLeftToRight";
            break;
        case MGSwipeStateSwippingRightToLeft:
            str = @"SwippingRightToLeft";
            break;
        case MGSwipeStateExpandingLeftToRight:
            str = @"ExpandingLeftToRight";
            break;
        case MGSwipeStateExpandingRightToLeft:
            str = @"ExpandingRightToLeft";
            break;
    }
    DDLogInfo(@"Swipe state: %@ ::: Gesture: %@", str, gestureIsActive ? @"Active" : @"Ended");
}


#pragma mark - remove user

- (void)removeUserFromThisGroup:(UITableViewCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    __weak __typeof(&*self) weakSelf = self;
    CellGroup *group = [self.groups objectAtIndexCheck:indexPath.section];
    AccountInfo *willRemoveUser = group.items[indexPath.row];
    DelOrQuitGroupMember *adduser = [[DelOrQuitGroupMember alloc] init];
    adduser.identifier = self.groupid;
    adduser.address = willRemoveUser.address;

    [MBProgressHUD showMessage:LMLocalizedString(@"Common Loading", nil) toView:self.view];

    [NetWorkOperationTool POSTWithUrlString:GroupGroupDeleteUserUrl postProtoData:adduser.data complete:^(id response) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:weakSelf.view];
        }];
        HttpResponse *hResponse = (HttpResponse *) response;
        if (hResponse.code != successCode) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Remove Member Failed", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
            }];
            return;
        }

        [[GroupDBManager sharedManager] removeMemberWithAddress:willRemoveUser.address groupId:weakSelf.groupid];

        NSArray *groupArray = [[GroupDBManager sharedManager] getgroupMemberByGroupIdentifier:weakSelf.groupid];
        if (groupArray.count <= 1) {
            [[GroupDBManager sharedManager] deletegroupWithGroupId:weakSelf.groupid];
        } else {
            [GCDQueue executeInMainQueue:^{
                SendNotify(ConnnectGroupInfoDidChangeNotification, weakSelf.groupid);
            }];

            [weakSelf createRemoveMessageWithUser:willRemoveUser];
        }

    }                                  fail:^(NSError *error) {
        [MBProgressHUD hideHUDForView:weakSelf.view];
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Remove Member Failed", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
        }];

    }];

}


- (void)createRemoveMessageWithUser:(AccountInfo *)user {

    [self.groupMembers removeObject:user];
    [self reloadView];
    SendNotify(ConnnectGroupInfoDidDeleteMember, user.username);
    NSString *msgId = [ConnectTool generateMessageId];
    ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
    chatMessage.messageId = msgId;
    chatMessage.messageOwer = self.groupid;
    chatMessage.createTime = [[NSDate date] timeIntervalSince1970] * 1000;
    MMMessage *message = [[MMMessage alloc] init];
    message.type = GJGCChatFriendContentTypeStatusTip;
    message.content = [NSString stringWithFormat:LMLocalizedString(@"Link You Remove from the group chat", nil), user.username];
    message.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
    message.message_id = msgId;
    message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
    chatMessage.message = message;

    [[MessageDBManager sharedManager] saveMessage:chatMessage];

}


#pragma mark - group attorn

- (void)groupAttornWithNewAdmin {

    if (GJCFStringIsNull(self.groupid) || GJCFStringIsNull(self.adminAttron.address)) {
        [MBProgressHUD showToastwithText:@"Occour unknow error" withType:ToastTypeFail showInView:self.view complete:nil];
        return;
    }
    GroupAttorn *attron = [GroupAttorn new];
    attron.identifier = self.groupid;
    attron.address = self.adminAttron.address;
    [NetWorkOperationTool POSTWithUrlString:GroupAttornUrl postProtoData:attron.data complete:^(id response) {
        HttpResponse *hReponse = (HttpResponse *) response;
        if (hReponse.code == successCode) {
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Attorn successful", nil) withType:ToastTypeSuccess showInView:self.view complete:^{
                if (self.SuccessAttornAdminCallback) {
                    self.SuccessAttornAdminCallback(self.adminAttron.address);
                }
                [self.navigationController popViewControllerAnimated:YES];
            }];
        } else {
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Attorn failed", nil) withType:ToastTypeFail showInView:self.view complete:nil];
        }
    }                                  fail:^(NSError *error) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:[LMErrorCodeTool showToastErrorType:ToastErrorTypeContact withErrorCode:error.code withUrl:GroupAttornUrl] withType:ToastTypeFail showInView:self.view complete:nil];
        }];
    }];
}

@end
