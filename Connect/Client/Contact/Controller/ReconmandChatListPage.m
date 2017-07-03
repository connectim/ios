//
//  ReconmandChatListPage.m
//  Connect
//
//  Created by MoHuilin on 16/7/22.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "ReconmandChatListPage.h"
#import "RecentChatDBManager.h"
#import "MessageDBManager.h"
#import "IMService.h"
#import "RecentChatForRecommendCell.h"
#import "LMShareContactViewController.h"
#import "LMTableHeaderView.h"
#import "LMRetweetMessageManager.h"


@implementation LMRerweetModel


@end

@interface ReconmandChatListPage () <UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) UITableView *tableView;
// recentChat
@property(nonatomic, strong) NSMutableArray *recentChats;
// recommand contact
@property(nonatomic, strong) AccountInfo *contact;
// tempoary array
@property(strong, nonatomic) NSMutableArray *dataArray;

@property(nonatomic, strong) LMRerweetModel *retweetModel;

@end

@implementation ReconmandChatListPage

- (instancetype)initWithRecommandContact:(AccountInfo *)contact {
    if (self = [super init]) {
        self.contact = contact;
    }

    return self;
}

- (instancetype)initWithRetweetModel:(LMRerweetModel *)retweetModel {
    if (self = [super init]) {
        self.retweetModel = retweetModel;
    }
    return self;
}

#pragma mark - lazy

- (UITableView *)tableView {
    if (!_tableView) {
        self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        [self.tableView registerNib:[UINib nibWithNibName:@"RecentChatForRecommendCell" bundle:nil] forCellReuseIdentifier:@"RecentChatForRecommendCellID"];
        self.tableView.rowHeight = AUTO_HEIGHT(111);
        self.tableView.delegate = self;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.tableHeaderView = [self creatHeadView];
        self.tableView.dataSource = self;
    }
    return _tableView;
}

- (NSMutableArray *)dataArray {
    if (_dataArray == nil) {
        self.dataArray = [NSMutableArray array];
    }
    return _dataArray;
}

#pragma mark - method respose

