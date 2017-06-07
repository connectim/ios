//
//  MMAppSetting.m
//  XChat
//
//  Created by MoHuilin on 16/2/16.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "MMAppSetting.h"
#import "FXKeychain.h"
#import "NSString+DictionaryValue.h"
#import "GJCFUitils.h"

static MMAppSetting *manager = nil;

@interface MMAppSetting ()

@property (nonatomic ,strong) NSMutableDictionary *userSet;
@property (nonatomic ,strong) NSMutableArray *temAllSets;
@property (nonatomic ,copy) NSString *path;

@end

@implementation MMAppSetting

+ (MMAppSetting *)sharedSetting{
    @synchronized(self) {
        if(manager == nil) {
            manager = [[[self class] alloc] init];
        }
    }
    return manager;
}

+(id)allocWithZone:(NSZone *)zone
{
    @synchronized(self)
    {
        if (manager == nil)
        {
            manager = [super allocWithZone:zone];
            return manager;
        }
    }
    return nil;
}


- (instancetype)init{
    if (self = [super init]){
        [self defaultSet];
    }
    
    return self;
}

- (void)defaultSet{
    
    NSString *plistPath = GJCFAppDoucmentPath(@"AccountSetInfo.plist");
    self.path = plistPath;
    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    self.temAllSets = [data valueForKey:@"accounts"];
    if (self.temAllSets.count <= 0) {
        self.temAllSets = [NSMutableArray array];
    } else{
        self.temAllSets = self.temAllSets.mutableCopy;
    }
    // Set the preferences for the currently logged-in user
    [self setUserDefaultConfig:[self getLoginAddress]];
    
    // Set pirivkey
    [self getLoginUserPrivkey];
}

- (void)setUserDefaultConfig:(NSString *)loginAddress{
    if (GJCFStringIsNull(loginAddress)) {
        return;
    }
    NSMutableDictionary *dict = nil;
    for (NSDictionary *temD in self.temAllSets) {
        NSString *address = [[temD allKeys] firstObject];
        if ([address isEqualToString:loginAddress]) {
            dict = [temD valueForKey:address];
            self.userSet = dict;
            break;
        }
    }
    if (!dict) { // Save one for a new user
        NSMutableDictionary *userSet = [NSMutableDictionary dictionary];
        // Set the default value
        [userSet setObject:MINNER_FEE forKey:@"transferfee"];
        [userSet setObject:@(NO) forKey:@"autoCalculateTransactionFee"];
        [userSet setObject:MAX_MINNER_FEE forKey:@"setMaxTransferFee"];
        [userSet setObject:@(YES) forKey:@"appsetaddress"];
        [userSet setObject:@(YES) forKey:@"appsetphone"];
        [userSet setObject:@(NO) forKey:@"appsetsysbook"];
        [userSet setObject:@(YES) forKey:@"appsetverfiy"];
        [userSet setObject:@(YES) forKey:@"voicenoti"];
        [userSet setObject:@(YES) forKey:@"vibratenoti"];
        [userSet setObject:@(NO) forKey:@"setAllowRecomand"];
        [userSet setObject:@"" forKey:@"im.conect.contactversionkey"];
      
        NSMutableString *currencySymbol = [[NSLocale currentLocale] objectForKey:NSLocaleCurrencySymbol];
        if ([currencySymbol isEqualToString:@"￥"]) {
            [userSet setObject:@"cny/￥" forKey:@"currency"];
        } else if ([currencySymbol isEqualToString:@"₽"]){
            [userSet setObject:@"rub/₽" forKey:@"currency"];
        } else {
            [userSet setObject:@"usd/$" forKey:@"currency"];
        }
        self.userSet = userSet;
        NSMutableDictionary *user = [NSMutableDictionary dictionary];
        [user setValue:userSet forKey:loginAddress];
        [self.temAllSets objectAddObject:user];
        [self saveToFile];
    }
}

