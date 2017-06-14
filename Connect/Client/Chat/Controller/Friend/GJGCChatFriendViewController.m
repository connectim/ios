
//
//  GJGCChatFriendViewController.m
//  Connect
//
//  Created by KivenLin on 14-11-3.
//  Copyright (c) 2014年 ConnectSoft. All rights reserved.
//

#import "GJGCChatFriendViewController.h"
#import "GJGCChatFriendAudioMessageCell.h"
#import "GJGCChatFriendImageMessageCell.h"
#import "UIImage+GJFixOrientation.h"
#import "GJGCGIFLoadManager.h"
#import "GJGCChatFriendVideoCell.h"
#import "ChatMapCell.h"
#import "PlayViewController.h"
#import "ChatFriendSetViewController.h"
#import "StringTool.h"
#import "InviteUserPage.h"
#import "UserDetailPage.h"
#import "NSString+iTunes.h"
#import "LMChatSingleTransferViewController.h"
#import "MapLocationViewController.h"
#import "LMChatRedLuckyViewController.h"
#import "LMChatRedLuckyDetailController.h"
#import "LMReciptNotesViewController.h"
#import "WallteNetWorkTool.h"
#import "LMGroupFriendsViewController.h"
#import "LMRecipFriendsViewController.h"
#import "LMTransferNotesViewController.h"
#import "LMGroupChatReciptViewController.h"
#import "LMGroupZChouReciptViewController.h"
#import "LMGroupZChouTransViewController.h"
#import "RedBagNetWorkTool.h"
#import "CommonClausePage.h"
#import "LMMessageExtendManager.h"
#import "SelectContactCardController.h"
#import "TZImagePickerController.h"
#import "MSSBrowseDefine.h"
#import "RecentChatDBManager.h"
#import "NetWorkOperationTool.h"
#import "IMService.h"
#import "CustomActionSheetView.h"
#import "TBActionSheet.h"
#import <Photos/Photos.h>
#import "LMBaseSSDBManager.h"
#import "ReconmandChatListPage.h"
#import "LMPhotoViewController.h"
#import "LMApplyJoinToGroupViewController.h"
#import "HandleUrlManager.h"
#import "NSURL+Param.h"
#import "LMSetMoneyResultViewController.h"
#import "LMUnSetMoneyResultViewController.h"
#import "LMMessageTool.h"

#define GJGCActionSheetCallPhoneNumberTag 132134

static NSString *const GJGCActionSheetAssociateKey = @"GJIMSimpleCellActionSheetAssociateKey";

@interface GJGCChatFriendViewController () <
        GJCFAudioPlayerDelegate,
        UIImagePickerControllerDelegate,
        UINavigationControllerDelegate,
        LMRedLuckyShowViewDelegate, TZImagePickerControllerDelegate, TBActionSheetDelegate>


@property(nonatomic, strong) NSString *playingAudioMsgId;

@property(nonatomic, assign) NSInteger lastPlayedAudioMsgIndex;

@property(nonatomic, assign) BOOL isLastPlayedMyAudio;

@property(nonatomic, strong) NSMutableArray *temWAVFilesArray;

/*
 * call phone webview
 */
@property(nonatomic, strong) UIWebView *callWebview;

@property(nonatomic, assign) BOOL isShowingOhterView;

@end

@implementation GJGCChatFriendViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    if (self.taklInfo.talkType == GJGCChatFriendTalkTypePrivate) {
        [self setRightButtonWithStateImage:@"menu_white" stateHighlightedImage:nil stateDisabledImage:nil titleName:nil];
        __weak __typeof(&*self) weakSelf = self;
        [[IMService instance] getUserCookieWihtChatUser:self.taklInfo.chatUser complete:^(NSError *erro, id data) {
            [weakSelf.dataSourceManager showEcdhKeyUpdataMessageWithSuccess:!erro && data];
        }];
    }

    self.audioPlayer = [[GJCFAudioPlayer alloc] init];
    self.audioPlayer.delegate = self;

    [self setStrNavTitle:self.dataSourceManager.title];

    /**
     *  Record temporary play files, need to close the dialog window is to delete the disk data
     */
    self.temWAVFilesArray = [NSMutableArray array];

    NSString *formateNoti = [GJGCChatInputConst panelNoti:GJGCChatInputPanelBeginRecordNoti formateWithIdentifier:self.inputPanel.panelIndentifier];
    [GJCFNotificationCenter addObserver:self selector:@selector(observeChatInputPanelBeginRecord:) name:formateNoti object:nil];
    [GJCFNotificationCenter addObserver:self selector:@selector(observeApplicationResignActive:) name:UIApplicationWillResignActiveNotification object:nil];

    RegisterNotify(ConnnectGroupInfoDidDeleteMember, @selector(removeGroupMember:))
    RegisterNotify(ConnnectGroupInfoDidAddMembers, @selector(addmemberToGroup:))
    RegisterNotify(ConnnectContactDidChangeNotification, @selector(contactChange:))
    [self.inputPanel startKeyboardObserve];

    //Receive external lackypackge
    if (!GJCFStringIsNull(self.outterRedpackHashid)) {
        [self grabRedBagWithHashId:self.outterRedpackHashid senderName:self.taklInfo.chatUser.username sendAddress:nil];
    }
}

- (void)contactChange:(NSNotification *)noti {
    AccountInfo *user = noti.object;
    if (self.taklInfo.talkType == GJGCChatFriendTalkTypePrivate) {
        if ([user.pub_key isEqualToString:self.taklInfo.chatIdendifier]) {
            self.taklInfo.name = user.normalShowName;
            self.dataSourceManager.title = self.taklInfo.name;
            self.taklInfo.chatUser = user;
            [GCDQueue executeInMainQueue:^{
                self.titleView.title = self.taklInfo.name;
            }];
        }
    }
}

- (void)addmemberToGroup:(NSNotification *)noti {
    NSString *tipMessage = noti.object;
    GJGCChatFriendContentModel *statusTipModel = [[GJGCChatFriendContentModel alloc] init];
    statusTipModel.baseMessageType = GJGCChatBaseMessageTypeChatMessage;
    statusTipModel.contentType = GJGCChatFriendContentTypeStatusTip;


    NSMutableAttributedString *tipMessageText = [[NSMutableAttributedString alloc] initWithString:tipMessage];
    [tipMessageText addAttribute:NSFontAttributeName
                           value:[UIFont systemFontOfSize:FONT_SIZE(22)]
                           range:NSMakeRange(0, tipMessage.length)];
    [tipMessageText addAttribute:NSForegroundColorAttributeName
                           value:LMAssociateTextColor
                           range:NSMakeRange(0, tipMessage.length)];
    statusTipModel.statusMessageString = tipMessageText;
    NSDate *sendTime = [NSDate date];
    statusTipModel.sendTime = [sendTime timeIntervalSince1970];
    statusTipModel.localMsgId = [ConnectTool generateMessageId];
    [self.dataSourceManager sendMesssage:statusTipModel];

}

- (void)removeGroupMember:(NSNotification *)noti {

    NSString *userName = noti.object;
    GJGCChatFriendContentModel *statusTipModel = [[GJGCChatFriendContentModel alloc] init];
    statusTipModel.baseMessageType = GJGCChatBaseMessageTypeChatMessage;
    statusTipModel.contentType = GJGCChatFriendContentTypeStatusTip;

    NSString *tipMessage = [NSString stringWithFormat:LMLocalizedString(@"Link You Remove from the group chat", nil), userName];
    NSMutableAttributedString *tipMessageText = [[NSMutableAttributedString alloc] initWithString:tipMessage];
    [tipMessageText addAttribute:NSFontAttributeName
                           value:[UIFont systemFontOfSize:FONT_SIZE(22)]
                           range:NSMakeRange(0, tipMessage.length)];
    [tipMessageText addAttribute:NSForegroundColorAttributeName
                           value:LMAssociateTextColor
                           range:NSMakeRange(0, tipMessage.length)];
    statusTipModel.statusMessageString = tipMessageText;
    NSDate *sendTime = [NSDate date];
    statusTipModel.sendTime = [sendTime timeIntervalSince1970];
    statusTipModel.localMsgId = [ConnectTool generateMessageId];

}

- (void)dealloc {
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    [self.inputPanel removeKeyboardObserve];
    RemoveNofify;
}

#pragma mark - observeApplicationResignActive

- (void)observeApplicationResignActive:(NSNotification *)noti {
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    [self stopPlayCurrentAudio];

    //Close distance sensor
    [self removeProximityMonitoring];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [GCDQueue executeInGlobalQueue:^{
        [[RecentChatDBManager sharedManager] clearUnReadCountWithIdetifier:self.taklInfo.chatIdendifier];
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    //Close distance sensor
    [self removeProximityMonitoring];

    if (self.audioPlayer.isPlaying) {
        [self stopPlayCurrentAudio];
    }
    for (NSString *path in self.temWAVFilesArray) {
        GJCFFileDeleteFile(path);
    }
    //Release the burn after reading the timer, otherwise it will cause memory problems!!!
    if (!self.isShowingOhterView) {
        [self.dataSourceManager.snapChatDisplayLink invalidate];
        self.dataSourceManager.snapChatDisplayLink = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.isShowingOhterView = NO;
    if (self.dataSourceManager.snapMessageContents.count) {
        self.dataSourceManager.snapChatDisplayLink.paused = NO;
    }
    [self.view endEditing:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)rightButtonPressed:(id)sender {
    ChatFriendSetViewController *setController = [[ChatFriendSetViewController alloc] initWithTalkModel:self.taklInfo];
    [self.navigationController pushViewController:setController animated:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0.26 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self reserveChatInputPanelState];
    });
}

#pragma mark - Observe the input tool to start recording

- (void)observeChatInputPanelBeginRecord:(NSNotification *)noti {
    [self stopPlayCurrentAudio];
}

#pragma mark - init

- (void)initDataManager {
    self.dataSourceManager = [[GJGCChatFriendDataSourceManager alloc] initWithTalk:self.taklInfo withDelegate:self];
}

#pragma mark - DataSourceManager Delegate

- (void)dataSourceManagerUpdateUploadprogress:(GJGCChatDetailDataSourceManager *)dataManager progress:(float)progress index:(NSInteger)index {
    GJGCChatFriendVideoCell *videoCell = [self.chatListTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];

    if ([self.chatListTable.visibleCells containsObject:videoCell]) {
        if ([videoCell respondsToSelector:@selector(setUploadProgress:)]) {
            [videoCell setUploadProgress:progress];
        }
    }
}


- (void)dataSourceManagerRequireDeleteMessages:(GJGCChatDetailDataSourceManager *)dataManager deletePaths:(NSArray *)willDeletePaths {
    for (NSIndexPath *indexPath in willDeletePaths) {
        GJGCChatContentBaseModel *model = [self.dataSourceManager contentModelAtIndex:indexPath.row];
        [self cancelDownloadAtIndexPath:indexPath];
        [self stopPlayCurrentAudio];

        [[MessageDBManager sharedManager] deleteMessageByMessageId:model.localMsgId messageOwer:self.taklInfo.chatIdendifier];
        [ChatMessageFileManager deleteRecentChatMessageFileByMessageID:model.localMsgId Address:self.taklInfo.fileDocumentName];
    }
    [GCDQueue executeInMainQueue:^{
        [self.chatListTable deleteRowsAtIndexPaths:willDeletePaths withRowAnimation:UITableViewRowAnimationNone];
    }];
}

- (void)dataSourceManagerRequireDeleteMessages:(GJGCChatDetailDataSourceManager *)dataManager deletePaths:(NSArray *)willDeletePaths deleteModels:(NSArray *)models {
    for (NSIndexPath *indexPath in willDeletePaths) {
        NSInteger index = [willDeletePaths indexOfObject:indexPath];
        GJGCChatContentBaseModel *model = [models objectAtIndexCheck:index];
        [self cancelDownloadAtIndexPath:indexPath];
        [self stopPlayCurrentAudio];
        [[MessageDBManager sharedManager] deleteMessageByMessageId:model.localMsgId messageOwer:self.taklInfo.chatIdendifier];
        [ChatMessageFileManager deleteRecentChatMessageFileByMessageID:model.localMsgId Address:self.taklInfo.fileDocumentName];
    }
    if (willDeletePaths.count) {
        [self.chatListTable beginUpdates];
        [self.chatListTable deleteRowsAtIndexPaths:willDeletePaths withRowAnimation:UITableViewRowAnimationBottom];
        [self.chatListTable endUpdates];
    }
}

#pragma mark - GJCFAudioPlayer Delegate

- (void)audioPlayer:(GJCFAudioPlayer *)audioPlay didFinishPlayAudio:(GJCFAudioModel *)audioFile {

    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    GJGCChatFriendContentModel *contentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelByMsgId:audioFile.message_id];

    //Update the message after the burn state
    if (contentModel.snapTime > 0 && !contentModel.isFromSelf && contentModel.readState != GJGCChatFriendMessageReadStatePlayCompleted) {
        [[MessageDBManager sharedManager] updateAudioMessageReadCompleteWithMsgID:contentModel.localMsgId messageOwer:self.taklInfo.chatIdendifier];
        contentModel.readTime = (long long) ([[NSDate date] timeIntervalSince1970] * 1000);
        contentModel.readState = GJGCChatFriendMessageReadStatePlayCompleted;
        contentModel.isRead = YES;
        if (self.dataSourceManager.ReadedMessageBlock) {
            self.dataSourceManager.ReadedMessageBlock(contentModel.localMsgId);
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopPlayCurrentAudio];
        [self removeProximityMonitoring];
        [self.temWAVFilesArray objectAddObject:audioFile.tempWamFilePath];
        [self checkNextAudioMsgToPlay];
    });
}

- (void)removeProximityMonitoring {
    if ([UIDevice currentDevice].proximityMonitoringEnabled) {
        [UIDevice currentDevice].proximityMonitoringEnabled = NO;
        [GJCFNotificationCenter removeObserver:self name:UIDeviceProximityStateDidChangeNotification object:nil];
    }
}

- (void)checkNextAudioMsgToPlay {
    NSInteger nextWaitPlayAudioIndex = NSNotFound;
    NSString *nextPlayMsgId = nil;

    NSInteger lastPlayIndex = self.lastPlayedAudioMsgIndex;
    if (lastPlayIndex == [self.dataSourceManager totalCount] - 1) {
        return;
    }
    if (self.isLastPlayedMyAudio) {

        GJGCChatFriendContentModel *contentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:lastPlayIndex + 1];

        if (contentModel.isFromSelf) {
            return;
        }

    }
    while (lastPlayIndex < [self.dataSourceManager totalCount] - 1) {
        lastPlayIndex++;
        GJGCChatFriendContentModel *contentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:lastPlayIndex];

        if (contentModel.contentType == GJGCChatFriendContentTypeAudio && !contentModel.isFromSelf) {

            if (contentModel.isRead) {


            } else {

                nextWaitPlayAudioIndex = lastPlayIndex;
                nextPlayMsgId = contentModel.localMsgId;

            }
            break;
        }
    }
    if (nextWaitPlayAudioIndex != NSNotFound) {

        self.playingAudioMsgId = nextPlayMsgId;

        [self startPlayCurrentAudio];

    }
}

