//
//  LMVerifyInGroupViewController.m
//  Connect
//
//  Created by bitmain on 2016/12/28.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import "LMVerifyInGroupViewController.h"
#import "LMGroupVerifyOtherTableViewCell.h"
#import "LMGroupFromTableViewCell.h"
#import "ConnectButton.h"
#import "UIImage+Color.h"
#import "NetWorkOperationTool.h"
#import "GroupDBManager.h"
#import "StringTool.h"
#import "IMService.h"
#import "GJGCChatFriendTalkModel.h"
#import "GJGCChatGroupViewController.h"
#import "LMVerifyTableHeadView.h"
#import "GroupDBManager.h"


typedef NS_ENUM(NSUInteger, CellType) {
    CellTypeOther = 0,
    CellTypeFrom = 1,
    CellTypeHandleResult = 2
};

@interface LMVerifyInGroupViewController () <UITableViewDelegate, UITableViewDataSource>

@property(strong, nonatomic) ConnectButton *acceptButton;
@property(strong, nonatomic) ConnectButton *refuseButton;
@property(strong, nonatomic) ConnectButton *enterButton;

@end

@implementation LMVerifyInGroupViewController

static NSString *cellOther_ID = @"LMGroupVerifyOtherTableViewCellID";
static NSString *cellFrom_ID = @"LMGroupFromTableViewCellID";

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = LMBasicBackgroudGray;
    self.title = LMLocalizedString(@"Wallet Detail", nil);
    [self.displayTbaleView registerNib:[UINib nibWithNibName:@"LMGroupVerifyOtherTableViewCell" bundle:nil] forCellReuseIdentifier:cellOther_ID];
    [self.displayTbaleView registerNib:[UINib nibWithNibName:@"LMGroupFromTableViewCell" bundle:nil] forCellReuseIdentifier:cellFrom_ID];
    self.displayTbaleView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    if (self.model.handled ||
        self.model.userIsinGroup) {
        [self creatEnterGroupButton];
    } else {
        [self creatButtonHandleButton];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 185;
    }
    return 0;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        UIView *sectionView = [self creatTableView];
        return sectionView;
    }
    return nil;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    DDLogInfo(@"%f", scrollView.contentOffset.y);
    if (scrollView.contentOffset.y >= -64) {
        [self.displayTbaleView setContentOffset:CGPointMake(0, -64)];
    }
}

