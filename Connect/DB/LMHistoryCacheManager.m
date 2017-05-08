//
//  LMHistoryCacheManager.m
//  Connect
//
//  Created by MoHuilin on 2017/1/18.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMHistoryCacheManager.h"
#import "LMBaseSSDBManager.h"
#import "ConnectTool.h"
#import "NSData+Hash.h"
#import "UserDBManager.h"

#define SocketIp @"SocketIp"

@implementation LMHistoryCacheManager

CREATE_SHARED_MANAGER(LMHistoryCacheManager)


- (void)cacheRegisterContacts:(NSData *)data {
    if (!data) {
        return;
    }
    NSString *key = [NSString stringWithFormat:@"%@_cacheRegisterContacts", [[LKUserCenter shareCenter] currentLoginUser].address];
    LMBaseSSDBManager *manager = [LMBaseSSDBManager open:@"system_message"];
    [manager set:key data:data];
    [manager close];
}

- (NSData *)getRegisterContactsCache {
    LMBaseSSDBManager *manager = [LMBaseSSDBManager open:@"system_message"];
    NSData *data;
    NSString *key = [NSString stringWithFormat:@"%@_cacheRegisterContacts", [[LKUserCenter shareCenter] currentLoginUser].address];
    [manager get:key data:&data];
    [manager close];
    return data;
}


- (void)cacheRedbagContacts:(NSData *)data {
    if (!data) {
        return;
    }
    LMBaseSSDBManager *manager = [LMBaseSSDBManager open:@"system_message"];
    NSString *key = [NSString stringWithFormat:@"%@_RedbagHistoryCache", [[LKUserCenter shareCenter] currentLoginUser].address];
    [manager set:key data:data];
    [manager close];

}

- (NSData *)getRedbagContactsCache {
    LMBaseSSDBManager *manager = [LMBaseSSDBManager open:@"system_message"];
    NSData *data;
    NSString *key = [NSString stringWithFormat:@"%@_RedbagHistoryCache", [[LKUserCenter shareCenter] currentLoginUser].address];
    [manager get:key data:&data];
    [manager close];
    return data;
}


- (void)cacheTransferContacts:(NSData *)data {
    if (!data) {
        return;
    }
    LMBaseSSDBManager *manager = [LMBaseSSDBManager open:@"system_message"];
    NSString *key = [NSString stringWithFormat:@"%@_transationRecord", [[LKUserCenter shareCenter] currentLoginUser].address];
    [manager set:key data:data];
    [manager close];
}

- (NSData *)getTransferContactsCache {
    LMBaseSSDBManager *manager = [LMBaseSSDBManager open:@"system_message"];
    NSData *data;
    NSString *key = [NSString stringWithFormat:@"%@_transationRecord", [[LKUserCenter shareCenter] currentLoginUser].address];
    [manager get:key data:&data];
    [manager close];
    return data;
}

- (void)cachePersonTransferContacts:(NSData *)data {
    if (!data) {
        return;
    }
    LMBaseSSDBManager *manager = [LMBaseSSDBManager open:@"system_message"];
    NSString *key = [NSString stringWithFormat:@"%@_personTransferRecord", [[LKUserCenter shareCenter] currentLoginUser].address];
    [manager set:key data:data];
    [manager close];
}

- (NSData *)getPersonTransferContactsCache {
    LMBaseSSDBManager *manager = [LMBaseSSDBManager open:@"system_message"];
    NSData *data;
    NSString *key = [NSString stringWithFormat:@"%@_personTransferRecord", [[LKUserCenter shareCenter] currentLoginUser].address];
    [manager get:key data:&data];
    [manager close];
    return data;
}

- (void)cachePublicFinaincContacts:(NSData *)data {
    if (!data) {
        return;
    }
    LMBaseSSDBManager *manager = [LMBaseSSDBManager open:@"system_message"];
    NSString *key = [NSString stringWithFormat:@"%@_publicFinaincRecord", [[LKUserCenter shareCenter] currentLoginUser].address];
    [manager set:key data:data];
    [manager close];

}

- (NSData *)getPublicFinaincContactsCache {
    LMBaseSSDBManager *manager = [LMBaseSSDBManager open:@"system_message"];
    NSData *data;
    NSString *key = [NSString stringWithFormat:@"%@_publicFinaincRecord", [[LKUserCenter shareCenter] currentLoginUser].address];
    [manager get:key data:&data];
    [manager close];
    return data;

}

