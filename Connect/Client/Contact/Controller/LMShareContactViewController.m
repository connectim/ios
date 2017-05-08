//
//  LMShareContactViewController.m
//  Connect
//
//  Created by bitmain on 2017/1/10.
//  Copyright © 2017年 Connect. All rights reserved.
//

//
//  ReconmandChatListPage.m
//  Connect
//
//  Created by MoHuilin on 16/7/22.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMShareContactViewController.h"
#import "RecentChatDBManager.h"
#import "MessageDBManager.h"
#import "IMService.h"
#import "UserDBManager.h"
#import "LinkmanFriendCell.h"
#import "NSString+Pinyin.h"
#import "GroupDBManager.h"
#import "ConnectTableHeaderView.h"
#import "LMRetweetMessageManager.h"

@interface LMShareContactViewController () <UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) UITableView *tableView;
//  contacts list
@property(nonatomic, strong) NSMutableArray *contactListArray;
/// user list
@property(nonatomic, strong) NSMutableArray *friendsArr;
//  common friends
@property(nonatomic, strong) NSMutableArray *normalFriends;
@property(nonatomic, strong) NSMutableArray *offenFriends;
// contacts group
@property(nonatomic, strong) NSMutableArray *commonGroup;
// indexs
@property(nonatomic, strong) NSMutableArray *indexs;
@property(nonatomic, strong) LMRerweetModel *retweetModel;


@end

@implementation LMShareContactViewController

- (instancetype)initWithRetweetModel:(LMRerweetModel *)retweetModel {
    if (self = [super init]) {
        self.retweetModel = retweetModel;
    }
    return self;
}

#pragma mark - 懒加载

- (NSMutableArray *)commonGroup {
    if (!_commonGroup) {
        _commonGroup = [NSMutableArray array];
    }

    return _commonGroup;
}

- (NSMutableArray *)offenFriends {
    if (!_offenFriends) {
        _offenFriends = [NSMutableArray array];
    }

    return _offenFriends;
}

- (NSMutableArray *)normalFriends {
    if (!_normalFriends) {
        _normalFriends = [NSMutableArray array];
    }

    return _normalFriends;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        [self.tableView registerNib:[UINib nibWithNibName:@"LinkmanFriendCell" bundle:nil] forCellReuseIdentifier:@"LinkmanFriendCellID"];
        [self.tableView registerClass:[ConnectTableHeaderView class] forHeaderFooterViewReuseIdentifier:@"ConnectTableHeaderViewID"];
        _tableView.rowHeight = AUTO_HEIGHT(100);
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.sectionIndexBackgroundColor = [UIColor clearColor];
        _tableView.sectionIndexTrackingBackgroundColor = [UIColor clearColor];
        _tableView.delegate = self;
        _tableView.dataSource = self;

    }
    return _tableView;
}

- (NSMutableArray *)indexs {
    if (!_indexs) {
        _indexs = [NSMutableArray array];
    }
    return _indexs;
}

- (NSMutableArray *)friendsArr {
    if (!_friendsArr) {
        _friendsArr = [[NSMutableArray alloc] initWithArray:[[UserDBManager sharedManager] getAllUsers]];
    }

    return _friendsArr;
}

- (NSMutableArray *)contactListArray {
    if (_contactListArray == nil) {
        self.contactListArray = [NSMutableArray array];
    }
    return _contactListArray;
}

#pragma mark - 方法的响应

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LMLocalizedString(@"Link Share", nil);
    [self.view addSubview:self.tableView];
    [self creatArray];
}

- (void)creatArray {
    [[GroupDBManager sharedManager] getCommonGroupListWithComplete:^(NSArray *groups) {
        [GCDQueue executeInMainQueue:^{
            for (LMGroupInfo *group in groups) {
                if (![self.commonGroup containsObject:group]) {
                    [self.commonGroup objectAddObject:group];
                } else {
                    [self.commonGroup replaceObjectAtIndex:[self.commonGroup indexOfObject:group] withObject:group];
                }
            }
            [self formartFiendsGrouping];
        }];
    }];
}

