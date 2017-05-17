//
//  AppDelegate.m
//  Connect
//
//  Created by MoHuilin on 16/5/9.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "AppDelegate.h"
#import "PhoneLoginPage.h"
#import <Bugly/Bugly.h>
#import <KSCrash/KSCrashInstallationStandard.h>
#import "IMService.h"
#import "LMlockGestureViewController.h"
#import "PLeakSniffer.h"
#import "RecentChatDBManager.h"
#import "BadgeNumberManager.h"
#import "UserDetailPage.h"
#import "NetWorkOperationTool.h"
#import "MMLaunchViewController.h"
#import "HandleUrlManager.h"
#import "LCNewFeatureVC.h"
#import "GJGCChatContentEmojiParser.h"
#import "SystemTool.h"
#import "LMDBUpdataController.h"

@interface AppDelegate ()

@property(nonatomic, strong) MainTabController *mainTabController;

@end

@implementation AppDelegate

- (MainTabController *)shareMainTabController {
    return self.mainTabController;
}

- (void)changeLanguageResetMainTabController {
    _mainTabController = nil;
    _mainTabController = [[MainTabController alloc] init];
    self.window.rootViewController = _mainTabController;
}

- (void)showMainTabPage:(id)userInfo {

    self.window.rootViewController = nil;
    if (userInfo) {
        self.currentUser = userInfo;
        NSString *olddbPath = [MMGlobal getDBFile:self.currentUser.pub_key.sha256String];
        if (GJCFFileIsExist(olddbPath)) {
            self.window.rootViewController = [[LMDBUpdataController alloc] initWithUpdateComplete:^(BOOL complete) {
                if (complete) {
                    self.window.rootViewController = self.mainTabController;
                }
            }];
        } else {
            self.window.rootViewController = self.mainTabController;
        }
    } else {
        
        PhoneLoginPage* phoneVc = [[PhoneLoginPage alloc]init];
        self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:phoneVc];
    }
}

- (void)setNavigationStytle {

    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];

    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
            [UIColor whiteColor], NSForegroundColorAttributeName, [UIFont fontWithName:@"Helvetica-Bold" size:18], NSFontAttributeName, nil]];

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    //set back image
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"top_background"] forBarMetrics:UIBarMetricsDefault];

}

/**
 * config log system
 */
- (void)configJack {

    MyLogFormatter *formatter = [[MyLogFormatter alloc] init];
    [[DDTTYLogger sharedInstance] setLogFormatter:formatter];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor colorWithRed:0.251 green:0.502 blue:0.000 alpha:1.000]
                                     backgroundColor:nil
                                             forFlag:DDLogFlagInfo];
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor redColor]
                                     backgroundColor:nil
                                             forFlag:DDLogFlagError];
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor colorWithWhite:0.498 alpha:1.000]
                                     backgroundColor:nil
                                             forFlag:DDLogFlagDebug];
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor colorWithRed:1.000 green:0.502 blue:0.000 alpha:1.000]
                                     backgroundColor:nil
                                             forFlag:DDLogFlagWarning];

    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];

    DDLogVerbose(@"Verbose");
    DDLogDebug(@"Debug");
    DDLogInfo(@"Info");
    DDLogWarn(@"Warn");
    DDLogError(@"Error");

}

/**
 * config bug track
 */
- (void)addBugTrackTX {

    BuglyConfig *bugConfg = [[BuglyConfig alloc] init];
    bugConfg.channel = [SystemTool isNationChannel] ? @"china" : @"appstore";
    bugConfg.blockMonitorEnable = YES;
    bugConfg.deviceIdentifier = [[MMAppSetting sharedSetting] getLoginAddress];
    bugConfg.blockMonitorTimeout = 3.f;
    [Bugly startWithAppId:@"900037966" config:bugConfg];
}

