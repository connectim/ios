//
//  LMRecommandFriendManager.m
//  Connect
//
//  Created by Connect on 2017/4/13.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMRecommandFriendManager.h"
#import "Protofile.pbobjc.h"

#define RecommandFriendTable @"t_recommand_friend"
#define Scope @"username",@"address",@"avatar",@"pub_key",@"status"

@interface LMRecommandFriendManager ()


@end

static LMRecommandFriendManager *manager = nil;

@implementation LMRecommandFriendManager

+ (LMRecommandFriendManager *)sharedManager {
    @synchronized (self) {
        if (manager == nil) {
            manager = [[[self class] alloc] init];
        }
    }
    return manager;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized (self) {
        if (manager == nil) {
            manager = [super allocWithZone:zone];
            return manager;
        }
    }
    return nil;
}

+ (void)tearDown {
    manager = nil;
}

- (void)deleteAllRecommandFriend; {
    [self deleteTableName:RecommandFriendTable conditions:nil];
}

- (void)deleteRecommandFriendWithAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return;
    }
    [self deleteTableName:RecommandFriendTable conditions:@{@"address": address}];
}

- (void)saveRecommandFriend:(NSArray *)friendArray; {
    if (friendArray.count <= 0) {
        return;
    }
    NSMutableArray *addArray = [NSMutableArray array];
    for (UserInfo *user in friendArray) {
        AccountInfo *accountInfo = [[AccountInfo alloc] init];
        accountInfo.username = user.username;
        accountInfo.address = user.address;
        accountInfo.avatar = user.avatar;
        accountInfo.pub_key = user.pubKey;
        accountInfo.recommandStatus = 1;
        if (accountInfo.address.length > 0) {
            [addArray objectAddObject:@[accountInfo.username, accountInfo.address, accountInfo.avatar, accountInfo.pub_key, @(accountInfo.recommandStatus)]];
        }
    }
    if (addArray.count > 0) {
        [self batchInsertTableName:RecommandFriendTable fields:@[Scope] batchValues:addArray];
    }
}

- (NSArray *)getRecommandFriendsWithPage:(int)page {
    if (page <= 0) {
        page = 1;
    }
    NSString *sql = [NSString stringWithFormat:@"select * from t_recommand_friend limit 20 offset %d", ((page - 1) * 20)];
    NSArray *recommandFriends = [self queryWithSql:sql];
    if (recommandFriends.count <= 0) {
        return nil;
    }
    NSMutableArray *resultArray = [NSMutableArray array];
    for (NSDictionary *dic in recommandFriends) {
        AccountInfo *accountInfo = [[AccountInfo alloc] init];
        accountInfo.username = [dic safeObjectForKey:@"username"];
        accountInfo.address = [dic safeObjectForKey:@"address"];
        accountInfo.avatar = [dic safeObjectForKey:@"avatar"];
        accountInfo.pub_key = [dic safeObjectForKey:@"pub_key"];
        accountInfo.recommandStatus = [[dic safeObjectForKey:@"status"] intValue];
        [resultArray objectAddObject:accountInfo];
    }
    return resultArray.copy;
}

- (BOOL)getUserInfoWith:(AccountInfo *)userInfo {
    if (GJCFStringIsNull(userInfo.address)) {
        return NO;
    }
    NSArray *recommandFriendArray = [self getDatasFromTableName:RecommandFriendTable conditions:@{@"address": userInfo.address} fields:@[Scope]];
    if (recommandFriendArray.count > 0) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)getUserInfoWithAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return NO;
    }
    NSArray *recommandFriendsArray = [self getDatasFromTableName:RecommandFriendTable conditions:@{@"address": address} fields:@[Scope]];
    if (recommandFriendsArray.count > 0) {
        return YES;
    } else {
        return NO;
    }
}

- (void)updateRecommandFriendStatus:(int32_t)status withAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return;
    }
    [self updateTableName:RecommandFriendTable fieldsValues:@{@"status": @(status)} conditions:@{@"address": address}];
}

- (NSArray *)getRecommandFriendsWithPage:(int)page withStatus:(int)status {
    if (page == 0) {
        return nil;
    }
    NSString *sql = [NSString stringWithFormat:@"select * from t_recommand_friend where status = %d limit 20 offset %d", status, ((page - 1) * 20)];
    NSArray *recommandFriendArray = [self queryWithSql:sql];
    if (recommandFriendArray.count <= 0) {
        return nil;
    }
    NSMutableArray *resultArray = [NSMutableArray array];
    for (NSDictionary *dic in recommandFriendArray) {
        AccountInfo *accountInfo = [[AccountInfo alloc] init];
        accountInfo.username = [dic safeObjectForKey:@"username"];
        accountInfo.address = [dic safeObjectForKey:@"address"];
        accountInfo.avatar = [dic safeObjectForKey:@"avatar"];
        accountInfo.pub_key = [dic safeObjectForKey:@"pub_key"];
        accountInfo.recommandStatus = status;
        [resultArray objectAddObject:accountInfo];
    }
    NSArray *result = resultArray.copy;
    result = [result sortedArrayUsingComparator:^NSComparisonResult(AccountInfo *obj1, AccountInfo *obj2) {
        return [obj2.pub_key compare:obj1.pub_key];
    }];
    return result;
}

@end

