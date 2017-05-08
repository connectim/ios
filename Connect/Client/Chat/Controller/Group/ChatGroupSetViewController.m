//
//  ChatGroupSetViewController.m
//  Connect
//
//  Created by MoHuilin on 16/7/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "ChatGroupSetViewController.h"
#import "ChatGroupSetGroupNameViewController.h"
#import "ChatSetMyNameViewController.h"
#import "ChooseContactViewController.h"
#import "GroupMembersListViewController.h"
#import "LMchatGroupQRCodeViewController.h"
#import "LMchatGroupManageViewController.h"
#import "NetWorkOperationTool.h"
#import "UserDBManager.h"
#import "GroupDBManager.h"
#import "RecentChatDBManager.h"
#import "IMService.h"
#import "UserDetailPage.h"
#import "InviteUserPage.h"
#import "YYImageCache.h"
#import "StringTool.h"
#import "MessageDBManager.h"
#import "CIImageCacheManager.h"
#import "NSMutableArray+MoveObject.h"

typedef NS_ENUM(NSUInteger, SourceType) {
    SourceTypeGroup = 5
};

@interface ChatGroupSetViewController ()

@property(nonatomic, copy) NSString *currentGroupName;

@property(nonatomic, copy) NSString *currentMyName;

@property(nonatomic, weak) AccountInfo *currentUser;

@property(nonatomic, weak) GJGCChatFriendTalkModel *talkModel;

@property (nonatomic ,strong) NSArray *members;

@property(assign, nonatomic) BOOL isGroupMaster;

@property(weak, nonatomic) AccountInfo *groupMasterInfo;
//Show arrow
@property(assign, nonatomic) BOOL isHaveSow;

@end


@implementation ChatGroupSetViewController


- (instancetype)initWithTalkInfo:(GJGCChatFriendTalkModel *)talkInfo {
    if (self = [super init]) {
        self.talkModel = talkInfo;
        self.members = talkInfo.chatGroupInfo.groupMembers;
        AccountInfo *currentUser = [[LKUserCenter shareCenter] currentLoginUser];
        self.currentGroupName = talkInfo.chatGroupInfo.groupName;
        for (AccountInfo *member in self.members) {
            if ([currentUser.address isEqualToString:member.address]) {
                self.currentMyName = member.groupShowName;
                self.currentUser = member;
                break;
            }
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self syncGroupBaseInfo];
    if ([self.talkModel.chatGroupInfo.admin.address isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
        self.isHaveSow = YES;
    } else if (!self.talkModel.chatGroupInfo.isPublic) {
        self.isHaveSow = YES;
    }
    self.title = LMLocalizedString(@"Link Group", nil);
    RegisterNotify(GroupAdminChangeNotification, @selector(groupAdmingChange))
    RegisterNotify(ConnnectGroupInfoDidChangeNotification, @selector(grouInfoChange:))
    RegisterNotify(@"UploadGroupAvatarSuccessNotification", @selector(uploadGroupAvatarComplete:))
}

- (void)groupAdmingChange {
    AccountInfo *currentAdmin = [[GroupDBManager sharedManager] getAdminByGroupId:self.talkModel.chatGroupInfo.groupIdentifer];
    [self reloadDataWithNewAdmin:currentAdmin.address];
}

- (void)syncGroupBaseInfo {
    GroupId *groupIdentifier = [GroupId new];
    groupIdentifier.identifier = self.talkModel.chatGroupInfo.groupIdentifer;
    
    [NetWorkOperationTool POSTWithUrlString:GroupSyncSettingInfoUrl postProtoData:groupIdentifier.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *) response;
        if (hResponse.code != successCode) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:hResponse.message withType:ToastTypeFail showInView:self.view complete:nil];
            }];
            return;
        }
        NSData *data = [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            NSError *error = nil;
            GroupSettingInfo *groupSetInfo = [GroupSettingInfo parseFromData:data error:&error];
            self.talkModel.chatGroupInfo.isPublic = groupSetInfo.public_p;
            self.talkModel.chatGroupInfo.isGroupVerify = groupSetInfo.reviewed;
            self.talkModel.chatGroupInfo.avatarUrl = groupSetInfo.avatar;
            self.talkModel.chatGroupInfo.summary = groupSetInfo.summary;
            if ([[RecentChatDBManager sharedManager] getMuteStatusWithIdentifer:self.talkModel.chatIdendifier] != groupSetInfo.mute) {
                if (groupSetInfo.mute) {
                    [[RecentChatDBManager sharedManager] setMuteWithIdentifer:self.talkModel.chatIdendifier];
                } else {
                    [[RecentChatDBManager sharedManager] removeMuteWithIdentifer:self.talkModel.chatIdendifier];
                }
                [GCDQueue executeInMainQueue:^{
                    SendNotify(ConnnectMuteNotification, self.talkModel.chatIdendifier);
                }];
            }
            [[GroupDBManager sharedManager] updateGroupPublic:groupSetInfo.public_p reviewed:groupSetInfo.reviewed summary:groupSetInfo.summary avatar:groupSetInfo.avatar withGroupId:self.talkModel.chatGroupInfo.groupIdentifer];
            [self reloadDataOnMainQueue];
        }
    }                                  fail:^(NSError *error) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:[LMErrorCodeTool showToastErrorType:ToastErrorTypeContact withErrorCode:error.code withUrl:GroupSyncSettingInfoUrl] withType:ToastTypeFail showInView:self.view complete:nil];
        }];
    }];

}

