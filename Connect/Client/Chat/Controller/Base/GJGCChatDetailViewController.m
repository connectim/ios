//
//  GJGCChatDetailViewController.m
//  ZYChat
//
//  Created by KivenLin on 14-10-17.
//  Copyright (c) 2014年 ConnectSoft. All rights reserved.
//

#import "GJGCChatDetailViewController.h"
#import "GJGCChatFriendBaseCell.h"
#import "InviteUserPage.h"
#import "LMMessageExtendManager.h"
#import "RecentChatDBManager.h"
#import "IMService.h"

@interface GJGCChatDetailViewController () <
        GJGCRefreshHeaderViewDelegate,
        UIGestureRecognizerDelegate
        >
@property(nonatomic, assign) BOOL isScrolledToBottom;
@property(nonatomic, assign) CGFloat inputBarHeight;

@property (nonatomic ,assign) CGFloat statusOffset;

@end

@implementation GJGCChatDetailViewController

- (instancetype)initWithTalkInfo:(GJGCChatFriendTalkModel *)talkModel {
    if (self = [super init]) {

        _taklInfo = talkModel;
        self.inputBarHeight = AUTO_HEIGHT(100);

        [self initDataManager];
        CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
        self.statusOffset = (statusBarHeight == 20?0:-20);
    }
    return self;
}

- (void)initDataManager {

}