- (void)formartFiendsGrouping {
    [[UserDBManager sharedManager] getAllUsersNoConnectWithComplete:^(NSArray *contacts) {
        [GCDQueue executeInMainQueue:^{
            for (AccountInfo *contact in contacts) {
                if (contact.isOffenContact) {
                    if (![self.offenFriends containsObject:contact]) {
                        [self.offenFriends objectAddObject:contact];
                    } else {
                        [self.offenFriends replaceObjectAtIndex:[self.offenFriends indexOfObject:contact] withObject:contact];
                    }
                    if ([contact.address isEqualToString:self.contact.address]) {
                        [self.offenFriends removeObject:contact];
                    }
                } else {
                    if (![self.normalFriends containsObject:contact]) {
                        [self.normalFriends objectAddObject:contact];
                    } else {
                        [self.normalFriends replaceObjectAtIndex:[self.normalFriends indexOfObject:contact] withObject:contact];
                    }
                    if ([contact.address isEqualToString:self.contact.address]) {
                        [self.normalFriends removeObject:contact];
                    }
                }
                if (![self.friendsArr containsObject:contact]) {
                    [self.friendsArr objectAddObject:contact];
                } else {
                    [self.friendsArr replaceObjectAtIndex:[self.friendsArr indexOfObject:contact] withObject:contact];
                }
                if ([contact.address isEqualToString:self.contact.address]) {
                    [self.friendsArr removeObject:contact];
                }
            }
            [self addDataToGroupArray];
        }];
    }];
}

- (void)addDataToGroupArray {

    //indexs
    NSMutableSet *set = [NSMutableSet set];
    NSMutableDictionary *groupDict = [NSMutableDictionary dictionary];
    NSMutableArray *temItems = nil;
    for (AccountInfo *info in self.normalFriends) {
        NSString *prex = @"";
        NSString *name = info.normalShowName;
        if (name.length) {
            prex = [[name transformToPinyin] substringToIndex:1];
        }
        // To heavy
        if ([self preIsInAtoZ:prex]) {
            prex = [prex uppercaseString];
        } else {
            prex = @"#";
        }
        [set addObject:prex];
        // save items
        temItems = [groupDict valueForKey:prex];
        if (!temItems) {
            temItems = [NSMutableArray array];
        }
        [temItems objectAddObject:info];
        [groupDict setObject:temItems forKey:prex];
    }
    for (NSObject *obj in set) {
        if (![self.indexs containsObject:obj]) {
            [self.indexs objectAddObject:obj];
        }
    }

    NSMutableArray *deleteIndexs = [NSMutableArray array];
    for (NSString *pre in self.indexs) {
        if (![set containsObject:pre]) {
            [deleteIndexs addObject:pre];
        }
    }
    [self.indexs removeObjectsInArray:deleteIndexs];
    // array sort
    [self.indexs sortUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
        NSString *str1 = obj1;
        NSString *str2 = obj2;
        return [str1 compare:str2];
    }];

    [self.contactListArray removeAllObjects];
    // common
    if (self.offenFriends.count) {
        NSMutableDictionary *offenFriend = [NSMutableDictionary dictionary];
        offenFriend[@"title"] = LMLocalizedString(@"Link Favorite Friend", nil);
        offenFriend[@"titleicon"] = @"table_header_favorite";
        offenFriend[@"items"] = self.offenFriends;
        [self.contactListArray objectAddObject:offenFriend];
    }
    // common group
    if (self.commonGroup.count) {
        NSMutableDictionary *commonGroup = [NSMutableDictionary dictionary];
        commonGroup[@"title"] = LMLocalizedString(@"Link Group Common", nil);
        commonGroup[@"titleicon"] = @"contract_group_chat";
        commonGroup[@"items"] = self.commonGroup;
        [self.contactListArray objectAddObject:commonGroup];
    }

    NSMutableDictionary *group = nil;
    NSMutableArray *items = nil;

    for (NSString *prex in self.indexs) {
        group = [NSMutableDictionary dictionary];
        items = [groupDict valueForKey:prex];
        group[@"title"] = prex;
        group[@"items"] = items;
        [self.contactListArray objectAddObject:group];
    }
    [GCDQueue executeInMainQueue:^{
        [self.tableView reloadData];
    }];
}