- (void)uploadGroupAvatarComplete:(NSNotification *)note {
    NSString *identifier = [note.object valueForKey:@"identifier"];
    NSString *groupavatar = [note.object valueForKey:@"groupavatar"];
    if ([identifier isEqualToString:self.talkModel.chatGroupInfo.groupIdentifer]) {
        self.talkModel.chatGroupInfo.avatarUrl = groupavatar;
    }
}

- (void)grouInfoChange:(NSNotification *)note {
    NSString *groupIdentifer = (NSString *) note.object;

    LMGroupInfo *group = [[GroupDBManager sharedManager] getgroupByGroupIdentifier:groupIdentifer];
    self.talkModel.chatGroupInfo = group;
    self.members = group.groupMembers;
    NSMutableArray *avatars = [NSMutableArray array];
    for (AccountInfo *membser in group.groupMembers) {
        if (avatars.count == 9) {
            break;
        }
        [avatars objectAddObject:membser.avatar];
    }
    [[CIImageCacheManager sharedInstance] groupAvatarByGroupIdentifier:group.groupIdentifer groupMembers:avatars complete:nil];
    self.currentGroupName = group.groupName;
    AccountInfo *currentUser = [[LKUserCenter shareCenter] currentLoginUser];
    for (AccountInfo *info in group.groupMembers) {
        if ([currentUser.address isEqualToString:info.address]) {
            self.currentMyName = info.groupShowName;
            self.currentUser = info;
            break;
        }
    }
    [self reloadDataOnMainQueue];
}

- (void)reloadDataOnMainQueue {
    [GCDQueue executeInMainQueue:^{
        [self setupCellData];
        [self.tableView reloadData];
    }];
}