- (void)dealloc {

    [self.chatListTable removeObserver:self forKeyPath:@"panGestureRecognizer.state"];

    [self.refreshFootView setDelegate:nil];
    [self.refreshHeadView setDelegate:nil];
    [self.dataSourceManager setDelegate:nil];
    self.chatListTable.dataSource = nil;
    self.chatListTable.delegate = nil;

    [UIDevice currentDevice].proximityMonitoringEnabled = NO;

    [self.dataSourceManager setDelegate:nil];
    [GJCFNotificationCenter removeObserver:self];
    [[GJCFFileDownloadManager shareDownloadManager] clearTaskBlockForObserver:self];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.willDisappear) {
        if (self.isKeyboardShowing) {
            [self.inputPanel becomeFirstResponse];
        }
        self.willDisappear = NO;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (![self.navigationController.childViewControllers containsObject:self]) {
        [SessionManager sharedManager].chatSession = nil;
        [SessionManager sharedManager].chatObject = nil;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.isKeyboardShowing = [self.inputPanel isInputTextFirstResponse];
    [self.dataSourceManager viewControllerWillDisMissToCheckSendingMessageSaveSendStateFail];
    [self clearAllFirstResponse];
    if (![self.navigationController.childViewControllers containsObject:self]) {
        self.willDisappear = YES;
        //stop tableview scroll
        [self.chatListTable setContentOffset:self.chatListTable.contentOffset animated:NO];
        if (!textField && [self.inputPanel isInputTextFirstResponse]) {
            textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
            [self.view addSubview:textField];
            textField.hidden = YES;
            [textField becomeFirstResponder];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.titleView = [[ChatPageTitleView alloc] init];
    self.navigationItem.titleView = self.titleView;
    self.titleView.title = self.taklInfo.name;
    if (self.taklInfo.snapChatOutDataTime > 0) {
        self.titleView.chatStyle = ChatPageTitleViewStyleSnapChat;
    }
    [self initSubViews];

    self.view.backgroundColor = [GJGCChatInputPanelStyle mainBackgroundColor];

    [self configFileDownloadManager];

    //add notification
    RegisterNotify(@"im.connect.DeleteMessageHistoryNotification", @selector(deleteMessageHistory));
    RegisterNotify(kAcceptNewFriendRequestNotification, @selector(friendAccept:))
    RegisterNotify(@"RereweetMessageNotification", @selector(retweetMessage:));
    [self observeApplicationState];
    RegisterNotify(TransactionStatusChangeNotification, @selector(transactionStatusChange:));
    RegisterNotify(GroupAdminChangeNotification, @selector(groupAdmingChange));
    RegisterNotify(@"deleteGroupReviewedMessageNotification", @selector(deleteReviewMessage:));
    RegisterNotify(ConnnectGroupDismissNotification, @selector(groupdissmiss:));
    
    RegisterNotify(UIApplicationDidChangeStatusBarFrameNotification, @selector(statusBarFrameChange:));
}

- (void)statusBarFrameChange:(NSNotification *)note{
    [self.view endEditing:YES];
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    self.statusOffset = (statusBarHeight == 20?0:-20);

    //reset frame
    self.chatListTable.frame = (CGRect) {0, 0, GJCFSystemScreenWidth, GJCFSystemScreenHeight - self.inputBarHeight + self.statusOffset};
    self.inputPanel.frame = (CGRect) {0, GJCFSystemScreenHeight - self.inputPanel.inputBarHeight + self.statusOffset, GJCFSystemScreenWidth, self.inputBarHeight + kMeunBarHeight};
    
    [self scrollToBottom:YES];
}

- (void)groupdissmiss:(NSNotification *)note{
    if ([note.object isEqualToString:self.taklInfo.chatIdendifier]) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)deleteReviewMessage:(NSNotification *)note{
    NSString *messageid = note.object;
    [self.dataSourceManager removeChatContentModelAtIndex:[self.dataSourceManager getContentModelIndexByLocalMsgId:messageid]];
    [self.chatListTable reloadData];
}
    
- (void)groupAdmingChange {
    AccountInfo *currentAdmin = [[GroupDBManager sharedManager] getAdminByGroupId:self.taklInfo.chatGroupInfo.groupIdentifer];
    if (currentAdmin) {
        self.taklInfo.chatGroupInfo.admin = currentAdmin;
    }
}

- (void)retweetMessage:(NSNotification *)note {
    ChatMessageInfo *chatMessage = note.object;
    if (![chatMessage.messageOwer isEqualToString:self.taklInfo.chatIdendifier]) {
        return;
    }
    GJGCChatFriendContentModel *contentModel = [self.dataSourceManager addMMMessage:chatMessage];
    contentModel.sendStatus = GJGCChatFriendSendMessageStatusSuccess;
    [self.chatListTable reloadData];
}

#pragma mark - transaction status change note

- (void)transactionStatusChange:(NSNotification *)note {
    NSString *txId = [note.object valueForKey:@"hashId"];
    if (GJCFStringIsNull(txId)) {
        return;
    }
    NoticeMessage *notice = [note.object valueForKey:@"notice"];
    
    NSString* chatIdentifier = [note.object valueForKey:@"identifier"];
    NSString* messageId = [[LMMessageExtendManager sharedManager] getMessageId:txId];
    int status = [[LMMessageExtendManager sharedManager] getStatus:txId];
    if ([chatIdentifier isEqualToString:self.taklInfo.chatIdendifier]) {
        GJGCChatFriendContentModel *chatModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelByMsgId:messageId];
        switch (notice.category) {
            case 1://Confrime
            {
                chatModel.transferStatusMessage = [GJGCChatSystemNotiCellStyle formateRecieptSubTipsWithTotal:chatModel.memberCount payCount:0 isCrowding:NO transStatus:status];
                [GCDQueue executeInMainQueue:^{
                    [self.chatListTable reloadData];
                }];
            }
                break;
            case 2://TransactionTypeRedBag
            {
                ChatMessageInfo *chatMessage = [note.object valueForKey:@"chatMessage"];
                [self.dataSourceManager showGetRedBagMessageWithWithMessage:chatMessage.message];
            }
                break;
            case 3:
            case 5://TransactionTypeReceipt
            {
                [GCDQueue executeInGlobalQueue:^{
                    ChatMessageInfo *chatMessage = [note.object valueForKey:@"chatMessage"];
                    chatMessage.message.content = [GJGCChatSystemNotiCellStyle formateReceiptTipWithPayName:self.taklInfo.chatUser.normalShowName receiptName:chatModel.senderName isCrowding:NO].string;
                    [[MessageDBManager sharedManager] updataMessage:chatMessage];
                }];
                chatModel.payOrReceiptStatusMessage = [GJGCChatSystemNotiCellStyle formateRecieptSubTipsWithTotal:chatModel.memberCount payCount:0 isCrowding:NO transStatus:status];
                [self.dataSourceManager showReceiptMessageMessageWithPayName:self.taklInfo.chatUser.normalShowName receiptName:chatModel.senderName isCrowd:NO];
            }
                break;
            case 6://crowding pay note
            {
                ChatMessageInfo *chatMessage = [note.object valueForKey:@"chatMessage"];
                NSString *operation = chatMessage.message.content;
                NSArray *temA = [operation componentsSeparatedByString:@"/"];
                Crowdfunding *crowdInfo = [note.object valueForKey:@"crowdfunding"];
                if (temA.count == 2) {
                    int payCount = (int) (crowdInfo.size - crowdInfo.remainSize);
                    if (crowdInfo.status) { //crowding complete
                        payCount = (int)crowdInfo.size;
                    }
                    chatModel.payOrReceiptStatusMessage = [GJGCChatSystemNotiCellStyle formateRecieptSubTipsWithTotal:chatModel.memberCount payCount:payCount isCrowding:YES transStatus:status];
                    NSString *senderAddress = [temA firstObject];
                    NSString *payAddress = [temA lastObject];
                    NSString *payName = nil;
                    NSString *senderName = nil;
                    switch (self.taklInfo.talkType) {
                        case GJGCChatFriendTalkTypeGroup:
                        {
                            if ([senderAddress isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                                senderName = [LKUserCenter shareCenter].currentLoginUser.normalShowName;
                                for (AccountInfo *groupMember in self.taklInfo.chatGroupInfo.groupMembers) {
                                    if ([groupMember.address isEqualToString:payAddress]) {
                                        payName = groupMember.normalShowName;
                                        break;
                                    }
                                }
                            } else if ([payAddress isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                                payName = [LKUserCenter shareCenter].currentLoginUser.normalShowName;
                                for (AccountInfo *groupMember in self.taklInfo.chatGroupInfo.groupMembers) {
                                    if ([groupMember.address isEqualToString:senderAddress]) {
                                        senderName = groupMember.normalShowName;
                                        break;
                                    }
                                }
                            }
                        }
                            break;
                        case GJGCChatFriendTalkTypePrivate:
                        {
                            if ([senderAddress isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                                senderName = [LKUserCenter shareCenter].currentLoginUser.normalShowName;
                                payName = self.taklInfo.chatUser.normalShowName;
                            } else if ([payAddress isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                                payName = [LKUserCenter shareCenter].currentLoginUser.normalShowName;
                                senderName = self.taklInfo.chatUser.normalShowName;
                            }
                        }
                            break;
                        default:
                            break;
                    }
                    chatMessage.message.content = [GJGCChatSystemNotiCellStyle formateReceiptTipWithPayName:payName receiptName:chatModel.senderName isCrowding:YES].string;
                    [[MessageDBManager sharedManager] updataMessage:chatMessage];
                    [GCDQueue executeInMainQueue:^{
                        [self.chatListTable reloadData];
                        [self.dataSourceManager showReceiptMessageMessageWithPayName:payName receiptName:chatModel.senderName isCrowd:YES];
                        if (crowdInfo.status) {
                            [self.dataSourceManager showCrowdingCompleteMessage];
                        }
                    }];
                }
            }
                break;
            default:
                break;
        }
    }
}

- (void)friendAccept:(NSNotification *)note {
    AccountInfo *user = note.object;

    if ([user.address isEqualToString:self.taklInfo.chatUser.address]) {
        self.chatListTable.frame = (CGRect) {0, 64, GJCFSystemScreenWidth, GJCFSystemScreenHeight - self.inputBarHeight - 64};
        [self.view setNeedsLayout];
    }

}

- (void)deleteMessageHistory {
    [self.dataSourceManager.chatListArray removeAllObjects];
    self.dataSourceManager.lastSendMsgTime = 0;
    [self.chatListTable reloadData];
}

- (void)rightButtonPressed:(UIButton *)sender {

}

- (void)clearAllFirstResponse {
    [self cancelMenuVisiableCellFirstResponse];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - init

- (NSMutableArray *)downLoadingRichMessageIds {
    if (!_downLoadingRichMessageIds) {
        _downLoadingRichMessageIds = [NSMutableArray array];
    }

    return _downLoadingRichMessageIds;
}

- (void)initSubViews {
    self.automaticallyAdjustsScrollViewInsets = NO;
    __weak __typeof(&*self) weakSelf = self;

    self.chatListTable = [[UITableView alloc] init];
    self.chatListTable.dataSource = self;
    self.chatListTable.delegate = self;
    self.chatListTable.backgroundColor = [GJGCChatInputPanelStyle mainBackgroundColor];
    self.chatListTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:self.chatListTable];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapTableView)];
    [self.chatListTable addGestureRecognizer:tap];
    tap.delegate = self;
    self.chatListTable.frame = (CGRect) {0, 0, GJCFSystemScreenWidth, GJCFSystemScreenHeight - self.inputBarHeight + self.statusOffset};
    self.chatListTable.contentInset = UIEdgeInsetsMake(64 , 0, 0, 0);
    /* scroll to bottom */
    if (self.dataSourceManager.totalCount > 0) {
        [self.chatListTable reloadData];
        [self.chatListTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.dataSourceManager.totalCount - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    }
    
    self.inputPanel = [[GJGCChatInputPanel alloc] initWithPanelDelegate:self];
    self.inputPanel.frame = (CGRect) {0, GJCFSystemScreenHeight - self.inputPanel.inputBarHeight + self.statusOffset, GJCFSystemScreenWidth, self.inputBarHeight + kMeunBarHeight};

    [self.inputPanel configInputPanelKeyboardFrameChange:^(GJGCChatInputPanel *panel, CGRect keyboardBeginFrame, CGRect keyboardEndFrame, NSTimeInterval duration, BOOL isPanelReserve) {
        if (panel.hidden || weakSelf.willDisappear) {
            return;
        }
        [UIView animateWithDuration:duration animations:^{
            if (keyboardEndFrame.origin.y == GJCFSystemScreenHeight) { //hiden keyboard
                [weakSelf changeFrameAndPositionWhenKeyBoardHidenIsShowInputMeunPanel:isPanelReserve];
            } else {
                if (keyboardEndFrame.size.height > kMeunBarHeight) {
                    panel.bottom = GJCFSystemScreenHeight - keyboardEndFrame.size.height + kMeunBarHeight + self.statusOffset;
                    weakSelf.chatListTable.height = panel.top;
                }
                [weakSelf scrollToBottom:YES];
            }
        }];

    }];

    [self.inputPanel configInputPanelRecordStateChange:^(GJGCChatInputPanel *panel, BOOL isRecording) {
        if (isRecording) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf stopPlayCurrentAudio];
                weakSelf.chatListTable.userInteractionEnabled = NO;
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.chatListTable.userInteractionEnabled = YES;
            });
        }
    }];

    [self.inputPanel configInputPanelInputTextViewHeightChangedBlock:^(GJGCChatInputPanel *panel, CGFloat changeDelta) {
        panel.top = panel.top - changeDelta;
        panel.height = panel.height + changeDelta;
        weakSelf.chatListTable.height -= changeDelta;
        [weakSelf scrollToBottom:YES];
    }];

    /* input bar action change */
    [self.inputPanel setActionChangeBlock:^(GJGCChatInputBar *inputBar, GJGCChatInputBarActionType toActionType) {
        [weakSelf inputBar:inputBar changeToAction:toActionType];
    }];
    [self.view addSubview:self.inputPanel];

    //set draft
    [self.inputPanel setLastMessageDraft:[[RecentChatDBManager sharedManager] getDraftWithIdentifier:self.taklInfo.chatIdendifier]];
    
    
    self.refreshHeadView = [[GJGCRefreshHeaderView alloc] init];
    self.refreshHeadView.delegate = self;
    [self.refreshHeadView setupChatFooterStyle];
    [self.chatListTable addSubview:self.refreshHeadView];

    /* load history data */
    [self addOrRemoveLoadMore];

    [self.chatListTable addObserver:self forKeyPath:@"panGestureRecognizer.state" options:NSKeyValueObservingOptionNew context:nil];
    
    
    NSString *textChangeNoti = [GJGCChatInputConst panelNoti:GJGCChatInputTextViewContentShouldChangeNoti formateWithIdentifier:self.inputPanel.panelIndentifier];
    RegisterNotify(textChangeNoti, @selector(inputTextChange:));
    
}

- (void)inputTextChange:(NSNotification *)note{
    NSString *text = note.object;
    [self inputTextChangeWithText:text];
}

- (void)inputTextChangeWithText:(NSString *)text{
    
}

- (void)tapTableView {
    /*
    //test
    Message *msg = [Message new];
    NoticeMessage *notice = [NoticeMessage new];
    notice.category = 5;
    BillNotice *bill = [BillNotice new];
    bill.hashId = @"870e05c48533406826a52961b4669080f1d5c13a";
    bill.sender = @"1LLGSy4qbioMWhbvRByKyxMB9qmPmQMq9K";
    bill.receiver = @"18cvaXyo1LtNd9mgrxKeA5i1PRPHBMDBwJ";
    bill.status = 2;
    notice.body = bill.data;
    
    
    TransactionNotice *tran = [TransactionNotice new];
    tran.hashId = @"36ffb35971b4ceef93c54d5ce031be667624de65";
    tran.status = 1;
    tran.identifer = self.taklInfo.chatUser.address;
    notice.body = tran.data;
    notice.category = 1;
    msg.body = notice;
    [[IMService instance] transactionStatusChangeNoti:msg];
    //test
     */
    [self cancelMenuVisiableCellFirstResponse];
    __weak __typeof(&*self) weakSelf = self;
    if ([self.inputPanel isInputTextFirstResponse]) {
        [self.inputPanel inputBarRegsionFirstResponse];
    }
    if (self.inputPanel.isFullState) {
        [UIView animateWithDuration:0.3 animations:^{
            weakSelf.inputPanel.top = GJCFSystemScreenHeight - (weakSelf.inputPanel.height - kMeunBarHeight);
            weakSelf.chatListTable.height = weakSelf.inputPanel.top;
        }];
        [weakSelf.inputPanel reserveState];
    }
}

#pragma mark -inputbar change

- (void)changeFrameAndPositionWhenKeyBoardHidenIsShowInputMeunPanel:(BOOL)isPanelReserve {
    CGFloat barShowHeight = 0;
    if (isPanelReserve) {
        barShowHeight = self.inputPanel.height - kMeunBarHeight;
    } else {
        barShowHeight = self.inputPanel.height;
    }
    self.inputPanel.top = GJCFSystemScreenHeight - barShowHeight + self.statusOffset;
    self.chatListTable.height = self.inputPanel.top;
    [self scrollToBottom:YES];
}

#pragma mark - kvo

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    UIGestureRecognizerState state = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
    switch (state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged: {
            [self makeVisiableGifCellPause];
        }
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            [self makeVisiableGifCellResume];
        }
            break;
        default:
            break;
    }
}