- (void)cacheOutContacts:(NSData *)data {
    if (!data) {
        return;
    }
    LMBaseSSDBManager *manager = [LMBaseSSDBManager open:@"system_message"];
    NSString *key = [NSString stringWithFormat:@"%@_outRecord", [[LKUserCenter shareCenter] currentLoginUser].address];
    [manager set:key data:data];
    [manager close];

}

- (NSData *)getOutContactsCache {
    LMBaseSSDBManager *manager = [LMBaseSSDBManager open:@"system_message"];
    NSData *data;
    NSString *key = [NSString stringWithFormat:@"%@_outRecord", [[LKUserCenter shareCenter] currentLoginUser].address];
    [manager get:key data:&data];
    [manager close];
    return data;
}

- (void)cacheIP:(NSString *)ip {
    if (!ip) {
        return;
    }
    LMBaseSSDBManager *manager = [LMBaseSSDBManager open:@"system_message"];
    [manager set:SocketIp string:ip];
    [manager close];

}

- (NSString *)getSocketIPCache {
    LMBaseSSDBManager *manager = [LMBaseSSDBManager open:@"system_message"];
    NSString *socketIp;
    [manager get:SocketIp string:&socketIp];
    [manager close];
    return socketIp;
}

- (NSString *)cacheDBPassSaltData {
    NSString *randomPubkey = [KeyHandle createPubkeyByPrikey:[KeyHandle creatNewPrivkey]];
    NSData *salt = [KeyHandle createRandom512bits];
    DBPassword *dbpass = [[DBPassword alloc] init];
    dbpass.pubKey = randomPubkey;
    dbpass.salt = salt;
    LMBaseSSDBManager *manager = [LMBaseSSDBManager open:@"system_message"];
    NSString *key = [NSString stringWithFormat:@"%@_dbpassword", [[LKUserCenter shareCenter] currentLoginUser].address];
    [manager set:key data:dbpass.data];
    [manager close];


    NSData *ecdh = [KeyHandle getECDHkeyWithPrivkey:[[LKUserCenter shareCenter] currentLoginUser].prikey publicKey:dbpass.pubKey];
    return [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdh salt:dbpass.salt].hash256String;
}

- (NSString *)getDBPassword {
    LMBaseSSDBManager *manager = [LMBaseSSDBManager open:@"system_message"];
    NSData *data;
    NSString *key = [NSString stringWithFormat:@"%@_dbpassword", [[LKUserCenter shareCenter] currentLoginUser].address];
    [manager get:key data:&data];
    [manager close];
    if (!data) {
        return [self cacheDBPassSaltData];
    }
    DBPassword *dbpass = [DBPassword parseFromData:data error:nil];
    NSData *ecdh = [KeyHandle getECDHkeyWithPrivkey:[[LKUserCenter shareCenter] currentLoginUser].prikey publicKey:dbpass.pubKey];
    return [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdh salt:dbpass.salt].hash256String;
}

- (void)cacheNotificatedContacts:(NSData *)data {
    if (!data) {
        return;
    }
    LMBaseSSDBManager *manager = [LMBaseSSDBManager open:@"system_message"];
    NSString *key = [NSString stringWithFormat:@"%@_getNotificatedContact", [[LKUserCenter shareCenter] currentLoginUser].address];
    [manager set:key data:data];
    [manager close];
}

- (NSData *)getNotificatedContact {
    LMBaseSSDBManager *manager = [LMBaseSSDBManager open:@"system_message"];
    NSData *data;
    NSString *key = [NSString stringWithFormat:@"%@_getNotificatedContact", [[LKUserCenter shareCenter] currentLoginUser].address];
    [manager get:key data:&data];
    [manager close];
    return data;
}


- (void)cacheTransferHistoryWith:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return;
    }
    AccountInfo *user = [[UserDBManager sharedManager] getUserByAddress:address];
    if (!user) {
        return;
    }
    UserInfo *userInfo = [UserInfo new];
    userInfo.pubKey = user.pub_key;
    userInfo.address = user.address;
    userInfo.username = user.username;
    userInfo.avatar = user.avatar;

    LMBaseSSDBManager *manager = [LMBaseSSDBManager open:@"system_message"];
    NSData *data;
    NSString *key = [NSString stringWithFormat:@"%@_TransferHistory", [[LKUserCenter shareCenter] currentLoginUser].address];
    [manager get:key data:&data];
    if (data && data.length > 0) {
        TransferHistory *traHis = [TransferHistory parseFromData:data error:nil];
        if (traHis.transferUsersArray.count > 10) {
            [traHis.transferUsersArray removeObjectAtIndex:0];
        }
        for (UserInfo *oldUserInfo in traHis.transferUsersArray) {
            if ([oldUserInfo.address isEqualToString:userInfo.address]) {
                return;
            }
        }
        [traHis.transferUsersArray addObject:userInfo];
        [manager set:key data:traHis.data];
    } else {
        TransferHistory *traHis = [TransferHistory new];
        [traHis.transferUsersArray addObject:userInfo];
        [manager set:key data:traHis.data];
    }
    [manager close];
}

