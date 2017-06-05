//
//  UserDBManager.m
//  Connect
//
//  Created by MoHuilin on 16/7/29.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "UserDBManager.h"
#import "MessageDBManager.h"
#import "RecentChatDBManager.h"
#import "BadgeNumberManager.h"

#define ContactTable @"t_contact"
#define NewFriendTable @"t_friendrequest"
#define TagsTable @"t_tag"

static UserDBManager *manager = nil;

@implementation UserDBManager

+ (UserDBManager *)sharedManager {
    @synchronized (self) {
        if (manager == nil) {
            manager = [[[self class] alloc] init];
        }
    }
    return manager;
}

+ (void)tearDown {
    manager = nil;
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

- (void)saveUser:(AccountInfo *)user {
    if (!user) {
        return;
    }
    if (GJCFStringIsNull(user.pub_key) ||
            GJCFStringIsNull(user.address) ||
            GJCFStringIsNull(user.avatar) ||
            GJCFStringIsNull(user.username)) {
        return;
    }

    NSMutableArray *bitchValues = [NSMutableArray array];
    [bitchValues objectAddObject:@[user.address,
            user.pub_key,
            user.avatar,
            user.username,
            user.remarks,
            @(user.source),
            @(user.isBlackMan),
            @(user.isOffenContact)]];
    BOOL result = [self executeUpdataOrInsertWithTable:ContactTable fields:@[@"address", @"pub_key", @"avatar", @"username", @"remark", @"source", @"blocked", @"common"] batchValues:bitchValues];
    if (result) {
        DDLogInfo(@"Save success");
    } else {
        DDLogInfo(@"Save fail");
    }
}

- (void)batchSaveUsers:(NSArray *)users {

    NSMutableArray *bitchValues = [NSMutableArray array];
    for (AccountInfo *user in users) {
        NSMutableArray *temArray = [NSMutableArray array];
        [temArray addObject:user.address];
        [temArray addObject:user.pub_key];
        [temArray addObject:user.avatar];
        [temArray addObject:user.username];
        [temArray addObject:user.remarks];
        [temArray addObject:@(user.source)];
        [temArray addObject:@(user.isBlackMan)];
        [temArray addObject:@(user.isOffenContact)];
        [bitchValues objectAddObject:temArray];
    }
    if (bitchValues.count) {
        [self batchInsertTableName:ContactTable fields:@[@"address", @"pub_key", @"avatar", @"username", @"remark", @"source", @"blocked", @"common"] batchValues:bitchValues.copy];
    }
}

- (void)deleteUserBypubkey:(NSString *)pubKey {
    if (GJCFStringIsNull(pubKey)) {
        return;
    }
    //delet message
    [[MessageDBManager sharedManager] deleteAllMessageByMessageOwer:pubKey];
    //delete chat
    [[RecentChatDBManager sharedManager] deleteByIdentifier:pubKey];
    //delete chat setting
    [[RecentChatDBManager sharedManager] deleteRecentChatSettingWithIdentifier:pubKey];
    //delete request
    [self deleteRequestUserByAddress:[KeyHandle getAddressByPubkey:pubKey]];
    //delete user
    [self deleteTableName:ContactTable conditions:@{@"pub_key": pubKey}];
}

- (void)deleteUserByAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return;
    }

    NSString *pubKey = [self getUserPubkeyByAddress:address];

    [[MessageDBManager sharedManager] deleteAllMessageByMessageOwer:pubKey];

    [[RecentChatDBManager sharedManager] deleteByIdentifier:pubKey];

    [self deleteTableName:ContactTable conditions:@{@"address": address}];
}

- (void)updateUserNameAndAvatar:(AccountInfo *)user {

    if (GJCFStringIsNull(user.pub_key) ||
            GJCFStringIsNull(user.avatar) ||
            GJCFStringIsNull(user.username)) {
        return;
    }
    NSMutableDictionary *fieldsValues = [NSMutableDictionary dictionary];
    [fieldsValues safeSetObject:user.avatar forKey:@"avatar"];
    [fieldsValues safeSetObject:user.username forKey:@"username"];

    [self updateTableName:ContactTable fieldsValues:fieldsValues conditions:@{@"pub_key": user.pub_key}];
}

