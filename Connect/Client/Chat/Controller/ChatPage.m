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
#import "BadgeNumberManager.h"
#import "UITabBar+Reddot.h"
#import "LMRegisterPrivkeyBackupTipView.h"
#import "AppDelegate.h"
#import "LMConversionManager.h"
#import "SystemTool.h"


@interface ChatPage () <
        MGSwipeTableCellDelegate,
        TCPConnectionObserver,
        LMConversionListChangeManagerDelegate,
        UITabBarControllerDelegate,
        UIViewControllerPreviewingDelegate>

@property(nonatomic, strong) RecentChatTitleView *titleView;
@property(nonatomic, strong) NSMutableArray<RecentChatModel *> *recentChats;
@property(nonatomic, assign) BOOL updated;
@property(nonatomic, assign) NSTimeInterval tapTimeInterval;
@property(nonatomic, assign) NSInteger selectIndex;

@end

@implementation ChatPage

- (UIViewController *)previewingContext:(id <UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    GJGCChatFriendViewController *showPage = nil;

    //location cell
    NSInteger index = (location.y - [UIApplication sharedApplication].statusBarFrame.size.height - 44) / self.tableView.rowHeight;
    if (0 <= index && index < self.recentChats.count) {
        RecentChatModel *recentModel = [self.recentChats objectAtIndex:index];
        if (recentModel.chatUser.stranger) {
            recentModel.chatUser.stranger = ![[UserDBManager sharedManager] isFriendByAddress:recentModel.chatUser.address];
        }
        switch (recentModel.talkType) {
            case GJGCChatFriendTalkTypePostSystem:
            case GJGCChatFriendTalkTypePrivate: {
                GJGCChatFriendTalkModel *talk = [[GJGCChatFriendTalkModel alloc] init];
                talk.talkType = recentModel.talkType;
                talk.chatIdendifier = recentModel.identifier;
                talk.headUrl = recentModel.headUrl;
                talk.name = recentModel.chatUser.normalShowName;
                talk.snapChatOutDataTime = recentModel.snapChatDeleteTime;

                talk.chatUser = recentModel.chatUser;
                if (recentModel.talkType == GJGCChatFriendTalkTypePostSystem) {
                    showPage = [[GJGCChatSystemNotiViewController alloc] initWithTalkInfo:talk];
                } else {
                    if (recentModel.stranger) {
                        BOOL isFriend = [[UserDBManager sharedManager] isFriendByAddress:[KeyHandle getAddressByPubkey:recentModel.identifier]];
                        if (isFriend) {
                            [[LMConversionManager sharedManager] setRecentStrangerStatusWithIdentifier:recentModel.identifier stranger:NO];
                        }
                    }
                    //Delete the message after reading
                    [[MessageDBManager sharedManager] deleteSnapOutTimeMessageByMessageOwer:recentModel.identifier];
                    showPage = [[GJGCChatFriendViewController alloc] initWithTalkInfo:talk];
                }
            }
                break;
            case GJGCChatFriendTalkTypeGroup: {
                GJGCChatFriendTalkModel *talk = [[GJGCChatFriendTalkModel alloc] init];
                talk.talkType = GJGCChatFriendTalkTypeGroup;
                talk.chatIdendifier = recentModel.identifier;
                talk.chatGroupInfo = recentModel.chatGroupInfo;
                talk.name = GJCFStringIsNull(recentModel.name) ? [NSString stringWithFormat:LMLocalizedString(@"Group (%lu)", nil), (unsigned long) recentModel.chatGroupInfo.groupMembers.count] : [NSString stringWithFormat:@"%@(%lu)", recentModel.name, (unsigned long) recentModel.chatGroupInfo.groupMembers.count];
                showPage = [[GJGCChatGroupViewController alloc] initWithTalkInfo:talk];
            }
                break;
            default:
                break;
        }
    }
    if ([self.presentedViewController isKindOfClass:[UIViewController class]]) {
        return nil;
    }
    return showPage;
}

