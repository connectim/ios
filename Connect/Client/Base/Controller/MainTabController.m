//
//  MainTabController.m
//  Connect
//
//  Created by MoHuilin on 16/5/22.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "MainTabController.h"
#import "LinkmanPage.h"
#import "ChatPage.h"
#import "MainWalletPage.h"
#import "AppDelegate.h"
#import "MainSetPage.h"
#import "NSString+DictionaryValue.h"
#import "UIImage+Color.h"
#import "NetWorkOperationTool.h"
#import "YYImageCache.h"
#import "YYWebImageManager.h"
#import "MMGlobal.h"
#import "BaseDB.h"
#import "IMService.h"
#import "LMTransferViewController.h"
#import "LMReceiptViewController.h"
#import "ScanAddPage.h"
#import "LMHandleScanResultManager.h"
#import "GroupDBManager.h"
#import "LMApplyJoinToGroupViewController.h"
#import "GJGCChatFriendTalkModel.h"
#import "GJGCChatSystemNotiViewController.h"
#import "LMConversionManager.h"
#import "CommonSetPage.h"
#import "RecentChatDBManager.h"
#import "GJGCChatGroupViewController.h"
#import "NSMutableArray+MoveObject.h"
@interface MainTabController (){
    dispatch_source_t _timer;
}

@property (nonatomic ,copy) void (^shortcutBlock)();

@end

@implementation MainTabController

- (instancetype)init{
    if (self = [super init]) {
    }
    return self;
}

- (void)dealloc{
    RemoveNofify;
}
    
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if ([[MMAppSetting sharedSetting] needReCacheEstimatefee] || [[MMAppSetting sharedSetting] getEstimatefee] <= 0.f) {
        [NetWorkOperationTool GETWithUrlString:estimetfeeUrl complete:^(id response) {
            NSDictionary *dict = [response mj_JSONObject];
            if ([[dict valueForKey:@"code"] integerValue] == successCode) {
                NSString *estimetfee = [dict valueForKey:@"data"];
                if (estimetfee) {
                    [[MMAppSetting sharedSetting] saveEstimatefee:estimetfee];
                }
            }
        } fail:^(NSError *error) {
            
        }];
    }
    
    NSString *urlHash = GJCFUDFGetValue(@"lanuchImagesHash");
    if (!urlHash) {
        urlHash = @"fristLaunchImages";
    }
    NSString *urlStr = [NSString stringWithFormat:lanuchImagesUrl,urlHash];
    [NetWorkOperationTool GETWithUrlString:urlStr complete:^(id response) {
        NSDictionary *dict = [response dictionaryValue];
        if ([[dict valueForKey:@"Code"] integerValue] == successCode) {
            NSString *hash = [[dict valueForKey:@"Data"] valueForKey:@"hash"];
            if (![lanuchImagesUrl isEqualToString:hash]) { //local lanuch image version
                NSArray *images = [[[dict valueForKey:@"Data"] valueForKey:@"images"] mj_JSONObject];
                if (images.count) {
                    NSArray *lanuchImages = [GJCFUDFGetValue(@"lanuchImages") mj_JSONObject];
                    for (NSString *localImageUrl in lanuchImages) {
                        if (![images containsObject:localImageUrl]) {
                            [[YYImageCache sharedCache] removeImageForKey:localImageUrl];
                        }
                    }
                    //cache image
                    NSMutableArray *downloadImages = [NSMutableArray array];
                    for (NSString *url in images) {
                        if (![[YYImageCache sharedCache] getImageForKey:url]) {
                            [[YYWebImageManager sharedManager] requestImageWithURL:[NSURL URLWithString:url] options:YYWebImageOptionAllowBackgroundTask | YYWebImageOptionIgnoreDiskCache progress:nil transform:nil completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error) {
                                [downloadImages objectAddObject:url.absoluteString];
                                GJCFUDFCache(@"lanuchImages", [downloadImages mj_JSONString]);
                                if (downloadImages.count == images.count) { //lanuch image download finish
                                    if (hash) {
                                        GJCFUDFCache(@"lanuchImagesHash",hash);
                                    }
                                }
                            }];
                        }
                    }
                }
            }
        }
    } fail:^(NSError *error) {
        
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupAllChildViewControllers];
    for (int i = 0; i < self.viewControllers.count; i ++) {
        self.selectedIndex = i;
    }
    self.selectedIndex = 0;
    
    //Database migration
    [BaseDB migrationWithUserPublicKey:[[LKUserCenter shareCenter] currentLoginUser].pub_key];
    //start imserver
    [[IMService instance] start];
    

    [self addNotification];
    
    //check salt expire
    [NetWorkOperationTool checkSaltExpired];
    NSTimeInterval period = 60.f;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(_timer, dispatch_walltime(NULL, 0), period * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(_timer, ^{
        if ([ServerCenter shareCenter].saltDeadTime - [[NSDate date] timeIntervalSince1970] < 400) {
            [NetWorkOperationTool getSaltWithComplete:nil forceUpdate:YES];
        };
        DDLogInfo(@"check %d",[ServerCenter shareCenter].saltDeadTime - [[NSDate date] timeIntervalSince1970] < 400);
    });
    dispatch_resume(_timer);
}