- (void)setUserCommonContact:(BOOL)commonContact AndSetNewRemark:(NSString *)remark withAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return;
    }
    if (!remark) {
        remark = @"";
    }
    NSMutableDictionary *fieldsValues = [NSMutableDictionary dictionary];
    [fieldsValues safeSetObject:remark forKey:@"remark"];
    [fieldsValues safeSetObject:@(commonContact) forKey:@"common"];

    [self updateTableName:ContactTable fieldsValues:fieldsValues conditions:@{@"address": address}];
}

- (AccountInfo *)getUserByPublickey:(NSString *)publickey {
    if (GJCFStringIsNull(publickey)) {
        return nil;
    }
    NSString *address = [KeyHandle getAddressByPubkey:publickey];
    if ([publickey isEqualToString:kSystemIdendifier]) {
        address = @"Connect";
    }
    return [self getUserByAddress:address];
}

- (NSString *)getUserPubkeyByAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return nil;
    }
    NSString *querySql = [NSString stringWithFormat:@"select c.pub_key from t_contact c where c.address = '%@'", address];
    NSArray *resultArray = [self queryWithSql:querySql];
    NSDictionary *resultDict = [resultArray firstObject];
    if (resultDict) {
        return [resultDict safeObjectForKey:@"pub_key"];
    }
    return nil;

}

- (AccountInfo *)getUserByAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return nil;
    }
    NSString *querySql = [NSString stringWithFormat:@"select c.address,c.pub_key,c.avatar,c.username,c.remark,c.source,c.blocked,c.common from t_contact c where c.address = '%@'", address];

    NSArray *resultArray = [self queryWithSql:querySql];
    NSDictionary *resultDict = [resultArray firstObject];
    AccountInfo *findUser = nil;
    if (resultDict) {
        findUser = [AccountInfo new];
        findUser.address = [resultDict safeObjectForKey:@"address"];
        findUser.pub_key = [resultDict safeObjectForKey:@"pub_key"];
        findUser.avatar = [resultDict safeObjectForKey:@"avatar"];
        findUser.username = [resultDict safeObjectForKey:@"username"];
        findUser.remarks = [resultDict safeObjectForKey:@"remark"];
        findUser.source = [[resultDict safeObjectForKey:@"source"] integerValue];
        findUser.isBlackMan = [[resultDict safeObjectForKey:@"blocked"] boolValue];
        findUser.isOffenContact = [[resultDict safeObjectForKey:@"common"] boolValue];
    }
    return findUser;
}

- (NSArray *)getAllUsers {
    NSString *querySql = @"select c.address,c.pub_key,c.avatar,c.username,c.remark,c.source,c.blocked,c.common from t_contact c";
    NSArray *resultArray = [self queryWithSql:querySql];
    NSMutableArray *findUsers = [NSMutableArray array];
    for (NSDictionary *resultDict in resultArray) {
        AccountInfo *findUser = [AccountInfo new];
        findUser.address = [resultDict safeObjectForKey:@"address"];
        findUser.pub_key = [resultDict safeObjectForKey:@"pub_key"];
        findUser.avatar = [resultDict safeObjectForKey:@"avatar"];
        findUser.username = [resultDict safeObjectForKey:@"username"];
        findUser.remarks = [resultDict safeObjectForKey:@"remark"];
        findUser.source = [[resultDict safeObjectForKey:@"source"] integerValue];
        findUser.isBlackMan = [[resultDict safeObjectForKey:@"blocked"] boolValue];
        findUser.isOffenContact = [[resultDict safeObjectForKey:@"common"] boolValue];

        [findUsers addObject:findUser];
    }
    return findUsers;
}

- (void)getAllUsersWithComplete:(void (^)(NSArray *))complete {
    if (complete) {
        [GCDQueue executeInGlobalQueue:^{
            complete([self getAllUsers]);
        }];
    }
}