- (void)saveToFile{
    // save
    NSMutableDictionary *all = @{@"accounts":self.temAllSets}.mutableCopy;
    BOOL result = [all writeToFile:self.path atomically:YES];
    if (result) {
        DDLogInfo(@"save success");
    } else{
        DDLogError(@"save filure");
    }
}

- (void)deleteLocalUserWithAddress:(NSString *)address{
    if (!GJCFStringIsNull(address)) {
        for (NSDictionary *userDefault in self.temAllSets) {
            if ([[userDefault.allKeys firstObject] isEqualToString:address]) {
                [self.temAllSets removeObject:userDefault];
                break;
            }
        }
        [self saveToFile];
    }
}

#pragma mark - Basic read and write delete method
- (void)removeObjectForKey:(NSString *)key{
    if (self.userSet) {
        [self.userSet removeObjectForKey:key];
        [self saveToFile];
    }
}
- (NSString *)getValue:(NSString *)key{
    return [self.userSet objectForKey:key];
}
- (void)setValue:(id)value forKey:(NSString *)key{
    if ([value isKindOfClass:[NSString class]]) {
        if (GJCFStringIsNull(value)) {
            value = @"";
        }
    }
    if (self.userSet) {
        [self.userSet setObject:value forKey:key];
        [self saveToFile];
    }
}


#pragma mark - Login user
- (void)deleteLoginUser{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:@"im.conect.loginuserkey"];
    [userDefaults removeObjectForKey:@"loginaddress"];
    [userDefaults synchronize];
    [[FXKeychain defaultKeychain] removeObjectForKey:@"im.conect.loginuserkey"];
    [[FXKeychain defaultKeychain] removeObjectForKey:@"loginaddress"];
    self.userSet = nil;
}


- (NSString *)getLoginAddress{
    NSString *address = [[NSUserDefaults standardUserDefaults] objectForKey:@"loginaddress"];
    return address;
}

- (BOOL)haveLoginAddress{
    NSString *address = [[NSUserDefaults standardUserDefaults] objectForKey:@"loginaddress"];
    if (!GJCFStringIsNull(address)) {
        if ([[LKUserCenter shareCenter] currentLoginUser]) {
            return YES;
        }
        [self deleteLoginUser];
        return NO;
    }
    return NO;
}

- (void )saveLoginAddress:(NSString *)address{
    // Save the login information
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:address forKey:@"loginaddress"];
    [userDefaults synchronize];
    // Configure the basic information for login users
    [self setUserDefaultConfig:address];
}

- (NSString *)getLoginUserPrivkey{

    NSString *login = [[NSUserDefaults standardUserDefaults] objectForKey:@"im.conect.loginuserkey"];
//    NSString *login = [[FXKeychain defaultKeychain] objectForKey:@"im.conect.loginuserkey"];
    if (!GJCFStringIsNull(login) &&[KeyHandle checkPrivkey:login]) {
        self.privkey = login;
    }
    
    return login;
}

- (void)saveLoginUserPrivkey:(NSString *)privkey{
    
//    [[FXKeychain defaultKeychain] setObject:user forKey:@"im.conect.loginuserkey"];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:privkey forKey:@"im.conect.loginuserkey"];
    [userDefaults synchronize];
}

#pragma mark - Address book version number
/**
 *  Address book version number
 *
 *  @param
 */
- (void)saveContactVersion:(NSString *)version{
    if (!version || version.length == 0) {
        NSString *localVersion = [self getValue:@"im.conect.contactversionkey"];
        if ([localVersion integerValue] <= 0) {
            version = @"0";
        } else{
            version = localVersion;
        }
    }
    [self setValue:version forKey: @"im.conect.contactversionkey"];
}
/**
 *  Get the address book version number
 *
 *  @return
 */