- (void)previewingContext:(id <UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    GJGCChatDetailViewController *showPage = (GJGCChatDetailViewController *) viewControllerToCommit;
    //clear unread / group @ note
    [[LMConversionManager sharedManager] clearConversionUnreadAndGroupNoteWithIdentifier:showPage.taklInfo.chatIdendifier];
    switch (showPage.taklInfo.talkType) {
        case GJGCChatFriendTalkTypePostSystem:
        case GJGCChatFriendTalkTypePrivate: {
            [SessionManager sharedManager].chatSession = showPage.taklInfo.chatIdendifier;
            [SessionManager sharedManager].chatObject = showPage.taklInfo.chatUser;
        }
            break;

        case GJGCChatFriendTalkTypeGroup: {
            [SessionManager sharedManager].chatSession = showPage.taklInfo.chatIdendifier;
            [SessionManager sharedManager].chatObject = showPage.taklInfo.chatGroupInfo;
        }
            break;
        default:
            break;
    }
    //ui jump
    showPage.hidesBottomBarWhenPushed = YES;
    [self showViewController:showPage sender:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.tabBarController.tabBar.hidden) {
        self.tabBarController.tabBar.hidden = NO;
    }
    //3d touch
//    if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) {
//        [self registerForPreviewingWithDelegate:(id)self sourceView:self.view];
//    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [SessionManager sharedManager].GetNewVersionInfoCallback = ^(VersionResponse *currentNewVersionInfo) {
        [self updateAppNoteWithCurrentNewVersionInfo:currentNewVersionInfo];
    };
    [self updateAppNoteWithCurrentNewVersionInfo:[SessionManager sharedManager].currentNewVersionInfo];

    self.tabBarController.delegate = self;
    self.navigationItem.leftBarButtonItems = nil;
    self.titleView = [[RecentChatTitleView alloc] init];
    self.navigationItem.titleView = self.titleView;
    self.recentChats = [NSMutableArray array];
    [self configTableView];

    [self addNotification];

    self.titleView = [[RecentChatTitleView alloc] init];
    self.navigationItem.titleView = self.titleView;
    [self onConnectState:0];

    [self showFristRegisterBackupTipView];

    //conversion  monitor
    [LMConversionManager sharedManager].conversationListDelegate = self;
    [[LMConversionManager sharedManager] getAllConversationFromDB];
}

#pragma mark - LMConversionListChangeManagerDelegate

- (void)conversationListDidChanged:(NSArray<RecentChatModel *> *)conversationList {
    self.recentChats = [conversationList mutableCopy];
    [self conversationListUpdate];
}

- (void)unreadMessageNumberDidChanged {
    [self updateBarBadgeIsNeedSyncBadge:NO];
}

- (void)unreadMessageNumberDidChangedNeedSyncbadge {
    [self updateBarBadgeIsNeedSyncBadge:YES];
}

- (void)showFristRegisterBackupTipView {
    if ([LKUserCenter shareCenter].isFristLogin) {
        LMRegisterPrivkeyBackupTipView *registerPrivkeyTipView = [[[NSBundle mainBundle] loadNibNamed:@"LMRegisterPrivkeyBackupTipView" owner:nil options:nil] lastObject];
        AppDelegate *app = (AppDelegate *) [UIApplication sharedApplication].delegate;
        UIWindow *window = app.window;
        registerPrivkeyTipView.frame = [UIScreen mainScreen].bounds;
        registerPrivkeyTipView.controller = self;
        [window addSubview:registerPrivkeyTipView];
        [window bringSubviewToFront:registerPrivkeyTipView];
    }
}

- (void)addNotification {
    [[IMService instance] addConnectionObserver:self];
    RegisterNotify(SocketDataVerifyIllegalityNotification, @selector(socketDataVerifyFail));
    RegisterNotify(UIApplicationWillEnterForegroundNotification, @selector(enterForeground));
}

- (void)enterForeground {
    if ([SessionManager sharedManager].currentNewVersionInfo.force) {
        [self showUpdataAlertWithMessage:[SessionManager sharedManager].currentNewVersionInfo.remark force:YES];
    }
}

- (void)socketDataVerifyFail {
    [self showUpdataAlertWithMessage:LMLocalizedString(@"Chat Connection protocol upgrades", nil) force:YES];
}