- (void)getAllUsersNoConnectWithComplete:(void (^)(NSArray *))complete {
    if (complete) {
        [GCDQueue executeInGlobalQueue:^{
            NSString *querySql = @"select c.address,c.pub_key,c.avatar,c.username,c.remark,c.source,c.blocked,c.common from t_contact c where c.pub_key <> 'connect'";
            NSArray *resultArray = [self queryWithSql:querySql];
            NSMutableArray *findUsers = [NSMutableArray array];
            for (NSDictionary *resultDict in resultArray) {
                AccountInfo *findUser = [AccountInfo new];
                findUser.address = [resultDict safeObjectForKey:@"address"];
                findUser.pub_key = [resultDict safeObjectForKey:@"pub_key"];
                findUser.avatar = [resultDict safeObjectForKey:@"avatar"];
                findUser.username = [resultDict safeObjectForKey:@"username"];
                findUser.remarks = [resultDict safeObjectForKey:@"remark"];
                findUser.source = [[resultDict safeObjectForKey:@"source"] integerValue];
                findUser.isBlackMan = [[resultDict safeObjectForKey:@"blocked"] boolValue];
                findUser.isOffenContact = [[resultDict safeObjectForKey:@"common"] boolValue];

                [findUsers addObject:findUser];
            }
            complete(findUsers);
        }];
    }
}

- (BOOL)isFriendByAddress:(NSString *)address {
    NSString *querySql = [NSString stringWithFormat:@"select count(pub_key) as user_count from t_contact where address = '%@'", address];
    NSArray *resultArray = [self queryWithSql:querySql];
    NSDictionary *resultDict = [resultArray lastObject];
    return [[resultDict safeObjectForKey:@"user_count"] boolValue];
}


- (long int)getRequestTimeByUserPublickey:(NSString *)publickey {
    if (GJCFStringIsNull(publickey)) {
        return 0;
    }
    NSString *querySql = [NSString stringWithFormat:@"select f.createtime,f.pub_key from t_friendrequest f where f.pub_key = '%@'", publickey];
    NSArray *resultArray = [self queryWithSql:querySql];
    NSDictionary *resultDict = [resultArray lastObject];
    return [[resultDict safeObjectForKey:@"createtime"] longLongValue];
}

- (NSString *)getRequestTipsByUserPublickey:(NSString *)publickey {
    if (GJCFStringIsNull(publickey)) {
        return 0;
    }
    NSString *querySql = [NSString stringWithFormat:@"select f.tips from t_friendrequest f where f.pub_key = '%@'", publickey];
    NSArray *resultArray = [self queryWithSql:querySql];
    NSDictionary *resultDict = [resultArray lastObject];
    if (resultDict) {
        return [resultDict safeObjectForKey:@"tips"];
    }
    return nil;
}

- (NSArray *)getAllNewFirendRequest {
    NSString *querySql = @"select f.address,f.pub_key,f.avatar,f.username,f.source,f.status,f.read,f.tips from t_friendrequest f order by f.createtime desc";
    NSArray *resultArray = [self queryWithSql:querySql];
    NSMutableArray *findUsers = [NSMutableArray array];
    for (NSDictionary *resultDict in resultArray) {
        AccountInfo *findUser = [AccountInfo new];
        findUser.address = [resultDict safeObjectForKey:@"address"];
        findUser.pub_key = [resultDict safeObjectForKey:@"pub_key"];
        findUser.avatar = [resultDict safeObjectForKey:@"avatar"];
        findUser.username = [resultDict safeObjectForKey:@"username"];
        findUser.source = [[resultDict safeObjectForKey:@"source"] intValue];
        findUser.status = [[resultDict safeObjectForKey:@"status"] integerValue];
        findUser.requestRead = [[resultDict safeObjectForKey:@"read"] boolValue];
        findUser.message = [resultDict safeObjectForKey:@"tips"];

        [findUsers addObject:findUser];
    }
    return findUsers;
}