- (void)audioPlayer:(GJCFAudioPlayer *)audioPlay didOccusError:(NSError *)error {
    if (error.code != -235) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self stopPlayCurrentAudio];
        });
    }
}

- (void)audioPlayer:(GJCFAudioPlayer *)audioPlay didUpdateSoundMouter:(CGFloat)soundMouter {
}

#pragma mark - rich message download

- (void)downloadRichtextWhenShowAtIndexPath:(NSIndexPath *)indexPath contentModel:(GJGCChatFriendContentModel *)contentModel {
    if ([self.downLoadingRichMessageIds containsObject:[NSString stringWithFormat:@"%@_%@", self.taklInfo.chatIdendifier, contentModel.localMsgId]]) {
        return;
    }
    switch (contentModel.contentType) {
        case GJGCChatFriendContentTypeAudio: {
            if (contentModel.audioIsDownload) {
                return;
            }
            GJGCChatFriendAudioMessageCell *audioCell = (GJGCChatFriendAudioMessageCell *) [self.chatListTable cellForRowAtIndexPath:indexPath];
            if ([audioCell respondsToSelector:@selector(startDownloadAction)]) {
                [audioCell startDownloadAction];
            }
            contentModel.isDownloading = YES;

            NSString *taskIdentifier = nil;
            GJCFFileDownloadTask *downloadTask = [GJCFFileDownloadTask taskWithDownloadUrl:contentModel.audioModel.remotePath withCachePath:contentModel.audioModel.downloadEncodeCachePath withObserver:self getTaskIdentifer:&taskIdentifier];
            if (self.taklInfo.talkType != GJGCChatFriendTalkTypePrivate && self.taklInfo.talkType != GJGCChatFriendTalkTypeGroup) {
                downloadTask.unEncodeData = YES;
            } else {
                NSData *ecdhkey = nil;
                if (self.taklInfo.talkType == GJGCChatFriendTalkTypeGroup) {
                    ecdhkey = [StringTool hexStringToData:self.taklInfo.chatGroupInfo.groupEcdhKey];
                } else if (self.taklInfo.talkType == GJGCChatFriendTalkTypePrivate) {
                    ecdhkey = [KeyHandle getECDHkeyWithPrivkey:[[LKUserCenter shareCenter] currentLoginUser].prikey
                                                     publicKey:self.taklInfo.chatIdendifier];
                }
                ecdhkey = [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdhkey salt:[ConnectTool get64ZeroData]];
                downloadTask.ecdhkey = ecdhkey;
            }
            downloadTask.userInfo = @{@"type": @"audio",
                                      @"localMsgId":contentModel.localMsgId};
            downloadTask.msgIdentifier = [NSString stringWithFormat:@"%@_%@", self.taklInfo.chatIdendifier, contentModel.localMsgId];
            downloadTask.temOriginFilePath = contentModel.audioModel.localAMRStorePath;
            contentModel.downloadTaskIdentifier = taskIdentifier;
            [self.downLoadingRichMessageIds objectAddObject:[NSString stringWithFormat:@"%@_%@", self.taklInfo.chatIdendifier, contentModel.localMsgId]];
            [self addDownloadTask:downloadTask];
        }
            break;
        default:
            break;
    }
}

- (void)finishDownloadWithTask:(GJCFFileDownloadTask *)task withDownloadFileData:(NSData *)fileData localPath:(NSString *)localPath {

    [self.downLoadingRichMessageIds removeObject:task.msgIdentifier];
    [super finishDownloadWithTask:task withDownloadFileData:fileData localPath:localPath];

    NSInteger index = [self.dataSourceManager getContentModelIndexByDownloadTaskIdentifier:task.taskUniqueIdentifier];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];

    NSDictionary *userInfo = task.userInfo;
    NSString *taskType = userInfo[@"type"];
    if ([taskType isEqualToString:@"audio"]) {
        NSString *localMsgId = [userInfo valueForKey:@"localMsgId"];
        NSInteger playingIndex = [self.dataSourceManager getContentModelIndexByLocalMsgId:localMsgId];
        GJGCChatFriendContentModel *contentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:playingIndex];
        contentModel.isDownloading = NO;
        contentModel.audioIsDownload = YES;

        GJGCChatFriendAudioMessageCell *audioCell = (GJGCChatFriendAudioMessageCell *) [self.chatListTable cellForRowAtIndexPath:indexPath];
        if ([audioCell respondsToSelector:@selector(successDownloadAction)]) {
            [audioCell successDownloadAction];
        }
        [GJCFEncodeAndDecode convertAudioFileToWAV:contentModel.audioModel];
        [self startPlayCurrentAudio];
    }

    if ([taskType isEqualToString:@"image"]) {
        GJGCChatFriendImageMessageCell *imageCell = [self.chatListTable cellForRowAtIndexPath:indexPath];
        GJGCChatFriendContentModel *contentModel = [self.dataSourceManager getContentModelByDownloadTaskIdentifier:task.taskUniqueIdentifier];
        UIImage *cacheImage = [UIImage imageWithData:fileData];
        contentModel.messageContentImage = cacheImage;
        contentModel.isDownloadImage = YES;

        if (![self.chatListTable.visibleCells containsObject:imageCell]) {
            return;
        }
        if ([imageCell isKindOfClass:[GJGCChatFriendImageMessageCell class]]) {
            [imageCell removePrepareState];
            [imageCell successDownloadWithImageData:fileData];
        }
    }

    if ([taskType isEqualToString:@"thumbimage"]) {
        GJGCChatFriendImageMessageCell *imageCell = [self.chatListTable cellForRowAtIndexPath:indexPath];
        GJGCChatFriendContentModel *contentModel = [self.dataSourceManager getContentModelByDownloadTaskIdentifier:task.taskUniqueIdentifier];
        UIImage *cacheImage = [UIImage imageWithData:fileData];
        contentModel.messageContentImage = cacheImage;
        contentModel.isDownloadThumbImage = YES;

        if (![self.chatListTable.visibleCells containsObject:imageCell]) {
            return;
        }
        if ([imageCell isKindOfClass:[GJGCChatFriendImageMessageCell class]]) {
            [imageCell removePrepareState];
            [imageCell successDownloadWithImageData:fileData];
        }
    }

    if ([taskType isEqualToString:@"locationimage"]) {
        ChatMapCell *imageCell = [self.chatListTable cellForRowAtIndexPath:indexPath];
        GJGCChatFriendContentModel *contentModel = [self.dataSourceManager getContentModelByDownloadTaskIdentifier:task.taskUniqueIdentifier];
        UIImage *cacheImage = [UIImage imageWithData:fileData];
        contentModel.messageContentImage = cacheImage;

        if (![self.chatListTable.visibleCells containsObject:imageCell]) {
            return;
        }
        if ([imageCell isKindOfClass:[ChatMapCell class]]) {
            [imageCell successDownloadWithImageData:fileData];
        }
    }


    if ([taskType isEqualToString:@"videocover"]) {
        GJGCChatFriendVideoCell *imageCell = [self.chatListTable cellForRowAtIndexPath:indexPath];
        GJGCChatFriendContentModel *contentModel = [self.dataSourceManager getContentModelByDownloadTaskIdentifier:task.taskUniqueIdentifier];
        UIImage *cacheImage = [UIImage imageWithData:fileData];
        contentModel.messageContentImage = cacheImage;

        if (![self.chatListTable.visibleCells containsObject:imageCell]) {
            return;
        }
        if ([imageCell isKindOfClass:[GJGCChatFriendVideoCell class]]) {
            [imageCell removePrepareState];
            [imageCell successDownloadWithImageData:fileData isVideo:NO];
        }
    }

    if ([taskType isEqualToString:@"video"]) {
        GJGCChatFriendContentModel *contentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:index];
        contentModel.videoIsDownload = YES;
        GJGCChatFriendVideoCell *imageCell = [self.chatListTable cellForRowAtIndexPath:indexPath];

        if (![self.chatListTable.visibleCells containsObject:imageCell]) {
            return;
        }
        if ([imageCell isKindOfClass:[GJGCChatFriendVideoCell class]]) {
            [imageCell removePrepareState];
            [imageCell successDownloadWithImageData:nil isVideo:YES];
        }
        PlayViewController *playController = [[PlayViewController alloc] initWithVideoFileURL:[NSURL fileURLWithPath:localPath]];
        __weak __typeof(&*self) weakSelf = self;
        playController.ClosePlayCallBack = ^(BOOL playComplete) {
            if (playComplete) {
                [weakSelf videoMessageReadCompleteWithMessageid:contentModel.localMsgId];
            }
        };
        [self presentViewController:playController animated:NO completion:nil];
    }
}

- (void)downloadFileWithTask:(GJCFFileDownloadTask *)task progress:(CGFloat)progress {
    [super downloadFileWithTask:task progress:progress];
    NSDictionary *userInfo = task.userInfo;
    NSString *taskType = userInfo[@"type"];
    if ([taskType isEqualToString:@"videocover"] || [taskType isEqualToString:@"image"]) {
        return;
    }

    NSInteger index = [self.dataSourceManager getContentModelIndexByDownloadTaskIdentifier:task.taskUniqueIdentifier];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];

    GJGCChatFriendContentModel *contentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:index];
    contentModel.downloadProgress = progress;

    GJGCChatFriendBaseCell *cell = [self.chatListTable cellForRowAtIndexPath:indexPath];
    if (![self.chatListTable.visibleCells containsObject:cell]) {
        return;
    }

    [cell downloadProgress:progress];
}

- (void)faildDownloadFileWithTask:(GJCFFileDownloadTask *)task {

    DDLogError(@"%@", task.userInfo);
    [super faildDownloadFileWithTask:task];
    [self.downLoadingRichMessageIds removeObject:task.msgIdentifier];
    NSInteger index = [self.dataSourceManager getContentModelIndexByDownloadTaskIdentifier:task.taskUniqueIdentifier];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];


    NSDictionary *userInfo = task.userInfo;

    NSString *taskType = userInfo[@"type"];

    if ([taskType isEqualToString:@"audio"]) {
        NSString *localMsgId = [userInfo valueForKey:@"localMsgId"];
        NSInteger playingIndex = [self.dataSourceManager getContentModelIndexByLocalMsgId:localMsgId];
        GJGCChatFriendAudioMessageCell *cell = [self.chatListTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:playingIndex inSection:0]];
        [cell faildDownloadAction];
        GJGCChatFriendContentModel *contentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:index];
        contentModel.isDownloading = NO;
        contentModel.audioIsDownload = NO;
    }
    if ([taskType isEqualToString:@"image"]) {
        GJGCChatFriendImageMessageCell *imageCell = [self.chatListTable cellForRowAtIndexPath:indexPath];
        if ([imageCell isKindOfClass:[GJGCChatFriendImageMessageCell class]]) {
            [imageCell faildState];
        }
    }
    if ([taskType isEqualToString:@"locationimage"]) {
        ChatMapCell *imageCell = [self.chatListTable cellForRowAtIndexPath:indexPath];
        if ([imageCell isKindOfClass:[ChatMapCell class]]) {
            [imageCell failDownloadState];
        }
    }
    if ([taskType isEqualToString:@"videocover"]) {

        GJGCChatFriendVideoCell *imageCell = [self.chatListTable cellForRowAtIndexPath:indexPath];
        if ([imageCell isKindOfClass:[GJGCChatFriendVideoCell class]]) {
            [imageCell faildCoverState];
        }
    }

    if ([taskType isEqualToString:@"video"]) {
        GJGCChatFriendVideoCell *imageCell = [self.chatListTable cellForRowAtIndexPath:indexPath];
        if ([imageCell isKindOfClass:[GJGCChatFriendVideoCell class]]) {
            [imageCell faildVideoState];
        }
    }

}


- (void)videoMessageReadCompleteWithMessageid:(NSString *)messageId {
    if (self.taklInfo.talkType == GJGCChatFriendTalkTypePostSystem) {
        return;
    }
    GJGCChatFriendContentModel *model = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelByMsgId:messageId];
    if (model.isFromSelf) {
        return;
    }

    if (![self.dataSourceManager.ignoreMessageTypes containsObject:@(model.contentType)]) {
        if (model.snapTime > 0 && model.readState == GJGCChatFriendMessageReadStateUnReaded) {
            [[MessageDBManager sharedManager] updateMessageReadTimeWithMsgID:model.localMsgId messageOwer:self.taklInfo.chatIdendifier];
            model.readTime = (long long) ([[NSDate date] timeIntervalSince1970] * 1000);
            model.readState = GJGCChatFriendMessageReadStateReaded;
            if (self.dataSourceManager.ReadedMessageBlock) {
                self.dataSourceManager.ReadedMessageBlock(model.localMsgId);
            }
        }
    }
}

#pragma mark - GJGCChatBaseCellDelegate

- (void)audioMessageCellDidTap:(GJGCChatBaseCell *)tapedCell {
    NSIndexPath *indexPath = [self.chatListTable indexPathForCell:tapedCell];
    GJGCChatFriendContentModel *contentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:indexPath.row];
    if (self.playingAudioMsgId && [self.playingAudioMsgId isEqualToString:contentModel.localMsgId] && self.audioPlayer.isPlaying) {

        [self stopPlayCurrentAudio];

        self.playingAudioMsgId = nil;

        return;
    }

    [self stopPlayCurrentAudio];
    self.playingAudioMsgId = contentModel.localMsgId;
    [self startPlayCurrentAudio];
}

- (void)videoMessageCancelDownload:(GJGCChatBaseCell *)tapedCell {
    NSIndexPath *indexPath = [self.chatListTable indexPathForCell:tapedCell];
    GJGCChatFriendContentModel *contentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:indexPath.row];
    [self cancelDownloadWithTaskIdentifier:contentModel.downloadTaskIdentifier];
}