- (void)setupCellData {

    __weak typeof(self) weakSelf = self;
    [self.groups removeAllObjects];
    CellGroup *group0 = [[CellGroup alloc] init];
    group0.headTitle = [NSString stringWithFormat:LMLocalizedString(@"Link Members", nil), (unsigned long) self.members.count];

    CellItem *groupMembers = [[CellItem alloc] init];
    groupMembers.type = CellItemTypeGroupMemberCell;

    groupMembers.operation = ^{
        [weakSelf showMembersListPage];
    };

    groupMembers.array = self.members;
    group0.items = @[groupMembers].copy;
    [self.groups objectAddObject:group0];

    CellItem *groupName = [CellItem itemWithIcon:@"message_groupchat_name" title:LMLocalizedString(@"Link Group Name", nil) type:CellItemTypeImageValue1 operation:^{

        if ([weakSelf.talkModel.chatGroupInfo.admin.address isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
            ChatGroupSetGroupNameViewController *groupName = [[ChatGroupSetGroupNameViewController alloc] initWithCurrentName:weakSelf.currentGroupName groupid:weakSelf.talkModel.chatIdendifier];
            [weakSelf.navigationController pushViewController:groupName animated:YES];
        } else if (!weakSelf.talkModel.chatGroupInfo.isPublic) {
            ChatGroupSetGroupNameViewController *groupName = [[ChatGroupSetGroupNameViewController alloc] initWithCurrentName:weakSelf.currentGroupName groupid:weakSelf.talkModel.chatIdendifier];
            [weakSelf.navigationController pushViewController:groupName animated:YES];
        }
    }];
    groupName.subTitle = self.currentGroupName;
    groupName.tag = SourceTypeGroup;

    CellItem *myName = [CellItem itemWithIcon:@"message_groupchat_myname" title:LMLocalizedString(@"Link My Alias in Group", nil) type:CellItemTypeImageValue1 operation:^{

        ChatSetMyNameViewController *myName = [[ChatSetMyNameViewController alloc] initWithUpdateUser:weakSelf.currentUser groupIdentifier:weakSelf.talkModel.chatIdendifier];
        [weakSelf.navigationController pushViewController:myName animated:YES];
    }];
    myName.subTitle = self.currentMyName;
    NSString *displayName = LMLocalizedString(@"Link Group is QR Code", nil);
    CellItem *groupQRCode = [CellItem itemWithIcon:@"message_groupchat_qrcode-1" title:displayName type:CellItemTypeImageValue1 operation:^{
        LMchatGroupQRCodeViewController *QRCodeVc = [[LMchatGroupQRCodeViewController alloc] init];
        QRCodeVc.talkModel = weakSelf.talkModel;
        QRCodeVc.titleName = displayName;
        [weakSelf.navigationController pushViewController:QRCodeVc animated:YES];

    }];
    CellGroup *group1 = [[CellGroup alloc] init];
    if ([self.talkModel.chatGroupInfo.admin.address isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
        NSString *displayName = LMLocalizedString(@"Link ManageGroup", nil);
        CellItem *manageGroup = [CellItem itemWithIcon:@"message_groupchat_setting" title:displayName type:CellItemTypeImageValue1 operation:^{
            LMchatGroupManageViewController *manageGroup = [[LMchatGroupManageViewController alloc] init];
            manageGroup.switchChangeBlock = ^(BOOL isPublic) {
                weakSelf.talkModel.chatGroupInfo.isPublic = isPublic;
            };
            manageGroup.titleName = displayName;
            manageGroup.talkModel = weakSelf.talkModel;
            manageGroup.groupMasterInfo = weakSelf.talkModel.chatGroupInfo.admin;
            manageGroup.groupAdminChangeCallBack = ^(NSString *address) {
                [weakSelf reloadDataWithNewAdmin:address];
            };
            [weakSelf.navigationController pushViewController:manageGroup animated:YES];
        }];
        group1.items = @[groupName, myName, groupQRCode, manageGroup].copy;
    } else {
        group1.items = @[groupName, myName, groupQRCode].copy;
    }

    [self.groups objectAddObject:group1];

    CellItem *topMessage = [CellItem itemWithTitle:LMLocalizedString(@"Chat Sticky on Top chat", nil) type:CellItemTypeSwitch operation:nil];
    topMessage.switchIsOn = [SetGlobalHandler chatIsTop:weakSelf.talkModel.chatIdendifier];
    topMessage.operationWithInfo = ^(id userInfo) {
        if ([userInfo boolValue]) {
            [SetGlobalHandler topChatWithChatIdentifer:weakSelf.talkModel.chatIdendifier];
        } else {
            [SetGlobalHandler CancelTopChatWithChatIdentifer:weakSelf.talkModel.chatIdendifier];
        }
    };

    CellItem *messageNoneNotifi = [CellItem itemWithTitle:LMLocalizedString(@"Chat Mute Notification", nil) type:CellItemTypeSwitch operation:nil];
    messageNoneNotifi.switchIsOn = [SetGlobalHandler GroupChatMuteStatusWithIdentifer:weakSelf.talkModel.chatIdendifier];
    messageNoneNotifi.operationWithInfo = ^(id userInfo) {
        BOOL notify = [userInfo boolValue];
        [SetGlobalHandler GroupChatSetMuteWithIdentifer:weakSelf.talkModel.chatIdendifier mute:notify complete:^(NSError *erro) {
            if (!erro) {
                if (notify) {
                    [[RecentChatDBManager sharedManager] setMuteWithIdentifer:weakSelf.talkModel.chatIdendifier];
                } else {
                    [[RecentChatDBManager sharedManager] removeMuteWithIdentifer:weakSelf.talkModel.chatIdendifier];
                }
                [GCDQueue executeInMainQueue:^{
                    SendNotify(ConnnectMuteNotification, weakSelf.talkModel.chatIdendifier);
                }];
            }
        }];
    };

    CellItem *savaToContact = [CellItem itemWithTitle:LMLocalizedString(@"Link Save to Contacts", nil) type:CellItemTypeSwitch operation:nil];
    savaToContact.switchIsOn = [[GroupDBManager sharedManager] isInCommonGroup:weakSelf.talkModel.chatIdendifier];
    savaToContact.operationWithInfo = ^(id userInfo) {
        if ([userInfo boolValue]) {
            [SetGlobalHandler setCommonContactGroupWithIdentifer:weakSelf.talkModel.chatIdendifier complete:^(NSError *error) {
                if (!error) {
                    [[GroupDBManager sharedManager] addGroupToCommonGroup:weakSelf.talkModel.chatIdendifier];
                } else {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Update fail", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:2 inSection:2];
                        [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    }];
                }
            }];
        } else {
            [SetGlobalHandler removeCommonContactGroupWithIdentifer:weakSelf.talkModel.chatIdendifier complete:^(NSError *error) {
                if (!error) {
                    [[GroupDBManager sharedManager] removeFromCommonGroup:weakSelf.talkModel.chatIdendifier];
                } else {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Fail", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:2 inSection:2];
                        [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    }];
                }
            }];
        }
    };

    CellGroup *group2 = [[CellGroup alloc] init];
    group2.headTitle = LMLocalizedString(@"Link Group Setting", nil);
    group2.items = @[topMessage, messageNoneNotifi, savaToContact].copy;
    [self.groups objectAddObject:group2];

    CellGroup *group3 = [[CellGroup alloc] init];
    group3.headTitle = LMLocalizedString(@"Link Other", nil);

    CellItem *clearHistory = [CellItem itemWithIcon:@"chat_friend_set_clearhistory" title:LMLocalizedString(@"Link Clear Chat History", nil) type:CellItemTypeNone operation:^{
        
        UIAlertController* actionController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction* clearHistoryAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Link Clear Chat History", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
             [weakSelf clearAllChatHistory];
        }];
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
        
        [actionController addAction:clearHistoryAction];
        [actionController addAction:cancelAction];
        [weakSelf presentViewController:actionController animated:YES completion:nil];

        
    }];
    CellItem *leaveGroup = [CellItem itemWithIcon:@"message_group_leave" title:LMLocalizedString(@"Link Delete and Leave", nil) type:CellItemTypeNone operation:^{
        UIAlertController* actionController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction* deleteAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Link Delete and Leave", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showLoadingMessageToView:weakSelf.view];
            }];
            [SetGlobalHandler quitGroupWithIdentifer:weakSelf.talkModel.chatIdendifier complete:^(NSError *erro) {
                [GCDQueue executeInMainQueue:^{
                    if (!erro) {
                        [[YYImageCache sharedCache] removeImageForKey:weakSelf.talkModel.chatGroupInfo.avatarUrl];
                        [MBProgressHUD hideHUDForView:weakSelf.view];
                        SendNotify(ConnnectQuitGroupNotification, weakSelf.talkModel.chatIdendifier);
                        [weakSelf.navigationController popToRootViewControllerAnimated:NO];
                    } else{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Chat Network connection failed please check network", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                    }
                }];
            }];
        }];
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
        
        [actionController addAction:deleteAction];
        [actionController addAction:cancelAction];
        [weakSelf presentViewController:actionController animated:YES completion:nil];

    }];

    clearHistory.type = CellItemTypeNone;

    group3.items = @[clearHistory, leaveGroup].copy;
    [self.groups objectAddObject:group3];

}

