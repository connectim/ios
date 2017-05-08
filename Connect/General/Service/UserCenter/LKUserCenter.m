//
//  LKUserCenter.m
//  Connect
//
//  Created by MoHuilin on 16/6/21.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LKUserCenter.h"
#import "AppDelegate.h"
#import "KeyHandle.h"
#import "NSString+Hash.h"
#import "IMService.h"
#import "NetWorkOperationTool.h"
#import "Protofile.pbobjc.h"
#import "BaseDB.h"
#import "LocalAccountLoginPage.h"
#import "PhoneLoginPage.h"
#import "Protofile.pbobjc.h"
#import "WallteNetWorkTool.h"
#import "UserDBManager.h"
#import "GroupDBManager.h"
#import "RecentChatDBManager.h"
#import "LMMessageExtendManager.h"
#import "MessageDBManager.h"
#import "CIImageCacheManager.h"
#import "ExportEncodePrivkeyPage.h"
#import "Protofile.pbobjc.h"
#import "LMConversionManager.h"
#import "LMLinkManDataManager.h"

@interface LKUserCenter ()

@property (nonatomic ,strong) AccountInfo *loginUser;

@end

@implementation LKUserCenter

static LKUserCenter *center = nil;

+ (LKUserCenter *)shareCenter{
    @synchronized(self) {
        if(center == nil) {
            center = [[[self class] alloc] init];
        }
    }
    return center;
}

- (instancetype)init{
    if (self = [super init]) {
    }
    
    return self;
}

+(id)allocWithZone:(NSZone *)zone
{
    @synchronized(self)
    {
        if (center == nil)
        {
            center = [super allocWithZone:zone];
            return center;
        }
    }
    return nil;
}

- (AccountInfo *)currentLoginUser{
    
    if (self.loginUser) {
        return self.loginUser;
    }
    
    NSString *prikey = [MMAppSetting sharedSetting].privkey;
    if (GJCFStringIsNull(prikey)) {
        return self.loginUser;
    }
    AccountInfo *loginUser = [[MMAppSetting sharedSetting] getLoginChainUsersByKey:prikey];
    if (!loginUser) {
        [GCDQueue executeInMainQueue:^{
            SendNotify(LKUserCenterLoginStatusNoti,nil);
        }];
    } else{
        self.loginUser = loginUser;
    }

    return loginUser;

}

- (NSString *)getLocalGCDEcodePass{
    return [[KeyHandle getPassByPrikey:[self currentLoginUser].prikey] sha256String];
}


- (void)LoginUserWithAccountUser:(AccountInfo *)loginUser
                    withPassword:(NSString *)password
                    withComplete:(LKUserCenterLoginCompleteBlock)complete{
    
    self.loginUser = loginUser;
    NSDictionary *decodeDict = [KeyHandle decodePrikeyGetDict:loginUser.encryption_pri withPassword:password];
    // Cache head
    [[CIImageCacheManager sharedInstance] contactAvatarWithUrl:loginUser.avatar complete:nil];
    NSError *error = nil;
    NSString *privkey = nil;
    
    if (decodeDict) {
        if (decodeDict[@"is_success"]) {
            loginUser.prikey = decodeDict[@"prikey"];
            
            // Database migration
            [BaseDB migrationWithUserPublicKey:loginUser.pub_key];
            
            privkey = loginUser.prikey;
            if (GJCFStringIsNull(loginUser.address)) { // May be swept of the user information
                //
                loginUser.address = [KeyHandle getAddressByPrivKey:privkey];
                loginUser.pub_key = [KeyHandle createPubkeyByPrikey:privkey];
                loginUser.isSelected = NO;
                // Download avatar
                SearchUser *usrAddInfo = [[SearchUser alloc] init];
                usrAddInfo.criteria = loginUser.address;
                [NetWorkOperationTool POSTWithUrlString:ContactUserSearchUrl postProtoData:usrAddInfo.data complete:^(id response) {
                    HttpResponse *hResponse = (HttpResponse *)response;
                    
                    if (hResponse.code != successCode) {
                        DDLogError(@"失败");
                        return;
                    }
                    NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
                    if (data) {
                        UserInfo *user = [UserInfo parseFromData:data error:nil];
                        DDLogInfo(@"%@",user);
                        loginUser.avatar = user.avatar;
                        loginUser.lastLoginTime = [[NSDate date] timeIntervalSince1970];
                        //保存keyChain
                        [[MMAppSetting sharedSetting] saveUserToKeyChain:loginUser];
                    }
                } fail:^(NSError *error) {
                    
                }];
                
            }
            // Call the login page
            [GCDQueue executeInMainQueue:^{
                AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
                [app showMainTabPage:loginUser];
            }];
            
            // Update the last login time
            [[MMAppSetting sharedSetting] updataUserLashLoginTime:loginUser.address];
            
            // Save the current login user information
            [[MMAppSetting sharedSetting]  saveLoginUserPrivkey:loginUser.prikey];
            [[MMAppSetting sharedSetting]  saveLoginAddress:loginUser.address];
            if (![[MMAppSetting sharedSetting] isHaveSyncBlickMan]) {
                // download black list
                [SetGlobalHandler blackListDownComplete:^(NSArray *blackList) {
                }];
            }
            
            if (![[MMAppSetting sharedSetting] isHaveSyncPaySet]) {
                [SetGlobalHandler getPaySetComplete:^(NSError *erro) {
                    if (erro) {
                        return ;
                    }
                }];
            }
            
            if (![[MMAppSetting sharedSetting] isHaveSyncUserTags]) {
                [SetGlobalHandler tagListDownCompelete:^(NSArray *tags) {
                    for (NSString *tag in tags) {
                        if ([[UserDBManager sharedManager] getUserTags:tag].count <= 0) {
                            [SetGlobalHandler tag:tag downUsers:^(NSArray *users) {
                                
                            }];
                        };
                    }
                }];
            }
            if (![[MMAppSetting sharedSetting] isHaveSyncPrivacy]) {
                [SetGlobalHandler syncPrivacyComplete:nil];
            }
            
            // Initialize the purse balance
            [WallteNetWorkTool queryAmountByAddress:loginUser.address complete:^(NSError *erro, long long amount, NSString *errorMsg) {
                if (GJCFStringIsNull(errorMsg)) {
                    [[MMAppSetting sharedSetting] saveBalance:amount];
                }
            }];
            
        }
    } else{
        error = [NSError errorWithDomain:@"Decryption failed" code:-1 userInfo:nil];
    }

    if (complete) {
        complete(privkey,error);
    }
}

