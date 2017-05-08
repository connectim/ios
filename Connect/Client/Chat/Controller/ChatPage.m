//
//  ChatPage.m
//  Connect
//
//  Created by MoHuilin on 16/5/22.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "ChatPage.h"
#import "RecentChatCell.h"
#import "GJGCChatFriendViewController.h"
#import "GJGCChatGroupViewController.h"
#import "GJGCChatSystemNotiViewController.h"
#import "RecentChatTitleView.h"
#import "IMService.h"
#import "SystemMessageHandler.h"
#import "CIImageCacheManager.h"
#import "BadgeNumberManager.h"
#import "UITabBar+Reddot.h"
#import "LMRegisterPrivkeyBackupTipView.h"
#import "AppDelegate.h"
#import "LMConversionManager.h"
#import "UIAlertController+Blocks.h"
#import "SystemTool.h"
#import "LMConnectStatusView.h"


@interface ChatPage () <
MGSwipeTableCellDelegate,
TCPConnectionObserver,
LMConversionListChangeManagerDelegate,
UITabBarControllerDelegate>

@property(nonatomic, strong) RecentChatTitleView *titleView;
@property(nonatomic, strong) NSMutableArray<RecentChatModel *> *recentChats;
@property (nonatomic) LMConnectStatusView *connectionAlertView;

@property(nonatomic, assign) BOOL updated;
@property (nonatomic ,assign) NSTimeInterval tapTimeInterval;
@property (nonatomic ,assign) NSInteger selectIndex;

@end

@implementation ChatPage

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.tabBarController.tabBar.hidden) {
        self.tabBarController.tabBar.hidden = NO;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [SessionManager sharedManager].GetNewVersionInfoCallback = ^(VersionResponse *currentNewVersionInfo) {
        [self updateAppNoteWithCurrentNewVersionInfo:currentNewVersionInfo];
    };
    [self updateAppNoteWithCurrentNewVersionInfo:[SessionManager sharedManager].currentNewVersionInfo];

    if ([LKUserCenter shareCenter].isFristLogin) {
        LMRegisterPrivkeyBackupTipView *registerPrivkeyTipView = [[[NSBundle mainBundle] loadNibNamed:@"LMRegisterPrivkeyBackupTipView" owner:nil options:nil] lastObject];
        AppDelegate *app = (AppDelegate *) [UIApplication sharedApplication].delegate;
        UIWindow *window = app.window;
        registerPrivkeyTipView.frame = [UIScreen mainScreen].bounds;
        registerPrivkeyTipView.controller = self;
        [window addSubview:registerPrivkeyTipView];
        [window bringSubviewToFront:registerPrivkeyTipView];
    }

    
    self.tabBarController.delegate=self;
    self.navigationItem.leftBarButtonItems = nil;
    self.titleView = [[RecentChatTitleView alloc] init];
    self.navigationItem.titleView = self.titleView;
    self.recentChats = [NSMutableArray array];
    [self configTableView];

    [self addNotification];

    self.titleView = [[RecentChatTitleView alloc] init];
    self.navigationItem.titleView = self.titleView;
    [self onConnectState:0];
    
    //conversion  monitor
    [LMConversionManager sharedManager].conversationListDelegate = self;
    [[LMConversionManager sharedManager] getAllConversationFromDB];
}

- (void)updateAppNoteWithCurrentNewVersionInfo:(VersionResponse *)currentNewVersionInfo {
    if (self.updated) {
        return;
    }
    self.updated = YES;
    if (currentNewVersionInfo.force) {
        [GCDQueue executeInMainQueue:^{
            [UIAlertController showAlertInViewController:self withTitle:LMLocalizedString(@"Set Found new version", nil) message:[SessionManager sharedManager].currentNewVersionInfo.remark cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@[LMLocalizedString(@"Set Now update app", nil)] tapBlock:^(UIAlertController *_Nonnull controller, UIAlertAction *_Nonnull action, NSInteger buttonIndex) {
                // native distribution
                if ([SystemTool isNationChannel]) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:nationalAppDownloadUrl]];
                } else {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appstoreAppDownloadUrl]];
                }
            }];
        }];
    } else {
        BOOL havedNoteUpdate = GJCFUDFGetValue(@"havedNoteUpdateKey");
        if (!havedNoteUpdate) {
            [GCDQueue executeInMainQueue:^{
                NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary]; //CFBundleIdentifier
                NSString *versionNum = [infoDict objectForKey:@"CFBundleShortVersionString"];
                int ver = [[currentNewVersionInfo.version stringByReplacingOccurrencesOfString:@"." withString:@""] intValue];
                int currentVer = [[versionNum stringByReplacingOccurrencesOfString:@"." withString:@""] intValue];
                if (currentVer < ver) {
                    [UIAlertController showAlertInViewController:self withTitle:LMLocalizedString(@"Set tip title", nil) message:[NSString stringWithFormat:LMLocalizedString(@"Set Found the new version update the content", nil), currentNewVersionInfo.remark] cancelButtonTitle:LMLocalizedString(@"Common Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:@[LMLocalizedString(@"Set Now update app", nil)] tapBlock:^(UIAlertController *_Nonnull controller, UIAlertAction *_Nonnull action, NSInteger buttonIndex) {
                        GJCFUDFCache(@"havedNoteUpdateKey", @(YES));
                        
                        if ([SystemTool isNationChannel]) {
                            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:nationalAppDownloadUrl]];
                        } else {
                            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appstoreAppDownloadUrl]];
                        }
                    }];
                }
            }];
        }
    }

}