- (NSArray *)getTransferHistory {
    LMBaseSSDBManager *manager = [LMBaseSSDBManager open:@"system_message"];
    NSData *data;
    NSString *key = [NSString stringWithFormat:@"%@_TransferHistory", [[LKUserCenter shareCenter] currentLoginUser].address];
    [manager get:key data:&data];
    [manager close];
    NSMutableArray *transferUsers = [NSMutableArray array];
    if (data && data.length > 0) {
        TransferHistory *traHis = [TransferHistory parseFromData:data error:nil];
        for (UserInfo *userInfo in traHis.transferUsersArray) {
            AccountInfo *user = [AccountInfo new];
            user.pub_key = userInfo.pubKey;
            user.address = userInfo.address;
            user.username = userInfo.username;
            user.avatar = userInfo.avatar;
            [transferUsers addObject:user];
        }
    }
    return transferUsers;
}

- (void)cacheChatCookie:(ChatCacheCookie *)chatCookie {
    if (!chatCookie) {
        return;
    }
    LMBaseSSDBManager *manager = [LMBaseSSDBManager open:@"system_message"];
    NSData *data;
    NSString *key = [NSString stringWithFormat:@"%@_cacheChatCookie", [[LKUserCenter shareCenter] currentLoginUser].address];
    [manager get:key data:&data];
    if (data && data.length > 0) {
        ChatCookieHistory *chatCookieHis = [ChatCookieHistory parseFromData:data error:nil];
        if (chatCookieHis.chatCookiesArray.count > 5) {
            [chatCookieHis.chatCookiesArray removeObjectAtIndex:0]; //移除最先进入的一个
        }
        [chatCookieHis.chatCookiesArray addObject:chatCookie];
        [manager set:key data:chatCookieHis.data];
    } else {
        ChatCookieHistory *chatCookieHis = [ChatCookieHistory new];
        [chatCookieHis.chatCookiesArray addObject:chatCookie];
        [manager set:key data:chatCookieHis.data];
        BOOL saved = [manager set:key data:chatCookieHis.data];
        if (saved) {

        }
    }
    [manager close];
}

- (ChatCacheCookie *)getChatCookieWithSaltVer:(NSData *)ver {
    LMBaseSSDBManager *manager = [LMBaseSSDBManager open:@"system_message"];
    NSData *data;
    NSString *key = [NSString stringWithFormat:@"%@_cacheChatCookie", [[LKUserCenter shareCenter] currentLoginUser].address];
    [manager get:key data:&data];
    [manager close];
    if (data && data.length > 0) {
        ChatCookieHistory *chatCookieHis = [ChatCookieHistory parseFromData:data error:nil];
        for (ChatCacheCookie *chatCookie in chatCookieHis.chatCookiesArray) {
            if ([chatCookie.salt isEqualToData:ver]) {
                return chatCookie;
                break;
            }
        }
    }
    return nil;
}

- (void)cacheLeastChatCookie:(ChatCookieData *)chatCookie {
    if (!chatCookie) {
        return;
    }
    LMBaseSSDBManager *manager = [LMBaseSSDBManager open:@"system_message"];
    NSString *key = [NSString stringWithFormat:@"%@_getLeastChatCookie", [[LKUserCenter shareCenter] currentLoginUser].address];
    [manager set:key data:chatCookie.data];
    [manager close];
}

- (ChatCookieData *)getLeastChatCookie {
    LMBaseSSDBManager *manager = [LMBaseSSDBManager open:@"system_message"];
    NSData *data;
    NSString *key = [NSString stringWithFormat:@"%@_getLeastChatCookie", [[LKUserCenter shareCenter] currentLoginUser].address];
    [manager get:key data:&data];
    [manager close];
    if (data && data.length > 0) {
        ChatCookieData *chatCookie = [ChatCookieData parseFromData:data error:nil];
        return chatCookie;
    }
    return nil;
}


@end