#pragma mark - inputbar action change

- (void)inputBar:(GJGCChatInputBar *)inputBar changeToAction:(GJGCChatInputBarActionType)actionType {
    switch (actionType) {
        case GJGCChatInputBarActionTypeChooseEmoji:
        case GJGCChatInputBarActionTypeExpandPanel: {
            if (!self.inputPanel.isFullState) {
                [UIView animateWithDuration:0.3 animations:^{
                    self.inputPanel.top = GJCFSystemScreenHeight - self.inputPanel.height;
                    self.chatListTable.height = self.inputPanel.top;
                }];
                self.inputPanel.isFullState = YES;
                [self scrollToBottom:YES];
            }
        }
            break;

        default:
            break;
    }
}

#pragma mark - load more

- (void)addOrRemoveLoadMore {
    if (!self.dataSourceManager.isFinishFirstHistoryLoad) {
        if (!self.refreshFootView) {
            self.refreshFootView = [[GJGCRefreshFooterView alloc] init];
            [self.refreshFootView setupChatFooterStyle];
            self.refreshFootView.backgroundColor = [UIColor redColor];
            [self.chatListTable addSubview:self.refreshFootView];
        }
        [self.refreshFootView resetFrameWithTableView:self.chatListTable];
    } else{
        [self stopLoadMore];
        if (self.refreshFootView) {
            [self.refreshFootView removeFromSuperview];
            self.refreshFootView = nil;
        }
    }

}