- (AccountInfo *)getFriendRequestBy:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return nil;
    }
    NSString *querySql = [NSString stringWithFormat:@"select f.address,f.pub_key,f.avatar,f.username,f.source,f.status,f.read,f.tips from t_friendrequest f where f.address = '%@'", address];
    NSArray *resultArray = [self queryWithSql:querySql];
    NSDictionary *resultDict = [resultArray lastObject];
    AccountInfo *findUser = nil;
    if (resultDict) {
        findUser = [AccountInfo new];
        findUser.address = [resultDict safeObjectForKey:@"address"];
        findUser.pub_key = [resultDict safeObjectForKey:@"pub_key"];
        findUser.avatar = [resultDict safeObjectForKey:@"avatar"];
        findUser.username = [resultDict safeObjectForKey:@"username"];
        findUser.source = [[resultDict safeObjectForKey:@"source"] integerValue];
        findUser.status = [[resultDict safeObjectForKey:@"status"] integerValue];
        findUser.requestRead = [[resultDict safeObjectForKey:@"read"] boolValue];
        findUser.message = [resultDict safeObjectForKey:@"tips"];
    }
    return findUser;
}

- (RequestFriendStatus)getFriendRequestStatusByAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return RequestFriendStatusAdd;
    }
    NSString *querySql = [NSString stringWithFormat:@"select f.status from t_friendrequest f where f.address = '%@'", address];
    NSArray *resultArray = [self queryWithSql:querySql];
    NSDictionary *resultDict = [resultArray lastObject];
    if (resultDict) {
        return [[resultDict safeObjectForKey:@"status"] integerValue];
    }
    return RequestFriendStatusAdd;
}

- (void)deleteRequestUserByAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return;
    }
    [self deleteTableName:NewFriendTable conditions:@{@"address": address}];
}

- (void)saveNewFriend:(AccountInfo *)user {
    if (!user) {
        return;
    }
    if (GJCFStringIsNull(user.pub_key) ||
            GJCFStringIsNull(user.address) ||
            GJCFStringIsNull(user.avatar) ||
            GJCFStringIsNull(user.username)) {
        return;
    }

    int long long time = [[NSDate date] timeIntervalSince1970] * 1000;

    if (user.status == RequestFriendStatusAccept) {
        [[BadgeNumberManager shareManager] getBadgeNumber:ALTYPE_CategoryTwo_NewFriend Completion:^(BadgeNumber *badgeNumber) {
            if (!badgeNumber) {
                BadgeNumber *createBadge = [[BadgeNumber alloc] init];
                createBadge.type = ALTYPE_CategoryTwo_NewFriend;
                createBadge.count = 1;
                createBadge.displayMode = ALDisplayMode_Number;
                [[BadgeNumberManager shareManager] setBadgeNumber:createBadge Completion:^(BOOL result) {

                }];
            } else {
                badgeNumber.count++;
                [[BadgeNumberManager shareManager] setBadgeNumber:badgeNumber Completion:^(BOOL result) {

                }];
            }
        }];
    }

    NSMutableArray *bitchValues = [NSMutableArray array];
    [bitchValues objectAddObject:@[user.address,
            user.pub_key,
            user.avatar,
            user.username,
            @(user.source),
            @(user.status),
            @(user.requestRead),
            user.message ? user.message : @"",
            @(time)]];
    BOOL result = [self executeUpdataOrInsertWithTable:NewFriendTable fields:@[@"address", @"pub_key", @"avatar", @"username", @"source", @"status", @"read", @"tips", @"createtime"] batchValues:bitchValues];
    if (result) {
        DDLogInfo(@"Save success");
    } else {
        DDLogInfo(@"Save fail");
    }
}

- (void)updateNewFriendStatusAddress:(NSString *)address withStatus:(int)status {
    if (GJCFStringIsNull(address)) {
        return;
    }

    if (status < 0) {
        status = 0;
    }

    NSMutableDictionary *fieldsValues = [NSMutableDictionary dictionary];
    [fieldsValues safeSetObject:@(status) forKey:@"status"];

    [self updateTableName:NewFriendTable fieldsValues:fieldsValues conditions:@{@"address": address}];
}


- (NSArray *)getUserTags:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return nil;
    }
    NSString *querySql = [NSString stringWithFormat:@"select t.tag from t_usertag ut, t_tag t where ut.tag_id = t.id and ut.address = '%@'", address];
    NSArray *queryArray = [self queryWithSql:querySql];
    NSMutableArray *tags = [NSMutableArray array];
    for (NSDictionary *queryDict in queryArray) {
        [tags addObject:[queryDict safeObjectForKey:@"tag"]];
    }
    return tags;
}