- (void)videoMessageCellDidTap:(GJGCChatBaseCell *)tapedCell {
    NSIndexPath *indexPath = [self.chatListTable indexPathForCell:tapedCell];
    GJGCChatFriendContentModel *contentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:indexPath.row];
    if (!GJCFFileDirectoryIsExist(contentModel.videoOriginDataPath)) {
        GJGCChatFriendContentModel *friendContentModel = (GJGCChatFriendContentModel *) contentModel;
        friendContentModel.isDownloading = YES;
        [self.dataSourceManager updateContentModelValuesNotEffectRowHeight:friendContentModel atIndex:indexPath.row];
        [self downloadAndPlayVideoAtRowIndex:indexPath];
    } else {
        PlayViewController *playController = [[PlayViewController alloc] initWithVideoFileURL:[NSURL fileURLWithPath:contentModel.videoOriginDataPath]];
        __weak __typeof(&*self) weakSelf = self;
        playController.ClosePlayCallBack = ^(BOOL playComplete) {
            if (playComplete) {
                [weakSelf videoMessageReadCompleteWithMessageid:contentModel.localMsgId];
            }
        };
        [self presentViewController:playController animated:NO completion:nil];
    }
}

- (void)imageMessageCellDidTap:(GJGCChatBaseCell *)tapedCell {
    if ([self.inputPanel isInputTextFirstResponse]) {
        [self.inputPanel inputBarRegsionFirstResponse];
        self.inputPanel.top = GJCFSystemScreenHeight - self.inputPanel.inputBarHeight;
        [self.inputPanel reserveState];
    }
    GJGCChatFriendImageMessageCell *imageCell = (GJGCChatFriendImageMessageCell *) tapedCell;
    NSIndexPath *indexPath = [self.chatListTable indexPathForCell:tapedCell];
    GJGCChatFriendContentModel *contentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:indexPath.row];
    BOOL isImageDown = GJCFFileIsExist(contentModel.imageOriginDataCachePath) || GJCFFileIsExist(contentModel.thumbImageCachePath);

    if (isImageDown && contentModel.snapTime > 0 && !contentModel.isFromSelf && contentModel.readState == GJGCChatFriendMessageReadStateUnReaded) {
        [[MessageDBManager sharedManager] updateMessageReadTimeWithMsgID:contentModel.localMsgId messageOwer:self.taklInfo.chatIdendifier];
        NSInteger readTime = [[MessageDBManager sharedManager] getReadTimeByMessageId:contentModel.localMsgId messageOwer:self.taklInfo.chatIdendifier];
        contentModel.readTime = readTime;
        contentModel.readState = GJGCChatFriendMessageReadStateReaded;
        contentModel.isRead = YES;
        if (self.dataSourceManager.ReadedMessageBlock) {
            self.dataSourceManager.ReadedMessageBlock(contentModel.localMsgId);
        }
    }
    NSMutableArray *browseItemArray = [[NSMutableArray alloc] init];
    NSInteger currentImageIndex = 0;
    for (int i = 0; i < [self.dataSourceManager totalCount]; i++) {
        GJGCChatFriendContentModel *itemModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:i];
        if (itemModel.contentType == GJGCChatFriendContentTypeImage) {
            MSSBrowseModel *browseItem = [[MSSBrowseModel alloc] init];
            browseItem.bigImageLocalPath = itemModel.imageOriginDataCachePath;
            if (!GJCFFileIsExist(itemModel.imageOriginDataCachePath)) {
                browseItem.bigImageLocalPath = itemModel.thumbImageCachePath;
            }
            browseItem.smallImageView = imageCell.contentImageView;
            if (itemModel.snapTime <= 0 || [itemModel.imageOriginDataCachePath isEqualToString:contentModel.imageOriginDataCachePath]) {
                [browseItemArray objectAddObject:browseItem];
            }
            if ([itemModel.imageOriginDataCachePath isEqualToString:contentModel.imageOriginDataCachePath]) {
                currentImageIndex = browseItemArray.count - 1;
            }
        }
    }
    MSSBrowseLocalViewController *bvc = [[MSSBrowseLocalViewController alloc] initWithBrowseItemArray:browseItemArray currentIndex:currentImageIndex];
    self.isShowingOhterView = YES;
    [self presentViewController:bvc animated:NO completion:nil];
}

- (void)textMessageCellDidTapOnPhoneNumber:(GJGCChatBaseCell *)tapedCell withPhoneNumber:(NSString *)phoneNumber {

    [self.view endEditing:YES];
    NSString *title = [NSString stringWithFormat:LMLocalizedString(@"Chat may be a phone number you can", nil), phoneNumber];
    UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:LMLocalizedString(@"Common Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:LMLocalizedString(@"Chat Call", nil), LMLocalizedString(@"Set Copy", nil), nil];
    action.tag = GJGCActionSheetCallPhoneNumberTag;
    objc_setAssociatedObject(action, &GJGCActionSheetAssociateKey, phoneNumber, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [action showInView:self.view];

}

- (void)textMessageCellDidTapOnUrl:(GJGCChatBaseCell *)tapedCell withUrl:(NSString *)url {
    if (![url hasPrefix:@"http://"] && ![url hasPrefix:@"https://"]) {
        url = [NSString stringWithFormat:@"http://%@", url];
    }
    if ([url isiTunesURL]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        return;
    }
    CommonClausePage *page = [[CommonClausePage alloc] initWithUrl:url];
    [self.navigationController pushViewController:page animated:YES];
}

- (void)chatCellDidChooseRetweetMessage:(GJGCChatBaseCell *)tappedCell {

    NSIndexPath *tapIndexPath = [self.chatListTable indexPathForCell:tappedCell];
    GJGCChatFriendContentModel *contentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:tapIndexPath.row];
    LMRerweetModel *retweetModel = [[LMRerweetModel alloc] init];

    MMMessage *retweetMessage = [self.dataSourceManager messageByMessageId:contentModel.localMsgId];
    retweetModel.retweetMessage = retweetMessage;
    switch (contentModel.contentType) {
        case GJGCChatFriendContentTypeImage: {
            retweetModel.thumData = GJCFFileRead(contentModel.thumbImageCachePath);
            retweetModel.fileData = GJCFFileRead(contentModel.imageOriginDataCachePath);
        }
            break;

        case GJGCChatFriendContentTypeVideo: {
            retweetModel.thumData = GJCFFileRead(contentModel.videoOriginCoverImageCachePath);
            retweetModel.fileData = GJCFFileRead(contentModel.videoOriginDataPath);
        }
            break;

        default:
            break;
    }
    ReconmandChatListPage *page = [[ReconmandChatListPage alloc] initWithRetweetModel:retweetModel];
    page.title = LMLocalizedString(@"Chat Message retweet", nil);
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:page];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)chatCellDidChooseDeleteMessage:(GJGCChatBaseCell *)tapedCell {
    NSIndexPath *tapIndexPath = [self.chatListTable indexPathForCell:tapedCell];
    GJGCChatFriendContentModel *contentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:tapIndexPath.row];

    [self cancelDownloadAtIndexPath:tapIndexPath];

    [self stopPlayCurrentAudio];
    [ChatMessageFileManager deleteRecentChatMessageFileByMessageID:contentModel.localMsgId Address:[KeyHandle getAddressByPubkey:self.taklInfo.chatIdendifier]];
    [[MessageDBManager sharedManager] deleteMessageByMessageId:contentModel.localMsgId messageOwer:self.taklInfo.chatIdendifier];

    NSArray *willDeletePaths = [self.dataSourceManager deleteMessageAtIndex:tapIndexPath.row];

    if (willDeletePaths && willDeletePaths.count > 0) {

        if (contentModel.isFromSelf) {
            [self.chatListTable deleteRowsAtIndexPaths:willDeletePaths withRowAnimation:UITableViewRowAnimationRight];
        } else {
            [self.chatListTable deleteRowsAtIndexPaths:willDeletePaths withRowAnimation:UITableViewRowAnimationLeft];
        }
    }
}

- (void)chatCellDidChooseReSendMessage:(GJGCChatBaseCell *)tapedCell {

    NSIndexPath *tapIndexPath = [self.chatListTable indexPathForCell:tapedCell];
    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:tapIndexPath.row];

    chatContentModel.senderAddress = [[LKUserCenter shareCenter] currentLoginUser].address;
    chatContentModel.senderHeadUrl = [[LKUserCenter shareCenter] currentLoginUser].avatar;
    chatContentModel.senderPublicKey = [[LKUserCenter shareCenter] currentLoginUser].pub_key;
    chatContentModel.senderName = [NSMutableString stringWithFormat:@"%@", [[LKUserCenter shareCenter] currentLoginUser].username];

    chatContentModel.reciverAddress = self.taklInfo.talkType == GJGCChatFriendTalkTypeGroup ? self.taklInfo.chatGroupInfo.groupIdentifer : self.taklInfo.chatUser.address;
    chatContentModel.reciverHeadUrl = self.taklInfo.headUrl;
    chatContentModel.reciverPublicKey = self.taklInfo.chatIdendifier;
    chatContentModel.reciverName = self.taklInfo.name;

    chatContentModel.headUrl = [[LKUserCenter shareCenter] currentLoginUser].avatar;

    [self.dataSourceManager reSendMesssage:chatContentModel];
}


- (void)chatCellDidTapOnHeadView:(GJGCChatBaseCell *)tapedCell {
    NSIndexPath *tapIndexPath = [self.chatListTable indexPathForCell:tapedCell];
    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:tapIndexPath.row];
    if (chatContentModel.isFromSelf) {

    } else {
        AccountInfo *info = nil;
        if (self.taklInfo.talkType == GJGCChatFriendTalkTypeGroup) {
            for (AccountInfo *groupUser in self.taklInfo.chatGroupInfo.groupMembers) {
                if ([groupUser.address isEqualToString:chatContentModel.senderAddress]) {
                    info = [[UserDBManager sharedManager] getUserByAddress:groupUser.address];
                    if (!info) {
                        info = groupUser;
                        info.stranger = YES;
                    }
                    break;
                }
            }
        } else {
            info = self.taklInfo.chatUser;
            if (!info) {
                info = [[UserDBManager sharedManager] getUserByPublickey:self.taklInfo.chatIdendifier];
            }
        }
        if (!info) {
            return;
        }
        if (!info.stranger) {
            if (self.taklInfo.talkType == GJGCChatFriendTalkTypePostSystem) {
                return;
            }
            UserDetailPage *page = [[UserDetailPage alloc] initWithUser:info];
            [self.navigationController pushViewController:page animated:YES];
        } else {
            InviteUserPage *page = [[InviteUserPage alloc] initWithUser:info];
            page.sourceType = UserSourceTypeTransaction;
            [self.navigationController pushViewController:page animated:YES];
        }
    }
}

- (void)mapLocationMessageCellDidTap:(GJGCChatBaseCell *)tapedCell {

    NSIndexPath *tapIndexPath = [self.chatListTable indexPathForCell:tapedCell];

    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:tapIndexPath.row];


    MapLocationViewController *locationPage = [[MapLocationViewController alloc] initWithLatitude:chatContentModel.locationLatitude longitude:chatContentModel.locationLongitude];

    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:locationPage] animated:YES completion:nil];
}


- (void)chatCellDidTapOnGroupInfoCard:(GJGCChatBaseCell *)tappedCell {
    NSIndexPath *tapIndexPath = [self.chatListTable indexPathForCell:tappedCell];
    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:tapIndexPath.row];
    if (chatContentModel.isFromSelf) {

    } else {
        LMBaseSSDBManager *ssdbManager = [LMBaseSSDBManager open:@"system_message"];
        NSData *data = nil;
        [ssdbManager get:chatContentModel.groupIdentifier data:&data];
        ReviewedResponse *reviewedRes = [ReviewedResponse parseFromData:data error:nil];
        [ssdbManager close];
        if (data && reviewedRes) {
            NSString *message = [NSString stringWithFormat:LMLocalizedString(@"Link You apply to join has passed", nil), reviewedRes.name];
            if (!reviewedRes.success) {
                message = [NSString stringWithFormat:LMLocalizedString(@"Link You apply to join rejected", nil), reviewedRes.name];
            }
            [UIAlertController showAlertInViewController:self withTitle:nil message:message cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@[LMLocalizedString(@"Common OK", nil)] tapBlock:nil];
            return;
        }
        LMApplyJoinToGroupViewController *page = [[LMApplyJoinToGroupViewController alloc] initWithGroupIdentifier:chatContentModel.groupIdentifier inviteToken:chatContentModel.inviteToken inviteByAddress:self.taklInfo.chatUser.address];
        [self.navigationController pushViewController:page animated:YES];
    }
}

- (void)chatCellDidTapOnNameCard:(GJGCChatBaseCell *)tappedCell {

    NSIndexPath *tapIndexPath = [self.chatListTable indexPathForCell:tappedCell];

    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:tapIndexPath.row];
    AccountInfo *user = [[UserDBManager sharedManager] getUserByAddress:chatContentModel.contactAddress];
    user.stranger = NO;
    if (!user) {
        user = [[AccountInfo alloc] init];
        user.address = chatContentModel.contactAddress;
        user.avatar = chatContentModel.contactAvatar;
        user.username = chatContentModel.contactName.string;
        user.pub_key = chatContentModel.contactPublickey;
        user.stranger = YES;

        InviteUserPage *page = [[InviteUserPage alloc] initWithUser:user];
        page.sourceType = UserSourceTypeRecommend;
        [self.navigationController pushViewController:page animated:YES];
    } else {
        UserDetailPage *page = [[UserDetailPage alloc] initWithUser:user];
        [self.navigationController pushViewController:page animated:YES];
    }
}


- (void)redBagCellDidTap:(GJGCChatBaseCell *)tappedCell {

    __weak __typeof(&*self) weakSelf = self;
    [MBProgressHUD showLoadingMessageToView:self.view];
    NSIndexPath *tapIndexPath = [self.chatListTable indexPathForCell:tappedCell];
    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:tapIndexPath.row];
    if (self.taklInfo.talkType == GJGCChatFriendTalkTypeGroup) {
        [self grabRedBagWithHashId:chatContentModel.hashID senderName:chatContentModel.senderName sendAddress:chatContentModel.senderAddress];
    } else {
        if (!chatContentModel.isFromSelf) {
            [self grabRedBagWithHashId:chatContentModel.hashID senderName:chatContentModel.senderName sendAddress:chatContentModel.senderAddress];
        } else {
            [RedBagNetWorkTool getRedBagDetailWithHashId:chatContentModel.hashID complete:^(RedPackageInfo *bagInfo, NSError *error) {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD hideHUDForView:weakSelf.view];
                }];
                if (error) {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Request sent failed Please try again later", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                    }];
                    return;
                }
                LMChatRedLuckyDetailController *page = [[LMChatRedLuckyDetailController alloc] initWithUserInfo:[[LKUserCenter shareCenter] currentLoginUser] redLuckyInfo:bagInfo];
                [GCDQueue executeInMainQueue:^{
                    [weakSelf presentViewController:[[UINavigationController alloc] initWithRootViewController:page] animated:YES completion:nil];
                }];
            }];
        }
    }
}

