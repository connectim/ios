//
//  LinkmanPage.m
//  Connect
//
//  Created by MoHuilin on 16/5/22.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LinkmanPage.h"
#import "LinkmanFriendCell.h"
#import "ScanAddPage.h"
#import "SearchPage.h"
#import "LMBitAddressViewController.h"
#import "ConnectTableHeaderView.h"
#import "NewFriendsRequestPage.h"
#import "GJGCChatFriendViewController.h"
#import "UserDetailPage.h"
#import "FriendSetPage.h"
#import "GJGCChatGroupViewController.h"
#import "NewFriendTipCell.h"
#import "BadgeNumberManager.h"
#import "GJGCChatSystemNotiViewController.h"
#import "LMHandleScanResultManager.h"
#import "LMLinkManDataManager.h"

@interface LinkmanPage () <MGSwipeTableCellDelegate, UINavigationControllerDelegate, LMLinkManDataManagerDelegate>

//tableView headerView
@property(nonatomic, strong) UIView *headerView;
// total members Label
@property(nonatomic, strong) UILabel *totalContactLabel;


@end

@implementation LinkmanPage


- (NSMutableArray *)groupsFriend {
    return [[LMLinkManDataManager sharedManager] getListGroupsFriend];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [LMLinkManDataManager sharedManager].delegate = self;
    [[LMLinkManDataManager sharedManager] getAllLinkMan];
    [self configTableView];

    self.navigationItem.leftBarButtonItems = nil;

    self.navigationController.title = LMLocalizedString(@"Link Contacts", nil);
    [self setNavigationRight:@"add_white"];
    // set left button
    [self setLeftButton];
    
}
-(void)setLeftButton
{
    UIButton* leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    leftButton.frame = CGRectMake(0, 0, 18, 18);
    [leftButton setImage:[UIImage imageNamed:@"search"] forState:UIControlStateNormal];
    [leftButton addTarget:self action:@selector(leftButtonAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem* item = [[UIBarButtonItem alloc] initWithCustomView:leftButton];
    self.navigationItem.leftBarButtonItem = item;
}
/**
 * button click action
 */
-(void)leftButtonAction
{
    SearchPage *searchP = [[SearchPage alloc] initWithUsers:[LMLinkManDataManager sharedManager].getListFriendsArr groups:[LMLinkManDataManager sharedManager].getListCommonGroup];
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:searchP] animated:NO completion:nil];
}
- (void)setTableViewFoot {
    NSString *commonGroupCountTip = nil;
    if ([LMLinkManDataManager sharedManager].getListCommonGroup.count > 0) {
        commonGroupCountTip = [NSString stringWithFormat:LMLocalizedString(@"Link group count", nil), (unsigned long) [LMLinkManDataManager sharedManager].getListCommonGroup.count];
    }
    self.totalContactLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Link contact count", nil), (unsigned long) [LMLinkManDataManager sharedManager].getListFriendsArr.count, ([LMLinkManDataManager sharedManager].getListFriendsArr.count > 1 && [LMLocalizedString(@"Link contact count", nil) containsString:@"contact"]) ? @"s" : @"", GJCFStringIsNull(commonGroupCountTip) ? @"" : commonGroupCountTip];
}

#pragma mark - event

- (void)friendPerssionSet:(UITableViewCell *)cell {

    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

    AccountInfo *user = self.groupsFriend[indexPath.section][@"items"][indexPath.row];

    user.tags = [[UserDBManager sharedManager] getUserTags:user.address];

    FriendSetPage *page = [[FriendSetPage alloc] initWithUser:user];
    page.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:page animated:YES];


}

- (void)doRight:(id)sender {
    __weak __typeof(&*self) weakSelf = self;
    ScanAddPage *scanPage = [[ScanAddPage alloc] initWithScanComplete:^(NSString *scanString) {
        __strong __typeof(&*weakSelf) strongSelf = weakSelf;
        [[LMHandleScanResultManager sharedManager] handleScanResult:scanString controller:strongSelf];
    }];
    scanPage.showMyQrCode = YES;
    [self presentViewController:scanPage animated:NO completion:nil];
}