- (void)loginResult:(NSNotification *)note {
    AccountInfo *user = note.object;
    [self showMainTabPage:user];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //check update
    [self checkUpdate];

    id shortcutItem = nil;
    if (SYSTEM_VERSION_GREATER_THAN(@"9.0")) {
        shortcutItem = [launchOptions objectForKey:UIApplicationLaunchOptionsShortcutItemKey];
        if (![[MMAppSetting sharedSetting] haveGesturePass] && [[MMAppSetting sharedSetting] haveLoginAddress]) {
            UIApplicationShortcutItem *item = (UIApplicationShortcutItem *) shortcutItem;
            SendNotify(@"ShortcutNotInbackgroundNotification", item.type);
        }
    }

    [self configJack];

    [self addBugTrackTX];

    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor clearColor];
    self.window.rootViewController = [[UIViewController alloc] init];


    [self setNavigationStytle];

    [self.window makeKeyAndVisible];

    [self registerPushForIOS8];


    [self loadLaunch:shortcutItem];

    //prepare recource
    [GCDQueue executeInGlobalQueue:^{
        [[GJGCChatContentEmojiParser sharedParser] prepareResources];
    }];


    KSCrashInstallationStandard *installation = [KSCrashInstallationStandard sharedInstance];
    installation.url = [NSURL URLWithString:AppCrashUrl];
    [installation install];
    [installation sendAllReportsWithCompletion:nil];

#ifdef DEBUG
    [[PLeakSniffer sharedInstance] installLeakSniffer];
#endif
    return YES;

}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [HandleUrlManager handleOpenURL:url];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [UIDevice currentDevice].proximityMonitoringEnabled = NO;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [application setApplicationIconBadgeNumber:0];
    [application cancelAllLocalNotifications];
    if ([self.window.rootViewController isKindOfClass:[MainTabController class]]) {
        [self gestureLockVertifyWith:nil];
    }
}

/**
 * Gesture verification
 * @param shortcutItem
 */