- (void)grabRedBagWithHashId:(NSString *)hashId senderName:(NSString *)senderName sendAddress:(NSString *)sendAddress {
    [RedBagNetWorkTool grabRedBagWithHashId:hashId complete:^(GrabRedPackageResp *response, NSError *error) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:self.view];
        }];
        if (error) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Chat Network connection failed please check network", nil) withType:ToastTypeFail showInView:self.view complete:nil];
            }];
        } else {
            switch (response.status) {
                case 0://fail
                {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"ErrorCode Error", nil) withType:ToastTypeFail showInView:self.view complete:nil];
                    }];
                }
                    break;
                case 1://success
                {
                    if (![senderName isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].normalShowName]) {
                        NSString *operation = [NSString stringWithFormat:@"%@/%@", self.taklInfo.chatUser.address, [[LKUserCenter shareCenter] currentLoginUser].address];
                        if (self.taklInfo.talkType == GJGCChatFriendTalkTypeGroup) {
                            operation = [NSString stringWithFormat:@"%@/%@", sendAddress, [[LKUserCenter shareCenter] currentLoginUser].address];
                        }
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
                case 2: //garbed
                {
                    [self showRedBagDetailWithHashId:hashId];
                }
                    break;
                case 3: //fail
                case 4: {
                    LMRedLuckyShowView *redLuckyView = [[LMRedLuckyShowView alloc] initWithFrame:[UIScreen mainScreen].bounds redLuckyGifImages:nil];
                    redLuckyView.hashId = hashId;
                    [redLuckyView setDelegate:self];
                    [redLuckyView showRedLuckyViewIsGetARedLucky:NO];
                }
                default:
                    break;
            }
        }
    }];

}

- (void)getSystemRedBagDetailWithHashId:(NSString *)hashId {
    __weak __typeof(&*self) weakSelf = self;
    [RedBagNetWorkTool getSystemRedBagDetailWithHashId:hashId complete:^(RedPackageInfo *bagInfo, NSError *error) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:weakSelf.view];
        }];
        if (error) {
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Network equest failed please try again later", nil) withType:ToastTypeFail showInView:self.view complete:nil];
            return;
        }
        if (bagInfo.redpackage.system) {
            LMChatRedLuckyDetailController *page = [[LMChatRedLuckyDetailController alloc] initWithUserInfo:nil redLuckyInfo:bagInfo];
            [GCDQueue executeInMainQueue:^{
                [weakSelf presentViewController:[[UINavigationController alloc] initWithRootViewController:page] animated:YES completion:nil];
            }];
        } else {
            AccountInfo *user = nil;
            NSString *address = bagInfo.redpackage.sendAddress;
            if ([address isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                user = [[LKUserCenter shareCenter] currentLoginUser];
            } else {
                if (self.taklInfo.talkType == GJGCChatFriendTalkTypeGroup) {
                    user = [[GroupDBManager sharedManager] getGroupMemberByGroupId:self.taklInfo.chatIdendifier memberAddress:address];
                } else {
                    user = [[UserDBManager sharedManager] getUserByAddress:bagInfo.redpackage.sendAddress];
                }
            }
            if (!user) {
                SearchUser *usrAddInfo = [[SearchUser alloc] init];
                usrAddInfo.criteria = address;
                [NetWorkOperationTool POSTWithUrlString:ContactUserSearchUrl postProtoData:usrAddInfo.data complete:^(id response) {
                    NSError *error;
                    HttpResponse *respon = (HttpResponse *) response;
                    if (respon.code != successCode) {
                        [GCDQueue executeInMainQueue:^{
                            [MBProgressHUD showToastwithText:LMLocalizedString(@"Server error", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                        }];
                    }
                    NSData *data = [ConnectTool decodeHttpResponse:respon];
                    if (data) {
                        UserInfo *info = [[UserInfo alloc] initWithData:data error:&error];
                        AccountInfo *accoutInfo = [[AccountInfo alloc] init];
                        accoutInfo.username = info.username;
                        accoutInfo.avatar = info.avatar;
                        accoutInfo.pub_key = info.pubKey;
                        accoutInfo.address = info.address;

                        if (error) {

                        } else {
                            LMChatRedLuckyDetailController *page = [[LMChatRedLuckyDetailController alloc] initWithUserInfo:accoutInfo redLuckyInfo:bagInfo];
                            page.groupMembers = self.taklInfo.chatGroupInfo.groupMembers;
                            [self presentViewController:[[UINavigationController alloc] initWithRootViewController:page] animated:YES completion:nil];
                        }
                    }
                }                                  fail:^(NSError *error) {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                    }];
                }];
            } else {
                LMChatRedLuckyDetailController *page = [[LMChatRedLuckyDetailController alloc] initWithUserInfo:user redLuckyInfo:bagInfo];
                [GCDQueue executeInMainQueue:^{
                    [weakSelf presentViewController:[[UINavigationController alloc] initWithRootViewController:page] animated:YES completion:nil];
                }];
            }
        }
    }];

}


- (void)showRedBagDetailWithHashId:(NSString *)hashId {
    __weak __typeof(&*self) weakSelf = self;
    [RedBagNetWorkTool getRedBagDetailWithHashId:hashId complete:^(RedPackageInfo *bagInfo, NSError *error) {
        if (error) {
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Network equest failed please try again later", nil) withType:ToastTypeFail showInView:self.view complete:nil];
            return;
        }
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:weakSelf.view];
        }];
        AccountInfo *user = nil;
        NSString *address = bagInfo.redpackage.sendAddress;
        if ([address isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
            user = [[LKUserCenter shareCenter] currentLoginUser];
        } else {
            if (self.taklInfo.talkType == GJGCChatFriendTalkTypeGroup) {
                user = [[GroupDBManager sharedManager] getGroupMemberByGroupId:self.taklInfo.chatIdendifier memberAddress:address];
            } else {
                user = [[UserDBManager sharedManager] getUserByAddress:bagInfo.redpackage.sendAddress];
            }
        }
        if (!user) {
            SearchUser *usrAddInfo = [[SearchUser alloc] init];
            usrAddInfo.criteria = address;
            [NetWorkOperationTool POSTWithUrlString:ContactUserSearchUrl postProtoData:usrAddInfo.data complete:^(id response) {
                NSError *error;
                HttpResponse *respon = (HttpResponse *) response;
                if (respon.code != successCode) {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                    }];
                }
                NSData *data = [ConnectTool decodeHttpResponse:respon];
                if (data) {
                    UserInfo *info = [[UserInfo alloc] initWithData:data error:&error];
                    AccountInfo *accoutInfo = [[AccountInfo alloc] init];
                    accoutInfo.username = info.username;
                    accoutInfo.avatar = info.avatar;
                    accoutInfo.pub_key = info.pubKey;
                    accoutInfo.address = info.address;

                    if (error) {

                    } else {
                        LMChatRedLuckyDetailController *page = [[LMChatRedLuckyDetailController alloc] initWithUserInfo:accoutInfo redLuckyInfo:bagInfo];
                        page.groupMembers = self.taklInfo.chatGroupInfo.groupMembers;
                        [self presentViewController:[[UINavigationController alloc] initWithRootViewController:page] animated:YES completion:nil];
                    }
                }
            }                                  fail:^(NSError *error) {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                }];
            }];
        } else {
            LMChatRedLuckyDetailController *page = [[LMChatRedLuckyDetailController alloc] initWithUserInfo:user redLuckyInfo:bagInfo];
            [GCDQueue executeInMainQueue:^{
                [weakSelf presentViewController:[[UINavigationController alloc] initWithRootViewController:page] animated:YES completion:nil];
            }];
        }
    }];

}

/**
 *  receipt cell tap
 *
 *  @param tapedCell
 */
- (void)payOrReceiptCellDidTap:(GJGCChatBaseCell *)tapedCell {

    [MBProgressHUD showLoadingMessageToView:self.view];

    NSIndexPath *tapIndexPath = [self.chatListTable indexPathForCell:tapedCell];

    __weak typeof(self) weakSelf = self;
    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:tapIndexPath.row];

    if (chatContentModel.isCrowdfundRceipt) {
        [WallteNetWorkTool crowdfuningInfoWithHashID:chatContentModel.hashID complete:^(NSError *erro, Crowdfunding *crowdInfo) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD hideHUDForView:weakSelf.view];
                if (erro) {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                    }];
                } else {
                    int payCount = (int) (crowdInfo.size - crowdInfo.remainSize);
                    NSAttributedString *statusTipsStr = [GJGCChatSystemNotiCellStyle formateRecieptSubTipsWithTotal:(int) crowdInfo.size payCount:payCount isCrowding:YES transStatus:(int) crowdInfo.status];
                    if (![statusTipsStr.string isEqualToString:chatContentModel.payOrReceiptStatusMessage.string]) {
                        chatContentModel.payOrReceiptStatusMessage = statusTipsStr;
                        [self.chatListTable reloadData];
                        [[LMMessageExtendManager sharedManager] updateMessageExtendPayCount:(int) (crowdInfo.size - crowdInfo.remainSize) status:(int) crowdInfo.status withHashId:crowdInfo.hashId];
                    }
                    if (chatContentModel.isFromSelf) {
                        LMGroupZChouReciptViewController *reciptVc = [[LMGroupZChouReciptViewController alloc] initWithCrowdfundingInfo:crowdInfo];
                        [self.navigationController pushViewController:reciptVc animated:YES];
                    } else {
                        for (AccountInfo *member in self.taklInfo.chatGroupInfo.groupMembers) {
                            if ([member.address isEqualToString:crowdInfo.sender.address]) {
                                crowdInfo.sender.username = member.groupShowName;
                                break;
                            }
                        }
                        LMGroupZChouTransViewController *tranferVc = [[LMGroupZChouTransViewController alloc] initWithCrowdfundingInfo:crowdInfo];
                        tranferVc.PaySuccessCallBack = ^(Crowdfunding *payedCrowding) {
                            [GCDQueue executeInMainQueue:^{
                                int payCount = (int) (payedCrowding.size - payedCrowding.remainSize);
                                chatContentModel.payOrReceiptStatusMessage = [GJGCChatSystemNotiCellStyle formateRecieptSubTipsWithTotal:(int) payedCrowding.size payCount:payCount isCrowding:YES transStatus:(int) payedCrowding.status];
                                [self.chatListTable reloadData];
                                ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
                                chatMessage.messageId = [ConnectTool generateMessageId];
                                chatMessage.messageOwer = weakSelf.taklInfo.chatIdendifier;
                                chatMessage.messageType = GJGCChatFriendContentTypeStatusTip;
                                chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                                chatMessage.createTime = (NSInteger) ([[NSDate date] timeIntervalSince1970] * 1000);
                                MMMessage *message = [[MMMessage alloc] init];
                                message.type = GJGCChatFriendContentTypeStatusTip;
                                message.content = [GJGCChatSystemNotiCellStyle formateReceiptTipWithPayName:[[LKUserCenter shareCenter] currentLoginUser].username receiptName:crowdInfo.sender.username isCrowding:YES].string;
                                message.ext1 = @(3);
                                message.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
                                message.message_id = chatMessage.messageId;
                                message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                                chatMessage.message = message;
                                [GCDQueue executeInGlobalQueue:^{
                                    [[MessageDBManager sharedManager] saveMessage:chatMessage];
                                }];

                                [weakSelf.dataSourceManager showReceiptMessageMessageWithPayName:[[LKUserCenter shareCenter] currentLoginUser].username receiptName:crowdInfo.sender.username isCrowd:YES];
                                if (crowdInfo.remainSize == 0) {
                                    ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
                                    chatMessage.messageId = [ConnectTool generateMessageId];
                                    chatMessage.messageOwer = weakSelf.taklInfo.chatIdendifier;
                                    chatMessage.messageType = GJGCChatFriendContentTypeStatusTip;
                                    chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                                    chatMessage.createTime = (long long) ([[NSDate date] timeIntervalSince1970] * 1000);
                                    MMMessage *message = [[MMMessage alloc] init];
                                    message.type = GJGCChatFriendContentTypeStatusTip;
                                    message.content = LMLocalizedString(@"Chat Founded complete", nil);
                                    message.sendtime = chatMessage.createTime;
                                    message.message_id = chatMessage.messageId;
                                    message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                                    chatMessage.message = message;
                                    [GCDQueue executeInGlobalQueue:^{
                                        [[MessageDBManager sharedManager] saveMessage:chatMessage];
                                    }];
                                    [weakSelf.dataSourceManager showCrowdingCompleteMessage];
                                }
                            }];
                        };
                        [self.navigationController pushViewController:tranferVc animated:YES];
                    }
                }
            }];
        }];
    } else {
        [WallteNetWorkTool queryBillInfoWithTransactionhashId:chatContentModel.hashID complete:^(NSError *erro, Bill *bill) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD hideHUDForView:weakSelf.view];
            }];
            BOOL isFrom = chatContentModel.isFromSelf;
            if (isFrom) {
                LMReciptNotesViewController *noteVc = [[LMReciptNotesViewController alloc] init];
                noteVc.user = self.taklInfo.chatUser;
                noteVc.PayStatus = bill.status;
                noteVc.bill = bill;
                [weakSelf.navigationController pushViewController:noteVc animated:YES];

                int status = [[LMMessageExtendManager sharedManager] getStatus:chatContentModel.hashID];
                if (status != bill.status) {
                    //更新服务器状态
                    [[LMMessageExtendManager sharedManager] updateMessageExtendStatus:bill.status withHashId:chatContentModel.hashID];
                    //刷新界面
                    chatContentModel.payOrReceiptStatusMessage = [GJGCChatSystemNotiCellStyle formateRecieptSubTipsWithTotal:1 payCount:1 isCrowding:NO transStatus:bill.status];
                    [GCDQueue executeInMainQueue:^{
                        [self.chatListTable reloadData];
                    }];
                }
            } else {
                LMTransferNotesViewController *transferVc = [[LMTransferNotesViewController alloc] init];
                transferVc.reciverUser = self.taklInfo.chatUser;
                transferVc.bill = bill;
                transferVc.PayResultBlock = ^(BOOL result) {
                    if (result) {
                        [GCDQueue executeInMainQueue:^{
                            chatContentModel.payOrReceiptStatusMessage = [GJGCChatSystemNotiCellStyle formateRecieptSubTipsWithTotal:1 payCount:1 isCrowding:NO transStatus:1];
                            [self.chatListTable reloadData];
                            ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
                            chatMessage.messageId = [ConnectTool generateMessageId];
                            chatMessage.messageOwer = weakSelf.taklInfo.chatIdendifier;
                            chatMessage.messageType = GJGCChatFriendContentTypeStatusTip;
                            chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                            chatMessage.createTime = (NSInteger) ([[NSDate date] timeIntervalSince1970] * 1000);
                            MMMessage *message = [[MMMessage alloc] init];
                            message.type = GJGCChatFriendContentTypeStatusTip;
                            message.content = [GJGCChatSystemNotiCellStyle formateReceiptTipWithPayName:[[LKUserCenter shareCenter] currentLoginUser].username receiptName:chatContentModel.senderName isCrowding:NO].string;
                            message.ext1 = @(3);
                            message.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
                            message.message_id = chatMessage.messageId;
                            message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
                            chatMessage.message = message;
                            [GCDQueue executeInGlobalQueue:^{
                                [[MessageDBManager sharedManager] saveMessage:chatMessage];
                            }];
                            [weakSelf.dataSourceManager showReceiptMessageMessageWithPayName:[[LKUserCenter shareCenter] currentLoginUser].normalShowName receiptName:chatContentModel.senderName isCrowd:NO];
                        }];
                    }
                };
                [weakSelf.navigationController pushViewController:transferVc animated:YES];
            }
        }];
    }
}