- (void)configTableView {
    [self.tableView registerNib:[UINib nibWithNibName:@"LinkmanFriendCell" bundle:nil] forCellReuseIdentifier:@"LinkmanFriendCellID"];
    [self.tableView registerNib:[UINib nibWithNibName:@"NewFriendTipCell" bundle:nil] forCellReuseIdentifier:@"NewFriendTipCellID"];
    [self.tableView registerClass:[ConnectTableHeaderView class] forHeaderFooterViewReuseIdentifier:@"ConnectTableHeaderViewID"];
    self.tableView.rowHeight = AUTO_HEIGHT(111);
    self.tableView.sectionIndexColor = [UIColor lightGrayColor];
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    self.tableView.backgroundColor = GJCFQuickHexColor(@"F0F0F6");
    // head tip view
    UIView *headerView = [[UIView alloc] init];
    self.headerView = headerView;
    headerView.backgroundColor = GJCFQuickHexColor(@"F0F0F6");
    self.headerView.alpha = 0;
    headerView.size = AUTO_SIZE(750, 120);
    UITextField *searchField = [UITextField new];
    searchField.placeholder = LMLocalizedString(@"Link Search", nil);
    searchField.borderStyle = UITextBorderStyleRoundedRect;
    [headerView addSubview:searchField];
    searchField.frame = AUTO_RECT(30, 0, 690, 80);
    searchField.centerY = headerView.centerY;
    searchField.backgroundColor = [UIColor whiteColor];
    self.tableView.tableHeaderView = headerView;
    UIEdgeInsets insets = self.tableView.contentInset;
    self.tableView.contentInset = UIEdgeInsetsMake(insets.top - headerView.height, insets.left, insets.bottom, insets.right);

    // bottom view
    UILabel *totalContactLabel = [[UILabel alloc] init];
    self.totalContactLabel = totalContactLabel;
    totalContactLabel.frame = AUTO_RECT(0, 0, 0, 111);
    totalContactLabel.width = DEVICE_SIZE.width;
    totalContactLabel.textAlignment = NSTextAlignmentCenter;
    totalContactLabel.textColor = [UIColor colorWithWhite:0.800 alpha:1.000];
    self.tableView.tableFooterView = totalContactLabel;
    totalContactLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
}
#pragma mark - linkmandatalist - delegate

- (void)listChange:(NSMutableArray *)linkDataArray withTabBarCount:(NSUInteger)count {
    self.groupsFriend = linkDataArray.mutableCopy;
    [GCDQueue executeInMainQueue:^{
        [self setTableViewFoot];
        [self.tableView reloadData];
        if (count <= 0) {
            self.tabBarItem.badgeValue = nil;
        } else {
            self.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d", (int) count];
        }
    }];
}