- (void)showUpdataAlertWithMessage:(NSString *)message force:(BOOL)force {
    NSString *cancel = nil;
    if (!force) {
        cancel = LMLocalizedString(@"Common Cancel", nil);
    }
    [UIAlertController showAlertInViewController:self withTitle:LMLocalizedString(@"Set Found new version", nil) message:message cancelButtonTitle:cancel destructiveButtonTitle:nil otherButtonTitles:@[LMLocalizedString(@"Set Now update app", nil)] tapBlock:^(UIAlertController *_Nonnull controller, UIAlertAction *_Nonnull action, NSInteger buttonIndex) {
        if (buttonIndex != 0) { //tap update
            if ([SystemTool isNationChannel]) {
                if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:nationalAppDownloadUrl] options:nil completionHandler:^(BOOL success) {

                    }];
                } else {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:nationalAppDownloadUrl]];
                }
            } else {
                if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appstoreAppDownloadUrl] options:nil completionHandler:^(BOOL success) {

                    }];
                } else {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appstoreAppDownloadUrl]];
                }
            }
        }
    }];
}


- (void)updateAppNoteWithCurrentNewVersionInfo:(VersionResponse *)currentNewVersionInfo {
    if (self.updated || !currentNewVersionInfo) {
        return;
    }
    self.updated = YES;
    if (currentNewVersionInfo.force) {
        [self showUpdataAlertWithMessage:currentNewVersionInfo.remark force:YES];
    } else {
        BOOL havedNoteUpdate = GJCFUDFGetValue(@"havedNoteUpdateKey");
        if (!havedNoteUpdate) {
            NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary]; //CFBundleIdentifier
            NSString *versionNum = [infoDict objectForKey:@"CFBundleShortVersionString"];
            int ver = [[currentNewVersionInfo.version stringByReplacingOccurrencesOfString:@"." withString:@""] intValue];
            int currentVer = [[versionNum stringByReplacingOccurrencesOfString:@"." withString:@""] intValue];
            if (currentVer < ver) {
                [self showUpdataAlertWithMessage:currentNewVersionInfo.remark force:NO];
                GJCFUDFCache(@"havedNoteUpdateKey", @(YES));
            }
        }
    }
}

- (void)dealloc {
    [[IMService instance] removeConnectionObserver:self];
    RemoveNofify;
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
        case GJGCChatFriendTalkTypePrivate: {
            [self pushFriendChatViewControllerWith:recentModel];
        }
            break;

        case GJGCChatFriendTalkTypeGroup: {
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
    talk.mute = recentModel.notifyStatus;
    talk.top = recentModel.isTopChat;
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
    talk.mute = recentModel.notifyStatus;
    talk.top = recentModel.isTopChat;
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
    __weak __typeof(&*self) weakSelf = self;
    [MBProgressHUD showLoadingMessageToView:self.view];
    [[LMConversionManager sharedManager] setConversationMute:model complete:^(BOOL complete) {
        if (complete) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Successful", nil) withType:ToastTypeSuccess showInView:weakSelf.view complete:nil];
            }];
        } else {
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

- (void)updateBarBadgeIsNeedSyncBadge:(BOOL)IsNeedSyncBadge {
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

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {

    UINavigationController *navdid = tabBarController.selectedViewController;
    UINavigationController *nav = (UINavigationController *) viewController;
    if (![navdid.topViewController isEqual:self]) {
        self.tapTimeInterval = 0;
    }
    if (self.tapTimeInterval) {
        NSTimeInterval time = [[NSDate date] timeIntervalSince1970] - self.tapTimeInterval;
        if (time > 0 && time < 1.2f) {
            if (self.recentChats.count) {
                NSIndexPath *indexPat = [NSIndexPath indexPathForRow:0 inSection:0];
                [self.tableView scrollToRowAtIndexPath:indexPat atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }
        }
        self.tapTimeInterval = 0;
    } else {
        if ([nav.topViewController isEqual:self]) {
            self.tapTimeInterval = [[NSDate date] timeIntervalSince1970];
        }
    }
    return YES;
}

@end