- (NSString *)getContactVersion{
    return [self getValue:@"im.conect.contactversionkey"];
}
#pragma set
- (void)setAllowAddress{
    [self setValue:@(YES) forKey:@"appsetaddress"];
}
- (void)setDelyAddress{
    [self removeObjectForKey:@"appsetaddress"];
}
- (BOOL)isAllowAddress{
    return [[self getValue:@"appsetaddress"] boolValue];
}

#pragma mark - Is recommended
- (void)setAllowRecomand{
    [self setValue:@(YES) forKey:@"setAllowRecomand"];
}
- (void)setDelyRecomand{
    [self removeObjectForKey:@"setAllowRecomand"];
}
- (BOOL)isAllowRecomand{
    return [[self getValue:@"setAllowRecomand"] boolValue];
}
#pragma mark - Whether or not the method of obtaining the old group was executed
- (void)setGroupExecuted
{
    [self setValue:@(YES) forKey:@"groupExecuted"];
}
- (BOOL)isGroupExecuted
{
   return [[self getValue:@"groupExecuted"] boolValue];
}
- (void)setAllowPhone{
    [self setValue:@(YES) forKey:@"appsetphone"];
}
- (void)setDelyPhone{
    [self removeObjectForKey:@"appsetphone"];
}
- (BOOL)isAllowPhone{
    return [[self getValue:@"appsetphone"] boolValue];
}



- (void)setNeedVerfiy{
    [self setValue:@(YES) forKey:@"appsetverfiy"];
}
- (void)setDelyVerfiy{
    [self removeObjectForKey:@"appsetverfiy"];
}
- (BOOL)isAllowVerfiy{
    return [[self getValue:@"appsetverfiy"] boolValue];
}



- (void)setAutoSysBook{
    [self setValue:@(YES) forKey:@"appsetsysbook"];
}
- (void)setNoAutoSysBook{
    [self removeObjectForKey:@"appsetsysbook"];
}
- (BOOL)isAutoSysBook{
    return [[self getValue:@"appsetsysbook"] boolValue];
}

- (NSTimeInterval)getLastSyncContactTime{
    return [[self getValue:@"appsetsysbooktime"] integerValue];
}
- (void)setLastSyncContactTime{
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    
    [self setValue:@(currentTime) forKey:@"appsetsysbooktime"];
}
- (void)removeLastSyncContactTime{
    [self removeObjectForKey:@"appsetsysbooktime"];
}




#pragma mark - Save the user to keyChain

- (void)updataUserLashLoginTime:(NSString *)address{
    NSMutableArray *users = [NSMutableArray arrayWithArray:[self getKeyChainUsers]];

    for (AccountInfo *userInfo in users) {
        if ([userInfo.address isEqualToString:address]) {
            userInfo.lastLoginTime = [[NSDate date] timeIntervalSince1970];
            break;
        }
    }

    NSMutableArray *usersDicts = [NSMutableArray array];
    for (AccountInfo *userInfo in users) {
        NSDictionary *userD = [userInfo mj_JSONObject];
        [usersDicts objectAddObject:userD];
    }
    
    // Save to keychain
    [[FXKeychain defaultKeychain] setObject:[usersDicts mj_JSONString] forKey:@"im.connect.keychainusers"];
    
}

- (void)saveUserAnduploadLoginTimeToKeyChain:(AccountInfo *)user{
    
    NSMutableArray *users = [NSMutableArray arrayWithArray:[self getKeyChainUsers]];
    if (!users) {
        users = [NSMutableArray array];
    }
    AccountInfo *repleceUser = nil;
    for (AccountInfo *userInfo in users) {
        if ([userInfo.address isEqualToString:user.address] || [userInfo.pub_key isEqualToString:user.pub_key]) {
            repleceUser = userInfo;
            break;
        }
    }
    if (repleceUser) {
        [users removeObject:repleceUser];
    }
    user.lastLoginTime = [[NSDate date] timeIntervalSince1970];
    [users objectAddObject:user];
    NSMutableArray *usersDicts = [NSMutableArray array];
    for (AccountInfo *userInfo in users) {
        NSDictionary *userD = [userInfo mj_JSONObject];
        [usersDicts objectAddObject:userD];
    }
    //Save to keychain
    [[FXKeychain defaultKeychain] setObject:[usersDicts mj_JSONString] forKey:@"im.connect.keychainusers"];
}