#pragma mark - LMConversionListChangeManagerDelegate

- (void)conversationListDidChanged:(NSArray<RecentChatModel *> *)conversationList {
    self.recentChats = [conversationList mutableCopy];
    [self conversationListUpdate];
}

- (void)unreadMessageNumberDidChanged {
    [self updateBarBadgeIsNeedSyncBadge:NO];
}

- (void)unreadMessageNumberDidChangedNeedSyncbadge{
    [self updateBarBadgeIsNeedSyncBadge:YES];
}

- (NSMutableArray<RecentChatModel *> *)currentConversationList {
    return [self.recentChats mutableCopy];
}

- (void)addNotification {
    //注册连接状态的监听
    [[IMService instance] addConnectionObserver:self];

    RegisterNotify(@"im.connect.appCreateGroupCompleteNotification", @selector(groupCreateComplete:));
    RegisterNotify(LoinOnNewDeviceStatusNotification, @selector(backToConnect:));
    RegisterNotify(SocketDataVerifyIllegalityNotification, @selector(SocketDataVerifyFail));
}

- (void)SocketDataVerifyFail {
    [UIAlertController showAlertInViewController:self withTitle:LMLocalizedString(@"Set Found new version", nil) message: LMLocalizedString(@"Chat Connection protocol upgrades", nil) cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@[LMLocalizedString(@"Set Now update app", nil)] tapBlock:^(UIAlertController *_Nonnull controller, UIAlertAction *_Nonnull action, NSInteger buttonIndex) {
        if ([SystemTool isNationChannel]) {
            if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")){
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:nationalAppDownloadUrl] options:nil completionHandler:^(BOOL success) {
                    
                }];
            } else{
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:nationalAppDownloadUrl]];
            }
        } else {
            if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")){
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appstoreAppDownloadUrl] options:nil completionHandler:^(BOOL success) {
                    
                }];
            } else{
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appstoreAppDownloadUrl]];
            }
        }
    }];
}

- (void)groupAvatarNicknameChange {
    [[LMConversionManager sharedManager] getAllConversationFromDB];
}

- (void)getOfflineComplete {

    [[LMConversionManager sharedManager] getAllConversationFromDB];

}

- (void)backToConnect:(NSNotification *)note {
    int status = [note.object intValue];
    DDLogError(@"status %d", status);
    switch (status) {
        case 1: {
            MBProgressHUD *hud = [MBProgressHUD showMessage:LMLocalizedString(@"Common Loading", nil) toView:self.view];
            [hud hide:YES afterDelay:20];
        }
            break;
        case 2: {
            [MBProgressHUD hideHUDForView:self.view];
            [[RecentChatDBManager sharedManager] createConnectTermWelcomebackChatAndMessage];
        }
            break;
        default:
            break;
    }
}

- (void)dealloc {
    [[IMService instance] removeConnectionObserver:self];
    RemoveNofify;
}