- (NSArray *)getTagUsers:(NSString *)tag {
    if (GJCFStringIsNull(tag)) {
        return nil;
    }
    NSString *querySql = [NSString stringWithFormat:@"select ut.address from t_usertag ut, t_tag t where ut.tag_id = t.id and t.tag = '%@'", tag];
    NSArray *queryArray = [self queryWithSql:querySql];
    NSMutableArray *users = [NSMutableArray array];
    for (NSDictionary *queryDict in queryArray) {
        NSString *address = [queryDict safeObjectForKey:@"address"];
        AccountInfo *user = [self getUserByAddress:address];
        if (user) {
            [users addObject:user];
        }
    }
    return users;
}


- (NSArray *)tagList {
    NSString *querySql = @"select tag from t_tag";
    NSArray *queryArray = [self queryWithSql:querySql];
    NSMutableArray *tags = [NSMutableArray array];
    for (NSDictionary *queryDict in queryArray) {
        [tags addObject:[queryDict safeObjectForKey:@"tag"]];
    }
    return tags;
}

- (BOOL)saveTag:(NSString *)tag {
    if (GJCFStringIsNull(tag)) {
        return NO;
    }
    return [self batchInsertTableName:TagsTable fields:@[@"tag"] batchValues:@[@[tag]]];
}

- (BOOL)removeTag:(NSString *)tag {
    if (GJCFStringIsNull(tag)) {
        return NO;
    }
    return [self deleteTableName:TagsTable conditions:@{@"tag": tag}];
}

- (BOOL)saveAddress:(NSString *)address toTag:(NSString *)tag {
    return YES;
}

- (BOOL)removeAddress:(NSString *)address fromTag:(NSString *)tag {
    return YES;
}


- (NSArray *)blackManList {
    NSString *querySql = @"select c.address,c.pub_key,c.avatar,c.username,c.remark,c.source,c.blocked,c.common from t_contact c where c.blocked = 1";
    NSArray *resultArray = [self queryWithSql:querySql];
    NSMutableArray *findUsers = [NSMutableArray array];
    for (NSDictionary *resultDict in resultArray) {
        AccountInfo *findUser = [AccountInfo new];
        findUser.address = [resultDict safeObjectForKey:@"address"];
        findUser.pub_key = [resultDict safeObjectForKey:@"pub_key"];
        findUser.avatar = [resultDict safeObjectForKey:@"avatar"];
        findUser.username = [resultDict safeObjectForKey:@"username"];
        findUser.remarks = [resultDict safeObjectForKey:@"remark"];
        findUser.source = [[resultDict safeObjectForKey:@"source"] integerValue];
        findUser.isBlackMan = [[resultDict safeObjectForKey:@"blocked"] boolValue];
        findUser.isOffenContact = [[resultDict safeObjectForKey:@"common"] boolValue];

        [findUsers addObject:findUser];
    }
    return findUsers;

}

- (void)addUserToBlackListWithAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return;
    }
    NSMutableDictionary *fieldsValues = [NSMutableDictionary dictionary];
    [fieldsValues safeSetObject:@(1) forKey:@"blocked"];

    [self updateTableName:ContactTable fieldsValues:fieldsValues conditions:@{@"address": address}];
}

- (void)removeUserFromBlackList:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return;
    }
    NSMutableDictionary *fieldsValues = [NSMutableDictionary dictionary];
    [fieldsValues safeSetObject:@(0) forKey:@"blocked"];

    [self updateTableName:ContactTable fieldsValues:fieldsValues conditions:@{@"address": address}];
}

- (BOOL)userIsInBlackList:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return NO;
    }
    NSString *querySql = [NSString stringWithFormat:@"select c.blocked  from t_contact c where c.address = '%@'", address];
    NSArray *queryArray = [self queryWithSql:querySql];
    NSDictionary *queryDict = [queryArray lastObject];
    return [[queryDict safeObjectForKey:@"blocked"] boolValue];
}

@end
