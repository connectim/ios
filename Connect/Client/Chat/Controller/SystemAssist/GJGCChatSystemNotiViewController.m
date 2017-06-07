//
//  GJGCSystemNotiViewController.m
//  ZYChat
//
//  Created by ZYVincent on 14-11-11.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import "GJGCChatSystemNotiViewController.h"
#import "CommonClausePage.h"
#import "WallteNetWorkTool.h"
#import "LMReciptNotesViewController.h"
#import "RedBagNetWorkTool.h"
#import "LMChatRedLuckyDetailController.h"
#import "NetWorkOperationTool.h"
#import "LMVerifyInGroupViewController.h"
#import "ApplyJoinToGroupCell.h"
#import "LMRedLuckyShowView.h"
#import "SystemTool.h"

@interface GJGCChatSystemNotiViewController () <GJGCChatBaseCellDelegate, LMRedLuckyShowViewDelegate>

@end

@implementation GJGCChatSystemNotiViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setStrNavTitle:self.dataSourceManager.title];
}

#pragma mark - 内部初始化

- (void)initDataManager {
    self.dataSourceManager = [[GJGCChatSystemNotiDataManager alloc] initWithTalk:self.taklInfo withDelegate:self];
}

#pragma mark - chatInputPanel Delegte

- (BOOL)chatInputPanelShouldShowMyFavoriteItem:(GJGCChatInputPanel *)panel {
    return NO;
}

- (void)transforCellDidTap:(GJGCChatBaseCell *)tapedCell {
    NSIndexPath *tapIndexPath = [self.chatListTable indexPathForCell:tapedCell];
    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:tapIndexPath.row];
    NSString *url = [NSString stringWithFormat:@"%@%@", txDetailBaseUrl, chatContentModel.hashID];
    CommonClausePage *page = [[CommonClausePage alloc] initWithUrl:url];
    page.title = LMLocalizedString(@"Wallet Transaction detail", nil);
    [self.navigationController pushViewController:page animated:YES];
}


- (void)chatCellDidTapDetail:(GJGCChatBaseCell *)tapedCell {
    NSIndexPath *tapIndexPath = [self.chatListTable indexPathForCell:tapedCell];
    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:tapIndexPath.row];
    if ([chatContentModel.typeString isEqualToString:@"redpackge"]) {
        [self showRedBagDetailWithHashId:chatContentModel.hashID];
    }
    if ([chatContentModel.typeString isEqualToString:@"addressnotify"]) {
        NSString *url = [NSString stringWithFormat:@"%@%@", txDetailBaseUrl, chatContentModel.hashID];
        CommonClausePage *page = [[CommonClausePage alloc] initWithUrl:url];
        page.title = LMLocalizedString(@"Wallet Transaction detail", nil);
        [self.navigationController pushViewController:page animated:YES];
    }
}

- (void)chatCellDidTapOnGroupReviewed:(GJGCChatBaseCell *)tappedCell {

    NSIndexPath *tapIndexPath = [self.chatListTable indexPathForCell:tappedCell];
    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:tapIndexPath.row];
    LMOtherModel *model = (LMOtherModel *) chatContentModel.contentModel;

    ApplyJoinToGroupCell *joinToGroupCell = (ApplyJoinToGroupCell *) tappedCell;
    if (!model.userIsinGroup) {
        chatContentModel.statusMessageString = [GJGCChatSystemNotiCellStyle formateCellStatusWithHandle:NO refused:NO isNoted:YES];
        [joinToGroupCell haveNoteThisMessage];
    }
    MMMessage *msg = [self.dataSourceManager messageByMessageId:chatContentModel.localMsgId];
    NSMutableDictionary *temDict = [msg.ext1 mutableCopy];
    if ([[temDict valueForKey:@"newaccept"] boolValue] == NO) {
        [temDict setObject:@(YES) forKey:@"newaccept"];
        msg.ext1 = temDict;
        ChatMessageInfo *messageInfo = [[MessageDBManager sharedManager] getMessageInfoByMessageid:msg.message_id messageOwer:self.taklInfo.chatIdendifier];
        messageInfo.message = msg;
        [[MessageDBManager sharedManager] updataMessage:messageInfo];
    }
    LMVerifyInGroupViewController *page = [[LMVerifyInGroupViewController alloc] init];
    page.model = model;

    if (!model.handled) {
        page.VerifyCallback = ^(BOOL refused) {
            chatContentModel.statusMessageString = [GJGCChatSystemNotiCellStyle formateCellStatusWithHandle:YES refused:refused isNoted:YES];
            model.handled = YES;
            [joinToGroupCell showStatusLabelWithResult:refused];
            MMMessage *msg = [self.dataSourceManager messageByMessageId:chatContentModel.localMsgId];
            NSMutableDictionary *temDict = [msg.ext1 mutableCopy];
            [temDict setObject:@(refused) forKey:@"refused"];
            msg.ext1 = temDict;
            ChatMessageInfo *messageInfo = [[MessageDBManager sharedManager] getMessageInfoByMessageid:msg.message_id messageOwer:self.taklInfo.chatIdendifier];
            messageInfo.message = msg;
            [[MessageDBManager sharedManager] updataMessage:messageInfo];
        };
    }
    [self.navigationController pushViewController:page animated:YES];
}