- (void)loginOutByServerWithInfo:(id)info{
    // Empt the app's badge
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    // Disconnect socket
    [[IMService instance] quitUser];
    self.loginUser = nil;
    [[MMAppSetting sharedSetting]  deleteLoginUser];
    [[MMAppSetting sharedSetting]  cancelGestursPass];
    [MMAppSetting sharedSetting].privkey = nil;
    // Empty a single column object
    [UserDBManager tearDown];
    [GroupDBManager tearDown];
    [RecentChatDBManager tearDown];
    [LMMessageExtendManager tearDown];
    [MessageDBManager tearDown];
    
    // Clear the single column object to clear the mainTabController
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate resetMainTabController];
    
    // Empty the session object
    [[LMConversionManager sharedManager] clearAllModel];
    [GCDQueue executeInMainQueue:^{
        PhoneLoginPage *phonePage = [[PhoneLoginPage alloc] init];
        LocalAccountLoginPage *page = [[LocalAccountLoginPage alloc] init];
        AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
        app.window.rootViewController = nil;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:phonePage];
        [nav pushViewController:page animated:NO];
        app.window.rootViewController = nav;
        if (info) {
            [page showLogoutTipWithInfo:info];
        }
    }];
    // Clear contact-related information
    [[LMLinkManDataManager sharedManager] clearArrays];
}


- (void)bindNewPhone:(NSString *)phone{

    self.loginUser.bondingPhone = phone;
    [GCDQueue executeInBackgroundPriorityGlobalQueue:^{
        [[MMAppSetting sharedSetting]  saveUserToKeyChain:self.loginUser];
    }];
    
    [self sendUserInfoUpdateNotification];
}

- (void)updateUserInfo:(AccountInfo *)user{
    [[MMAppSetting sharedSetting]  saveUserToKeyChain:user];
    [self sendUserInfoUpdateNotification];
}

- (void)registerUser:(AccountInfo *)user{
    self.loginUser = user;
    // Database migration
    [BaseDB migrationWithUserPublicKey:user.pub_key];
    // save current user message
    [[MMAppSetting sharedSetting]  saveLoginUserPrivkey:self.loginUser.prikey];
    [[MMAppSetting sharedSetting]  saveLoginAddress:self.loginUser.address];    
    // Call the login page
    [GCDQueue executeInMainQueue:^{
        AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
        self.isFristLogin = YES;
        [app showMainTabPage:self.loginUser];
    }];
}


/**
 *  Issue a notification of user information updates
 */
- (void)sendUserInfoUpdateNotification{
    [GCDQueue executeInMainQueue:^{
        SendNotify(LKUserCenterUserInfoUpdateNotification, self.loginUser);
    }];
}


- (void)showCurrentPage{
    __weak __typeof(&*self)weakSelf = self;
    NSString *prikey = [MMAppSetting sharedSetting].privkey;
    if (prikey) {
        NSArray *users = [[MMAppSetting sharedSetting]  getKeyChainUsers];
        NSString *address = [KeyHandle getAddressByPrivKey:prikey];
        for (AccountInfo *user in users) {
            if ([user.address isEqualToString:address]) {
                self.loginUser = user;
                self.loginUser.prikey = prikey;
                break;
            }
        }
        if (!self.loginUser) {
        }
        [GCDQueue executeInMainQueue:^{
            SendNotify(LKUserCenterLoginStatusNoti,weakSelf.loginUser);
        }];
    } else{
        [GCDQueue executeInMainQueue:^{
            SendNotify(LKUserCenterLoginStatusNoti,nil);
        }];
    }
}

@end