- (void)clearAllChatHistory {
    AccountInfo *chatUser = [[UserDBManager sharedManager] getUserByPublickey:self.talkModel.chatIdendifier];
    if (chatUser) {
        [ChatMessageFileManager deleteRecentChatAllMessageFilesByAddress:chatUser.address];
    } else {
        [ChatMessageFileManager deleteRecentChatAllMessageFilesByAddress:self.talkModel.chatIdendifier];
    }
    [[MessageDBManager sharedManager] deleteAllMessageByMessageOwer:self.talkModel.chatIdendifier];
    [GCDQueue executeInMainQueue:^{
        SendNotify(@"im.connect.DeleteMessageHistoryNotification", nil);
    }];

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
        cell.textLabel.text = item.title;
        return cell;
    } else if (item.type == CellItemTypeGroupMemberCell) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"GroupMembersCellID"];
        GroupMembersCell *memberCell = (GroupMembersCell *) cell;
        memberCell.data = self.members;
        memberCell.tapAddMemberBlock = ^{
            [weakSelf showAccountListPage];
        };

        memberCell.tapMemberHeaderBlock = ^(AccountInfo *tapInfo) {
            [weakSelf showUserDetailPageWithUser:tapInfo];
        };
        return cell;
    } else if (item.type == CellItemTypeNone) {

        cell = [tableView dequeueReusableCellWithIdentifier:@"SystemCellID"];
        cell.textLabel.text = item.title;
        cell.imageView.image = [UIImage imageNamed:item.icon];
        cell.detailTextLabel.text = item.subTitle;

    } else if (item.type == CellItemTypeImageValue1) {

        cell = [tableView dequeueReusableCellWithIdentifier:@"NCellImageValue1ID"];
        NCellImageValue1 *imageCell = (NCellImageValue1 *) cell;
        imageCell.tag = item.tag;
        imageCell.data = item;
        if (imageCell.tag == SourceTypeGroup) {
            if (self.isHaveSow) {
                imageCell.arrowImageView.hidden = NO;
            } else {
                imageCell.arrowImageView.hidden = YES;
            }
        } else {
            imageCell.arrowImageView.hidden = NO;
        }
    }
    return cell;
}