- (void)transforCellDidTap:(GJGCChatBaseCell *)tapedCell {
    [MBProgressHUD showLoadingMessageToView:self.view];
    NSIndexPath *tapIndexPath = [self.chatListTable indexPathForCell:tapedCell];
    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:tapIndexPath.row];

    __weak typeof(self) weakself = self;
    AccountInfo *user = self.taklInfo.chatUser;
    if (!user) {
        user = [[UserDBManager sharedManager] getUserByPublickey:self.taklInfo.chatIdendifier];
    }

    if (chatContentModel.isOuterTransfer) {
        [WallteNetWorkTool queryOuterBillInfoWithTransactionhashId:chatContentModel.hashID complete:^(NSError *erro, Bill *bill) {
            [MBProgressHUD hideHUDForView:weakself.view];
            LMReciptNotesViewController *noteVc = [[LMReciptNotesViewController alloc] init];
            noteVc.user = user;
            noteVc.PayStatus = YES;
            noteVc.bill = bill;
            [weakself.navigationController pushViewController:noteVc animated:YES];
            if (bill.status == 2) {
                chatContentModel.transferStatusMessage = [GJGCChatSystemNotiCellStyle formateRecieptSubTipsWithTotal:1 payCount:1 isCrowding:NO transStatus:2];
                [GCDQueue executeInMainQueue:^{
                    [self.chatListTable reloadData];
                }];
            }
        }];
    } else {
        [WallteNetWorkTool queryBillInfoWithTransactionhashId:chatContentModel.hashID complete:^(NSError *erro, Bill *bill) {
            [MBProgressHUD hideHUDForView:weakself.view];
            LMReciptNotesViewController *noteVc = [[LMReciptNotesViewController alloc] init];
            noteVc.user = user;
            noteVc.PayStatus = YES;
            noteVc.bill = bill;
            [weakself.navigationController pushViewController:noteVc animated:YES];
            if (bill.status == 2) {
                chatContentModel.transferStatusMessage = [GJGCChatSystemNotiCellStyle formateRecieptSubTipsWithTotal:1 payCount:1 isCrowding:NO transStatus:2];
                [GCDQueue executeInMainQueue:^{
                    [self.chatListTable reloadData];
                }];
            }
        }];
    }
}


- (void)noRelationShipTapAddFriend:(GJGCChatBaseCell *)tapedCell {
    if (self.taklInfo.chatUser.stranger) {
        self.taklInfo.chatUser.stranger = ![[UserDBManager sharedManager] isFriendByAddress:self.taklInfo.chatUser.address];
    }
    if (self.taklInfo.chatUser.stranger) {
        InviteUserPage *page = [[InviteUserPage alloc] initWithUser:self.taklInfo.chatUser];
        page.sourceType = UserSourceTypeTransaction;
        [self.navigationController pushViewController:page animated:YES];
    } else {
        UserDetailPage *page = [[UserDetailPage alloc] initWithUser:self.taklInfo.chatUser];
        [self.navigationController pushViewController:page animated:YES];
    }
}

- (void)chatCellDidTapWalletLinkMessage:(GJGCChatBaseCell *)tapedCell {
    NSIndexPath *tapIndexPath = [self.chatListTable indexPathForCell:tapedCell];
    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:tapIndexPath.row];
    NSURL *url = [NSURL URLWithString:chatContentModel.originTextMessage];
    NSURL *openUrl = nil;
    switch (chatContentModel.walletLinkType) {
        case LMWalletlinkTypeOuterTransfer: {
            NSString *token = [url valueForParameter:@"token"];
            openUrl = [NSURL URLWithString:[NSString stringWithFormat:@"connectim://transfer?token=%@", token]];
            [HandleUrlManager handleOpenURL:openUrl];
        }
            break;
        case LMWalletlinkTypeOuterPacket: {
            [MBProgressHUD showLoadingMessageToView:self.view];
            NSString *token = [url valueForParameter:@"token"];
            [NetWorkOperationTool POSTWithUrlString:QueryRedpackgeWithToken(token) postProtoData:nil complete:^(id response) {
                HttpResponse *hResponse = (HttpResponse *) response;
                if (hResponse.code != successCode) {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Set Load failed please try again later", nil) withType:ToastTypeFail showInView:self.view complete:nil];
                    }];
                } else {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD hideHUDForView:self.view];
                    }];
                    NSData *data = [ConnectTool decodeHttpResponse:hResponse];
                    if (data) {
                        RedPackage *redpackge = [RedPackage parseFromData:data error:nil];
                        if (redpackge.remainSize == 0) {
                            if (!redpackge.system) {
                                [self showRedBagDetailWithHashId:redpackge.hashId];
                            } else {
                                [self getSystemRedBagDetailWithHashId:redpackge.hashId];
                            }
                        } else {
                            NSURL *openUrl = [NSURL URLWithString:[NSString stringWithFormat:@"connectim://packet?token=%@", token]];
                            [HandleUrlManager handleOpenURL:openUrl];
                        }
                    }
                }
            }                                  fail:^(NSError *error) {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Set Load failed please try again later", nil) withType:ToastTypeFail showInView:self.view complete:nil];
                }];
            }];
        }
            break;
        case LMWalletlinkTypeOuterCollection: {
            NSString *address = [url valueForParameter:@"address"];
            NSDecimalNumber *decimalAmount = nil;
            if ([url valueForParameter:@"amount"]) {
                decimalAmount = [NSDecimalNumber decimalNumberWithString:[url valueForParameter:@"amount"]];
            }
            if (GJCFStringIsNull(address) || decimalAmount.doubleValue < 0 || ![KeyHandle checkAddress:address]) {
                [MBProgressHUD showToastwithText:LMLocalizedString(@"ErrorCode data error", nil) withType:ToastTypeFail showInView:self.view complete:nil];
                return;
            }
            if (decimalAmount.doubleValue > 0) {
                AccountInfo *info = [[UserDBManager sharedManager] getUserByAddress:address];
                if (info) {
                    LMSetMoneyResultViewController *unsetVc = [[LMSetMoneyResultViewController alloc] init];
                    unsetVc.info = info;
                    unsetVc.trasferAmount = [NSDecimalNumber decimalNumberWithString:decimalAmount.stringValue];
                    unsetVc.hidesBottomBarWhenPushed = YES;
                    [self.navigationController pushViewController:unsetVc animated:YES];
                } else {
                    SearchUser *usrAddInfo = [[SearchUser alloc] init];
                    usrAddInfo.criteria = address;
                    [NetWorkOperationTool POSTWithUrlString:ContactUserSearchUrl postProtoData:usrAddInfo.data complete:^(id response) {
                        NSError *error;
                        HttpResponse *respon = (HttpResponse *) response;
                        NSData *data = [ConnectTool decodeHttpResponse:respon];
                        if (data) {
                            UserInfo *info = [[UserInfo alloc] initWithData:data error:&error];
                            if (error) {
                                return;
                            }
                            AccountInfo *accoutInfo = [[AccountInfo alloc] init];
                            accoutInfo.username = info.username;
                            accoutInfo.avatar = info.avatar;
                            accoutInfo.pub_key = info.pubKey;
                            accoutInfo.address = info.address;
                            [GCDQueue executeInMainQueue:^{
                                LMSetMoneyResultViewController *unsetVc = [[LMSetMoneyResultViewController alloc] init];
                                unsetVc.info = accoutInfo;
                                unsetVc.trasferAmount = [NSDecimalNumber decimalNumberWithString:decimalAmount.stringValue];
                                unsetVc.hidesBottomBarWhenPushed = YES;
                                [self.navigationController pushViewController:unsetVc animated:YES];
                            }];
                        } else {
                            return;
                        }
                    }                                  fail:^(NSError *error) {
                        [GCDQueue executeInMainQueue:^{
                            [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:self.view complete:nil];
                        }];

                    }];
                }
            } else {
                AccountInfo *info = [[UserDBManager sharedManager] getUserByAddress:address];
                if (info) {
                    LMUnSetMoneyResultViewController *unsetVc = [[LMUnSetMoneyResultViewController alloc] init];
                    unsetVc.info = info;
                    unsetVc.hidesBottomBarWhenPushed = YES;
                    [self.navigationController pushViewController:unsetVc animated:YES];
                } else {
                    SearchUser *usrAddInfo = [[SearchUser alloc] init];
                    usrAddInfo.criteria = address;
                    [NetWorkOperationTool POSTWithUrlString:ContactUserSearchUrl postProtoData:usrAddInfo.data complete:^(id response) {
                        NSError *error;
                        HttpResponse *respon = (HttpResponse *) response;
                        if (respon.code != successCode) {
                            return;
                        }
                        NSData *data = [ConnectTool decodeHttpResponse:respon];
                        if (data) {
                            UserInfo *info = [[UserInfo alloc] initWithData:data error:&error];
                            if (error) {
                                return;
                            }
                            AccountInfo *accoutInfo = [[AccountInfo alloc] init];
                            accoutInfo.username = info.username;
                            accoutInfo.avatar = info.avatar;
                            accoutInfo.pub_key = info.pubKey;
                            accoutInfo.address = info.address;
                            [GCDQueue executeInMainQueue:^{
                                LMUnSetMoneyResultViewController *unsetVc = [[LMUnSetMoneyResultViewController alloc] init];
                                unsetVc.info = accoutInfo;
                                unsetVc.hidesBottomBarWhenPushed = YES;
                                [self.navigationController pushViewController:unsetVc animated:YES];
                            }];
                        }
                    }                                  fail:^(NSError *error) {
                        [GCDQueue executeInMainQueue:^{
                            [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:self.view complete:nil];
                        }];
                    }];
                }
            }
        }
            break;
        case LMWalletlinkTypeOuterOther: {
            NSString *linkUrl = chatContentModel.originTextMessage;
            if (![linkUrl hasPrefix:@"http://"] && ![linkUrl hasPrefix:@"https://"]) {
                linkUrl = [NSString stringWithFormat:@"http://%@", linkUrl];
            }
            if ([linkUrl isiTunesURL]) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:linkUrl]];
                return;
            }
            CommonClausePage *page = [[CommonClausePage alloc] initWithUrl:linkUrl];
            page.title = chatContentModel.linkTitle;
            [self.navigationController pushViewController:page animated:YES];
        }
            break;
        default:
            break;
    }
}

#pragma mark - lucky packge delegate
- (void)redLuckyShowView:(LMRedLuckyShowView *)showView goRedLuckyDetailWithSender:(UIButton *)sender {
    [showView dismissRedLuckyView];
    [MBProgressHUD showLoadingMessageToView:self.view];
    [self showRedBagDetailWithHashId:showView.hashId];
}

#pragma mark - textFieldChange -delegate
- (void)textFieldChange:(UITextField *)currentTextField {
    if (currentTextField.text.length > 20) {
        currentTextField.text = [currentTextField.text substringToIndex:20];
    }
}

#pragma mark UIActionSheet methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == GJGCActionSheetCallPhoneNumberTag) {

        switch (buttonIndex) {
            case 0: {
                NSString *phoneNumber = objc_getAssociatedObject(actionSheet, &GJGCActionSheetAssociateKey);

                [self makePhoneCall:phoneNumber];

                objc_removeAssociatedObjects(actionSheet);

            }
                break;
            case 1: {
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                NSString *phoneNumber = objc_getAssociatedObject(actionSheet, &GJGCActionSheetAssociateKey);
                [pasteboard setString:phoneNumber];
                objc_removeAssociatedObjects(actionSheet);

            }
                break;

            default:
                break;
        }
    }
}

#pragma mark - open or close snapchat

- (void)enterSnapchatModeWithTime:(int)time {
    self.titleView.chatStyle = ChatPageTitleViewStyleSnapChat;
    [self.dataSourceManager openSnapChatModeWithTime:time];

    if (![[MMAppSetting sharedSetting] isDontShowSnapchatTip]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LMLocalizedString(@"Chat Enable Self destruct Mode", nil) message:LMLocalizedString(@"Chat Hide  messages ", nil) preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Chat I know", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
            [[MMAppSetting sharedSetting] setDontShowSnapchatTip];
        }];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)quitSnapChatMode {
    self.titleView.chatStyle = ChatPageTitleViewStyleNomarl;
    [self.dataSourceManager closeSnapChatMode];
}

#pragma mark - call phone

- (void)makePhoneCall:(NSString *)phoneNumber {
    if (!self.callWebview) {
        self.callWebview = [[UIWebView alloc] initWithFrame:CGRectZero];

    }
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", phoneNumber]];
    if (!GJCFSystemCanMakePhoneCall) {
        return;
    }

    [self.callWebview loadRequest:[NSURLRequest requestWithURL:url]];
}

#pragma mark - audio play

- (void)downloadAndPlayAudioAtRowIndex:(NSIndexPath *)rowIndex {
    GJGCChatFriendContentModel *contentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:rowIndex.row];

    GJGCChatFriendAudioMessageCell *audioCell = (GJGCChatFriendAudioMessageCell *) [self.chatListTable cellForRowAtIndexPath:rowIndex];
    if ([audioCell respondsToSelector:@selector(startDownloadAction)]) {
        [audioCell startDownloadAction];
    }
    contentModel.isDownloading = YES;

    NSString *taskIdentifier = nil;
    GJCFFileDownloadTask *downloadTask = [GJCFFileDownloadTask taskWithDownloadUrl:contentModel.audioModel.remotePath withCachePath:contentModel.audioModel.downloadEncodeCachePath withObserver:self getTaskIdentifer:&taskIdentifier];

    if (self.taklInfo.talkType != GJGCChatFriendTalkTypePrivate && self.taklInfo.talkType != GJGCChatFriendTalkTypeGroup) {
        downloadTask.unEncodeData = YES;
    } else {
        NSData *ecdhkey = nil;
        if (self.taklInfo.talkType == GJGCChatFriendTalkTypeGroup) {
            ecdhkey = [StringTool hexStringToData:self.taklInfo.chatGroupInfo.groupEcdhKey];
        } else if (self.taklInfo.talkType == GJGCChatFriendTalkTypePrivate) {
            ecdhkey = [KeyHandle getECDHkeyWithPrivkey:[[LKUserCenter shareCenter] currentLoginUser].prikey
                                             publicKey:self.taklInfo.chatIdendifier];
        }
        ecdhkey = [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdhkey salt:[ConnectTool get64ZeroData]];
        downloadTask.ecdhkey = ecdhkey;
    }

    downloadTask.userInfo = @{@"type": @"audio"};
    downloadTask.msgIdentifier = [NSString stringWithFormat:@"%@_%@", self.taklInfo.chatIdendifier, contentModel.localMsgId];
    downloadTask.temOriginFilePath = contentModel.audioModel.localAMRStorePath;

    contentModel.downloadTaskIdentifier = taskIdentifier;

    [self addDownloadTask:downloadTask];
}