- (void)saveUserToKeyChain:(AccountInfo *)user{
    
    NSMutableArray *users = [NSMutableArray arrayWithArray:[self getKeyChainUsers]];
    if (!users) {
        users = [NSMutableArray array];
    }
    
    AccountInfo *repleceUser = nil;
    
    for (AccountInfo *userInfo in users) {
        if ([userInfo.address isEqualToString:user.address] || [userInfo.pub_key isEqualToString:user.pub_key]) {
            repleceUser = userInfo;
            break;
        }
    }
    
    if (repleceUser) {
        [users removeObject:repleceUser];
    }
    [users objectAddObject:user];
    
    NSMutableArray *usersDicts = [NSMutableArray array];
    for (AccountInfo *userInfo in users) {
        NSDictionary *userD = [userInfo mj_JSONObject];
        [usersDicts objectAddObject:userD];
    }
    
    //Save to keychain
    [[FXKeychain defaultKeychain] setObject:[usersDicts mj_JSONString] forKey:@"im.connect.keychainusers"];
}

- (void)deleteKeyChainUser{
    [[FXKeychain defaultKeychain] removeObjectForKey:@"im.connect.keychainusers"];
}

- (void)deleteKeyChainUserWithUser:(AccountInfo *)user{
    
    if (!user) {
        return;
    }
    // Remove the user
    NSMutableArray *users = [self getKeyChainUsers].mutableCopy;
    AccountInfo *deleteUser = nil;
    
    for (AccountInfo *userInfo in users) {
        if ([userInfo.address isEqualToString:user.address] || [userInfo.pub_key isEqualToString:user.pub_key]) {
            deleteUser = userInfo;
            break;
        }
    }
    
    if (!deleteUser) {
        return;
    }
    [users removeObject:deleteUser];
    
    
    NSMutableArray *usersDicts = [NSMutableArray array];
    for (AccountInfo *userInfo in users) {
        NSDictionary *userD = [userInfo mj_JSONObject];
        [usersDicts objectAddObject:userD];
    }
    
    // Save to keychain
    [[FXKeychain defaultKeychain] setObject:[usersDicts mj_JSONString] forKey:@"im.connect.keychainusers"];
    
}

- (AccountInfo *)getLoginChainUsersByEncodePri:(NSString *)encodePri{
    NSArray *users = [self  getKeyChainUsers];
    AccountInfo *userInfo = nil;
    for (AccountInfo *user in users) {
        if ([user.encryption_pri isEqualToString:encodePri]) {
            userInfo = user;
            break;
        }
    }
    return userInfo;

}

- (AccountInfo *)getLoginChainUsersByKey:(NSString *)key{
    NSArray *users = [self  getKeyChainUsers];
    NSString *address = [KeyHandle getAddressByPrivKey:key];
    AccountInfo *loginUser = nil;
    for (AccountInfo *user in users) {
        if ([user.address isEqualToString:address]) {
            loginUser = user;
            loginUser.prikey = key;
            break;
        }
    }
    return loginUser;
}

- (NSArray *)getKeyChainUsers{
    NSString *allUsersJson = [[FXKeychain defaultKeychain] objectForKey:@"im.connect.keychainusers"];
    
    NSMutableArray *users = [NSMutableArray arrayWithArray:[AccountInfo mj_objectArrayWithKeyValuesArray:allUsersJson]];
    
    [users sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        AccountInfo *user1 = obj1;
        AccountInfo *user2 = obj2;
        if (user1.lastLoginTime < user2.lastLoginTime) {
            return NSOrderedDescending;
        } else{
            return NSOrderedAscending;
        }
    }];
    
    
    return users;
}