#pragma mark - Table view data source

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [[LMLinkManDataManager sharedManager] getListIndexs].copy;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *items = self.groupsFriend[section][@"items"];
    return items.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.groupsFriend.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 0;
    }
    return AUTO_HEIGHT(40);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    ConnectTableHeaderView *hearderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"ConnectTableHeaderViewID"];
    hearderView.customTitle.text = [self.groupsFriend[section] valueForKey:@"title"];
    NSString *titleIcon = [self.groupsFriend[section] valueForKey:@"titleicon"];
    hearderView.customIcon = titleIcon;
    return hearderView;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    NSDictionary *groupDict = [self.groupsFriend objectAtIndex:indexPath.section];
    NSArray *items = [groupDict valueForKey:@"items"];
    id data = [items objectAtIndex:indexPath.row];
    if (indexPath.section == 0) {
        NewFriendTipCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NewFriendTipCellID" forIndexPath:indexPath];
        cell.data = data;
        return cell;
    }
    LinkmanFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LinkmanFriendCellID" forIndexPath:indexPath];
    cell.delegate = self;
    cell.data = data;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        //New friend
        [[LMLinkManDataManager sharedManager] clearUnreadCountWithType:ALTYPE_CategoryTwo_NewFriend];
        NewFriendsRequestPage *page = [[NewFriendsRequestPage alloc] init];
        page.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:page animated:YES];
    } else {
        id data = self.groupsFriend[indexPath.section][@"items"][indexPath.row];
        if ([data isKindOfClass:[LMGroupInfo class]]) {
            LMGroupInfo *group = (LMGroupInfo *) data;
            GJGCChatFriendTalkModel *talk = [[GJGCChatFriendTalkModel alloc] init];
            talk.talkType = GJGCChatFriendTalkTypeGroup;
            talk.chatIdendifier = group.groupIdentifer;
            talk.group_ecdhKey = group.groupEcdhKey;
            talk.chatGroupInfo = group;
            // save session object
            [SessionManager sharedManager].chatSession = talk.chatIdendifier;
            [SessionManager sharedManager].chatObject = group;
            talk.name = GJCFStringIsNull(group.groupName) ? [NSString stringWithFormat:LMLocalizedString(@"Link Group", nil), (unsigned long) talk.chatGroupInfo.groupMembers.count] : [NSString stringWithFormat:@"%@(%lu)", group.groupName, (unsigned long) talk.chatGroupInfo.groupMembers.count];
            GJGCChatGroupViewController *groupChat = [[GJGCChatGroupViewController alloc] initWithTalkInfo:talk];
            groupChat.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:groupChat animated:YES];

        } else if ([data isKindOfClass:[AccountInfo class]]) {
            AccountInfo *user = (AccountInfo *) data;
            if ([user.pub_key isEqualToString:kSystemIdendifier]) {
                GJGCChatFriendTalkModel *talk = [[GJGCChatFriendTalkModel alloc] init];
                talk.talkType = GJGCChatFriendTalkTypePrivate;
                talk.chatIdendifier = user.pub_key;
                talk.snapChatOutDataTime = 0;
                talk.talkType = GJGCChatFriendTalkTypePostSystem;
                talk.name = user.username;
                talk.headUrl = user.avatar;
                talk.chatUser = user;
                // save session object
                [SessionManager sharedManager].chatSession = talk.chatIdendifier;
                [SessionManager sharedManager].chatObject = talk.chatUser;

                GJGCChatSystemNotiViewController *privateChat = [[GJGCChatSystemNotiViewController alloc] initWithTalkInfo:talk];
                privateChat.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:privateChat animated:YES];
            } else {
                UserDetailPage *detailPage = [[UserDetailPage alloc] initWithUser:user];
                detailPage.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:detailPage animated:YES];
            }
        }
    }
}


- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    if ([LMLinkManDataManager sharedManager].getListFriendsArr.count > 0 && [LMLinkManDataManager sharedManager].getListCommonGroup.count > 0) {
        return index + 3;
    } else if ([LMLinkManDataManager sharedManager].getListFriendsArr.count > 0 || [LMLinkManDataManager sharedManager].getListCommonGroup.count > 0) {
        return index + 2;
    } else {
        return index + 1;
    }
}

#pragma mark Swipe Delegate

- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell canSwipe:(MGSwipeDirection)direction; {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (indexPath.section == 0) {
        return NO;
    }
    id model = self.groupsFriend[indexPath.section][@"items"][indexPath.row];
    if ([model isKindOfClass:[LMGroupInfo class]]) {
        return NO;
    } else if ([model isKindOfClass:[AccountInfo class]]){
        AccountInfo *user = (AccountInfo *)model;
        if ([user.pub_key isEqualToString:kSystemIdendifier]) {
            return NO;
        }
    }
    return YES;
}

- (NSArray *)swipeTableCell:(MGSwipeTableCell *)cell swipeButtonsForDirection:(MGSwipeDirection)direction
              swipeSettings:(MGSwipeSettings *)swipeSettings expansionSettings:(MGSwipeExpansionSettings *)expansionSettings {

    swipeSettings.transition = MGSwipeTransitionStatic;

    if (direction == MGSwipeDirectionRightToLeft) {

        CGFloat padding = AUTO_WIDTH(50);
        __weak __typeof(&*self) weakSelf = self;
        MGSwipeButton *setButton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"contract_setting"] backgroundColor:[UIColor whiteColor] padding:padding callback:^BOOL(MGSwipeTableCell *sender) {
            DDLogInfo(@"Set to be clicked");
            [weakSelf friendPerssionSet:cell];
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
@end