- (UIView *)creatTableView {
    LMGroupInfo *groupInfo = [[GroupDBManager sharedManager] getgroupByGroupIdentifier:self.model.groupIdentifier];
    LMVerifyTableHeadView *headView = [[[NSBundle mainBundle] loadNibNamed:@"LMVerifyTableHeadView" owner:nil options:nil] lastObject];
    headView.frame = CGRectMake(0, 0, DEVICE_SIZE.width, 185);
    [headView.groupHeaderImageView setImageWithAvatarUrl:groupInfo.avatarUrl];
    headView.groupNameLable.text = groupInfo.groupName;
    headView.groupMemberLable.text = [NSString stringWithFormat:LMLocalizedString(@"Link Members", nil), groupInfo.groupMembers.count, 200];
    headView.groupSummaryLable.text = groupInfo.summary;
    return headView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section; {
    return self.model.handled ? 3 : 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    CellType type = indexPath.row;
    switch (type) {
        case CellTypeOther: {
            cell = [tableView dequeueReusableCellWithIdentifier:cellOther_ID];
            LMGroupVerifyOtherTableViewCell *groupOtherCell = (LMGroupVerifyOtherTableViewCell *) cell;
            if (groupOtherCell == nil) {
                groupOtherCell = [[[NSBundle mainBundle] loadNibNamed:@"LMGroupVerifyOtherTableViewCell" owner:nil options:nil] lastObject];
            }
            groupOtherCell.selectionStyle = UITableViewCellSelectionStyleNone;
            groupOtherCell.model = self.model;
            return groupOtherCell;

        }
            break;
        case CellTypeFrom: {
            cell = [tableView dequeueReusableCellWithIdentifier:cellFrom_ID];
            LMGroupFromTableViewCell *fromCell = (LMGroupFromTableViewCell *) cell;
            if (fromCell == nil) {
                fromCell = [[[NSBundle mainBundle] loadNibNamed:@"LMGroupFromTableViewCell" owner:nil options:nil] lastObject];
            }
            switch (self.model.sourceType) {
                case InviteSourceTypeQrcode:
                    fromCell.fromLable.text = LMLocalizedString(@"Link From QR Code", nil);
                    break;
                case InviteSourceTypeGroupInfoCard:
                    fromCell.fromLable.text = LMLocalizedString(@"Link From friends to share", nil);
                    break;
                case InviteSourceTypeToken:
                    fromCell.fromLable.text = LMLocalizedString(@"Link From group link", nil);
                    break;
                default:
                    break;
            }
            fromCell.selectionStyle = UITableViewCellSelectionStyleNone;
            return fromCell;

        }
            break;
        case CellTypeHandleResult: {
            cell = [tableView dequeueReusableCellWithIdentifier:cellFrom_ID];
            LMGroupFromTableViewCell *fromCell = (LMGroupFromTableViewCell *) cell;
            if (fromCell == nil) {
                fromCell = [[[NSBundle mainBundle] loadNibNamed:@"LMGroupFromTableViewCell" owner:nil options:nil] lastObject];
            }
            if (self.model.refused) {
                fromCell.fromLable.text = LMLocalizedString(@"Link application was refused", nil);
            } else {
                fromCell.fromLable.text = LMLocalizedString(@"Link Application has passed", nil);
            }
            fromCell.selectionStyle = UITableViewCellSelectionStyleNone;
            return fromCell;

        }
            break;
        default:
            break;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CellType type = indexPath.row;
    switch (type) {
        case CellTypeOther: {
            return AUTO_HEIGHT(190);
        }
        case CellTypeFrom:
        case CellTypeHandleResult: {
            return AUTO_HEIGHT(60);
        }
        default:
            break;
    }
    return 44;
}

- (void)creatEnterGroupButton {
    self.displayTbaleView.sectionFooterHeight = 200;
    UIView *footView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, DEVICE_SIZE.width, 200)];
    footView.backgroundColor = LMBasicBackgroudGray;
    self.displayTbaleView.tableFooterView = footView;

    
    BOOL enabled = [[GroupDBManager sharedManager] groupInfoExisitByGroupIdentifier:self.model.groupIdentifier];
    if (enabled) {
        self.enterButton = [[ConnectButton alloc] initWithNormalTitle:LMLocalizedString(@"Chat Group chat", nil) disableTitle:nil];
        self.enterButton.enabled = enabled;
        [self.enterButton addTarget:self action:@selector(entergroupAction) forControlEvents:UIControlEventTouchUpInside];
        [footView addSubview:self.enterButton];
        [self.enterButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(footView.mas_bottom).offset(-AUTO_HEIGHT(120));
            make.centerX.equalTo(self.view);
            make.height.mas_equalTo(AUTO_HEIGHT(100));
            make.width.mas_equalTo(DEVICE_SIZE.width - AUTO_HEIGHT(100));
        }];
        UIView *topLine = [[UIView alloc] init];
        topLine.backgroundColor = LMBasicMiddleGray;
        [footView addSubview:topLine];
        [topLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(footView.mas_top).offset(AUTO_HEIGHT(40));
            make.centerX.equalTo(self.view);
            make.height.mas_equalTo(AUTO_HEIGHT(1));
            make.width.mas_equalTo(DEVICE_SIZE.width);
        }];
    } else{
        self.acceptButton = [[ConnectButton alloc] initWithNormalTitle:LMLocalizedString(@"Chat You have left the group", nil) disableTitle:nil];
        self.acceptButton.enabled = NO;
        [self.acceptButton addTarget:self action:@selector(acceptAction:) forControlEvents:UIControlEventTouchUpInside];
        [footView addSubview:self.acceptButton];
        
        [self.acceptButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(footView.mas_top).offset(AUTO_HEIGHT (100));
            make.centerX.equalTo(self.view);
            make.height.mas_equalTo(self.acceptButton.height);
            make.width.mas_equalTo(self.acceptButton.width);
        }];
        UIView *topLine = [[UIView alloc] init];
        topLine.backgroundColor = LMBasicMiddleGray;
        [footView addSubview:topLine];
        [topLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(footView.mas_top).offset(AUTO_HEIGHT(40));
            make.centerX.equalTo(self.view);
            make.height.mas_equalTo(AUTO_HEIGHT(1));
            make.width.mas_equalTo(DEVICE_SIZE.width);
        }];
    }
}