#pragma mark - Table view data source

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.indexs;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *items = self.contactListArray[section][@"items"];
    return items.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.contactListArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return AUTO_HEIGHT(40);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    ConnectTableHeaderView *hearderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"ConnectTableHeaderViewID"];
    hearderView.customTitle.text = [self.contactListArray[section] valueForKey:@"title"];
    NSString *titleIcon = [self.contactListArray[section] valueForKey:@"titleicon"];
    hearderView.customIcon = titleIcon;
    return hearderView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id data = self.contactListArray[indexPath.section][@"items"][indexPath.row];
    LinkmanFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LinkmanFriendCellID" forIndexPath:indexPath];
    cell.data = data;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    id data = self.contactListArray[indexPath.section][@"items"][indexPath.row];

    __weak __typeof(&*self) weakSelf = self;
    NSString *displayName = nil;
    if ([data isKindOfClass:[LMGroupInfo class]]) {
        LMGroupInfo *groupInfo = (LMGroupInfo *) data;
        displayName = groupInfo.groupName;
    } else {
        AccountInfo *user = (AccountInfo *) data;
        displayName = user.username;
    }


    NSString *title = [NSString stringWithFormat:LMLocalizedString(@"Chat Share contact to", nil), self.contact.username, displayName];
    if (self.retweetModel) {
        if (self.retweetModel.retweetMessage.type == GJGCChatFriendContentTypeVideo) {
            title = [NSString stringWithFormat:LMLocalizedString(@"Chat Send video to", nil), displayName];
        } else if (self.retweetModel.retweetMessage.type == GJGCChatFriendContentTypeImage) {
            title = [NSString stringWithFormat:LMLocalizedString(@"Chat Send image to", nil), displayName];
        } else {
            title = [NSString stringWithFormat:LMLocalizedString(@"Chat Send vioce", nil), displayName];
        }
    }


    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        [weakSelf sendShareCardMessageWithChat:data];
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    alertController.automaticallyAdjustsScrollViewInsets = NO;
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)sendShareCardMessageWithChat:(id)data {


    if (self.retweetModel) {
        self.retweetModel.toFriendModel = data;
        __weak __typeof(&*self) weakSelf = self;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeAnnularDeterminate;
        hud.labelText = LMLocalizedString(@"Common Loading", nil);
        [[LMRetweetMessageManager sharedManager] retweetMessageWithModel:self.retweetModel complete:^(NSError *error, float progress) {
            [GCDQueue executeInMainQueue:^{
                if (!error) {
                    if (progress <= 1) {
                        hud.progress = progress;
                    } else {
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Send successful", nil) withType:ToastTypeSuccess showInView:weakSelf.view complete:nil];
                        [weakSelf dismissViewControllerAnimated:YES completion:nil];
                    }
                } else {
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Send failed", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                }
            }];
        }];
    } else {
        [MBProgressHUD showMessage:LMLocalizedString(@"Sending...", nil) toView:self.view];
        // create name card
        MMMessage *message = [[MMMessage alloc] init];
        if ([data isKindOfClass:[AccountInfo class]]) {
            AccountInfo *info = (AccountInfo *) data;
            message.user_name = info.username;
            message.type = GJGCChatFriendContentTypeNameCard;
            message.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
            message.message_id = [ConnectTool generateMessageId];
            message.content = self.contact.address;
            message.publicKey = info.pub_key;
            message.user_id = info.address;
            message.sendstatus = GJGCChatFriendSendMessageStatusSending;
        } else {
            LMGroupInfo *info = (LMGroupInfo *) data;
            message.user_name = info.groupName;
            message.type = GJGCChatFriendContentTypeNameCard;
            message.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
            message.message_id = [ConnectTool generateMessageId];
            message.content = self.contact.address;
            message.publicKey = info.groupIdentifer;
            message.user_id = info.groupIdentifer;
            message.sendstatus = GJGCChatFriendSendMessageStatusSending;
        }

        message.senderInfoExt = @{@"username": [[LKUserCenter shareCenter] currentLoginUser].username,
                @"address": [[LKUserCenter shareCenter] currentLoginUser].address,
                @"avatar": [[LKUserCenter shareCenter] currentLoginUser].avatar};

        message.ext1 = @{@"username": self.contact.username,
                @"avatar": self.contact.avatar,
                @"pub_key": self.contact.pub_key,
                @"address": self.contact.address};

        ChatMessageInfo *messageInfo = [[ChatMessageInfo alloc] init];
        messageInfo.messageId = message.message_id;
        messageInfo.messageType = message.type;
        messageInfo.createTime = message.sendtime;

        if ([data isKindOfClass:[AccountInfo class]]) {
            AccountInfo *info = (AccountInfo *) data;
            messageInfo.messageOwer = info.pub_key;
        } else {
            LMGroupInfo *info = (LMGroupInfo *) data;
            messageInfo.messageOwer = info.groupIdentifer;
        }

        messageInfo.sendstatus = GJGCChatFriendSendMessageStatusSending;
        messageInfo.message = message;
        messageInfo.snapTime = 0;
        messageInfo.readTime = 0;
        [[MessageDBManager sharedManager] saveMessage:messageInfo];

        if ([data isKindOfClass:[LMGroupInfo class]]) {
            LMGroupInfo *info = (LMGroupInfo *) data;
            // creat new session
            [[RecentChatDBManager sharedManager] createNewChatWithIdentifier:info.groupIdentifer groupChat:YES lastContentShowType:0 lastContent:[GJGCChatFriendConstans lastContentMessageWithType:message.type textMessage:message.content] ecdhKey:info.groupEcdhKey talkName:nil];
        } else {
            AccountInfo *info = (AccountInfo *) data;
            NSString *ecdhKey = [KeyHandle getECDHkeyUsePrivkey:[LKUserCenter shareCenter].currentLoginUser.prikey PublicKey:info.pub_key];
            [[RecentChatDBManager sharedManager] createNewChatWithIdentifier:info.pub_key groupChat:NO lastContentShowType:0 lastContent:[GJGCChatFriendConstans lastContentMessageWithType:message.type textMessage:message.content] ecdhKey:ecdhKey talkName:nil];
        }
        // send message
        __weak __typeof(&*self) weakSelf = self;
        if ([data isKindOfClass:[LMGroupInfo class]]) {
            LMGroupInfo *info = (LMGroupInfo *) data;
            [[IMService instance] asyncSendGroupMessage:message withGroupEckhKey:info.groupEcdhKey onQueue:nil completion:^(MMMessage *message, NSError *error) {
                if (error) {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD hideHUDForView:weakSelf.view];
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Share failed", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                    }];
                } else {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD hideHUDForView:weakSelf.view];
                        [weakSelf dismissViewControllerAnimated:YES completion:nil];
                    }];
                    // update message status
                    [[MessageDBManager sharedManager] updateMessageSendStatus:GJGCChatFriendSendMessageStatusSuccess withMessageId:message.message_id messageOwer:info.groupIdentifer];
                }
            }                                   onQueue:nil];
        } else {
            AccountInfo *info = (AccountInfo *) data;
            [[IMService instance] asyncSendMessageMessage:message onQueue:nil completion:^(MMMessage *message, NSError *error) {
                if (error) {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD hideHUDForView:weakSelf.view];
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Share failed", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                    }];
                } else {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD hideHUDForView:weakSelf.view];
                        [weakSelf dismissViewControllerAnimated:YES completion:nil];
                    }];
                    // update message status
                    [[MessageDBManager sharedManager] updateMessageSendStatus:GJGCChatFriendSendMessageStatusSuccess withMessageId:message.message_id messageOwer:info.pub_key];
                }
            }                                     onQueue:nil];
        }
    }
}

#pragma mark - 其他方法

- (BOOL)preIsInAtoZ:(NSString *)str {
    return [@"QWERTYUIOPLKJHGFDSAZXCVBNM" containsString:str] || [[@"QWERTYUIOPLKJHGFDSAZXCVBNM" lowercaseString] containsString:str];
}

- (void)dealloc {
    [self.tableView removeFromSuperview];
    self.tableView = nil;
    self.friendsArr = nil;
    self.contactListArray = nil;
    self.indexs = nil;
    self.offenFriends = nil;
    self.normalFriends = nil;
}
@end