- (void)gestureLockVertifyWith:(UIApplicationShortcutItem *)shortcutItem {
    __weak __typeof(&*self) weakSelf = self;
    if ([[MMAppSetting sharedSetting] haveGesturePass]) {
        int __block count = 0;
        LMlockGestureViewController *lockGesturePage = [[LMlockGestureViewController alloc] initWithAction:^(BOOL result) {
            if (result) {
                [GCDQueue executeInMainQueue:^{
                    if ([[MMAppSetting sharedSetting] haveLoginAddress]) {
                        [[LKUserCenter shareCenter] showCurrentPage];
                        if (shortcutItem) {
                            if (SYSTEM_VERSION_GREATER_THAN(@"9.0")) {
                                SendNotify(@"ShortcutNotInbackgroundNotification", shortcutItem.type);
                            }
                        }
                        RegisterNotify(LKUserCenterLoginStatusNoti, @selector(loginResult:));
                    } else {
                        [weakSelf showMainTabPage:nil];
                    }
                }];
            } else {
                count++;
            }
            if (count >= 5) { //More than 5 delete login information
                weakSelf.mainTabController = nil;
                [[MMAppSetting sharedSetting] cancelGestursPass];
                [[MMAppSetting sharedSetting] deleteLoginUser];
                [GCDQueue executeInMainQueue:^{
                    [weakSelf showMainTabPage:nil];
                }];
            }
        }];
        self.window.rootViewController = lockGesturePage;
    } else {
        if (![self.window.rootViewController isKindOfClass:[MainTabController class]]) {
            [GCDQueue executeInMainQueue:^{
                if (!GJCFStringIsNull([[MMAppSetting sharedSetting] getLoginAddress])) {
                    if (shortcutItem) {
                        if (SYSTEM_VERSION_GREATER_THAN(@"9.0")) {
                            SendNotify(@"ShortcutNotInbackgroundNotification", shortcutItem.type);
                        }
                    }
                    [[LKUserCenter shareCenter] showCurrentPage];
                    RegisterNotify(LKUserCenterLoginStatusNoti, @selector(loginResult:));
                } else {
                    [weakSelf showMainTabPage:nil];
                }
            }];
        } else {
            if (shortcutItem) {
                if (SYSTEM_VERSION_GREATER_THAN(@"9.0")) {
                    SendNotify(@"ShortcutNotInbackgroundNotification", shortcutItem.type);
                }
            }
            self.window.rootViewController = self.mainTabController;
        }
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {

    if ([[MMAppSetting sharedSetting] haveLoginAddress]) {
        [[RecentChatDBManager sharedManager] getAllUnReadCountWithComplete:^(int count) {
            [[BadgeNumberManager shareManager] getBadgeNumberCountWithMin:ALTYPE_CategoryTwo_NewFriend max:ALTYPE_CategoryTwo_PhoneContact Completion:^(NSUInteger contactConnt) {
                [GCDQueue executeInMainQueue:^{
                    [UIApplication sharedApplication].applicationIconBadgeNumber = count + contactConnt;
                }];
            }];
        }];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

// log NSSet with UTF8
// if not ,log will be \Uxxx
- (NSString *)logDic:(NSDictionary *)dic {
    if (![dic count]) {
        return nil;
    }
    NSString *tempStr1 =
            [[dic description] stringByReplacingOccurrencesOfString:@"\\u"
                                                         withString:@"\\U"];
    NSString *tempStr2 =
            [tempStr1 stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    NSString *tempStr3 =
            [[@"\"" stringByAppendingString:tempStr2] stringByAppendingString:@"\""];
    NSData *tempData = [tempStr3 dataUsingEncoding:NSUTF8StringEncoding];
    NSString *str = [NSPropertyListSerialization propertyListWithData:tempData options:NSPropertyListImmutable format:NULL error:NULL];
    return str;
}


- (void)loadLaunch:(id)shortcutItem {
    MMLaunchViewController *launchViewController = [[MMLaunchViewController alloc] initWithNibName:@"MMLaunchViewController" bundle:nil];
    self.window.rootViewController = launchViewController;
    __weak typeof(self) weakSelf = self;
    [GCDQueue executeInMainQueue:^{
        BOOL showNewFeature = [LCNewFeatureVC shouldShowNewFeature];
        if (showNewFeature) {

            LCNewFeatureVC *newFeatureVC = [LCNewFeatureVC newFeatureWithImageName:@"new_feature"
                                                                        imageCount:3
                                                                   showPageControl:YES
                                                                       finishBlock:^{
                                                                           if ([[MMAppSetting sharedSetting] haveLoginAddress]) {
                                                                               self.window.rootViewController = [[LMDBUpdataController alloc] initWithUpdateComplete:^(BOOL complete) {
                                                                                   if (complete) {
                                                                                       [weakSelf gestureLockVertifyWith:shortcutItem];
                                                                                   }
                                                                               }];
                                                                           } else {
                                                                               [self gestureLockVertifyWith:shortcutItem];
                                                                           }
                                                                       }];
            newFeatureVC.showSkip = YES;
            newFeatureVC.skipBlock = ^(void) {
                if ([[MMAppSetting sharedSetting] haveLoginAddress]) {
                    self.window.rootViewController = [[LMDBUpdataController alloc] initWithUpdateComplete:^(BOOL complete) {
                        if (complete) {
                            [weakSelf gestureLockVertifyWith:shortcutItem];
                        }
                    }];
                } else {
                    [self gestureLockVertifyWith:shortcutItem];
                }
            };
            newFeatureVC.pointCurrentColor = [UIColor blackColor];
            self.window.rootViewController = newFeatureVC;
        } else {
            if ([[MMAppSetting sharedSetting] haveLoginAddress]) {
                self.window.rootViewController = [[LMDBUpdataController alloc] initWithUpdateComplete:^(BOOL complete) {
                    if (complete) {

                        [self gestureLockVertifyWith:shortcutItem];
                    }
                }];
            } else {
                [weakSelf gestureLockVertifyWith:shortcutItem];
            }
        }
    }             afterDelaySecs:LANUCH_DURATION];
}


- (void)checkUpdate {

    VersionRequest *version = [VersionRequest new];

    version.version = [MMGlobal currentVersion];

    //channel app strore
    if ([SystemTool isNationChannel]) {
        version.category = 2;
    } else {
        version.category = 1;
    }

    int iosPlatform = 1;
    version.platform = iosPlatform;

    version.protocolVersion = socketProtocolVersion;
    [NetWorkOperationTool POSTWithUrlString:updateVersionUrl postData:version.data NotSignComplete:^(id response) {
        HttpNotSignResponse *httpNotResponse = (HttpNotSignResponse *) response;
        if (httpNotResponse.code == successCode) {
            NSData *data = [ConnectTool decodeHttpNotSignResponse:httpNotResponse];
            if (data) {
                NSError *error = nil;
                VersionResponse *versionResponse = [VersionResponse parseFromData:data error:&error];
                [SessionManager sharedManager].currentNewVersionInfo = versionResponse;
            }
        }
    }                                  fail:^(NSError *error) {

    }];

}

#pragma mark - APNS

- (void)registerPushForIOS8 {
    //Types
    UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;

    //Actions
    UIMutableUserNotificationAction *acceptAction = [[UIMutableUserNotificationAction alloc] init];

    acceptAction.identifier = @"ACCEPT_IDENTIFIER";
    acceptAction.title = @"Accept";
    acceptAction.activationMode = UIUserNotificationActivationModeForeground;
    acceptAction.destructive = NO;
    acceptAction.authenticationRequired = NO;

    //Categories
    UIMutableUserNotificationCategory *inviteCategory = [[UIMutableUserNotificationCategory alloc] init];
    inviteCategory.identifier = @"INVITE_CATEGORY";
    [inviteCategory setActions:@[acceptAction] forContext:UIUserNotificationActionContextDefault];
    [inviteCategory setActions:@[acceptAction] forContext:UIUserNotificationActionContextMinimal];
    NSSet *categories = [NSSet setWithObjects:inviteCategory, nil];

    UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:categories];
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}


- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= _IPHONE80_

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {

}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler {
    if ([identifier isEqualToString:@"ACCEPT_IDENTIFIER"]) {
        DDLogInfo(@"ACCEPT_IDENTIFIER is clicked");
    }
    completionHandler();
}

#endif

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {


    NSString *deviceTokenString2 = [[[[deviceToken description] stringByReplacingOccurrencesOfString:@"<" withString:@""]
            stringByReplacingOccurrencesOfString:@">" withString:@""]
            stringByReplacingOccurrencesOfString:@" " withString:@""];
    DDLogInfo(@"deviceToken：%@", deviceTokenString2);
    self.deviceToken = deviceTokenString2;
    [IMService instance].deviceToken = deviceTokenString2;
    if ([IMService instance].RegisterDeviceTokenComplete) {
        [IMService instance].RegisterDeviceTokenComplete(deviceTokenString2);
    }
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    DDLogError(@"Register fail");
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    DDLogError(@"didReceiveRemoteNotification %@", userInfo);
}

- (MainTabController *)mainTabController {
    if (!_mainTabController) {
        _mainTabController = [[MainTabController alloc] init];
    }
    return _mainTabController;
}

- (void)resetMainTabController {
    _mainTabController = nil;
}


#pragma mark - 3D touch

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    if (![[MMAppSetting sharedSetting] haveGesturePass] && [[MMAppSetting sharedSetting] haveLoginAddress]) {
        SendNotify(@"ShortcutInbackgroundNotification", shortcutItem.type);
    } else {
        [GCDQueue executeInMainQueue:^{
            [self gestureLockVertifyWith:shortcutItem];
        }             afterDelaySecs:LANUCH_DURATION];
    }
}

@end