#pragma mark - To create a group after the success of the interface jump
- (void)groupCreateComplete:(NSNotification *)note {

    /*
     @"groupIdentifier":groupInfo.group.identifier,
     @"content":content})
     */
    NSString *identifier = [note.object valueForKey:@"groupIdentifier"];
    NSString *content = [note.object valueForKey:@"content"];
    if (GJCFStringIsNull(identifier)) {
        return;
    }

    LMGroupInfo *groupInfo = [[GroupDBManager sharedManager] getgroupByGroupIdentifier:identifier];
    [GCDQueue executeInGlobalQueue:^{
        NSMutableArray *avatars = [NSMutableArray array];
        for (AccountInfo *member in groupInfo.groupMembers) {
            [avatars objectAddObject:member.avatar];
        }
        [[CIImageCacheManager sharedInstance] uploadGroupAvatarWithGroupIdentifier:groupInfo.groupIdentifer groupMembers:avatars];
    }];

    NSString *tipMessage = content;
    NSString *localMsgId = [ConnectTool generateMessageId];
    ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
    chatMessage.messageId = localMsgId;
    chatMessage.messageOwer = identifier;
    chatMessage.messageType = GJGCChatFriendContentTypeStatusTip;
    chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
    chatMessage.createTime = (long long) ([[NSDate date] timeIntervalSince1970] * 1000);
    MMMessage *message = [[MMMessage alloc] init];
    message.type = GJGCChatFriendContentTypeStatusTip;
    message.content = tipMessage;
    message.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
    message.message_id = localMsgId;
    message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
    chatMessage.message = message;
    [[MessageDBManager sharedManager] saveMessage:chatMessage];

    GJGCChatFriendTalkModel *talk = [[GJGCChatFriendTalkModel alloc] init];
    talk.talkType = GJGCChatFriendTalkTypeGroup;
    talk.chatIdendifier = identifier;
    talk.group_ecdhKey = groupInfo.groupEcdhKey;
    talk.chatGroupInfo = groupInfo;
    
    talk.name = [NSString stringWithFormat:@"%@(%lu)", groupInfo.groupName, (unsigned long) talk.chatGroupInfo.groupMembers.count];

    [SessionManager sharedManager].chatSession = talk.chatIdendifier;
    [SessionManager sharedManager].chatObject = groupInfo;

    GJGCChatGroupViewController *groupChat = [[GJGCChatGroupViewController alloc] initWithTalkInfo:talk];
    groupChat.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:groupChat animated:YES];

}

#pragma mark - TCPConnectionObserver

/**
 #define STATE_UNCONNECTED 0
 #define STATE_CONNECTING 1
 #define STATE_CONNECTED 2
 #define STATE_CONNECTFAIL 3

 */
- (void)onConnectState:(int)state {
    switch (state) {
        case 0: {
            self.titleView.connectState = RecentChatConnectStateFaild;
        }
            break;
        case 1: {
            self.titleView.connectState = RecentChatConnectStateConnecting;
        }
            break;

        case 2: {
            self.titleView.connectState = RecentChatConnectStateSuccess;
        }
            break;

        case 3: {
            self.titleView.connectState = RecentChatConnectStateAuthing;
        }
            break;

        case 4: {
            self.titleView.connectState = RecentChatConnectStateGetOffline;
        }
            break;
        default:
            break;
    }
//    [self adjustConcectStatus];
}

- (void)adjustConcectStatus{
    switch (self.titleView.connectState) {
        case 2: {
            [self.connectionAlertView showViewWithStatue:LMConnectStatusViewUpdateecdhSuccess];
            [GCDQueue executeInMainQueue:^{
                [self.tableView setTableHeaderView:nil];
            } afterDelaySecs:0.8f];
        }
            break;
        case 1:
        case 3: {
            self.connectionAlertView.height = AUTO_HEIGHT(60);
            [self.tableView setTableHeaderView:self.connectionAlertView];
            [self.connectionAlertView showViewWithStatue:LMConnectStatusViewUpdatingEcdh];
        }
            break;
        default:
            break;
    }
}

- (void)configTableView {
    [self.tableView registerNib:[UINib nibWithNibName:@"RecentChatCell" bundle:nil] forCellReuseIdentifier:@"RecentChatCellID"];
    self.tableView.rowHeight = AUTO_HEIGHT(140);
    self.tableView.tableFooterView = [[UIView alloc] init];//http://ios.jobbole.com/84377/
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.recentChats.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RecentChatCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RecentChatCellID" forIndexPath:indexPath];
    cell.delegate = self;
    RecentChatModel *recentModel = [self.recentChats objectAtIndexCheck:indexPath.row];
    [cell setData:recentModel];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    RecentChatModel *recentModel = [self.recentChats objectAtIndexCheck:indexPath.row];
    if (recentModel.chatUser.stranger) {
        recentModel.chatUser.stranger = ![[UserDBManager sharedManager] isFriendByAddress:recentModel.chatUser.address];
    }
    //clear unread / group @ note
    [[LMConversionManager sharedManager] clearConversionUnreadAndGroupNoteWithIdentifier:recentModel.identifier];
    
    switch (recentModel.talkType) {
        case GJGCChatFriendTalkTypePostSystem:
        case GJGCChatFriendTalkTypePrivate:
        {
            [self pushFriendChatViewControllerWith:recentModel];
        }
            break;

        case GJGCChatFriendTalkTypeGroup:
        {
            [self pushGroupChatViewControllerWith:recentModel];
        }
            break;
        default:
            break;
    }
}