- (void)creatButtonHandleButton {

    self.displayTbaleView.sectionFooterHeight = 300;
    UIView *footView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, DEVICE_SIZE.width, 300)];
    footView.backgroundColor = LMBasicBackgroudGray;
    self.displayTbaleView.tableFooterView = footView;
    BOOL enabled = [[GroupDBManager sharedManager] groupInfoExisitByGroupIdentifier:self.model.groupIdentifier];
    if (enabled) {
        self.acceptButton = [[ConnectButton alloc] initWithNormalTitle:LMLocalizedString(@"Link Accept", nil) disableTitle:nil];
        [self.acceptButton addTarget:self action:@selector(acceptAction:) forControlEvents:UIControlEventTouchUpInside];
        [footView addSubview:self.acceptButton];
        
        [self.acceptButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(footView.mas_top).offset(AUTO_HEIGHT (100));
            make.centerX.equalTo(self.view);
            make.height.mas_equalTo(self.acceptButton.height);
            make.width.mas_equalTo(self.acceptButton.width);
        }];
        
        self.refuseButton = [[ConnectButton alloc] initWithNormalTitle:LMLocalizedString(@"Link Refuse", nil) disableTitle:nil];
        [self.refuseButton addTarget:self action:@selector(refuseAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.refuseButton setBackgroundImage:[UIImage imageWithColor:[UIColor whiteColor]] forState:UIControlStateNormal];
        [self.refuseButton setTitleColor:LMBasicRed forState:UIControlStateNormal];
        [footView addSubview:self.refuseButton];
        
        [self.refuseButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.acceptButton.mas_bottom).offset(AUTO_HEIGHT(45));
            make.centerX.equalTo(self.view);
            make.height.mas_equalTo(self.refuseButton.height);
            make.width.mas_equalTo(self.refuseButton.width);
        }];
        UIView *topLine = [[UIView alloc] init];
        topLine.backgroundColor = LMBasicMiddleGray;
        [footView addSubview:topLine];
        [topLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(footView.mas_top).offset(AUTO_HEIGHT(40));
            make.centerX.equalTo(self.view);
            make.height.mas_equalTo(AUTO_HEIGHT(1));
            make.width.mas_equalTo(DEVICE_SIZE.width);
        }];
    } else{
        self.acceptButton = [[ConnectButton alloc] initWithNormalTitle:LMLocalizedString(@"Chat You have left the group", nil) disableTitle:nil];
        self.acceptButton.enabled = NO;
        [self.acceptButton addTarget:self action:@selector(acceptAction:) forControlEvents:UIControlEventTouchUpInside];
        [footView addSubview:self.acceptButton];
        
        [self.acceptButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(footView.mas_top).offset(AUTO_HEIGHT (100));
            make.centerX.equalTo(self.view);
            make.height.mas_equalTo(self.acceptButton.height);
            make.width.mas_equalTo(self.acceptButton.width);
        }];
        UIView *topLine = [[UIView alloc] init];
        topLine.backgroundColor = LMBasicMiddleGray;
        [footView addSubview:topLine];
        [topLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(footView.mas_top).offset(AUTO_HEIGHT(40));
            make.centerX.equalTo(self.view);
            make.height.mas_equalTo(AUTO_HEIGHT(1));
            make.width.mas_equalTo(DEVICE_SIZE.width);
        }];
    }
}

#pragma mark - buuton action

- (void)acceptAction:(id)sender {

    GroupReviewed *reviewed = [GroupReviewed new];
    reviewed.identifier = self.model.groupIdentifier;
    reviewed.verificationCode = self.model.verificationCode;
    reviewed.address = [KeyHandle getAddressByPubkey:self.model.publickey];

    CreateGroupMessage *createGroup = [CreateGroupMessage new];
    createGroup.identifier = reviewed.identifier;
    createGroup.secretKey = [[GroupDBManager sharedManager] getGroupEcdhKeyByGroupIdentifier:self.model.groupIdentifier];
    
    GcmData *groupInfoGcmData = [ConnectTool createGcmWithData:createGroup.data publickey:self.model.publickey needEmptySalt:YES];

    NSString *backUp = [NSString stringWithFormat:@"%@/%@", [[LKUserCenter shareCenter] currentLoginUser].pub_key, [StringTool hexStringFromData:groupInfoGcmData.data]];
    reviewed.backup = backUp;

    
    NSString *messageID = [ConnectTool generateMessageId];
    MessageData *messageData = [[MessageData alloc] init];
    messageData.cipherData = groupInfoGcmData;
    messageData.receiverAddress = [KeyHandle getAddressByPubkey:self.model.publickey];
    messageData.msgId = messageID;
    NSString *sign = [ConnectTool signWithData:messageData.data];
    MessagePost *messagePost = [[MessagePost alloc] init];
    messagePost.sign = sign;
    messagePost.pubKey = [[LKUserCenter shareCenter] currentLoginUser].pub_key;
    messagePost.msgData = messageData;
    [[IMService instance] asyncSendGroupInfo:messagePost];

    [MBProgressHUD showLoadingMessageToView:self.view];

    [NetWorkOperationTool POSTWithUrlString:GroupReviewewUrl postProtoData:reviewed.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *) response;
        
        switch (hResponse.code) {
                case 2432: //Not Group Master
            {
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Chat Not Group Master", nil) withType:ToastTypeFail showInView:self.view complete:nil];
            }
                break;
                case 2433: //already in group
            {
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Chat User already in group", nil) withType:ToastTypeFail showInView:self.view complete:nil];
            }
                break;
                case 2434: //VerifyCode not match
            {
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Chat VerifyCode has expired", nil) withType:ToastTypeFail showInView:self.view complete:nil];
            }
                break;
            case successCode:
            {
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Successful", nil) withType:ToastTypeSuccess showInView:self.view complete:^{
                    [self.navigationController popViewControllerAnimated:YES];
                }];
                if (self.VerifyCallback) {
                    self.VerifyCallback(NO);
                }
            }
                break;
            default:
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:self.view complete:nil];
                break;
        }
    }                                  fail:^(NSError *error) {
        [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:self.view complete:nil];
    }];

}