- (void)downloadAndPlayVideoAtRowIndex:(NSIndexPath *)rowIndex {
    GJGCChatFriendContentModel *contentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:rowIndex.row];

    NSString *taskIdentifier = nil;
    GJCFFileDownloadTask *downloadTask = [GJCFFileDownloadTask taskWithDownloadUrl:contentModel.videoEncodeUrl withCachePath:contentModel.videoDownVideoEncodePath withObserver:self getTaskIdentifer:&taskIdentifier];

    NSData *ecdhkey = nil;
    if (self.taklInfo.talkType == GJGCChatFriendTalkTypeGroup) {
        ecdhkey = [StringTool hexStringToData:self.taklInfo.chatGroupInfo.groupEcdhKey];
    } else if (self.taklInfo.talkType == GJGCChatFriendTalkTypePrivate) {
        ecdhkey = [KeyHandle getECDHkeyWithPrivkey:[[LKUserCenter shareCenter] currentLoginUser].prikey
                                         publicKey:self.taklInfo.chatIdendifier];
    }
    ecdhkey = [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdhkey salt:[ConnectTool get64ZeroData]];
    downloadTask.ecdhkey = ecdhkey;

    downloadTask.userInfo = @{@"type": @"video"};
    downloadTask.msgIdentifier = [NSString stringWithFormat:@"%@_%@", self.taklInfo.chatIdendifier, contentModel.localMsgId];
    downloadTask.temOriginFilePath = contentModel.videoOriginDataPath;
    contentModel.downloadTaskIdentifier = taskIdentifier;
    [self addDownloadTask:downloadTask];
}

- (void)startPlayCurrentAudio {

    if (!self.playingAudioMsgId) {
        return;
    }

    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];

    NSInteger playingIndex = [self.dataSourceManager getContentModelIndexByLocalMsgId:self.playingAudioMsgId];

    GJGCChatFriendContentModel *contentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:playingIndex];

    if (!contentModel.isFromSelf && !contentModel.isRead) {
        contentModel.isRead = YES;
        [[MessageDBManager sharedManager] updateMessageReadTimeWithMsgID:contentModel.localMsgId messageOwer:self.taklInfo.chatIdendifier];
    }
    contentModel.audioModel.message_id = contentModel.localMsgId;
    NSIndexPath *playingIndexPath = [NSIndexPath indexPathForRow:playingIndex inSection:0];
    if (contentModel.audioIsDownload) {

        if (!GJCFFileIsExist(contentModel.audioModel.tempWamFilePath)) {
            [GJCFEncodeAndDecode convertAudioFileToWAV:contentModel.audioModel];
        }

        [self.audioPlayer playAudioFile:contentModel.audioModel];
        contentModel.isPlayingAudio = YES;
        contentModel.isRead = YES;
        self.isLastPlayedMyAudio = contentModel.isFromSelf;
        [self.dataSourceManager updateContentModelValuesNotEffectRowHeight:contentModel atIndex:playingIndex];

        GJGCChatFriendAudioMessageCell *playingCell = (GJGCChatFriendAudioMessageCell *) [self.chatListTable cellForRowAtIndexPath:playingIndexPath];
        [playingCell playAudioAction];

        [UIDevice currentDevice].proximityMonitoringEnabled = YES;
        RegisterNotify(UIDeviceProximityStateDidChangeNotification, @selector(sensorStateChange:));
        return;
    }

    GJGCChatFriendContentModel *friendContentModel = (GJGCChatFriendContentModel *) contentModel;
    friendContentModel.isDownloading = YES;
    [self.dataSourceManager updateContentModelValuesNotEffectRowHeight:friendContentModel atIndex:playingIndex];

    GJGCChatFriendAudioMessageCell *playingCell = (GJGCChatFriendAudioMessageCell *) [self.chatListTable cellForRowAtIndexPath:playingIndexPath];
    [playingCell startDownloadAction];

    if ([self.downLoadingRichMessageIds containsObject:[NSString stringWithFormat:@"%@_%@", self.taklInfo.chatIdendifier, contentModel.localMsgId]]) {
        return;
    }

    [self downloadAndPlayAudioAtRowIndex:playingIndexPath];

}

#pragma mark - Distance sensor monitoring

- (void)sensorStateChange:(NSNotificationCenter *)notification; {
    if ([[UIDevice currentDevice] proximityState] == YES) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    } else {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    }

}

- (void)stopPlayCurrentAudio {
    if (self.audioPlayer.isPlaying) {
        [self.audioPlayer stop];
    }
    if (self.playingAudioMsgId) {
        NSInteger playingIndex = [self.dataSourceManager getContentModelIndexByLocalMsgId:self.playingAudioMsgId];
        self.lastPlayedAudioMsgIndex = playingIndex;

        if (playingIndex != NSNotFound) {

            GJGCChatFriendContentModel *contentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:playingIndex];
            contentModel.isPlayingAudio = NO;
            contentModel.isDownloading = NO;
            [self.dataSourceManager updateContentModelValuesNotEffectRowHeight:contentModel atIndex:playingIndex];
            self.playingAudioMsgId = nil;
            NSIndexPath *playingIndexPath = [NSIndexPath indexPathForRow:playingIndex inSection:0];
            if ([[self.chatListTable indexPathsForVisibleRows] containsObject:playingIndexPath]) {
                [self.chatListTable reloadData];
            }
        }
    }
}

#pragma mark - image video download

- (void)downloadImageFile:(GJGCChatContentBaseModel *)contentModel forIndexPath:(NSIndexPath *)indexPath {
    GJGCChatFriendContentModel *imageContentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:indexPath.row];
    if (imageContentModel.baseMessageType == GJGCChatBaseMessageTypeSystemNoti) {
        return;
    }
    if ([imageContentModel isKindOfClass:[GJGCChatSystemNotiModel class]]) {
        return;
    }
    switch (imageContentModel.contentType) {
        case GJGCChatFriendContentTypeGif: {
            [self downloadGifFile:imageContentModel forIndexPath:indexPath];
        }
            break;
        case GJGCChatFriendContentTypeImage: {
            NSString *taskIdentifier = nil;
            if (!imageContentModel.isDownloadThumbImage) {
                if (imageContentModel.encodeThumbFileUrl) {
                    GJCFFileDownloadTask *downloadTask = [GJCFFileDownloadTask taskWithDownloadUrl:imageContentModel.encodeThumbFileUrl withCachePath:imageContentModel.downThumbEncodeImageCachePath withObserver:self getTaskIdentifer:&taskIdentifier];
                    imageContentModel.downloadTaskIdentifier = taskIdentifier;
                    if (self.taklInfo.talkType != GJGCChatFriendTalkTypePrivate && self.taklInfo.talkType != GJGCChatFriendTalkTypeGroup) {
                        downloadTask.unEncodeData = YES;
                    } else {
                        NSData *ecdhkey = nil;
                        if (self.taklInfo.talkType == GJGCChatFriendTalkTypeGroup) {
                            ecdhkey = [StringTool hexStringToData:self.taklInfo.chatGroupInfo.groupEcdhKey];
                        } else if (self.taklInfo.talkType == GJGCChatFriendTalkTypePrivate) {
                            ecdhkey = [KeyHandle getECDHkeyWithPrivkey:[[LKUserCenter shareCenter] currentLoginUser].prikey
                                                             publicKey:self.taklInfo.chatIdendifier];
                        }
                        ecdhkey = [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdhkey salt:[ConnectTool get64ZeroData]];
                        downloadTask.ecdhkey = ecdhkey;

                    }
                    downloadTask.userInfo = @{@"type": @"thumbimage"};
                    downloadTask.msgIdentifier = [NSString stringWithFormat:@"%@_%@", self.taklInfo.chatIdendifier, contentModel.localMsgId];
                    downloadTask.temOriginFilePath = imageContentModel.thumbImageCachePath;
                    imageContentModel.downloadTaskIdentifier = taskIdentifier;

                    [self addDownloadTask:downloadTask];
                }
            }
            if (!imageContentModel.isDownloadImage && imageContentModel.isDownloadThumbImage) {
                if (imageContentModel.encodeFileUrl) {
                    GJCFFileDownloadTask *downloadOriginTask = [GJCFFileDownloadTask taskWithDownloadUrl:imageContentModel.encodeFileUrl withCachePath:imageContentModel.downEncodeImageCachePath withObserver:self getTaskIdentifer:&taskIdentifier];
                    imageContentModel.downloadTaskIdentifier = taskIdentifier;
                    if (self.taklInfo.talkType != GJGCChatFriendTalkTypePrivate && self.taklInfo.talkType != GJGCChatFriendTalkTypeGroup) {
                        downloadOriginTask.unEncodeData = YES;
                    } else {
                        NSData *ecdhkey = nil;
                        if (self.taklInfo.talkType == GJGCChatFriendTalkTypeGroup) {
                            ecdhkey = [StringTool hexStringToData:self.taklInfo.chatGroupInfo.groupEcdhKey];
                        } else if (self.taklInfo.talkType == GJGCChatFriendTalkTypePrivate) {
                            ecdhkey = [KeyHandle getECDHkeyWithPrivkey:[[LKUserCenter shareCenter] currentLoginUser].prikey
                                                             publicKey:self.taklInfo.chatIdendifier];
                        }
                        ecdhkey = [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdhkey salt:[ConnectTool get64ZeroData]];
                        downloadOriginTask.ecdhkey = ecdhkey;

                    }
                    downloadOriginTask.userInfo = @{@"type": @"image"};
                    downloadOriginTask.msgIdentifier = [NSString stringWithFormat:@"%@_%@", self.taklInfo.chatIdendifier, contentModel.localMsgId];
                    downloadOriginTask.temOriginFilePath = imageContentModel.imageOriginDataCachePath;
                    imageContentModel.downloadTaskIdentifier = taskIdentifier;
                    [self addDownloadTask:downloadOriginTask];
                }
            }
        }
            break;
        case GJGCChatFriendContentTypeMapLocation: {
            if (imageContentModel.messageContentImage) {
                return;
            }
            NSString *taskIdentifier = nil;
            GJCFFileDownloadTask *downloadTask = [GJCFFileDownloadTask taskWithDownloadUrl:imageContentModel.encodeFileUrl withCachePath:imageContentModel.locationImageDownPath withObserver:self getTaskIdentifer:&taskIdentifier];
            imageContentModel.downloadTaskIdentifier = taskIdentifier;

            NSData *ecdhkey = nil;
            if (self.taklInfo.talkType == GJGCChatFriendTalkTypeGroup) {
                ecdhkey = [StringTool hexStringToData:self.taklInfo.chatGroupInfo.groupEcdhKey];
            } else if (self.taklInfo.talkType == GJGCChatFriendTalkTypePrivate) {
                ecdhkey = [KeyHandle getECDHkeyWithPrivkey:[[LKUserCenter shareCenter] currentLoginUser].prikey
                                                 publicKey:self.taklInfo.chatIdendifier];
            }
            ecdhkey = [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdhkey salt:[ConnectTool get64ZeroData]];
            downloadTask.ecdhkey = ecdhkey;

            downloadTask.userInfo = @{@"type": @"locationimage"};
            downloadTask.msgIdentifier = [NSString stringWithFormat:@"%@_%@", self.taklInfo.chatIdendifier, contentModel.localMsgId];
            downloadTask.temOriginFilePath = imageContentModel.locationImageOriginDataCachePath;
            imageContentModel.downloadTaskIdentifier = taskIdentifier;

            [self addDownloadTask:downloadTask];
        }
            break;

        case GJGCChatFriendContentTypeVideo: {
            if (imageContentModel.messageContentImage) {
                return;
            }
            NSString *taskIdentifier = nil;
            GJCFFileDownloadTask *downloadTask = [GJCFFileDownloadTask taskWithDownloadUrl:imageContentModel.encodeFileUrl withCachePath:imageContentModel.videoDownCoverEncodePath withObserver:self getTaskIdentifer:&taskIdentifier];
            imageContentModel.downloadTaskIdentifier = taskIdentifier;
            NSData *ecdhkey = nil;
            if (self.taklInfo.talkType == GJGCChatFriendTalkTypeGroup) {
                ecdhkey = [StringTool hexStringToData:self.taklInfo.chatGroupInfo.groupEcdhKey];
            } else if (self.taklInfo.talkType == GJGCChatFriendTalkTypePrivate) {
                ecdhkey = [KeyHandle getECDHkeyWithPrivkey:[[LKUserCenter shareCenter] currentLoginUser].prikey
                                                 publicKey:self.taklInfo.chatIdendifier];
            }
            ecdhkey = [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdhkey salt:[ConnectTool get64ZeroData]];
            downloadTask.ecdhkey = ecdhkey;

            downloadTask.userInfo = @{@"type": @"videocover"};
            downloadTask.msgIdentifier = [NSString stringWithFormat:@"%@_%@", self.taklInfo.chatIdendifier, contentModel.localMsgId];
            downloadTask.temOriginFilePath = imageContentModel.videoOriginCoverImageCachePath;
            imageContentModel.downloadTaskIdentifier = taskIdentifier;
            [self addDownloadTask:downloadTask];
        }
            break;
        default:
            break;
    }
}

- (void)downloadGifFile:(GJGCChatFriendContentModel *)gifContentModel forIndexPath:(NSIndexPath *)indexPath {
    if ([GJGCGIFLoadManager gifEmojiIsExistById:gifContentModel.gifLocalId]) {
        return;
    }

    //@"http://tb2.bdstatic.com/tb/editor/images/ali/ali_033.gif?t=20140803"
    NSString *taskIdentifier = nil;
    GJCFFileDownloadTask *downloadTask = [GJCFFileDownloadTask taskWithDownloadUrl:@"" withCachePath:[GJGCGIFLoadManager gifCachePathById:gifContentModel.gifLocalId] withObserver:self getTaskIdentifer:&taskIdentifier];
    gifContentModel.downloadTaskIdentifier = taskIdentifier;

    downloadTask.userInfo = @{@"type": @"gif", @"msgId": gifContentModel.localMsgId};

    [self addDownloadTask:downloadTask];

}

