//
//  LMChatRedLuckyDetailController.m
//  Connect
//
//  Created by Qingxu Kuang on 16/7/30.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMChatRedLuckyDetailController.h"
#import "LMRecLuckyDetailCell.h"
#import "LMRedLuckyDetailModel.h"
#import "CommonClausePage.h"
#import "YYImageCache.h"


typedef NS_ENUM(NSUInteger,PacketStatus) {
    PacketStatusWaitOpen               = 1 << 0,
    PacketStatusOverTimeAndBack        = 1 << 1,
    PacketStatusOverTime               = 1 << 2,
    PacketStatusWaitArrivalYourWallet  = 1 << 3,
    PacketStatusIsDone                 = 1 << 4,
    PacketStatusIsArrivalYourWallet    = 1 << 5,
    
};

static NSString *cellIdentifier = @"cellIdentifier";

@interface LMChatRedLuckyDetailController () <UITableViewDelegate, UITableViewDataSource>
@property(weak, nonatomic) IBOutlet UIImageView *icon;
@property(weak, nonatomic) IBOutlet UILabel *nameLabel;
@property(weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property(weak, nonatomic) IBOutlet UILabel *moneyValue;
@property(weak, nonatomic) IBOutlet UILabel *redLuckyStatusLabel;
@property(weak, nonatomic) IBOutlet UITableView *redLuckyListTableView;
@property(strong, nonatomic) NSArray *statusStrings;
@property(strong, nonatomic) NSMutableArray *dataArray;
@property(strong, nonatomic) AccountInfo *accountInfo;
@property(copy, nonatomic) NSString *moneyString;
@property(assign, nonatomic) long long garbedMoney;
@property(strong, nonatomic) RedPackageInfo *redLuckyInfo;
@property(assign, nonatomic) BOOL isFromHistory;
@property(assign, nonatomic) PacketStatus packetStatus;
@end

@implementation LMChatRedLuckyDetailController

#pragma mark - system method

- (instancetype)initWithUserInfo:(AccountInfo *)info redLuckyInfo:(RedPackageInfo *)redLuckyInfo {
    self = [super init];
    if (self) {
        
        _accountInfo = info;
        _dataArray = @[].mutableCopy;
        self.redLuckyInfo = redLuckyInfo;
        for (GradRedPackageHistroy *history in redLuckyInfo.gradHistoryArray) {
            
            self.garbedMoney += history.amount;
            UserInfo *userGranded = history.userinfo;
            AccountInfo *userInfo = [self openRedPackgeUserWithAddress:userGranded.address];
            LMRedLuckyDetailModel *userModel = [LMRedLuckyDetailModel new];
            userModel.userName = userGranded.username;
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:history.createdAt];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"MM-dd HH:mm";
            NSString *timeString = [formatter stringFromDate:date];
            userModel.dateString = timeString;
            userModel.moneyString = [PayTool getBtcStringWithAmount:history.amount];
            if ([userGranded.address isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                
                self.moneyString = userModel.moneyString;
            }
            NSString *avatar = userGranded.avatar;
            if (userInfo) {
                
                userModel.userName = userInfo.groupShowName;
                avatar = userInfo.avatar;
                
            }
            userModel.iconURLString = avatar;
            [self.dataArray objectAddObject:userModel];
        }

        if (!GJCFStringIsNull(self.redLuckyInfo.redpackage.txid) && !self.redLuckyInfo.redpackage.expired && !self.redLuckyInfo.redpackage.refund) {
            // red packet
            LMRedLuckyDetailModel *winerModel = [self.dataArray firstObject];
            for (LMRedLuckyDetailModel *model in self.dataArray) {
                
                if (model.moneyString.doubleValue >= winerModel.moneyString.doubleValue) {
                    
                    winerModel = model;
                }
            }
            winerModel.winer = YES;
        }
        if (redLuckyInfo.redpackage.category == 0 &&
            
                !redLuckyInfo.redpackage.system) { // per packet display money system is not
            
            self.moneyString = [NSString stringWithFormat:@"%@", [PayTool getBtcStringWithAmount:redLuckyInfo.redpackage.money]];
        }
    }
    return self;
}

- (instancetype)initWithUserInfo:(AccountInfo *)info redLuckyInfo:(RedPackageInfo *)redLuckyInfo isFromHistory:(BOOL)isFromHistory {
    
    if (self = [self initWithUserInfo:info redLuckyInfo:redLuckyInfo]) {
        
        self.isFromHistory = isFromHistory;
    }
    return self;
}
- (instancetype)init {
    [NSException raise:@"use  sharedRecLuckyDetailControllerWithUserInfo:dataArray:redLuckyStatusStyle: " format:@"Need to pass in user information。"];
    return nil;
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    [self.navigationController.navigationBar lt_setBackgroundColor:[UIColor clearColor]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // set backimage
    [self.navigationController.navigationBar lt_reset];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"top_background"] forBarMetrics:UIBarMetricsDefault];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setTitle:LMLocalizedString(@"Wallet Packet", nil)];
    [self tableViewConfigure];
    [self topAction];
    if (self.isFromHistory) {
        
        if (self.redLuckyInfo.redpackage.typ == 1 && !self.redLuckyInfo.redpackage.expired && self.redLuckyInfo.redpackage.remainSize != 0) {
            
            [self setNavigationRight:@"wallet_share_payment"];
            
        }
    } else {
        
        [self addCloseBarItem];
        
    }
}
#pragma mark - lazy loading