#pragma mark - gesture password
- (void)openGesturePassWithPass:(NSString *)pass{
    if (GJCFStringIsNull(pass)) {
        return;
    }
    pass = [KeyHandle getHash256:pass];
    [self setValue:@(YES) forKey:@"im.connect.gesturepass"];
    
    NSString *privkey = [[LKUserCenter shareCenter] currentLoginUser].prikey;
    NSString *aad = [[NSString stringWithFormat:@"%d",arc4random() % 100 + 1000] sha1String];
    NSString *iv = [[NSString stringWithFormat:@"%d",arc4random() % 100 + 1000] sha1String];
    
    NSDictionary *encodeDict = [KeyHandle xtalkEncodeAES_GCM:pass data:privkey aad:aad iv:iv];
    NSString *ciphertext = [encodeDict valueForKey:@"encryptedDatastring"];
    NSString *tag = [encodeDict valueForKey:@"tagstring"];
    
    NSDictionary *saveDict = @{@"ciphertext":ciphertext,
                               @"tag":tag,
                               @"aad":aad,
                               @"iv":iv};
    
    [self saveLoginUserPrivkey:[saveDict mj_JSONString]];

    
}
- (BOOL)haveGesturePass{
    return [[self getValue:@"im.connect.gesturepass"] boolValue];
}
- (void)cancelGestursPass{
    [self removeObjectForKey:@"im.connect.gesturepass"];
    NSString *privkey = [[LKUserCenter shareCenter] currentLoginUser].prikey;
    [self saveLoginUserPrivkey:privkey];
}

- (BOOL)vertifyGesturePass:(NSString *)pass{
    if (GJCFStringIsNull(pass)) {
        return NO;
    }
    pass = [KeyHandle getHash256:pass];
    NSString *encodePrivkey = [self getLoginUserPrivkey];
    NSDictionary *dict = [encodePrivkey dictionaryValue];
    if (dict) {
        GcmDataModel *model = [GcmDataModel gcmDataWith:dict];
        NSString *privkey = [KeyHandle xtalkDecodeAES_GCM:pass data:model.ciphertext aad:model.aad iv:model.iv tag:model.tag];
        if (GJCFStringIsNull(privkey)) {
            return NO;
        }
        self.privkey = privkey;
    } else{
        self.privkey = encodePrivkey;
    }
    return YES;
    
}

- (void)setLastErroGestureTime:(NSTimeInterval)time{
    [self setValue:@(time) forKey:@"gesturelasterrortime"];
}
- (NSTimeInterval)getLastErroGestureTime{
    return [[self getValue:@"gesturelasterrortime"] doubleValue];
}
- (void)removeLastErroGestureTime{
    [self removeObjectForKey:@"gesturelasterrortime"];
}


#pragma mark - touch id
// Verify whether to support fingerprint payment (system iOS8.0 +, for security jailbreak users can not use)
-(BOOL)isDeviceSupportFingerPay{
    BOOL isSystemValied = [[UIDevice currentDevice].systemVersion floatValue] > 8.0;
    BOOL isJailBreak    = [self isJailBreak];
    if (isSystemValied && !isJailBreak) {
        // Fingerprint payment conditions
        return YES;
    }
    return NO;
}
// To determine whether to escape
char* printEnv(void)
{
    char *env = getenv("DYLD_INSERT_LIBRARIES");
    NSLog(@"%s", env);
    return env;
}

- (BOOL)isJailBreak
{
    if (printEnv()) {
        NSLog(@"The device is jail broken!");
        return YES;
    }
    NSLog(@"The device is NOT jail broken!");
    return NO;
}

- (void)setFingerPay{
    BOOL isValied = [self isDeviceSupportFingerPay];
    [self setValue:@(isValied) forKey:@"fingerpay"];
}
- (void)cacelFingerPay{
    [self removeObjectForKey:@"fingerpay"];
}
- (BOOL)needFingerPay{
    return [[self getValue:@"fingerpay"] boolValue];
}