#pragma mark - cancel download

- (void)cancelDownloadAtIndexPath:(NSIndexPath *)indexPath {
    GJGCChatFriendContentModel *contentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:indexPath.row];

    if (contentModel.downloadTaskIdentifier) {
        [self cancelDownloadWithTaskIdentifier:contentModel.downloadTaskIdentifier];
    }
}

- (void)clearAllEarlyMessage {
    if (!self.refreshFootView.isLoading && !self.refreshHeadView.isLoading) {
        [self.dataSourceManager clearOverEarlyMessage];
    }
}


#pragma mark - GJGCChatInputPanelDelegate
#pragma mark - meun config

- (GJGCChatInputExpandMenuPanelConfigModel *)chatInputPanelRequiredCurrentConfigData:(GJGCChatInputPanel *)panel {
    GJGCChatInputExpandMenuPanelConfigModel *configModel = [[GJGCChatInputExpandMenuPanelConfigModel alloc] init];
    configModel.talkType = self.taklInfo.talkType;
    return configModel;
}

- (void)chatInputPanel:(GJGCChatInputPanel *)panel didChooseMenuAction:(GJGCChatInputMenuPanelActionType)actionType {
    switch (actionType) {
        case GJGCChatInputMenuPanelActionTypeCamera: {
            self.isShowingOhterView = YES;
            [self getAuthorization];
        }
            break;
        case GJGCChatInputMenuPanelActionTypePhotoLibrary: {
            self.isShowingOhterView = YES;
            TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:9 delegate:self];
            imagePickerVc.allowPickingOriginalPhoto = YES;
            imagePickerVc.isSelectOriginalPhoto = NO;
            imagePickerVc.allowPickingVideo = YES;
            [self presentViewController:imagePickerVc animated:YES completion:nil];
        }
            break;
        case GJGCChatInputMenuPanelActionTypeMapLocation: {
            self.isShowingOhterView = YES;
            __weak __typeof(&*self) weakSelf = self;
            MapLocationViewController *mapPage = [[MapLocationViewController alloc] initWithComplete:^(NSDictionary *complete) {
                [weakSelf sendLocation:complete];
            }                                                                                 cancel:^{

            }];

            [self presentViewController:[[UINavigationController alloc] initWithRootViewController:mapPage] animated:YES completion:nil];


        }
            break;
        case GJGCChatInputMenuPanelActionTypeSecurty: {

            __weak __typeof(&*self) weakSelf = self;
            TBActionSheet *actionSheet = [[TBActionSheet alloc] initWithTitle:nil message:nil delegate:self cancelButtonTitle:LMLocalizedString(@"Common Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:nil];
            actionSheet.backgroundTransparentEnabled = YES;
            actionSheet.blurEffectEnabled = YES;
            actionSheet.ambientColor = [UIColor whiteColor];
            CustomActionSheetView *customActionSheet = [[CustomActionSheetView alloc] initWithFrame:CGRectMake(0, 0, [TBActionSheet appearance].sheetWidth, 9 * AUTO_HEIGHT(114))];
            customActionSheet.initTime = self.taklInfo.snapChatOutDataTime;
            __weak __typeof(&*actionSheet) weakActionSheet = actionSheet;
            actionSheet.customView = customActionSheet;
            customActionSheet.ItemClick = ^(int snapTime) {
                [weakActionSheet close];
                weakSelf.taklInfo.snapChatOutDataTime = snapTime;
                if (snapTime > 0) {
                    [weakSelf enterSnapchatModeWithTime:snapTime];
                } else if (snapTime == 0) {
                    [weakSelf quitSnapChatMode];
                } else {
                    weakSelf.taklInfo.snapChatOutDataTime = 0;
                }
            };
            [actionSheet show];
        }
            break;
        case GJGCChatInputMenuPanelActionTypeTransfer: {
            self.isShowingOhterView = YES;
            [self transfer];
        }
            break;
        case GJGCChatInputMenuPanelActionTypePayMent: {
            self.isShowingOhterView = YES;
            [self sendCrowdBlance];
        }
            break;
        case GJGCChatInputMenuPanelActionTypeRedBag: {
            self.isShowingOhterView = YES;
            [self showCreateRedPage];
        }
            break;
        case GJGCChatInputMenuPanelActionTypeContact: {
            self.isShowingOhterView = YES;
            __weak __typeof(&*self) weakSelf = self;
            SelectContactCardController *contactPage = [[SelectContactCardController alloc] initWihtTalkName:self.taklInfo.talkType == GJGCChatFriendTalkTypeGroup ? nil : self.taklInfo.chatIdendifier complete:^(AccountInfo *user) {

                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:[NSString stringWithFormat:LMLocalizedString(@"Chat Send contact card to the current chat", nil), user.username] preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Link Send", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
                    [weakSelf sendContact:user];
                }];
                [alertController addAction:cancelAction];
                [alertController addAction:okAction];

                [weakSelf presentViewController:alertController animated:YES completion:nil];

            }                                                                                         cancel:^{

            }];
            [self presentViewController:[[UINavigationController alloc] initWithRootViewController:contactPage] animated:YES completion:nil];

        }
            break;
        default:
            break;
    }
}

#pragma mark - Distance sensor monitoring

- (void)getAuthorization {
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusAuthorized:       //The client is authorized to access the hardware supporting a media type.
        {
            [self presentPhotoController];
            break;
        }
        case AVAuthorizationStatusNotDetermined:    //Indicates that the user has not yet made a choice regarding whether the client can access the hardware.
        {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    [self presentPhotoController];
                } else {
                    [self creatSetLable];
                }
            }];
            break;
        }
        default: {
            [self creatSetLable];
            return;
        }
    }
}

- (void)presentPhotoController {
    __weak typeof(self) weakSelf = self;
    LMPhotoViewController *photoVc = [[LMPhotoViewController alloc] init];
    photoVc.savePhotoBlock = ^(UIImage *image, BOOL isBack) {
        NSData *data = UIImagePNGRepresentation(image);
        if (data.length <= 0) {
            return;
        }
        NSArray *photos = @[image];
        [weakSelf sendPhotoImages:photos backPhoto:isBack];
    };
    __weak __typeof(&*photoVc) weakPhotovc = photoVc;
    photoVc.saveVideoBlock = ^(NSURL *videoUrl) {
        if (videoUrl == nil) {
            return;
        }
        [weakSelf sendVideoWithUrl:videoUrl controller:weakPhotovc];
    };
    [self presentViewController:photoVc animated:YES completion:nil];

}

- (void)creatSetLable {
    [self showMsgWithTitle:LMLocalizedString(@"ErrorCode Error", nil) andContent:LMLocalizedString(@"Link User refuses camera permission please set", nil)];
}

- (void)showMsgWithTitle:(NSString *)title andContent:(NSString *)content {
    [UIAlertController showAlertInViewController:self withTitle:title message:content cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@[LMLocalizedString(@"Common OK", nil)] tapBlock:^(UIAlertController *_Nonnull controller, UIAlertAction *_Nonnull action, NSInteger buttonIndex) {

    }];
}

#pragma mark - TBActionSheetDelegate

- (void)chatInputPanel:(GJGCChatInputPanel *)panel didFinishRecord:(GJCFAudioModel *)audioFile {
    if (self.inputPanel.disableActionType == GJGCChatInputBarActionTypeRecordAudio) {
        [self.inputPanel recordRightStartLimit];
        return;
    }
    GJGCChatFriendContentModel *chatContentModel = [LMMessageTool packContentModelWithTalkModel:self.taklInfo contentType:GJGCChatFriendContentTypeAudio extData:audioFile];
    [self.dataSourceManager sendMesssage:chatContentModel];
}

- (void)chatInputPanel:(GJGCChatInputPanel *)panel sendTextMessage:(NSString *)text {

    GJGCChatFriendContentModel *chatContentModel = [LMMessageTool packContentModelWithTalkModel:self.taklInfo contentType:GJGCChatFriendContentTypeText extData:text];

    if ([[GJGCChatContentEmojiParser sharedParser] isWalletUrlString:chatContentModel.originTextMessage]) {
        chatContentModel.contentType = GJGCChatWalletLink;
        if ([text containsString:@"transfer?"]) {
            chatContentModel.walletLinkType = LMWalletlinkTypeOuterTransfer;
        } else if ([text containsString:@"packet?"]) {
            chatContentModel.walletLinkType = LMWalletlinkTypeOuterPacket;
        } else if ([text containsString:@"pay?"]) {
            chatContentModel.walletLinkType = LMWalletlinkTypeOuterCollection;
        }
    }

    //group @
    NSDictionary *parseTextDict = [GJGCChatFriendCellStyle formateSimpleTextMessage:text];
    chatContentModel.simpleTextMessage = [parseTextDict objectForKey:@"contentString"];
    chatContentModel.emojiInfoArray = [parseTextDict objectForKey:@"imageInfo"];
    chatContentModel.phoneNumberArray = [parseTextDict objectForKey:@"phone"];
    if (self.noteGroupMembers.count) {
        NSString *seachRegexString = @"@.*?\\s";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:seachRegexString
                                                                               options:NSRegularExpressionAnchorsMatchLines
                                                                                 error:nil];
        NSArray *array = [regex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
        NSMutableArray *finalNoteMembers = [NSMutableArray array];
        for (NSTextCheckingResult *str2 in array) {
            NSString *nameString = [text substringWithRange:str2.range];
            if ([nameString hasPrefix:@"@"]) {
                nameString = [nameString stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
            }
            if (nameString.length > 0) {
                nameString = [nameString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            }
            for (AccountInfo *user in self.noteGroupMembers) {
                if ([user.groupShowName isEqualToString:nameString] ||
                        [user.username isEqualToString:nameString]) {
                    [finalNoteMembers objectAddObject:user];
                }
            }
        }
        chatContentModel.noteGroupMemberAddresses = [NSMutableArray array];
        for (AccountInfo *user in finalNoteMembers) {
            if (user.address) {
                [chatContentModel.noteGroupMemberAddresses objectAddObject:user.address];
            }
        }
    }
    [self.noteGroupMembers removeAllObjects];
    [self.dataSourceManager sendMesssage:chatContentModel];
}

- (void)chatInputPanel:(GJGCChatInputPanel *)panel sendGIFMessage:(NSString *)gifCode {
    GJGCChatFriendContentModel *chatContentModel = [LMMessageTool packContentModelWithTalkModel:self.taklInfo contentType:GJGCChatFriendContentTypeGif extData:gifCode];
    [self.dataSourceManager sendMesssage:chatContentModel];

}

- (NSString *)createThumbFromCaptureOriginImage:(UIImage *)originImage withOriginImagePath:(NSString *)originImagePath {
    UIImage *thumbImage = [[originImage copy] fixOrietationWithScale:0.48];
    return [self createTumbWithImage:thumbImage withOriginImagePath:originImagePath imageID:@""];
}

#pragma mark - TZImagePickerControllerDelegate

- (void)sendPhotoImages:(NSArray *)photos backPhoto:(BOOL)isBack {
    NSMutableArray *images = [NSMutableArray array];
    for (UIImage *image in photos) {
        UIImage *originImage = image;
        @autoreleasepool {
            NSInteger imageSize = 0;
            if (isBack) {
                imageSize = 1080;
            } else {
                imageSize = 720;
            }

            if (originImage.size.width > 1200 || originImage.size.height > 1200) {

                CGFloat max = originImage.size.width > originImage.size.height ? originImage.size.width : originImage.size.height;
                originImage = [originImage fixOrietationWithScale:(imageSize * 1200 / 675) / max];

            } else {
                originImage = [originImage fixOrietationWithScale:1.0];
            }
            NSDictionary *originImageInfo = [self createOriginImageToCacheDiretory:originImage];
            NSDictionary *imageInfo = @{@"origin": originImageInfo[@"path"], @"thumb": originImageInfo[@"thumbImageName"], @"originWidth": @(originImage.size.width), @"originHeight": @(originImage.size.height), @"imageID": originImageInfo[@"imageID"]};
            [images objectAddObject:imageInfo];
        }
    }
    [self sendImages:images];
}

- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto {
    NSMutableArray *images = [NSMutableArray array];
    for (UIImage *image in photos) {
        UIImage *originImage = image;
        @autoreleasepool {
            NSInteger imageSize = 720;
            if (originImage.size.width > 1200 || originImage.size.height > 1200) {

                CGFloat max = originImage.size.width > originImage.size.height ? originImage.size.width : originImage.size.height;
                NSString *floatStr = [NSString stringWithFormat:@"%0.2f", ((imageSize * 1200 / 675) / max)];
                originImage = [originImage fixOrietationWithScale:floatStr.floatValue];

            } else {
                originImage = [originImage fixOrietationWithScale:1.0];
            }
            NSDictionary *originImageInfo = [self createOriginImageToCacheDiretory:originImage];
            NSDictionary *imageInfo = @{@"origin": originImageInfo[@"path"], @"thumb": originImageInfo[@"thumbImageName"], @"originWidth": @(originImage.size.width), @"originHeight": @(originImage.size.height), @"imageID": originImageInfo[@"imageID"]};
            [images objectAddObject:imageInfo];
        }

    }
    [self sendImages:images];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingVideo:(UIImage *)coverImage sourceAssets:(PHAsset *)asset {
    PHAsset *phAsset = asset;
    if (phAsset.mediaType == PHAssetMediaTypeVideo) {
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        options.version = PHImageRequestOptionsVersionCurrent;
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;

        PHImageManager *manager = [PHImageManager defaultManager];
        [manager requestAVAssetForVideo:phAsset options:options resultHandler:^(AVAsset *_Nullable asset, AVAudioMix *_Nullable audioMix, NSDictionary *_Nullable info) {
            AVURLAsset *urlAsset = (AVURLAsset *) asset;
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showMessage:LMLocalizedString(@"Chat Compressing", nil) toView:picker.view];
            }];
            [self sendVideoWithUrl:urlAsset.URL controller:picker];
        }];
    }
}