- (void)refuseAction:(id)sender {
    GroupReviewed *reviewed = [GroupReviewed new];
    reviewed.identifier = self.model.groupIdentifier;
    reviewed.verificationCode = self.model.verificationCode;
    reviewed.address = [KeyHandle getAddressByPubkey:self.model.publickey];

    [MBProgressHUD showLoadingMessageToView:self.view];
    [NetWorkOperationTool POSTWithUrlString:GroupRejectUrl postProtoData:reviewed.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *) response;
        switch (hResponse.code) {
                case 2432: //Not Group Master
            {
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Chat Not Group Master", nil) withType:ToastTypeFail showInView:self.view complete:nil];
            }
                break;
                case 2433: //already in group
            {
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Chat User already in group", nil) withType:ToastTypeFail showInView:self.view complete:nil];
            }
                break;
                case 2434: //VerifyCode not match
            {
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Chat VerifyCode has expired", nil) withType:ToastTypeFail showInView:self.view complete:nil];
            }
                break;
                case successCode:
            {
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Successful", nil) withType:ToastTypeSuccess showInView:self.view complete:^{
                    [self.navigationController popViewControllerAnimated:YES];
                }];
                if (self.VerifyCallback) {
                    self.VerifyCallback(YES);
                }
            }
                break;
            default:
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:self.view complete:nil];
                break;
        }

    }                                  fail:^(NSError *error) {
        [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:self.view complete:nil];
    }];
}

- (void)entergroupAction {
    
    UINavigationController *nav = self.navigationController;
    NSMutableArray *controllers = [NSMutableArray arrayWithArray:nav.viewControllers];
    if (controllers.count > 1) {
        [controllers removeObjectsInRange:NSMakeRange(1, controllers.count - 1)];
    }
    nav.viewControllers = controllers;
    
    LMGroupInfo *group = [[GroupDBManager sharedManager] getgroupByGroupIdentifier:self.model.groupIdentifier];
    GJGCChatFriendTalkModel *talk = [[GJGCChatFriendTalkModel alloc] init];
    talk.talkType = GJGCChatFriendTalkTypeGroup;
    talk.chatIdendifier = group.groupIdentifer;
    talk.group_ecdhKey = group.groupEcdhKey;
    talk.chatGroupInfo = group;
    
    [SessionManager sharedManager].chatSession = talk.chatIdendifier;
    [SessionManager sharedManager].chatObject = group;
    talk.name = GJCFStringIsNull(group.groupName) ? [NSString stringWithFormat:LMLocalizedString(@"Group chat(%lu)", nil), (unsigned long) talk.chatGroupInfo.groupMembers.count] : [NSString stringWithFormat:@"%@(%lu)", group.groupName, (unsigned long) talk.chatGroupInfo.groupMembers.count];
    GJGCChatGroupViewController *groupChat = [[GJGCChatGroupViewController alloc] initWithTalkInfo:talk];
    groupChat.hidesBottomBarWhenPushed = YES;
    [nav pushViewController:groupChat animated:YES];

}

- (void)dealloc {
    [self.displayTbaleView removeFromSuperview];
    self.displayTbaleView = nil;
}


@end