#pragma mark - Free payment
- (void)setNoPassPay{
    [self setValue:@(YES) forKey:@"nopasspay"];
}
- (void)cacelNoPassPay{
    [self removeObjectForKey:@"nopasspay"];
}
- (BOOL)isCanNoPassPay{
    return [[self getValue:@"nopasspay"] boolValue];
}

#pragma mark - Transfer fee
- (void)setTransferFee:(NSString *)fee{
    [self setValue:fee forKey:@"transferfee"];
}
- (void)removeTransfer{
    [self removeObjectForKey:@"transferfee"];
}
- (long long)getTranferFee{
    double fee = [[self getValue:@"transferfee"] doubleValue];
    if (fee <= 0) {
        [self setValue:MINNER_FEE forKey:@"transferfee"];
        fee = [MINNER_FEE longLongValue];
    }
    return fee;
}

- (void)setMaxTransferFee:(NSString *)fee{
    [self setValue:fee forKey:@"setMaxTransferFee"];
}
- (void)removeMaxTransfer{
    [self removeObjectForKey:@"setMaxTransferFee"];
}
- (long long)getMaxTranferFee{
    double fee = [[self getValue:@"setMaxTransferFee"] doubleValue];
    if (fee <= 0) {
        [self setValue:MAX_MINNER_FEE forKey:@"setMaxTransferFee"];
        fee = [MAX_MINNER_FEE longLongValue];
    }
    return fee;
}
#pragma mark - Payment password
- (void)setPayPass:(NSString *)pass{
    [self setValue:pass forKey:@"password"];
}
- (void)removePayPass{
    [self removeObjectForKey:@"password"];
}
- (NSString *)getPayPass{
    return [self getValue:@"password"];
}
- (void)setpaypassVersion:(NSString *)version{
    [self setValue:version forKey:@"paypassVersion"];
}
- (NSString *)getpaypassVersion{
    NSString *version = [self getValue:@"paypassVersion"];
    if (GJCFStringIsNull([self getValue:@"paypassVersion"])) {
        version = @"0";
    }
    return version;
}


#pragma mark -Whether the user tags are synchronized
- (void)haveSyncUserTags; {
    [self setValue:@(YES) forKey:@"haveSyncUserTags"];
    
}
- (BOOL)isHaveSyncUserTags{
    return [[self getValue:@"haveSyncUserTags"] boolValue];
}

#pragma mark - Whether to synchronize privacy settings
- (void)haveSyncPrivacy{
    [self setValue:@(YES) forKey:@"haveSyncPrivacy"];
}
- (BOOL)isHaveSyncPrivacy{
    return [[self getValue:@"haveSyncPrivacy"] boolValue];
}

#pragma mark - Whether or not a registered address book has been obtained
- (void)haveSyncPhoneContactRegister{
    [self setValue:@(YES) forKey:@"haveSyncPhoneContactRegister"];
}
- (BOOL)isHavePhoneContactRegister{
    return [[self getValue:@"haveSyncPhoneContactRegister"] boolValue];
}

#pragma mark - Whether to synchronize the blacklist
- (void)haveSyncBlickMan{
    [self setValue:@(YES) forKey:@"haveSyncBlickMan"];
}
- (BOOL)isHaveSyncBlickMan{
    return [[self getValue:@"haveSyncBlickMan"] boolValue];
}

#pragma mark - Whether the payment setup data is synchronized
- (void)haveSyncPaySet{
    [self setValue:@(YES) forKey:@"haveSyncPaySet"];
}
- (BOOL)isHaveSyncPaySet{
    return [[self getValue:@"haveSyncPaySet"] boolValue];
}

#pragma mark - Whether to synchronize frequently used groups
- (void)haveSyncCommonGroup{
    [self setValue:@(YES) forKey:@"haveSyncCommonGroup"];
}
- (BOOL)isHaveCommonGroup{
    return [[self getValue:@"haveSyncCommonGroup"] boolValue];
}