#pragma mark - UINavigationControllerDelegate, UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:@"public.image"]) {
        UIImage *originImage = [info objectForKey:UIImagePickerControllerOriginalImage];

        if (originImage.size.width > 1200 || originImage.size.height > 1200) {
            CGFloat max = originImage.size.width > originImage.size.height ? originImage.size.width : originImage.size.height;
            originImage = [originImage fixOrietationWithScale:1200 / max];
        } else {
            originImage = [originImage fixOrietationWithScale:1.0];
        }
        NSDictionary *originImageInfo = [self createOriginImageToCacheDiretory:originImage];
        NSDictionary *imageInfo = @{@"origin": originImageInfo[@"path"], @"thumb": originImageInfo[@"thumbImageName"], @"originWidth": @(originImage.size.width), @"originHeight": @(originImage.size.height), @"imageID": originImageInfo[@"imageID"]};
        [self sendImages:@[imageInfo]];
        [picker dismissViewControllerAnimated:YES completion:nil];
    } else if ([mediaType isEqualToString:@"public.movie"]) {
        NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showMessage:LMLocalizedString(@"Chat Compressing", nil) toView:picker.view];
        }];
        [self sendVideoWithUrl:videoURL controller:picker];
    }
}

- (void)sendVideoWithUrl:(NSURL *)videoURL controller:(UIViewController *)picker {
    NSString *movie = [NSString stringWithFormat:@"%f.mp4", [[NSDate date] timeIntervalSince1970]];
    NSString *temVideoPath = GJCFAppCachePath(movie);
    __weak __typeof(&*self) weakSelf = self;
    [self compressVideoWithVideoURL:videoURL savedPath:temVideoPath withComplete:^(BOOL saved) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:picker.view];
            NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:temVideoPath error:nil];
            NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
            long long fileSize = [fileSizeNumber longLongValue];
            float nM = fileSize / 1024 / 1024.f;
            int nK = (fileSize % (1024 * 1024)) / 1024;
            NSString *videoSize = [NSString stringWithFormat:@"%dkb", nK];
            NSString *message = [NSString stringWithFormat:LMLocalizedString(@"Chat Video compress size Are yousend", nil), videoSize];
            if (nM >= 1) {
                videoSize = [NSString stringWithFormat:@"%.1fM", nM];
                message = [NSString stringWithFormat:LMLocalizedString(@"Chat Video compress size Are yousend", nil), videoSize];
            }
            [UIAlertController showAlertInViewController:self
                                               withTitle:LMLocalizedString(@"Set tip title", nil)
                                                 message:message
                                       cancelButtonTitle:LMLocalizedString(@"Common Cancel", nil)
                                  destructiveButtonTitle:nil
                                       otherButtonTitles:@[LMLocalizedString(@"Link Send", nil)]
                                                tapBlock:^(UIAlertController *controller, UIAlertAction *action, NSInteger buttonIndex) {
                                                    if (buttonIndex == controller.cancelButtonIndex) {
                                                        [picker dismissViewControllerAnimated:YES completion:nil];
                                                    } else if (buttonIndex == controller.destructiveButtonIndex) {
                                                    } else if (buttonIndex >= controller.firstOtherButtonIndex) {
                                                        [picker dismissViewControllerAnimated:YES completion:^{
                                                            [weakSelf sendVideo:videoURL compressedFile:temVideoPath videoSize:videoSize];
                                                        }];
                                                    }
                                                }];

        }];
    }];
}


- (void)compressVideoWithVideoURL:(NSURL *)videoURL
                        savedPath:(NSString *)savedPath withComplete:(void (^)(BOOL saved))complete {

    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];

    NSArray *presets = [AVAssetExportSession exportPresetsCompatibleWithAsset:videoAsset];

    if ([presets containsObject:AVAssetExportPreset960x540]) {
        AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:videoAsset presetName:AVAssetExportPresetMediumQuality];
        session.outputURL = [NSURL fileURLWithPath:savedPath];
        session.shouldOptimizeForNetworkUse = YES;
        NSArray *supportedTypeArray = session.supportedFileTypes;
        if ([supportedTypeArray containsObject:AVFileTypeMPEG4]) {
            session.outputFileType = AVFileTypeMPEG4;
        } else if (supportedTypeArray.count == 0) {
            DDLogInfo(@"No supported file types");
            if (complete) {
                complete(NO);
            }
            return;
        } else {
            session.outputFileType = [supportedTypeArray objectAtIndexCheck:0];
        }
        [session exportAsynchronouslyWithCompletionHandler:^{
            if ([session status] == AVAssetExportSessionStatusCompleted) {
                if (complete) {
                    complete(YES);
                }
            } else {
                if (complete) {
                    complete(NO);
                }
            }
        }];
    }
}


#pragma mark - send video

- (void)sendVideo:(NSURL *)originUrl compressedFile:(NSString *)filePath videoSize:(NSString *)videoSize {

    NSDictionary *dataDict = @{@"originUrl": originUrl,
            @"filePath": filePath,
            @"videoSize": videoSize};
    GJGCChatFriendContentModel *chatContentModel = [LMMessageTool packContentModelWithTalkModel:self.taklInfo contentType:GJGCChatFriendContentTypeVideo extData:dataDict];
    [self.dataSourceManager sendMesssage:chatContentModel];
}

#pragma mark - send photo

- (void)sendImages:(NSArray *)images {
    for (NSDictionary *imageInfo in images) {
        GJGCChatFriendContentModel *chatContentModel = [LMMessageTool packContentModelWithTalkModel:self.taklInfo contentType:GJGCChatFriendContentTypeImage extData:imageInfo];
        [self.dataSourceManager sendMesssage:chatContentModel];
    }
}


#pragma mark - send luckypackge

- (void)showCreateRedPage {
    NSInteger redPackType = 0;
    NSString *reciverIdentifier = @"";
    if (self.taklInfo.talkType == GJGCChatFriendTalkTypeGroup) {
        redPackType = LMChatRedLuckyStyleGroup;
        reciverIdentifier = self.taklInfo.chatIdendifier;
    } else {
        redPackType = LMChatRedLuckyStyleSingle;
        reciverIdentifier = self.taklInfo.chatUser.address;
    }
    __weak __typeof(&*self) weakSelf = self;
    LMChatRedLuckyViewController *page = [[LMChatRedLuckyViewController alloc] initChatRedLuckyViewControllerWithStyle:redPackType reciverIdentifier:reciverIdentifier];
    page.userInfo = self.taklInfo.chatUser;
    page.didGetRedLuckyMoney = ^(NSString *money, NSString *hashId, NSString *tips) {
        [weakSelf sendRedBagWithHashID:hashId tips:tips];
    };
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:page] animated:YES completion:nil];

}

- (void)sendRedBagWithHashID:(NSString *)hashId tips:(NSString *)tips {
    LMTransactionModel *transactionModel = [LMTransactionModel new];
    transactionModel.note = tips;
    transactionModel.hashId = hashId;
    GJGCChatFriendContentModel *chatContentModel = [LMMessageTool packContentModelWithTalkModel:self.taklInfo contentType:GJGCChatFriendContentTypeRedEnvelope extData:transactionModel];
    [self.dataSourceManager sendMesssage:chatContentModel];
}

- (void)sendLocation:(NSDictionary *)locationInfo {
    GJGCChatFriendContentModel *chatContentModel = [LMMessageTool packContentModelWithTalkModel:self.taklInfo contentType:GJGCChatFriendContentTypeMapLocation extData:locationInfo];
    [self.dataSourceManager sendMesssage:chatContentModel];
}

- (void)sendContact:(AccountInfo *)user {
    GJGCChatFriendContentModel *chatContentModel = [LMMessageTool packContentModelWithTalkModel:self.taklInfo contentType:GJGCChatFriendContentTypeNameCard extData:user];
    [self.dataSourceManager sendMesssage:chatContentModel];
}


#pragma mark - send transfer message
- (void)transfer {
    if (self.taklInfo.talkType == GJGCChatFriendTalkTypeGroup) {
        LMGroupFriendsViewController *page = [[LMGroupFriendsViewController alloc] init];
        page.groupFriends = [NSMutableArray arrayWithArray:self.taklInfo.chatGroupInfo.groupMembers];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:page];
        [self presentViewController:nav animated:YES completion:nil];

    } else {
        __weak __typeof(&*self) weakSelf = self;
        LMChatSingleTransferViewController *transferVc = [[LMChatSingleTransferViewController alloc] init];
        transferVc.didGetTransferMoney = ^(NSString *money, NSString *hashId, NSString *notes) {
            [weakSelf sendTransferMessageWithAmount:money transactionID:hashId note:notes];
        };
        AccountInfo *info = [[UserDBManager sharedManager] getUserByPublickey:self.taklInfo.chatIdendifier];
        transferVc.info = info;

        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:transferVc];
        [self presentViewController:nav animated:YES completion:nil];
    }
}

- (void)sendTransferMessageWithAmount:(NSString *)amount transactionID:(NSString *)transactionID note:(NSString *)note {
    LMTransactionModel *transactionModel = [LMTransactionModel new];
    transactionModel.note = note;
    transactionModel.hashId = transactionID;
    transactionModel.amount = [[NSDecimalNumber decimalNumberWithString:amount] decimalNumberByMultiplyingBy:[[NSDecimalNumber alloc] initWithLong:pow(10, 8)]];
    GJGCChatFriendContentModel *chatContentModel = [LMMessageTool packContentModelWithTalkModel:self.taklInfo contentType:GJGCChatFriendContentTypeTransfer extData:transactionModel];
    [GCDQueue executeInGlobalQueue:^{
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic safeSetObject:chatContentModel.localMsgId forKey:@"message_id"];
        [dic safeSetObject:transactionID forKey:@"hashid"];
        [dic safeSetObject:@(1) forKey:@"status"];
        [dic safeSetObject:0 forKey:@"pay_count"];
        [dic safeSetObject:0 forKey:@"crowd_count"];
        [[LMMessageExtendManager sharedManager] saveBitchMessageExtendDict:dic];
    }];
    [self.dataSourceManager sendMesssage:chatContentModel];
}

#pragma mark - receipt

- (void)sendCrowdBlance {
    __weak __typeof(&*self) weakSelf = self;
    if (self.taklInfo.talkType == GJGCChatFriendTalkTypeGroup) {
        LMGroupChatReciptViewController *groupRecipVc = [[LMGroupChatReciptViewController alloc] initWithIdentifier:self.taklInfo.chatIdendifier];
        groupRecipVc.groupMemberCount = self.taklInfo.chatGroupInfo.groupMembers.count;
        groupRecipVc.didGetNumberAndMoney = ^(int totalNum, NSDecimalNumber *money, NSString *hashId, NSString *note) {
            [weakSelf sendFriendRceiptMessageWithAmount:money transactionID:hashId totalMember:totalNum isCrowdfundRceipt:YES note:note];
        };
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:groupRecipVc];
        [self presentViewController:nav animated:YES completion:nil];
    } else {
        LMRecipFriendsViewController *recipVc = [[LMRecipFriendsViewController alloc] init];
        recipVc.didGetMoneyAndWithAccountID = ^(NSDecimalNumber *money, NSString *hashId, NSString *note) {
            [weakSelf sendFriendRceiptMessageWithAmount:money transactionID:hashId totalMember:1 isCrowdfundRceipt:NO note:note];
        };
        AccountInfo *info = [[UserDBManager sharedManager] getUserByPublickey:self.taklInfo.chatIdendifier];
        recipVc.info = info;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:recipVc];
        [self presentViewController:nav animated:YES completion:nil];
    }
}

- (void)sendFriendRceiptMessageWithAmount:(NSDecimalNumber *)amount transactionID:(NSString *)transactionID totalMember:(int)totalMember isCrowdfundRceipt:(BOOL)isCrowdfundRceipt note:(NSString *)note {

    LMTransactionModel *transactionModel = [LMTransactionModel new];
    transactionModel.note = note;
    transactionModel.isCrowding = isCrowdfundRceipt;
    transactionModel.size = totalMember;
    transactionModel.hashId = transactionID;
    transactionModel.amount = amount;
    GJGCChatFriendContentModel *chatContentModel = [LMMessageTool packContentModelWithTalkModel:self.taklInfo contentType:GJGCChatFriendContentTypePayReceipt extData:transactionModel];
    //save trancation status
    [GCDQueue executeInGlobalQueue:^{
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict safeSetObject:chatContentModel.localMsgId forKey:@"message_id"];
        [dict safeSetObject:transactionID forKey:@"hashid"];
        [dict safeSetObject:@(0) forKey:@"status"];
        [dict safeSetObject:0 forKey:@"pay_count"];
        if (totalMember > 1) {
            [dict safeSetObject:@(totalMember) forKey:@"crowd_count"];
        } else {
            [dict safeSetObject:@(0) forKey:@"crowd_count"];
        }
        [[LMMessageExtendManager sharedManager] saveBitchMessageExtendDict:dict];
    }];
    [self.dataSourceManager sendMesssage:chatContentModel];
}


#pragma mark -privte method
- (NSString *)createTumbWithImage:(UIImage *)thumbImage withOriginImagePath:(NSString *)originImagePath imageID:(NSString *)imageID {

    NSString *thumbName = [NSString stringWithFormat:@"%@-thumb.jpg", imageID];
    NSString *thumbPath = [originImagePath stringByAppendingPathComponent:thumbName];

    NSData *imageData = UIImageJPEGRepresentation(thumbImage, 1);

    BOOL saveThumbResult = GJCFFileWrite(imageData, thumbPath);

    if (saveThumbResult) {
        DDLogInfo(@"thumbPath %@", thumbPath);
    } else {
        DDLogInfo(@"Send picture save error");
    }

    return thumbPath;
}

- (NSDictionary *)createOriginImageToCacheDiretory:(UIImage *)originImage {

    NSString *filePath = [[GJCFCachePathManager shareManager] mainImageCacheDirectory];
    filePath = [[filePath stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].address]
            stringByAppendingPathComponent:self.taklInfo.fileDocumentName];
    if (!GJCFFileDirectoryIsExist(filePath)) {
        GJCFFileProtectCompleteDirectoryCreate(filePath);
    }
    NSString *imageID = [ConnectTool generateMessageId];
    NSData *imageData = UIImageJPEGRepresentation(originImage, 1);
    NSString *imageName = [NSString stringWithFormat:@"%@.jpg", imageID];
    BOOL saveOriginResult = GJCFFileWrite(imageData, [filePath stringByAppendingPathComponent:imageName]);
    NSString *thumbImageName = [NSString stringWithFormat:@"%@-thumb.jpg", imageID];
    NSData *thumbImageData = UIImageJPEGRepresentation(originImage, 0);
    saveOriginResult = GJCFFileWrite(thumbImageData, [filePath stringByAppendingPathComponent:thumbImageName]);
    if (saveOriginResult) {
        DDLogInfo(@"filePath %@", filePath);
    } else {
        DDLogInfo(@"Send picture save error");
    }
    return @{@"imageID": imageID, @"path": [filePath stringByAppendingPathComponent:imageName], @"thumbImageName": [filePath stringByAppendingPathComponent:thumbImageName]};
}


@end