- (void)reloadData {
    [self cancelMenuVisiableCellFirstResponse];

    [self.chatListTable reloadData];
    [self stopRefresh];
    [self stopLoadMore];
    [self addOrRemoveLoadMore];

}

- (void)reloadDataStopRefreshNoAnimated {
    [self cancelMenuVisiableCellFirstResponse];

    [self.chatListTable reloadData];
    [self stopRefreshNoAnimated];
    [self stopLoadMore];
    [self addOrRemoveLoadMore];

}

#pragma mark -RefreshHeaderViewDelegate

- (void)refreshHeaderViewTriggerRefresh:(GJGCRefreshHeaderView *)headerView {

    self.dataSourceManager.isLoadingMore = YES;

    [self triggleRefreshing];
}

- (void)stopRefresh {
    if (self.refreshHeadView) {
        [self.refreshHeadView stopLoadingForScrollView:self.chatListTable];
    }
}

- (void)stopRefreshNoAnimated {
    if (self.refreshHeadView) {
        [self.refreshHeadView stopLoadingForScrollView:self.chatListTable isAnimation:NO];
    }
}

- (void)stopLoadMore {
    if (self.refreshFootView) {
        [self.refreshFootView stopLoadingForScrollView:self.chatListTable];
    }
}

- (void)startRefresh {
    if (self.refreshHeadView) {
        [self.refreshHeadView startLoadingForScrollView:self.chatListTable];
    }
}