- (void)redBagCellDidTap:(GJGCChatBaseCell *)tappedCell {
    NSIndexPath *tapIndexPath = [self.chatListTable indexPathForCell:tappedCell];
    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:tapIndexPath.row];
    [self grabRedBagWithHashId:chatContentModel.hashID senderName:LMLocalizedString(@"Wallet Connect term", nil) sendAddress:nil];
}


- (void)grabRedBagWithHashId:(NSString *)hashId senderName:(NSString *)senderName sendAddress:(NSString *)sendAddress {
    [MBProgressHUD showLoadingMessageToView:self.view];
    [RedBagNetWorkTool grabSystemRedBagWithHashId:hashId complete:^(GrabRedPackageResp *response, NSError *error) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:self.view];
        }];
        if (error) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Network equest failed please try again later", nil) withType:ToastTypeFail showInView:self.view complete:nil];
            }];
        } else {
            switch (response.status) {
                case 0://failed
                {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"ErrorCode Error", nil) withType:ToastTypeFail showInView:self.view complete:nil];
                    }];
                }
                    break;
                case 1://success
                {
                    //create tips message
                    if (![senderName isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].normalShowName]) {
                        NSString *operation = [NSString stringWithFormat:@"%@/%@", self.taklInfo.chatUser.address, [[LKUserCenter shareCenter] currentLoginUser].address];

                        ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
                        chatMessage.messageId = [ConnectTool generateMessageId];
                        chatMessage.messageOwer = self.taklInfo.chatIdendifier;
                        chatMessage.messageType = GJGCChatFriendContentTypeStatusTip;
                        chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                        chatMessage.createTime = (NSInteger) ([[NSDate date] timeIntervalSince1970] * 1000);
                        MMMessage *message = [[MMMessage alloc] init];
                        message.type = GJGCChatFriendContentTypeStatusTip;
                        message.content = operation;
                        message.ext1 = @(2);
                        message.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
                        message.message_id = chatMessage.messageId;
                        message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                        chatMessage.message = message;
                        [[MessageDBManager sharedManager] saveMessage:chatMessage];
                        [self.dataSourceManager showGetRedBagMessageWithWithMessage:message];
                    }

                    LMRedLuckyShowView *redLuckyView = [[LMRedLuckyShowView alloc] initWithFrame:[UIScreen mainScreen].bounds redLuckyGifImages:nil];
                    redLuckyView.hashId = hashId;
                    [redLuckyView setDelegate:self];
                    [redLuckyView showRedLuckyViewIsGetARedLucky:YES];
                }
                    break;
                case 2: //have garbed
                {
                    [self getSystemRedBagDetailWithHashId:hashId];
                }
                    break;
                case 4: //luckypackage is complete
                case 3: {//failed
                    LMRedLuckyShowView *redLuckyView = [[LMRedLuckyShowView alloc] initWithFrame:[UIScreen mainScreen].bounds redLuckyGifImages:nil];
                    redLuckyView.hashId = hashId;
                    [redLuckyView setDelegate:self];
                    [redLuckyView showRedLuckyViewIsGetARedLucky:NO];
                }
                    break;
                case 5://User does not bind phone number
                {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Chat Your account is not bound to the phone", nil) withType:ToastTypeFail showInView:self.view complete:nil];
                    }];
                }
                    break;
                case 6://A phone number can only grab once
                {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Set A phone number can only grab once", nil) withType:ToastTypeFail showInView:self.view complete:nil];
                    }];
                }
                    break;
                case 7://system luckypackage have been frozen
                {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Chat system luckypackage have been frozen", nil) withType:ToastTypeFail showInView:self.view complete:nil];
                    }];
                }
                    break;
                case 8://one device can only grab a luckypackage
                {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Chat one device can only grab a luckypackage", nil) withType:ToastTypeFail showInView:self.view complete:nil];
                    }];
                }
                    break;
                default:
                    break;
            }
        }
    }];

}


#pragma mark - garb luckybackage delegate

- (void)redLuckyShowView:(LMRedLuckyShowView *)showView goRedLuckyDetailWithSender:(UIButton *)sender {
    [showView dismissRedLuckyView];
    [MBProgressHUD showLoadingMessageToView:self.view];
    [self getSystemRedBagDetailWithHashId:showView.hashId];
}

#pragma mark - cell tap

- (void)systemNotiBaseCellDidTapOnPublicMessage:(GJGCChatBaseCell *)tapedCell {
    NSIndexPath *tapIndexPath = [self.chatListTable indexPathForCell:tapedCell];
    GJGCChatSystemNotiModel *contentModel = (GJGCChatSystemNotiModel *) [self.dataSourceManager contentModelAtIndex:tapIndexPath.row];
    switch (contentModel.systemJumpType) {
        case 1: { //jumpType is 1 mean url
            if ([SystemTool isNationChannel]) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:nationalAppDownloadUrl]];
            } else {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appstoreAppDownloadUrl]];
            }
        }
            break;
        default: {
            if (GJCFStringIsNull(contentModel.systemJumpUrl)) {
                return;
            }
            CommonClausePage *page = [[CommonClausePage alloc] initWithUrl:contentModel.systemJumpUrl];
            page.title = contentModel.systemNotiTitle.string;
            [self.navigationController pushViewController:page animated:YES];
        }
            break;
    }
}

@end