#pragma mark - group
- (void)pushGroupChatViewControllerWith:(RecentChatModel *)recentModel {

    GJGCChatFriendTalkModel *talk = [[GJGCChatFriendTalkModel alloc] init];
    talk.talkType = GJGCChatFriendTalkTypeGroup;
    talk.chatIdendifier = recentModel.identifier;
    talk.chatGroupInfo = recentModel.chatGroupInfo;
    talk.name = GJCFStringIsNull(recentModel.name) ? [NSString stringWithFormat:LMLocalizedString(@"Group (%lu)", nil), (unsigned long) recentModel.chatGroupInfo.groupMembers.count] : [NSString stringWithFormat:@"%@(%lu)", recentModel.name, (unsigned long) recentModel.chatGroupInfo.groupMembers.count];
    [SessionManager sharedManager].chatSession = talk.chatIdendifier;
    [SessionManager sharedManager].chatObject = recentModel.chatGroupInfo;

    GJGCChatGroupViewController *groupChat = [[GJGCChatGroupViewController alloc] initWithTalkInfo:talk];
    groupChat.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:groupChat animated:YES];

}

#pragma mark - friend or system
- (void)pushFriendChatViewControllerWith:(RecentChatModel *)recentModel {

    GJGCChatFriendTalkModel *talk = [[GJGCChatFriendTalkModel alloc] init];
    talk.talkType = recentModel.talkType;
    talk.chatIdendifier = recentModel.identifier;
    talk.headUrl = recentModel.headUrl;
    talk.name = recentModel.chatUser.normalShowName;
    talk.snapChatOutDataTime = recentModel.snapChatDeleteTime;
    
    [SessionManager sharedManager].chatSession = recentModel.chatUser.pub_key;
    [SessionManager sharedManager].chatObject = recentModel.chatUser;
    talk.chatUser = recentModel.chatUser;
    if (recentModel.talkType == GJGCChatFriendTalkTypePostSystem) {
        GJGCChatSystemNotiViewController *privateChat = [[GJGCChatSystemNotiViewController alloc] initWithTalkInfo:talk];
        privateChat.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:privateChat animated:YES];
    } else {
        if (recentModel.stranger) {
            BOOL isFriend = [[UserDBManager sharedManager] isFriendByAddress:[KeyHandle getAddressByPubkey:recentModel.identifier]];
            if (isFriend) {
                [[LMConversionManager sharedManager] setRecentStrangerStatusWithIdentifier:recentModel.identifier stranger:NO];
            }
        }
        //Delete the message after reading
        [[MessageDBManager sharedManager] deleteSnapOutTimeMessageByMessageOwer:recentModel.identifier];
        GJGCChatFriendViewController *privateChat = [[GJGCChatFriendViewController alloc] initWithTalkInfo:talk];
        privateChat.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:privateChat animated:YES];
    }
}


- (void)deleteCell:(MGSwipeTableCell *)cell {

    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    RecentChatModel *model = self.recentChats[indexPath.row];
    [[LMConversionManager sharedManager] deleteConversation:model];
    [self.recentChats removeObjectAtIndexCheck:indexPath.row];
    [self.tableView reloadData];
}

- (void)setMuteWithCell:(UITableViewCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    RecentChatModel *model = self.recentChats[indexPath.row];
    __weak __typeof(&*self)weakSelf = self;
    [MBProgressHUD showLoadingMessageToView:self.view];
    [[LMConversionManager sharedManager] setConversationMute:model complete:^(BOOL complete) {
        if (complete) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Successful", nil) withType:ToastTypeSuccess showInView:weakSelf.view complete:nil];
            }];
        } else{
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Operation frequent", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
            }];
        }
    }];
}

#pragma mark Swipe Delegate

- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell canSwipe:(MGSwipeDirection)direction; {
    return YES;
}