- (void)viewDidLoad {
    [super viewDidLoad];

    [self addCloseBarItem];
    if (!self.retweetModel) {
        self.title = LMLocalizedString(@"Chat Share contact", nil);
    }
    self.recentChats = [SessionManager sharedManager].allRecentChats;
    for (RecentChatModel *recentModel in self.recentChats) {
        if (!([recentModel.identifier isEqualToString:self.contact.pub_key] || recentModel.talkType == GJGCChatFriendTalkTypePostSystem)) {
            [self.dataArray objectAddObject:recentModel];
        }
    }
    [self.view addSubview:self.tableView];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    RecentChatForRecommendCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RecentChatForRecommendCellID" forIndexPath:indexPath];
    RecentChatModel *recentModel = [self.dataArray objectAtIndexCheck:indexPath.row];
    [cell setData:recentModel];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    RecentChatModel *recentModel = [self.dataArray objectAtIndexCheck:indexPath.row];
    __weak __typeof(&*self) weakSelf = self;

    NSString *title = [NSString stringWithFormat:LMLocalizedString(@"Chat Share contact to", nil), self.contact.username, recentModel.name];
    if (self.retweetModel) {
        if (self.retweetModel.retweetMessage.type == GJGCChatFriendContentTypeVideo) {
            title = [NSString stringWithFormat:LMLocalizedString(@"Chat Send video to", nil), recentModel.name];
        } else if (self.retweetModel.retweetMessage.type == GJGCChatFriendContentTypeImage) {
            title = [NSString stringWithFormat:LMLocalizedString(@"Chat Send image to", nil), recentModel.name];
        } else {
            title = [NSString stringWithFormat:LMLocalizedString(@"Link Send to", nil), recentModel.name];
        }
    }

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        [weakSelf shareWithRecentModel:recentModel];
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    alertController.automaticallyAdjustsScrollViewInsets = NO;
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)shareWithRecentModel:(RecentChatModel *)recentModel {
    if (self.retweetModel) {
        if (recentModel.talkType == GJGCChatFriendTalkTypeGroup) {
            self.retweetModel.toFriendModel = recentModel.chatGroupInfo;
        } else {
            self.retweetModel.toFriendModel = recentModel.chatUser;
        }
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
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }
                } else {
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Send failed", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                }
            }];
        }];
    } else {
        
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showMessage:LMLocalizedString(@"Common Loading", nil) toView:self.view];
        }];
        // creat card
        MMMessage *message = [[MMMessage alloc] init];
        message.user_name = recentModel.name;
        message.type = GJGCChatFriendContentTypeNameCard;
        message.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
        message.message_id = [ConnectTool generateMessageId];
        message.content = self.contact.address;
        message.publicKey = recentModel.identifier;
        message.user_id = recentModel.chatUser.address;
        message.sendstatus = GJGCChatFriendSendMessageStatusSending;
        message.ext1 = @{@"username": self.contact.username,
                @"avatar": self.contact.avatar,
                @"pub_key": self.contact.pub_key,
                @"address": self.contact.address};
        if (recentModel.talkType == GJGCChatFriendTalkTypeGroup) {
            message.senderInfoExt = @{@"username": [[LKUserCenter shareCenter] currentLoginUser].username,
                    @"address": [[LKUserCenter shareCenter] currentLoginUser].address,
                    @"avatar": [[LKUserCenter shareCenter] currentLoginUser].avatar};
            message.user_id = recentModel.identifier;
        }
        NSInteger snapTime = 0;
        if (message.ext && [message.ext isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dict = message.ext;
            if ([dict.allKeys containsObject:@"luck_delete"]) {
                snapTime = [[dict valueForKey:@"luck_delete"] integerValue];
            }
        }

        ChatMessageInfo *messageInfo = [[ChatMessageInfo alloc] init];
        messageInfo.messageId = message.message_id;
        messageInfo.messageType = message.type;
        messageInfo.createTime = message.sendtime;
        messageInfo.messageOwer = recentModel.identifier;
        messageInfo.sendstatus = GJGCChatFriendSendMessageStatusSending;
        messageInfo.message = message;
        messageInfo.snapTime = snapTime;
        messageInfo.readTime = 0;
        [[MessageDBManager sharedManager] saveMessage:messageInfo];

        // top session
        int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
        NSString *last_time = [NSString stringWithFormat:@"%lld", time];
        recentModel.time = last_time;
        [[RecentChatDBManager sharedManager] updataRecentChatLastTimeByIdentifer:recentModel.identifier];
        SendNotify(ConnnectRecentChatChangeNotification, recentModel);

        // send message
        __weak __typeof(&*self) weakSelf = self;
        if (recentModel.talkType == GJGCChatFriendTalkTypeGroup) {
            [[IMService instance] asyncSendGroupMessage:message withGroupEckhKey:recentModel.chatGroupInfo.groupEcdhKey onQueue:nil completion:^(MMMessage *message, NSError *error) {
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
                    [[MessageDBManager sharedManager] updateMessageSendStatus:GJGCChatFriendSendMessageStatusSuccess withMessageId:message.message_id messageOwer:recentModel.identifier];
                }
            }                                   onQueue:nil];
        } else {
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
                    [[MessageDBManager sharedManager] updateMessageSendStatus:GJGCChatFriendSendMessageStatusSuccess withMessageId:message.message_id messageOwer:recentModel.identifier];
                }
            }                                     onQueue:nil];
        }
    }
}

#pragma mark - tableview - head message

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VSIZE.width, AUTO_HEIGHT(40))];
    bgView.backgroundColor = LMBasicBackgroundColor;
    UILabel *titleOneLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, VSIZE.width - 10, AUTO_HEIGHT(40))];
    titleOneLabel.backgroundColor = [UIColor clearColor];
    titleOneLabel.text = LMLocalizedString(@"Chat Recent chat", nil);
    titleOneLabel.font = [UIFont systemFontOfSize:FONT_SIZE(26)];
    titleOneLabel.textColor = LMBasicDarkGray;
    titleOneLabel.textAlignment = NSTextAlignmentLeft;
    [bgView addSubview:titleOneLabel];
    return bgView;

}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return AUTO_HEIGHT(40);
}

- (UIView *)creatHeadView {
    __weak typeof(self) weakSelf = self;
    LMTableHeaderView *headerView = [[[NSBundle mainBundle] loadNibNamed:@"LMTableHeaderView" owner:nil options:nil] lastObject];
    headerView.height = AUTO_HEIGHT(88);
    headerView.buttonClickBlock = ^() {
        [weakSelf pushContactVc];
    };
    return headerView;
}

#pragma mark - click head message

- (void)pushContactVc {
    LMShareContactViewController *lmShareVc = nil;
    if (self.retweetModel) {
        lmShareVc = [[LMShareContactViewController alloc] initWithRetweetModel:self.retweetModel];
    } else {
        lmShareVc = [[LMShareContactViewController alloc] initWithAccount:self.contact];
    }
    [self.navigationController pushViewController:lmShareVc animated:YES];
}
@end