- (NSArray *)statusStrings {
    if (!_statusStrings) {
        
        _statusStrings = @[
                LMLocalizedString(@"Chat Waitting for open", nil),
                LMLocalizedString(@"Chat Bitcoin has been return to your wallet", nil),
                LMLocalizedString(@"Chat Lucky packet Overtime", nil),
                LMLocalizedString(@"Chat Lucky packet transfering to your wallet", nil),
                LMLocalizedString(@"Wallet Good luck next time",nil),
                LMLocalizedString(@"Wallet Lucky packet transferred to your wallet",nil)
        ];
        
    }
    return _statusStrings;
}
- (NSMutableArray *)dataArray {
    if (!_dataArray) {
        _dataArray = @[].mutableCopy;
    }
    return _dataArray;
}

#pragma mark - life cycle

- (AccountInfo *)openRedPackgeUserWithAddress:(NSString *)address {
    AccountInfo *findUser = nil;
    for (AccountInfo *user in self.groupMembers) {
        
        if ([user.address isEqualToString:address]) {
            
            findUser = user;
            break;
        }
    }
    
    return findUser;
}
- (void)doRight:(id)sender {
    NSString *title = [NSString stringWithFormat:@"%@ send lucky packet via Connect", [[LKUserCenter shareCenter] currentLoginUser].username];

    UIImage *avatar = [[YYImageCache sharedCache] getImageForKey:[[LKUserCenter shareCenter] currentLoginUser].avatar];
    if (!avatar) {
        avatar = [UIImage imageNamed:@"default_user_avatar"];
    }
    UIActivityViewController *activeViewController = [[UIActivityViewController alloc] initWithActivityItems:@[title, [NSURL URLWithString:self.redLuckyInfo.redpackage.URL], avatar] applicationActivities:nil];
    activeViewController.excludedActivityTypes = @[UIActivityTypeAirDrop, UIActivityTypeCopyToPasteboard, UIActivityTypeAddToReadingList];
    [self presentViewController:activeViewController animated:YES completion:nil];
    UIActivityViewControllerCompletionWithItemsHandler myblock = ^(NSString *__nullable activityType, BOOL completed, NSArray *__nullable returnedItems, NSError *__nullable activityError) {
        NSLog(@"%d %@", completed, activityType);
    };
    activeViewController.completionWithItemsHandler = myblock;
}

#pragma mark - methods

- (void)topAction {
    
    self.icon.contentMode = UIViewContentModeScaleAspectFit;
    self.icon.layer.borderWidth = 1.0;
    self.icon.layer.borderColor = [UIColor lightGrayColor].CGColor;

    if (self.redLuckyInfo.redpackage.system) {
        
        self.icon.image = [UIImage imageNamed:@"connect_logo"];
        self.nameLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Lucky packet from", nil), LMLocalizedString(@"Wallet Connect term", nil)];
        
    } else {
        
        [self.icon setPlaceholderImageWithAvatarUrl:_accountInfo.avatar];
         self.nameLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Lucky packet from", nil), _accountInfo.username];
    }

    if (GJCFStringIsNull(self.redLuckyInfo.redpackage.tips)) {
        
        self.descriptionLabel.text = LMLocalizedString(@"Wallet Best wishes", nil);
        
    } else {
        
        self.descriptionLabel.text = [NSString stringWithFormat:@"%@:%@", LMLocalizedString(@"Wallet Note", nil), self.redLuckyInfo.redpackage.tips];
    }
    if (!GJCFStringIsNull(self.moneyString)) {
        
        NSString *str = [NSString stringWithFormat:LMLocalizedString(@"%@BTC", nil), self.moneyString];
        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:str];
        [attrStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:FONT_SIZE(30)] range:[str rangeOfString:@"BTC"]];
        self.moneyValue.attributedText = attrStr;
        self.moneyValue.hidden = NO;
        
    } else {
        self.moneyValue.hidden = YES;
        [self.moneyValue mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(0);
        }];
    }
    
     [self packetStatusLable];
}