#pragma mark - Need to be prompted to read after the description
- (void)setDontShowSnapchatTip{
    [self setValue:@(YES) forKey:@"setDontShowSnapchatTip"];
}
- (BOOL)isDontShowSnapchatTip{
    return [[self getValue:@"setDontShowSnapchatTip"] boolValue];
}

#pragma mark - Whether to synchronize the address Bo
- (void)haveSyncAddressbook{
    [self setValue:@(YES) forKey:@"haveSyncAddressbook"];
}
- (BOOL)isHaveAddressbook{
    return [[self getValue:@"haveSyncAddressbook"] boolValue];
}

#pragma mark - currency
- (void)setcurrency:(NSString *)currency{
    [self setValue:currency forKey:@"currency"];
}
- (NSString *)getcurrency{
    NSString *currency = [self getValue:@"currency"];
    if (GJCFStringIsNull(currency)) {
        NSMutableString *currencySymbol = [[NSLocale currentLocale] objectForKey:NSLocaleCurrencySymbol];
        if ([currencySymbol containsString:@"￥"]) {
            currency =[NSString stringWithFormat:@"cny/%@", currencySymbol];
        } else if ([currencySymbol containsString:@"₽"]){
            currency =[NSString stringWithFormat:@"rub/%@", currencySymbol];
        } else {
            currency =[NSString stringWithFormat:@"usd/%@", @"$"];
        }
        
        [self setcurrency:currency];
    }
    
    return currency;
}


#pragma mark - notification
- (void)openVoiceNoti{
    [self setValue:@(YES) forKey:@"voicenoti"];
}
- (void)closeVoiceNoti{
    [self removeObjectForKey:@"voicenoti"];
}
- (BOOL)canVoiceNoti{
    return [[self getValue:@"voicenoti"] boolValue];
}

- (void)openVibrateNoti{
    [self setValue:@(YES) forKey:@"vibratenoti"];
}
- (void)closeVibrateNoti{
    [self removeObjectForKey:@"vibratenoti"];
}
- (BOOL)canVibrateNoti{
    return [[self getValue:@"vibratenoti"] boolValue];
}

#pragma mark - Wallet balance
- (void)saveBalance:(long long int)balance{
    [self setValue:[NSString stringWithFormat:@"%lld",balance] forKey:@"balance"];
}
- (long long int)getBalance{
    return [[self getValue:@"balance"] integerValue];
}

- (void)saveAvaliableAmount:(NSString *)balance{
    if (!GJCFStringIsNull(balance)) {
        [self setValue:balance forKey:@"avaliableAmount"];
    }
}
- (long long int)getAvaliableAmount{
    return [[self getValue:@"avaliableAmount"] integerValue];
}

#pragma mark - rate
- (void)saveRate:(float)rate{
    [self setValue:[NSString stringWithFormat:@"%f",rate] forKey:@"rate"];
}
- (double)getRate{
    return [[self getValue:@"rate"] doubleValue];
}


#pragma mark -free
- (void)saveEstimatefee:(NSString *)estimatefee{
    GJCFUDFCache(@"getEstimatefee", estimatefee);
    GJCFUDFCache(@"getEstimatefeeDate", [NSDate date]);
}
- (double)getEstimatefee{
    return [GJCFUDFGetValue(@"getEstimatefee") doubleValue];
}

- (void)setAutoCalculateTransactionFee:(BOOL)autoCalculate{
    [self setValue:@(autoCalculate) forKey:@"autoCalculateTransactionFee"];
}

- (BOOL)canAutoCalculateTransactionFee{
    return [[self getValue:@"autoCalculateTransactionFee"] boolValue];
}


- (BOOL)needReCacheEstimatefee{
    return GJCFDateDaysAgo(GJCFUDFGetValue(@"getEstimatefeeDate")) >= 1;
}

@end