- (void)addNewGroupMembers:(NSArray *)contacts {
    [GCDQueue executeInMainQueue:^{
        [MBProgressHUD showMessage:LMLocalizedString(@"Common Loading", nil) toView:self.view];
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
    inviteUser.identifier = self.talkModel.chatGroupInfo.groupIdentifer;
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
                message.ext1 = @{@"avatar": self.talkModel.chatGroupInfo.avatarUrl ? self.talkModel.chatGroupInfo.avatarUrl : @"",
                        @"groupname": self.talkModel.chatGroupInfo.groupName,
                        @"groupidentifier": self.talkModel.chatGroupInfo.groupIdentifer,
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
                            [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Group invitation has been sent", nil) withType:ToastTypeSuccess showInView:self.view complete:^{

                            }];
                        }];
                    } else {
                        [GCDQueue executeInMainQueue:^{
                            [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Group invitation sent failed", nil) withType:ToastTypeFail showInView:self.view complete:^{

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

- (void)inviteNewMembers:(NSArray *)membsers {

    __weak typeof(self) weakSelf = self;
    LMGroupInfo *group = [[GroupDBManager sharedManager] addMember:membsers ToGroupChat:weakSelf.talkModel.chatIdendifier];
    self.members = group.groupMembers.copy;

    [self reloadDataOnMainQueue];

    NSMutableString *welcomeTip = [NSMutableString string];
    CreateGroupMessage *groupMessage = [[CreateGroupMessage alloc] init];
    groupMessage.secretKey = weakSelf.talkModel.group_ecdhKey;
    groupMessage.identifier = weakSelf.talkModel.chatIdendifier;

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
    MMMessage *message = [[MMMessage alloc] init];
    message.user_name = weakSelf.talkModel.name;
    message.type = GJGCChatInviteNewMemberTip;
    message.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
    message.message_id = [ConnectTool generateMessageId];
    message.senderInfoExt = @{@"username": [[LKUserCenter shareCenter] currentLoginUser].username,
            @"address": [[LKUserCenter shareCenter] currentLoginUser].address,
            @"avatar": [[LKUserCenter shareCenter] currentLoginUser].avatar};

    message.publicKey = weakSelf.talkModel.chatIdendifier;
    message.user_id = weakSelf.talkModel.chatIdendifier;
    message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
    message.ext1 = @{@"inviter": [[LKUserCenter shareCenter] currentLoginUser].username,
            @"message": welcomeTip};

    [[IMService instance] asyncSendGroupMessage:message withGroupEckhKey:weakSelf.talkModel.group_ecdhKey onQueue:nil completion:^(MMMessage *message, NSError *error) {
        [GCDQueue executeInMainQueue:^{
            SendNotify(ConnnectSendMessageSuccessNotification, weakSelf.talkModel.chatIdendifier);
        }];
    }                                   onQueue:nil];
}

- (void)showAccountListPage {
    ChooseContactViewController *page = [[ChooseContactViewController alloc] initWithChooseComplete:^(NSArray *selectContactArray) {
        DDLogInfo(@"%@", selectContactArray);
        [self addNewGroupMembers:selectContactArray];
    }                                                                          defaultSelectedUsers:self.members];

    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:page] animated:YES completion:nil];
}

- (void)showMembersListPage {
    if (GJCFStringIsNull(self.talkModel.chatIdendifier) || GJCFStringIsNull(self.talkModel.group_ecdhKey)) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Unknown error", nil) withType:ToastTypeFail showInView:self.view complete:nil];
        }];
        return;
    }
    GroupMembersListViewController *page1 = [[GroupMembersListViewController alloc] initWithMemberInfos:self.members groupIdentifer:self.talkModel.chatIdendifier groupEchhKey:self.talkModel.group_ecdhKey];
    page1.talkInfo = self.talkModel;
    page1.isGroupMaster = [self.talkModel.chatGroupInfo.admin.address isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address];
    [self.navigationController pushViewController:page1 animated:YES];
}

- (void)showUserDetailPageWithUser:(AccountInfo *)user {

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

- (void)dealloc {
    self.currentUser = nil;
    self.talkModel = nil;
    RemoveNofify;
}

#pragma mark - relod ui

- (void)reloadDataWithNewAdmin:(NSString *)address {
    AccountInfo *newAdmin = nil;
    for (AccountInfo *member in self.talkModel.chatGroupInfo.groupMembers) {
        if ([address isEqualToString:member.address]) {
            newAdmin = member;
            newAdmin.isGroupAdmin = YES;
        } else {
            member.isGroupAdmin = NO;
        }
    }
    self.talkModel.chatGroupInfo.admin = newAdmin;
    if (newAdmin) {
        NSMutableArray *temMembers = self.talkModel.chatGroupInfo.groupMembers.mutableCopy;
        [temMembers moveObject:newAdmin toIndex:0];
        self.talkModel.chatGroupInfo.groupMembers = temMembers;
    }
    [self reloadDataOnMainQueue];
}

@end