/* Whether to remove the navigationBar bottom black line*/
- (void)makeBlackLineInNavigationBarHidden:(BOOL)hidden {
    
    if ([self.navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) {

        NSArray *list = self.navigationController.navigationBar.subviews;
        for (id obj in list) {

            if ([obj isKindOfClass:[UIImageView class]]) {

                UIImageView *imageView = (UIImageView *) obj;
                imageView.hidden = hidden;
                
            }
        }
    }
}

- (void)tableViewConfigure {
    
    self.redLuckyListTableView.delegate = self;
    self.redLuckyListTableView.rowHeight = AUTO_HEIGHT(130);
    self.redLuckyListTableView.dataSource = self;
    self.redLuckyListTableView.backgroundColor = [UIColor colorWithHexString:@"EAEBEE"];
    self.redLuckyListTableView.tableFooterView = [UIView new];
    [self.redLuckyListTableView registerNib:[UINib nibWithNibName:@"LMRecLuckyDetailCell" bundle:nil] forCellReuseIdentifier:cellIdentifier];

}
/* packetStatusLable display*/
- (void)packetStatusLable {
    
    self.packetStatus = [self getPacketStatus];
    self.redLuckyStatusLabel.hidden = NO;
    
    switch (self.packetStatus) {
        case PacketStatusWaitOpen:
        {
            self.redLuckyStatusLabel.text = self.statusStrings[0];
            self.redLuckyStatusLabel.textColor = GJCFQuickHexColor(@"ff6c5a");
          
        }
            break;
        case PacketStatusOverTimeAndBack:
        {
            self.redLuckyStatusLabel.text = self.statusStrings[1];
            self.redLuckyStatusLabel.textColor = GJCFQuickHexColor(@"ff6c5a");
            
        }
            break;
        case PacketStatusOverTime:
        {
            self.redLuckyStatusLabel.text = self.statusStrings[2];
            self.redLuckyStatusLabel.textColor = GJCFQuickHexColor(@"ff6c5a");
        }
            break;
        case PacketStatusWaitArrivalYourWallet:
        {
            self.redLuckyStatusLabel.text = self.statusStrings[3];
            self.redLuckyStatusLabel.textColor = GJCFQuickHexColor(@"007aff");
        }
            break;
        case PacketStatusIsDone:
        {
            self.redLuckyStatusLabel.text = self.statusStrings[4];
            self.redLuckyStatusLabel.textColor = GJCFQuickHexColor(@"007aff");
        }
            break;
        case PacketStatusIsArrivalYourWallet:
        {
            self.redLuckyStatusLabel.text = self.statusStrings[5];
            self.redLuckyStatusLabel.textColor = GJCFQuickHexColor(@"007aff");
        }
            break;
        default:
            break;
    }
    
    if (self.redLuckyStatusLabel.hidden) {
        [self.redLuckyStatusLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(0);
        }];
    }

}
/* getStatus*/
- (NSUInteger)getPacketStatus {
   
    for (GradRedPackageHistroy *his in self.redLuckyInfo.gradHistoryArray) {
        if ([his.userinfo.address isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
            
            if (GJCFStringIsNull(self.redLuckyInfo.redpackage.txid)) {
                
                return PacketStatusWaitArrivalYourWallet;
                
            }else {
                
                return PacketStatusIsArrivalYourWallet;
            }
            break;
        }
    }
    
    if (self.redLuckyInfo.gradHistoryArray.count == self.redLuckyInfo.redpackage.size) {
        
        return PacketStatusIsDone;
        
    }else {
        if (self.redLuckyInfo.redpackage.expired) {
            
            BOOL loginUserisSender = [self.redLuckyInfo.redpackage.sendAddress isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address];
            
            if (loginUserisSender) {
                
                return PacketStatusOverTime;
                
            }else {
                
                return PacketStatusOverTimeAndBack;
                
            }
            
        }else {
            
            return PacketStatusWaitOpen;
        }
    }
}
#pragma mark - UItableview delegate && data source

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section != 0) {
        
        return 0.01f;
    }

    return 40.f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] init];

    UILabel *headerLabel = [[UILabel alloc] init];
    NSString *header = [NSString stringWithFormat:LMLocalizedString(@"Wallet Opened", nil), self.redLuckyInfo.redpackage.size - self.redLuckyInfo.redpackage.remainSize, self.redLuckyInfo.redpackage.size];
    [headerLabel setText:header];
    [headerLabel setTextColor:[UIColor colorWithHexString:@"767A82"]];
    [headerLabel setFont:[UIFont systemFontOfSize:12.f]];
    [headerView addSubview:headerLabel];

    [headerLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(headerView);
        make.edges.mas_offset(UIEdgeInsetsMake(11.f, 15.5f, 11.f, 15.5f));
    }];

    return headerView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    LMRecLuckyDetailCell *dCell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    LMRedLuckyDetailModel *model = self.dataArray[indexPath.row];
    [dCell.icon setPlaceholderImageWithAvatarUrl:model.iconURLString];
    [dCell.nameLabel setText:model.userName];
    [dCell.dateLabel setText:model.dateString];
    [dCell.moneyValueLabel setText:model.moneyString];
    dCell.winerTipView.hidden = !model.winer;
    return dCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (!GJCFStringIsNull(self.redLuckyInfo.redpackage.txid)) {
        
        NSString *url = [NSString stringWithFormat:@"%@%@", txDetailBaseUrl, self.redLuckyInfo.redpackage.txid];
        CommonClausePage *page = [[CommonClausePage alloc] initWithUrl:url];
        page.title = LMLocalizedString(@"Wallet Packet", nil);
        [self.navigationController pushViewController:page animated:YES];
    }
}

@end