- (NSArray *)swipeTableCell:(MGSwipeTableCell *)cell swipeButtonsForDirection:(MGSwipeDirection)direction
              swipeSettings:(MGSwipeSettings *)swipeSettings expansionSettings:(MGSwipeExpansionSettings *)expansionSettings {

    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

    RecentChatModel *model = self.recentChats[indexPath.row];

    swipeSettings.transition = MGSwipeTransitionStatic;
    CGFloat padding = 0;
    if (model.talkType != GJGCChatFriendTalkTypePostSystem) {
        if (model.talkType != GJGCChatFriendTalkTypeGroup && model.chatUser.stranger) {
            padding = AUTO_WIDTH(50);
        }
        if (direction == MGSwipeDirectionRightToLeft) {
            __weak __typeof(&*self) weakSelf = self;
            MGSwipeButton *trashButton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"message_trash"] backgroundColor:[UIColor whiteColor] padding:padding callback:^BOOL(MGSwipeTableCell *sender) {
                [weakSelf deleteCell:cell];
                return YES;
            }];
            if (model.talkType == GJGCChatFriendTalkTypeGroup || !model.chatUser.stranger) {
                NSString *icon = @"message_notify_disable";
                if (model.notifyStatus) {
                    icon = @"message_notify_enable";
                }
                MGSwipeButton *ringButton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:icon] backgroundColor:[UIColor whiteColor] padding:padding callback:^BOOL(MGSwipeTableCell *sender) {
                    [weakSelf setMuteWithCell:cell];
                    return YES;
                }];
                return @[ringButton, trashButton];
            } else {
                return @[trashButton];
            }
        }

    } else {
        padding = AUTO_WIDTH(50);
        if (direction == MGSwipeDirectionRightToLeft) {
            __weak __typeof(&*self) weakSelf = self;
            MGSwipeButton *trashButton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"message_trash"] backgroundColor:[UIColor whiteColor] padding:padding callback:^BOOL(MGSwipeTableCell *sender) {
                [weakSelf deleteCell:cell];
                return YES;
            }];
            return @[trashButton];
        }
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

#pragma -mark - reload

- (void)conversationListUpdate {
    [self.tableView reloadData];
}

#pragma -mark reflash badge

- (void)updateBarBadgeIsNeedSyncBadge:(BOOL)IsNeedSyncBadge{
    [[RecentChatDBManager sharedManager] getAllUnReadCountWithComplete:^(int count) {
        [[BadgeNumberManager shareManager] getBadgeNumberCountWithMin:ALTYPE_CategoryTwo_NewFriend max:ALTYPE_CategoryTwo_PhoneContact Completion:^(NSUInteger contactConnt) {
            if ([UIApplication sharedApplication].applicationIconBadgeNumber != count + contactConnt) {
                [GCDQueue executeInMainQueue:^{
                    [UIApplication sharedApplication].applicationIconBadgeNumber = count + contactConnt;
                }];
                if (IsNeedSyncBadge) {
                    [[IMService instance] syncBadgeNumber:count + contactConnt];
                }
            }
        }];
        [GCDQueue executeInMainQueue:^{
            [self.tabBarController.tabBar hideBadgeOnItemIndex:0];
            if (count >= 100) {
                self.tabBarItem.badgeValue = [NSString stringWithFormat:@"99+"];
            } else if (count > 0 && count < 100) {
                self.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d", count];
            } else {
                self.tabBarItem.badgeValue = nil;
            }
        }];
    }];
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController{

    UINavigationController *navdid=tabBarController.selectedViewController;
    UINavigationController *nav=(UINavigationController*)viewController;
    if (![navdid.topViewController isEqual:self]) {
        self.tapTimeInterval = 0;
    }
    if (self.tapTimeInterval) {
        NSTimeInterval time = [[NSDate date] timeIntervalSince1970] - self.tapTimeInterval;
        if (time > 0 && time < 1.2f) {
            if (self.recentChats.count) {
                NSIndexPath* indexPat = [NSIndexPath indexPathForRow:0 inSection:0];
                [self.tableView scrollToRowAtIndexPath:indexPat atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }
        }
        self.tapTimeInterval = 0;
    } else{
        if ([nav.topViewController isEqual:self]) {
            self.tapTimeInterval = [[NSDate date] timeIntervalSince1970];
        }
    }
    return YES;
}

- (UIView *)connectionAlertView {
    if (!_connectionAlertView) {
        _connectionAlertView = [[LMConnectStatusView alloc] initWithFrame:CGRectMake(0, 0, DEVICE_SIZE.width, AUTO_HEIGHT(60))];
    }
    return _connectionAlertView;
}


@end