- (void)addNotification{
    RegisterNotify(@"HandleGroupTokenNotification", @selector(handleGroupToken:));
    //enter foreground noti
    RegisterNotify(UIApplicationWillEnterForegroundNotification, @selector(entreForegroud));
    //Receive notification of external envelopes
    RegisterNotify(ConnectGetOuterRedpackgeNotification, @selector(getOuterRedpackge:));
    //Application notification
    RegisterNotify(@"ShortcutInbackgroundNotification", @selector(handInbgShortcutWithType:))
    RegisterNotify(@"ShortcutNotInbackgroundNotification", @selector(handNotInbgShortcutWithType:))
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (self.shortcutBlock) {
        self.shortcutBlock();
        self.shortcutBlock = nil;
        
    }
}

- (void)changeLanguageResetController{
    self.viewControllers = @[].copy;
    [self setupAllChildViewControllers];
    
    //Interface jump
    self.selectedIndex = 3;
    UINavigationController *nav = [self.viewControllers objectAtIndex:3];
    NSMutableArray *navControllers = [NSMutableArray arrayWithArray:nav.viewControllers];
    CommonSetPage *page = [[CommonSetPage alloc] init];
    [navControllers addObject:page];
    nav.viewControllers = navControllers;
}

- (void)setupAllChildViewControllers{
    LinkmanPage *contactP = [[LinkmanPage alloc] init];
    ChatPage *recentP = [[ChatPage alloc] init];
    MainWalletPage *walletP = [[MainWalletPage alloc] init];
    
    MainSetPage *mainsetP = [[MainSetPage alloc] init];
    
    [self setupChildViewController:recentP title:LMLocalizedString(@"Chat Chats", nil) imageName:@"bottom_messages_unselect" selectedImageName:@"bottom_messages_select"];
    
    [self setupChildViewController:contactP title:LMLocalizedString(@"Link Contacts", nil) imageName:@"bottom_contact_unselect" selectedImageName:@"bottom_contact_select"];

    [self setupChildViewController:walletP title:LMLocalizedString(@"Wallet Wallet", nil) imageName:@"bottom_wallet_unselect" selectedImageName:@"bottom_wallet_select"];

    [self setupChildViewController:mainsetP title:LMLocalizedString(@"Set Setting", nil) imageName:@"bottom_setting_unselect" selectedImageName:@"bottom_setting_select"];

}