- (void)startLoadMore {
    [self addOrRemoveLoadMore];
    [self.refreshFootView resetFrameWithTableView:self.chatListTable];
    [self.refreshFootView startLoadingForScrollView:self.chatListTable];
}

- (void)stopPlayAudio {

}

- (void)triggleRefreshing {
    [self.dataSourceManager trigglePullHistoryMsgForEarly];
}

- (void)triggleLoadingMore {

}

- (void)stopPlayCurrentAudio {

}

#pragma mark - stop gif

- (void)makeVisiableGifCellPause {
    [self.chatListTable.visibleCells makeObjectsPerformSelector:@selector(pause)];
}

- (void)makeVisiableGifCellResume {
    [self.chatListTable.visibleCells makeObjectsPerformSelector:@selector(resume)];

}

#pragma mark - cancel cell FirstResponse

- (void)cancelMenuVisiableCellFirstResponse {
    UIMenuController *shareMenuViewController = [UIMenuController sharedMenuController];
    if (shareMenuViewController.isMenuVisible) {
        [shareMenuViewController setMenuVisible:NO animated:YES];
    }
}

#pragma mark -recover input panel state

- (void)reserveChatInputPanelState {
    if (self.inputPanel.isFullState) {
        self.inputPanel.top = GJCFSystemScreenHeight - (self.inputPanel.height - kMeunBarHeight);
        self.chatListTable.height = self.inputPanel.top;
        [self scrollToBottom:YES];
        [self.inputPanel reserveState];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self cancelMenuVisiableCellFirstResponse];
    __weak __typeof(&*self) weakSelf = self;
    if ([self.inputPanel isInputTextFirstResponse]) {
        [self.inputPanel inputBarRegsionFirstResponse];
    }

    if (self.inputPanel.isFullState) {
        [UIView animateWithDuration:0.3 animations:^{
            weakSelf.inputPanel.top = GJCFSystemScreenHeight - (weakSelf.inputPanel.height - kMeunBarHeight);
            weakSelf.chatListTable.height = weakSelf.inputPanel.top;
        }];
        [weakSelf.inputPanel reserveState];
    }

    if (self.dataSourceManager.isFinishFirstHistoryLoad) {

        if (self.dataSourceManager.isFinishLoadAllHistoryMsg == NO) {

            [self.refreshHeadView scrollViewWillBeginDragging:scrollView];

        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

    if (self.dataSourceManager.isFinishFirstHistoryLoad) {

        if (self.dataSourceManager.isFinishLoadAllHistoryMsg == NO) {

            [self.refreshHeadView scrollViewDidScroll:scrollView];
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (self.dataSourceManager.isFinishFirstHistoryLoad) {

        if (self.dataSourceManager.isFinishLoadAllHistoryMsg == NO) {
            [self.refreshHeadView scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
}

#pragma mark - GJCFFileDownloadManager config

- (void)configFileDownloadManager {
    GJCFWeakSelf weakSelf = self;
    [[GJCFFileDownloadManager shareDownloadManager] setDownloadCompletionBlock:^(GJCFFileDownloadTask *task, NSData *fileData, NSString *localPath, BOOL isFinishCache) {

        [weakSelf finishDownloadWithTask:task withDownloadFileData:fileData localPath:localPath];

    }                                                              forObserver:self];

    [[GJCFFileDownloadManager shareDownloadManager] setDownloadFaildBlock:^(GJCFFileDownloadTask *task, NSError *error) {

        [weakSelf faildDownloadFileWithTask:task];

    }                                                         forObserver:self];

    [[GJCFFileDownloadManager shareDownloadManager] setDownloadProgressBlock:^(GJCFFileDownloadTask *task, CGFloat progress) {

        [weakSelf downloadFileWithTask:task progress:progress];

    }                                                            forObserver:self];

}

- (void)addDownloadTask:(GJCFFileDownloadTask *)task {
    [[GJCFFileDownloadManager shareDownloadManager] addTask:task];
}

- (void)downloadRichtextWhenShowAtIndexPath:(NSIndexPath *)indexPath contentModel:(GJGCChatFriendContentModel *)contentModel {
}

- (void)finishDownloadWithTask:(GJCFFileDownloadTask *)task withDownloadFileData:(NSData *)fileData localPath:(NSString *)localPath; {
}

- (void)downloadFileWithTask:(GJCFFileDownloadTask *)task progress:(CGFloat)progress; {

}

- (void)faildDownloadFileWithTask:(GJCFFileDownloadTask *)task; {

}

- (void)cancelDownloadWithTaskIdentifier:(NSString *)taskIdentifier; {
    [[GJCFFileDownloadManager shareDownloadManager] cancelTask:taskIdentifier];
}

#pragma mark - tableView Delegate DataSource

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {

    if ([cell isKindOfClass:[GJGCChatBaseCell class]]) {
        GJGCChatBaseCell *baceCell = (GJGCChatBaseCell *) cell;
        [baceCell willDisplayCell];
    }


    if (self.taklInfo.talkType == GJGCChatFriendTalkTypePostSystem) {
        return;
    }

    GJGCChatFriendContentModel *model = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:indexPath.row];
    if (model.isFromSelf) {
        return;
    }

    //pre load rich message
    [self downloadRichtextWhenShowAtIndexPath:indexPath contentModel:model];

    //message read ack
    if (![self.dataSourceManager.ignoreMessageTypes containsObject:@(model.contentType)]) {
        if (model.snapTime > 0 && model.readState == GJGCChatFriendMessageReadStateUnReaded) {
            if (model.contentType == GJGCChatFriendContentTypeVideo || model.contentType == GJGCChatFriendContentTypeAudio || model.contentType == GJGCChatFriendContentTypeImage) {
                return;
            }
            [[MessageDBManager sharedManager] updateMessageReadTimeWithMsgID:model.localMsgId messageOwer:self.taklInfo.chatIdendifier];
            model.readTime = (long long) ([[NSDate date] timeIntervalSince1970] * 1000);
            model.readState = GJGCChatFriendMessageReadStateReaded;
            if (self.dataSourceManager.ReadedMessageBlock) {
                self.dataSourceManager.ReadedMessageBlock(model.localMsgId);
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[GJGCChatBaseCell class]]) {
        GJGCChatBaseCell *baceCell = (GJGCChatBaseCell *) cell;
        [baceCell didEndDisplayingCell];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataSourceManager totalCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *DefaultBaseCellIdentifier = @"DefaultBaseCellIdentifier";
    NSString *identifier = [self.dataSourceManager contentCellIdentifierAtIndex:indexPath.row];

    Class cellClass = [self.dataSourceManager contentCellAtIndex:indexPath.row];

    if (!cellClass) {

        GJGCChatBaseCell *baseCell = (GJGCChatBaseCell *) [tableView dequeueReusableCellWithIdentifier:DefaultBaseCellIdentifier];

        if (!baseCell) {

            baseCell = [[GJGCChatBaseCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        }

        return baseCell;
    }

    GJGCChatBaseCell *baseCell = (GJGCChatBaseCell *) [tableView dequeueReusableCellWithIdentifier:identifier];

    if (!baseCell) {

        baseCell = [(GJGCChatBaseCell *) [cellClass alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        baseCell.delegate = self;
    }

    [baseCell setContentModel:[self.dataSourceManager contentModelAtIndex:indexPath.row]];

    if (tableView.isTracking) {

        [baseCell pause];

    } else {

        [baseCell resume];
    }

    [self downloadImageFile:[self.dataSourceManager contentModelAtIndex:indexPath.row] forIndexPath:indexPath];

    return baseCell;

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.dataSourceManager rowHeightAtIndex:indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

}

- (void)downloadImageFile:(GJGCChatContentBaseModel *)contentModel forIndexPath:(NSIndexPath *)indexPath {

}


#pragma mark -scroll to bottom

- (void)scrollToBottom:(BOOL)animated {
    if ([self.dataSourceManager totalCount] == 0)
        return;
    [self.chatListTable reloadData];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.dataSourceManager totalCount] - 1 inSection:0];
    UITableViewCell *cell = [self.chatListTable cellForRowAtIndexPath:indexPath];
    if (cell) {
        CGFloat offsetY = self.chatListTable.contentSize.height + self.chatListTable.contentInset.bottom - CGRectGetHeight(self.chatListTable.frame);
        if (offsetY < -self.chatListTable.contentInset.top)
            offsetY = -self.chatListTable.contentInset.top;
        [self.chatListTable setContentOffset:CGPointMake(0, offsetY) animated:animated];
    } else {
        [self.chatListTable scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}

#pragma mark - dataSouceManager Delegate

- (void)dataSourceManagerEnterSnapChat:(GJGCChatDetailDataSourceManager *)dataManager {
    self.titleView.chatStyle = ChatPageTitleViewStyleSnapChat;
}

- (void)dataSourceManagerCloseSnapChat:(GJGCChatDetailDataSourceManager *)dataManager {
    self.titleView.chatStyle = ChatPageTitleViewStyleNomarl;
}

- (void)dataSourceManagerInsertNewMessagesReloadTableView:(GJGCChatDetailDataSourceManager *)dataManager {
    [GCDQueue executeInMainQueue:^{
        BOOL isNeedScrollToBottom = NO;
        if (self.chatListTable.contentOffset.y >= self.chatListTable.contentSize.height - 2 * self.chatListTable.height - self.refreshHeadView.height) {
            isNeedScrollToBottom = YES;
        }
        [self reloadData];
        if (isNeedScrollToBottom) {
            [self scrollToBottom:YES];
        }
    }];
}

- (void)dataSourceManagerRequireTriggleLoadMore:(GJGCChatDetailDataSourceManager *)dataManager {
    __weak __typeof(&*self) weakSelf = self;
    GJCFAsyncMainQueue(^{
        [weakSelf startLoadMore];
    });
}

- (void)dataSourceManagerSnapChatUpdateListTable:(GJGCChatDetailDataSourceManager *)dataManager scrollToBottom:(BOOL)scrollToBottom {
    [GCDQueue executeInMainQueue:^{
        [self reloadData];
        NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:self.dataSourceManager.totalCount - 1 inSection:0];
        if (scrollToBottom) {
            [self.chatListTable scrollToRowAtIndexPath:lastIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    }];
}

- (void)dataSourceManagerSnapChatUpdateListTable:(GJGCChatDetailDataSourceManager *)dataManager {
    [GCDQueue executeInMainQueue:^{
        [self reloadData];
    }];
}

- (void)dataSourceManagerRequireFinishLoadMore:(GJGCChatDetailDataSourceManager *)dataManager {
    __weak __typeof(&*self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{

        BOOL isNeedScrollToBottom = NO;
        if (weakSelf.chatListTable.contentOffset.y >= weakSelf.chatListTable.contentSize.height - weakSelf.chatListTable.height - weakSelf.refreshHeadView.height) {
            isNeedScrollToBottom = YES;
        }

        [weakSelf reloadData];

        [weakSelf.dataSourceManager resetFirstAndLastMsgId];

        if (isNeedScrollToBottom) {
            [weakSelf scrollToBottom:YES];
        }

    });

}

- (void)dataSourceManagerRequireFinishRefresh:(GJGCChatDetailDataSourceManager *)dataManager {
    __weak __typeof(&*self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{

        [weakSelf reloadDataStopRefreshNoAnimated];

        if (weakSelf.dataSourceManager.lastFirstLocalMsgId) {

            NSInteger lastFirstMsgIndex = [weakSelf.dataSourceManager getContentModelIndexByLocalMsgId:weakSelf.dataSourceManager.lastFirstLocalMsgId];

            if (lastFirstMsgIndex >= 0 && lastFirstMsgIndex < weakSelf.dataSourceManager.totalCount) {
                NSIndexPath *moveToPath = [NSIndexPath indexPathForRow:lastFirstMsgIndex inSection:0];
                [weakSelf.chatListTable reloadData];
                [weakSelf.chatListTable scrollToRowAtIndexPath:moveToPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
                [weakSelf.dataSourceManager resetFirstAndLastMsgId];
            }
        }
    });
}


- (void)dataSourceManagerRequireUpdateListTable:(GJGCChatDetailDataSourceManager *)dataManager {

    BOOL isNeedScrollToBottom = NO;
    if (self.chatListTable.contentOffset.y >= self.chatListTable.contentSize.height - self.chatListTable.height - self.refreshHeadView.height) {
        isNeedScrollToBottom = YES;
    }
    [self reloadData];
    if (isNeedScrollToBottom) {
        if (self.dataSourceManager.totalCount > 2) {
            [self.chatListTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.dataSourceManager.totalCount - 2 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        }
        [self scrollToBottom:YES];
    }
    self.titleView.title = self.dataSourceManager.title;

}

- (void)dataSourceManagerRequireUpdateListTable:(GJGCChatDetailDataSourceManager *)dataManager reloadIndexPaths:(NSArray *)indexPaths {
    if (indexPaths.count) {
        [self.chatListTable reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)dataSourceManagerRequireUpdateListTable:(GJGCChatDetailDataSourceManager *)dataManager reloadAtIndex:(NSInteger)index {
    if (index >= 0 && index < self.dataSourceManager.totalCount) {
        NSIndexPath *reloadPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.chatListTable reloadRowsAtIndexPaths:@[reloadPath] withRowAnimation:UITableViewRowAnimationNone];
        if (reloadPath.row == self.dataSourceManager.totalCount - 1) {
            [self.chatListTable reloadData];
            [self.chatListTable scrollToRowAtIndexPath:reloadPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    }
}

- (void)dataSourceManagerRequireUpdateListTable:(GJGCChatDetailDataSourceManager *)dataManager reloadForUpdateMsgStateAtIndex:(NSInteger)index {
    if (index >= 0 && index < self.dataSourceManager.totalCount) {

        NSIndexPath *reloadPath = [NSIndexPath indexPathForRow:index inSection:0];
        if (![[self.chatListTable indexPathsForVisibleRows] containsObject:reloadPath]) {
            return;
        }
        GJGCChatFriendBaseCell *chatCell = (GJGCChatFriendBaseCell *) [self.chatListTable cellForRowAtIndexPath:reloadPath];
        GJGCChatContentBaseModel *contentModel = [self.dataSourceManager contentModelAtIndex:index];

        if ([chatCell isKindOfClass:[GJGCChatFriendBaseCell class]]) {
            [chatCell setSendStatus:contentModel.sendStatus];
            [chatCell faildWithType:contentModel.faildType andReason:contentModel.faildReason];
        }
    }
}

- (void)dataSourceManagerRequireUpdateListTable:(GJGCChatDetailDataSourceManager *)dataManager insertWithIndex:(NSInteger)index {
    __weak __typeof(&*self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{

        if (index >= 0 && index < weakSelf.dataSourceManager.totalCount) {

            [weakSelf cancelMenuVisiableCellFirstResponse];

            NSIndexPath *insertPath = [NSIndexPath indexPathForRow:index inSection:0];

            [weakSelf.chatListTable insertRowsAtIndexPaths:@[insertPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    });
}

- (void)dataSourceManagerRequireUpdateListTable:(GJGCChatDetailDataSourceManager *)dataManager insertIndexPaths:(NSArray *)indexPaths {
    if (![UIView areAnimationsEnabled]) {
        [UIView setAnimationsEnabled:YES];
    }
    if (indexPaths.count > 0) {
        NSIndexPath *lastIndexPath = [indexPaths lastObject];
        if (lastIndexPath.row + 1 != self.dataSourceManager.totalCount) {
            [self.chatListTable reloadData];
        } else {
            [self cancelMenuVisiableCellFirstResponse];

            [self.chatListTable beginUpdates];
            [self.chatListTable insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
            [self.chatListTable endUpdates];
            BOOL isNeedScrollToBottom = NO;
            if (self.chatListTable.contentOffset.y >= self.chatListTable.contentSize.height - self.chatListTable.height - self.refreshHeadView.height) {
                isNeedScrollToBottom = YES;
            }
            if (isNeedScrollToBottom) {
                [self.chatListTable reloadData];
                [self.chatListTable scrollToRowAtIndexPath:lastIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }
            [self clearAllEarlyMessage];
        }
    }
}

- (void)clearAllEarlyMessage {

}

#pragma mark - back / frongroup note

- (void)observeApplicationState {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(becomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)becomeActive:(NSNotification *)noti {
    dispatch_async(dispatch_get_main_queue(), ^{
    });
}

#pragma -mark  UIGestureRecognizerDelegate-》》 Gesture conflict can not be the key word
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([NSStringFromClass([touch.view class]) isEqualToString:@"GJCFCoreTextContentView"]) {
        return NO;
    }
    return YES;
}


@end