- (void)setupChildViewController:(UIViewController *)childVc title:(NSString *)title imageName:(NSString *)imageName selectedImageName:(NSString *)selectedImageName
{
    childVc.title = title;
    
    UITabBarItem *tabBarItem = [[UITabBarItem alloc] initWithTitle:nil image:[[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] selectedImage:[[UIImage imageNamed:selectedImageName]  imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
    
    childVc.tabBarItem = tabBarItem;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:childVc];
    [self addChildViewController:nav];

}

- (void)getOuterRedpackge:(NSNotification *)note {
    /**
     @{@"senderUser":senderUser,
     @"hashid":redPackgeinfo.hashId}
     */
    AccountInfo *user = [note.object valueForKey:@"senderUser"];
    if (user) {
        //Remove the controller from the stack
        for (UINavigationController *nav in self.viewControllers) {
            NSMutableArray *controllers = [NSMutableArray arrayWithArray:nav.viewControllers];
            if (controllers.count > 1) {
                [controllers removeObjectsInRange:NSMakeRange(1, controllers.count - 1)];
            }
            nav.viewControllers = controllers;
        }
        //interface jump
        [self chatWithFriend:user withObject:@{@"type": @"redpackge",
                                                                               @"hashid": [note.object valueForKey:@"hashid"]}];
    }
}


#pragma mark - Conversation page navigation

- (void)createGroupWithGroupInfo:(LMGroupInfo *)groupInfo content:(NSString *)tipMessage{
    
    NSString *localMsgId = [ConnectTool generateMessageId];
    ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
    chatMessage.messageId = localMsgId;
    chatMessage.messageOwer = groupInfo.groupIdentifer;
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
    // Put the current user in the first place
    if (groupInfo.groupMembers.count > 0) {
        AccountInfo * info = [groupInfo.groupMembers firstObject];
        if (![info.address isEqualToString:[LKUserCenter shareCenter].currentLoginUser.address]) {
            [groupInfo.groupMembers moveObject:[LKUserCenter shareCenter].currentLoginUser toIndex:0];
        }
    }
    GJGCChatFriendTalkModel *talk = [[GJGCChatFriendTalkModel alloc] init];
    talk.talkType = GJGCChatFriendTalkTypeGroup;
    talk.chatIdendifier = groupInfo.groupIdentifer;
    talk.group_ecdhKey = groupInfo.groupEcdhKey;
    talk.chatGroupInfo = groupInfo;
    talk.name = [NSString stringWithFormat:@"%@(%lu)", groupInfo.groupName, (unsigned long) talk.chatGroupInfo.groupMembers.count];
    [SessionManager sharedManager].chatSession = talk.chatIdendifier;
    [SessionManager sharedManager].chatObject = groupInfo;
    
    GJGCChatGroupViewController *groupChat = [[GJGCChatGroupViewController alloc] initWithTalkInfo:talk];
    groupChat.hidesBottomBarWhenPushed = YES;
    UINavigationController *nav = [self selectedViewController];
    [nav pushViewController:groupChat animated:YES];

}

- (void)chatWithFriend:(AccountInfo *)chatUser{
    [self chatWithFriend:chatUser withObject:nil];
}
- (void)chatWithFriend:(AccountInfo *)user withObject:(NSDictionary *)obj{
    self.selectedIndex = 0;
    //obtain current controller
    UINavigationController *nav = [self selectedViewController];
    DDLogInfo(@"nav %lu nav.viewControllers %@",(unsigned long)nav.viewControllers.count,nav.viewControllers);
    //save session
    [SessionManager sharedManager].chatSession = user.pub_key;
    [SessionManager sharedManager].chatObject = user;
    
    //jump to chat controller
    GJGCChatFriendTalkModel *talk = [[GJGCChatFriendTalkModel alloc] init];
    talk.talkType = GJGCChatFriendTalkTypePrivate;
    talk.name = user.normalShowName;
    talk.headUrl = user.avatar;
    talk.chatIdendifier = user.pub_key;
    talk.chatUser = user;
    talk.mute = [[RecentChatDBManager sharedManager] getMuteStatusWithIdentifer:talk.chatIdendifier];
    talk.top = [[RecentChatDBManager sharedManager] isTopChat:talk.chatIdendifier];
    talk.snapChatOutDataTime = [[RecentChatDBManager sharedManager] getSnapTimeWithChatIdentifer:talk.chatIdendifier];
    if ([user.pub_key isEqualToString:kSystemIdendifier]) {
        GJGCChatSystemNotiViewController *systemChat = [[GJGCChatSystemNotiViewController alloc] initWithTalkInfo:talk];
        talk.talkType = GJGCChatFriendTalkTypePostSystem;
        talk.name = user.username;
        talk.headUrl = user.avatar;
        /*
         @{@"type":@"redpackge",
         @"hashid":[note.object valueForKey:@"hashid"]})
         */
        if (obj &&
            [obj isKindOfClass:[NSDictionary class]] &&
            [[obj valueForKey:@"type"] isEqualToString:@"redpackge"]) {
            systemChat.outterRedpackHashid = [obj valueForKey:@"hashid"];
        }
        systemChat.hidesBottomBarWhenPushed = YES;
        [nav pushViewController:systemChat animated:YES];
        
    } else {
        GJGCChatFriendViewController *privateChat = [[GJGCChatFriendViewController alloc] initWithTalkInfo:talk];
        /*
         @{@"type":@"redpackge",
         @"hashid":[note.object valueForKey:@"hashid"]})
         */
        if (obj &&
            [obj isKindOfClass:[NSDictionary class]] &&
            [[obj valueForKey:@"type"] isEqualToString:@"redpackge"]) {
            privateChat.outterRedpackHashid = [obj valueForKey:@"hashid"];
        }
        privateChat.hidesBottomBarWhenPushed = YES;
        [nav pushViewController:privateChat animated:YES];
    }
    //clear unread
    [[LMConversionManager sharedManager] markConversionMessagesAsReadWithIdentifier:user.pub_key];
}    
    
#pragma mark - 3dtouch
- (void)handNotInbgShortcutWithType:(NSNotification *)note{
    NSString *type = note.object;
    __weak __typeof(&*self)weakSelf = self;
    self.shortcutBlock = ^(){
        //Remove the controller from the stack
        for (UINavigationController *nav in weakSelf.viewControllers) {
            NSMutableArray *controllers = [NSMutableArray arrayWithArray:nav.viewControllers];
            if (controllers.count > 1) {
                [controllers removeObjectsInRange:NSMakeRange(1, controllers.count - 1)];
            }
            nav.viewControllers = controllers;
        }
        if ([type isEqualToString:@"collection"]) {
            weakSelf.selectedIndex = 2;
            UINavigationController *controller = weakSelf.selectedViewController;
            LMReceiptViewController *bigReVc = [[LMReceiptViewController alloc] init];
            bigReVc.hidesBottomBarWhenPushed = YES;
            [controller pushViewController:bigReVc animated:YES];
        } else if ([type isEqualToString:@"scanQrcode"]){
            UINavigationController *controller = weakSelf.selectedViewController;
            ScanAddPage *scanPage = [[ScanAddPage alloc] initWithScanComplete:^(NSString *scanString) {
                [[LMHandleScanResultManager sharedManager] handleScanResult:scanString controller:controller];
            }];
            scanPage.showMyQrCode = YES;
            [controller presentViewController:scanPage animated:NO completion:nil];
        } else if ([type isEqualToString:@"transfer"]){
            weakSelf.selectedIndex = 2;
            UINavigationController *controller = weakSelf.selectedViewController;
            LMTransferViewController *transVc = [[LMTransferViewController alloc] init];
            transVc.hidesBottomBarWhenPushed = YES;
            [controller pushViewController:transVc animated:YES];
        }
    };
}

- (void)handInbgShortcutWithType:(NSNotification *)note{
    NSString *type = note.object;
    //Remove the controller from the stack
    for (UINavigationController *nav in self.viewControllers) {
        NSMutableArray *controllers = [NSMutableArray arrayWithArray:nav.viewControllers];
        if (controllers.count > 1) {
            [controllers removeObjectsInRange:NSMakeRange(1, controllers.count - 1)];
        }
        nav.viewControllers = controllers;
    }
    if ([type isEqualToString:@"collection"]) {
        
        self.selectedIndex = 2;
        
        UINavigationController *controller = self.selectedViewController;
        LMReceiptViewController *bigReVc = [[LMReceiptViewController alloc] init];
        bigReVc.hidesBottomBarWhenPushed = YES;
        [controller pushViewController:bigReVc animated:YES];
    } else if ([type isEqualToString:@"scanQrcode"]){
        //nav to contact page
        self.selectedIndex = 1;
        UINavigationController *controller = self.selectedViewController;
        ScanAddPage *scanPage = [[ScanAddPage alloc] initWithScanComplete:^(NSString *scanString) {
            [[LMHandleScanResultManager sharedManager] handleScanResult:scanString controller:[controller.viewControllers firstObject]];
        }];
        scanPage.showMyQrCode = YES;
        [controller presentViewController:scanPage animated:NO completion:nil];
    } else if ([type isEqualToString:@"transfer"]){
        
        self.selectedIndex = 2;
        UINavigationController *controller = self.selectedViewController;
        LMTransferViewController *transVc = [[LMTransferViewController alloc] init];
        transVc.hidesBottomBarWhenPushed = YES;
        [controller pushViewController:transVc animated:YES];
    }
}

- (void)handleGroupToken:(NSNotification *)note{
    NSString *token = note.object;
    //Remove the controller from the stack
    for (UINavigationController *nav in self.viewControllers) {
        NSMutableArray *controllers = [NSMutableArray arrayWithArray:nav.viewControllers];
        if (controllers.count > 1) {
            [controllers removeObjectsInRange:NSMakeRange(1, controllers.count - 1)];
        }
        nav.viewControllers = controllers;
    }
    
    self.selectedIndex = 0;

    UINavigationController *controller = self.selectedViewController;
    LMApplyJoinToGroupViewController *page = [[LMApplyJoinToGroupViewController alloc] initWithGroupToken:token];
    page.hidesBottomBarWhenPushed = YES;
    [controller pushViewController:page animated:YES];
}

- (void)entreForegroud{
    [NetWorkOperationTool checkSaltExpired];
}

@end
