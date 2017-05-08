//
//  GroupDBManager.m
//  Connect
//
//  Created by MoHuilin on 16/8/1.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "GroupDBManager.h"


#define GroupInformationTable  @"t_group"
#define GroupMemberTable       @"t_group_Member"
#define GroupInformation @"identifier",@"name",@"ecdh_key",@"common",@"verify",@"pub",@"avatar",@"summary"
#define GroupMemberScope  @"identifier",@"username",@"avatar",@"address",@"role",@"nick",@"pub_key"


static GroupDBManager *manager = nil;

@implementation GroupDBManager

+ (GroupDBManager *)sharedManager {
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

- (void)addGroupSummary:(NSString *)textString withGroupId:(NSString *)groupId {
    if (GJCFStringIsNull(groupId)) {
        return;
    }
    if (textString == nil) {
        textString = @"";
    }
    NSMutableDictionary *fieldValues = @{}.mutableCopy;
    [fieldValues safeSetObject:textString forKey:@"summary"];
    BOOL result = [self updateTableName:GroupInformationTable fieldsValues:fieldValues conditions:@{@"identifier": groupId}];
    if (!result) {
        DDLogInfo(@"failed");
    }
}

- (LMGroupInfo *)addMember:(NSArray *)newMembers ToGroupChat:(NSString *)groupId {

    if (GJCFStringIsNull(groupId)) {
        return nil;
    }
    if (newMembers.count <= 0) {
        return nil;
    }
    [self saveGroupMember:newMembers withGroupIdentifier:groupId];
    LMGroupInfo *groupInfo = [self getgroupByGroupIdentifier:groupId];


    return groupInfo;

}

- (void)savegroup:(LMGroupInfo *)group {

    if (GJCFStringIsNull(group.groupIdentifer)) {
        return;
    }
    [self saveGroupInformation:group];
    [self saveGroupMember:group.groupMembers withGroupIdentifier:group.groupIdentifer];

}

- (void)saveGroupMember:(NSArray *)array withGroupIdentifier:(NSString *)groupIdentifer {
    NSMutableArray *memberArray = [NSMutableArray array];
    NSMutableArray *secondMemberArray = [NSMutableArray array];
    for (AccountInfo *accountInfo in array) {
        NSDictionary *dic = [[self getDatasFromTableName:GroupMemberTable conditions:@{@"identifier": groupIdentifer, @"address": accountInfo.address} fields:@[@"address"]] lastObject];
        NSString *address = [dic safeObjectForKey:@"address"];
        if (address == nil || address.length <= 0) {
            [memberArray objectAddObject:@[groupIdentifer, accountInfo.username, accountInfo.avatar, accountInfo.address, @(accountInfo.roleInGroup), accountInfo.groupNickName, accountInfo.pub_key]];
        } else {
            [self deleteTableName:GroupMemberTable conditions:@{@"identifier": groupIdentifer, @"address": accountInfo.address}];
            [secondMemberArray objectAddObject:@[groupIdentifer, accountInfo.username, accountInfo.avatar, accountInfo.address, @(accountInfo.roleInGroup), accountInfo.groupNickName, accountInfo.pub_key]];
        }
    }
    if (memberArray.count > 0) {
        [self batchInsertTableName:GroupMemberTable fields:@[GroupMemberScope] batchValues:memberArray];
    }
    if (secondMemberArray.count > 0) {
        [self batchInsertTableName:GroupMemberTable fields:@[GroupMemberScope] batchValues:secondMemberArray];
    }

}

- (void)saveGroupInformation:(LMGroupInfo *)group {
    if (group.summary.length <= 0) {
        group.summary = group.groupName;
    }
    NSMutableDictionary *fieldValues = @{}.mutableCopy;
    [fieldValues safeSetObject:group.groupIdentifer forKey:@"identifier"];
    [fieldValues safeSetObject:group.groupName forKey:@"name"];
    [fieldValues safeSetObject:group.groupEcdhKey forKey:@"ecdh_key"];
    [fieldValues safeSetObject:@(group.isCommonGroup) forKey:@"common"];
    [fieldValues safeSetObject:@(group.isGroupVerify) forKey:@"verify"];
    [fieldValues safeSetObject:@(group.isPublic) forKey:@"pub"];
    [fieldValues safeSetObject:group.avatarUrl forKey:@"avatar"];
    [fieldValues safeSetObject:group.summary forKey:@"summary"];

    BOOL result = [self saveToCuttrentDBTableName:GroupInformationTable fieldsValues:fieldValues];
    if (result) {
        DDLogInfo(@"---》success");
        if (group.isCommonGroup) {
            [self addGroupToCommonGroup:group.groupIdentifer];
        }
    } else {
        DDLogError(@"---》failed");
    }
}

- (void)deletegroupWithGroupId:(NSString *)groupId {
    if (GJCFStringIsNull(groupId)) {
        return;
    }

    if ([self isInCommonGroup:groupId]) {
        [self removeFromCommonGroup:groupId];
    }
    BOOL result = [self deleteTableName:GroupInformationTable conditions:@{@"identifier": groupId}];

    BOOL resultMember = [self deleteTableName:GroupMemberTable conditions:@{@"identifier": groupId}];
    if (result && resultMember) {
        DDLogInfo(@"---》success");
    } else {
        DDLogError(@"---》failed");
    }


}

- (NSString *)getGroupSummaryWithGroupID:(NSString *)groupId {
    if (GJCFStringIsNull(groupId)) {
        return nil;
    }
    NSDictionary *dict = [[self getDatasFromTableName:GroupInformationTable conditions:@{@"identifier": groupId} fields:@[@"summary"]] lastObject];
    NSString *summary = [dict safeObjectForKey:@"summary"];
    if (summary) {
        return summary;
    } else {
        return @"";
    }
}

- (void)removeMemberWithAddress:(NSString *)address groupId:(NSString *)groupId {
    if (GJCFStringIsNull(groupId) || GJCFStringIsNull(address)) {
        return;
    }

    [self deleteTableName:GroupMemberTable conditions:@{@"identifier": groupId, @"address": address}];

}

- (void)updateMyGroupNickName:(NSString *)name groupId:(NSString *)groupId {
    if (GJCFStringIsNull(groupId) || GJCFStringIsNull(name)) {
        return;
    }
    [self updateGroupMembserUsername:name address:[LKUserCenter shareCenter].currentLoginUser.address groupId:groupId];
}

- (void)updateGroup:(LMGroupInfo *)group {
    if (GJCFStringIsNull(group.groupIdentifer)) {
        return;
    }
    NSMutableDictionary *fieldValues = @{}.mutableCopy;
    [fieldValues safeSetObject:group.groupIdentifer forKey:@"identifier"];
    [fieldValues safeSetObject:group.groupName forKey:@"name"];
    [fieldValues safeSetObject:group.groupEcdhKey forKey:@"ecdh_key"];
    [fieldValues safeSetObject:@(group.isCommonGroup) forKey:@"common"];
    [fieldValues safeSetObject:@(group.isGroupVerify) forKey:@"verify"];
    [fieldValues safeSetObject:@(group.isPublic) forKey:@"pub"];
    [fieldValues safeSetObject:group.avatarUrl forKey:@"avatar"];
    [fieldValues safeSetObject:group.summary forKey:@"summary"];
    [self updateTableName:GroupInformationTable fieldsValues:fieldValues conditions:@{@"identifier": group.groupIdentifer}];
    BOOL result = [self deleteTableName:GroupMemberTable conditions:@{@"identifier": group.groupIdentifer}];
    if (result) {
        [self saveGroupMember:group.groupMembers withGroupIdentifier:group.groupIdentifer];
    }
}


- (void)updateGroupMembserUsername:(NSString *)userName address:(NSString *)address groupId:(NSString *)groupId {
    if (GJCFStringIsNull(groupId) || GJCFStringIsNull(address)) {
        return;
    }
    NSMutableDictionary *fieldValues = @{}.mutableCopy;
    [fieldValues safeSetObject:userName forKey:@"username"];
    [self updateTableName:GroupMemberTable fieldsValues:fieldValues conditions:@{@"address": address, @"identifier": groupId}];
}

- (void)updateGroupMembserAvatarUrl:(NSString *)avatarUrl address:(NSString *)address groupId:(NSString *)groupId {
    if (GJCFStringIsNull(groupId) || GJCFStringIsNull(address) || GJCFStringIsNull(avatarUrl)) {
        return;
    }
    NSMutableDictionary *fieldValues = @{}.mutableCopy;
    [fieldValues safeSetObject:avatarUrl forKey:@"avatar"];
    [self updateTableName:GroupMemberTable fieldsValues:fieldValues conditions:@{@"address": address, @"identifier": groupId}];
}

- (void)updateGroupMembserNick:(NSString *)nickName address:(NSString *)address groupId:(NSString *)groupId {
    if (GJCFStringIsNull(groupId) || GJCFStringIsNull(address)) {
        return;
    }
    NSMutableDictionary *fieldValues = @{}.mutableCopy;
    [fieldValues safeSetObject:nickName forKey:@"nick"];
    [self updateTableName:GroupMemberTable fieldsValues:fieldValues conditions:@{@"address": address, @"identifier": groupId}];
}

- (void)updateGroupMembserRole:(int)role address:(NSString *)address groupId:(NSString *)groupId {
    if (GJCFStringIsNull(groupId) || GJCFStringIsNull(address)) {
        return;
    }
    [self updateTableName:GroupMemberTable fieldsValues:@{@"role": @(role)} conditions:@{@"address": address, @"identifier": groupId}];
}

- (void)changeOldAdminToMemberWithGroupId:(NSString *)groupId {
    if (GJCFStringIsNull(groupId)) {
        return;
    }
    [self updateTableName:GroupMemberTable fieldsValues:@{@"role": @(0)} conditions:@{@"role": @(1), @"identifier": groupId}];
}


- (void)updateGroupName:(NSString *)name groupId:(NSString *)groupId {

    if (GJCFStringIsNull(name) || GJCFStringIsNull(groupId)) {
        return;
    }
    NSMutableDictionary *fieldValues = @{}.mutableCopy;
    [fieldValues safeSetObject:name forKey:@"name"];
    [self updateTableName:GroupInformationTable fieldsValues:fieldValues conditions:@{@"identifier": groupId}];

}

- (void)updateGroupAvatarUrl:(NSString *)avatarUrl groupId:(NSString *)groupId {
    if (GJCFStringIsNull(avatarUrl) || GJCFStringIsNull(groupId)) {
        return;
    }
    NSMutableDictionary *fieldValues = @{}.mutableCopy;
    [fieldValues safeSetObject:avatarUrl forKey:@"avatar"];
    [self updateTableName:GroupInformationTable fieldsValues:fieldValues conditions:@{@"identifier": groupId}];
}


- (LMGroupInfo *)getgroupByGroupIdentifier:(NSString *)groupid {

    if (GJCFStringIsNull(groupid)) {
        return nil;
    }

    NSDictionary *dict = [[self getDatasFromTableName:GroupInformationTable conditions:@{@"identifier": groupid} fields:@[GroupInformation]] lastObject];
    if (!dict) {
        return nil;
    }
    LMGroupInfo *lmGroup = [[LMGroupInfo alloc] init];
    lmGroup.groupIdentifer = [dict safeObjectForKey:@"identifier"];
    lmGroup.groupName = [dict safeObjectForKey:@"name"];
    lmGroup.groupEcdhKey = [dict safeObjectForKey:@"ecdh_key"];
    lmGroup.isCommonGroup = [[dict safeObjectForKey:@"common"] boolValue];
    lmGroup.isGroupVerify = [[dict safeObjectForKey:@"verify"] boolValue];
    lmGroup.isPublic = [[dict safeObjectForKey:@"pub"] boolValue];
    lmGroup.avatarUrl = [dict safeObjectForKey:@"avatar"];
    lmGroup.summary = [dict safeObjectForKey:@"summary"];
    if (lmGroup.summary.length <= 0) {
        lmGroup.summary = lmGroup.groupName;
    }
    lmGroup.groupMembers = [self getgroupMemberByGroupIdentifier:groupid];
    lmGroup.admin = [lmGroup.groupMembers firstObject];
    if (lmGroup.groupMembers.count <= 0) {
        return nil;
    }
    return lmGroup;

}

- (BOOL)groupInfoExisitByGroupIdentifier:(NSString *)groupid {
    if (GJCFStringIsNull(groupid)) {
        return NO;
    }
    NSDictionary *dict = [[self getDatasFromTableName:GroupInformationTable conditions:@{@"identifier": groupid} fields:@[@"identifier"]] lastObject];
    if (!dict) {
        return NO;
    } else {
        return YES;
    }
}


- (NSMutableArray *)getgroupMemberByGroupIdentifier:(NSString *)groupid {
    if (GJCFStringIsNull(groupid)) {
        return nil;
    }
    NSArray *memberArray = [self queryWithSql:[NSString stringWithFormat:@"select gm.username,gm.avatar,gm.pub_key,gm.address,gm.role,gm.nick,c.remark from t_group_Member as gm left join t_contact as c on c.pub_key = gm.pub_key where gm.identifier = '%@'", groupid]];
    if (memberArray.count <= 0) {
        return nil;
    }
    NSMutableArray *mutableMembers = [NSMutableArray array];
    AccountInfo *admin = nil;
    for (NSDictionary *dic in memberArray) {
        AccountInfo *accountInfo = [[AccountInfo alloc] init];
        accountInfo.username = [dic safeObjectForKey:@"username"];
        accountInfo.avatar = [dic safeObjectForKey:@"avatar"];
        accountInfo.address = [dic safeObjectForKey:@"address"];
        NSString *remark = [dic valueForKey:@"remarks"];
        if (GJCFStringIsNull(remark) || [remark isEqual:[NSNull null]]) {
            accountInfo.groupNickName = [dic safeObjectForKey:@"nick"];
        } else {
            accountInfo.groupNickName = remark;
        }
        accountInfo.roleInGroup = [[dic safeObjectForKey:@"role"] intValue];
        accountInfo.pub_key = [dic safeObjectForKey:@"pub_key"];
        if (accountInfo.roleInGroup == 1) {
            admin = accountInfo;
            accountInfo.isGroupAdmin = YES;
        } else {
            [mutableMembers objectAddObject:accountInfo];
        }
    }

    if (admin) {
        [mutableMembers objectInsert:admin atIndex:0];
    }
    return mutableMembers;
}

- (NSString *)getGroupEcdhKeyByGroupIdentifier:(NSString *)groupid {
    if (GJCFStringIsNull(groupid)) {
        return nil;
    }
    NSDictionary *dict = [[self getDatasFromTableName:GroupInformationTable conditions:@{@"identifier": groupid} fields:@[@"ecdh_key"]] lastObject];

    return [dict safeObjectForKey:@"ecdh_key"];
}


- (NSArray *)getAllgroups {
    NSArray *groupArray = [self getDatasFromTableName:GroupInformationTable conditions:nil fields:@[GroupInformation]];
    if (groupArray.count <= 0) {
        return nil;
    }
    NSMutableArray *groupsArray = [NSMutableArray array];
    for (NSDictionary *dict in groupArray) {
        LMGroupInfo *lmGroup = [[LMGroupInfo alloc] init];
        lmGroup.groupIdentifer = [dict safeObjectForKey:@"identifier"];
        lmGroup.groupName = [dict safeObjectForKey:@"name"];
        lmGroup.groupEcdhKey = [dict safeObjectForKey:@"ecdh_key"];
        lmGroup.isCommonGroup = [[dict safeObjectForKey:@"common"] boolValue];
        lmGroup.isGroupVerify = [[dict safeObjectForKey:@"verify"] boolValue];
        lmGroup.isPublic = [[dict safeObjectForKey:@"pub"] boolValue];
        lmGroup.avatarUrl = [dict safeObjectForKey:@"avatar"];
        lmGroup.summary = [dict safeObjectForKey:@"summary"];
        lmGroup.groupMembers = [self getgroupMemberByGroupIdentifier:lmGroup.groupIdentifer];
        lmGroup.admin = [lmGroup.groupMembers firstObject];
        [groupsArray objectAddObject:lmGroup];
    }
    return groupsArray;
}

- (BOOL)isGroupPublic:(NSString *)groupid {
    if (GJCFStringIsNull(groupid)) {
        return NO;
    }

    NSDictionary *dict = [[self getDatasFromTableName:GroupInformationTable conditions:@{@"identifier": groupid} fields:@[@"pub"]] lastObject];

    return [[dict safeObjectForKey:@"pub"] boolValue];
}

- (void)getAllgroupsWithComplete:(void (^)(NSArray *groups))complete {
    [GCDQueue executeInGlobalQueue:^{
        NSArray *allGoup = [self getAllgroups];
        if (complete) {
            complete(allGoup);
        }

    }];
}


- (NSArray *)commonGroupList {

    NSArray *commonGroupArray = [self getDatasFromTableName:GroupInformationTable conditions:@{@"common": @(1)} fields:@[GroupInformation]];
    if (commonGroupArray.count <= 0) {
        return nil;
    }
    NSMutableArray *commonArray = [NSMutableArray array];
    for (NSDictionary *dict in commonGroupArray) {
        LMGroupInfo *lmGroup = [[LMGroupInfo alloc] init];
        lmGroup.groupIdentifer = [dict safeObjectForKey:@"identifier"];
        lmGroup.groupName = [dict safeObjectForKey:@"name"];
        lmGroup.groupEcdhKey = [dict safeObjectForKey:@"ecdh_key"];
        lmGroup.isCommonGroup = [[dict safeObjectForKey:@"common"] boolValue];
        lmGroup.isGroupVerify = [[dict safeObjectForKey:@"verify"] boolValue];
        lmGroup.isPublic = [[dict safeObjectForKey:@"pub"] boolValue];
        lmGroup.avatarUrl = [dict safeObjectForKey:@"avatar"];
        lmGroup.summary = [dict safeObjectForKey:@"summary"];
        lmGroup.groupMembers = [self getgroupMemberByGroupIdentifier:lmGroup.groupIdentifer];
        lmGroup.admin = [lmGroup.groupMembers firstObject];
        if (lmGroup.groupMembers.count > 0) {
            [commonArray objectAddObject:lmGroup];
        }
    }
    if (commonArray.count <= 0) {
        return nil;
    }
    return commonArray.copy;

}

- (void)getCommonGroupListWithComplete:(void (^)(NSArray *CommonGroups))complete {
    [GCDQueue executeInGlobalQueue:^{
        NSArray *commonArray = [self commonGroupList];
        if (complete) {
            complete(commonArray);
        }
    }];
}

- (void)addGroupToCommonGroup:(NSString *)groupid {
    if (GJCFStringIsNull(groupid)) {
        return;
    }
    BOOL result = [self updateTableName:GroupInformationTable fieldsValues:@{@"common": @(1)} conditions:@{@"identifier": groupid}];
    if (result) {
        DDLogInfo(@"success");
        [GCDQueue executeInMainQueue:^{
            SendNotify(ConnnectAddCommonGroupNotification, groupid);
        }];
    } else {
        DDLogError(@"failed");
    }

}

- (void)setGroupNeedPublic:(NSString *)groupid {
    if (GJCFStringIsNull(groupid)) {
        return;
    }

    BOOL result = [self updateTableName:GroupInformationTable fieldsValues:@{@"pub": @(1)} conditions:@{@"identifier": groupid}];
    if (result) {
        DDLogInfo(@"success");
    } else {
        DDLogError(@"failed");
    }
}

- (void)updateGroupPublic:(BOOL)isPublic groupId:(NSString *)groupid {
    if (GJCFStringIsNull(groupid)) {
        return;
    }
    int value = 0;
    if (isPublic) {
        value = 1;
    }
    BOOL result = [self updateTableName:GroupInformationTable fieldsValues:@{@"pub": @(value)} conditions:@{@"identifier": groupid}];
    if (result) {
        DDLogInfo(@"success ");
    } else {
        DDLogError(@"failed");
    }

}

- (void)setGroupNeedNotPublic:(NSString *)groupid {
    if (GJCFStringIsNull(groupid)) {
        return;
    }

    BOOL result = [self updateTableName:GroupInformationTable fieldsValues:@{@"pub": @(0)} conditions:@{@"identifier": groupid}];
    if (result) {
        DDLogInfo(@"success");
    } else {
        DDLogError(@"failed");
    }
}

- (void)setGroupNewAdmin:(NSString *)address groupId:(NSString *)groupId {
    if (GJCFStringIsNull(groupId) || address.length <= 0) {
        return;
    }
    [self changeOldAdminToMemberWithGroupId:groupId];

    [self updateGroupMembserRole:1 address:address groupId:groupId];

}

- (void)removeFromCommonGroup:(NSString *)groupid {
    if (GJCFStringIsNull(groupid)) {
        return;
    }

    BOOL result = [self updateTableName:GroupInformationTable fieldsValues:@{@"common": @(0)} conditions:@{@"identifier": groupid}];
    if (result) {
        DDLogInfo(@"success");
        [GCDQueue executeInMainQueue:^{
            SendNotify(ConnnectRemoveCommonGroupNotification, groupid);
        }];
    } else {
        DDLogError(@"failed");
    }

}

- (void)removeAllGroup {
    BOOL result = [self deleteTableName:GroupInformationTable conditions:nil];
    BOOL resultMember = [self deleteTableName:GroupMemberTable conditions:nil];
    if (result && resultMember) {
        DDLogInfo(@"success");
    } else {
        DDLogInfo(@"fail");
    }
}

- (BOOL)isInCommonGroup:(NSString *)groupid {
    if (GJCFStringIsNull(groupid)) {
        return NO;
    }

    NSDictionary *dict = [[self getDatasFromTableName:GroupInformationTable conditions:@{@"identifier": groupid} fields:@[@"common"]] lastObject];

    return [[dict safeObjectForKey:@"common"] boolValue];
}

- (AccountInfo *)getAdminByGroupId:(NSString *)groupId {
    if (GJCFStringIsNull(groupId)) {
        return nil;
    }
    NSDictionary *dic = [[self getDatasFromTableName:GroupMemberTable conditions:@{@"identifier": groupId, @"role": @(1)} fields:@[GroupMemberScope]] lastObject];
    if (!dic) {
        return nil;
    }
    AccountInfo *accountInfo = [[AccountInfo alloc] init];
    accountInfo.username = [dic safeObjectForKey:@"username"];
    accountInfo.avatar = [dic safeObjectForKey:@"avatar"];
    accountInfo.pub_key = [dic safeObjectForKey:@"pub_key"];
    accountInfo.address = [dic safeObjectForKey:@"address"];
    accountInfo.roleInGroup = [[dic safeObjectForKey:@"role"] intValue];
    accountInfo.groupNickName = [dic safeObjectForKey:@"nick"];
    return accountInfo;
}


- (AccountInfo *)getGroupMemberByGroupId:(NSString *)groupId memberAddress:(NSString *)address {
    if (GJCFStringIsNull(groupId) || GJCFStringIsNull(address)) {
        return nil;
    }
    NSDictionary *dic = [[self getDatasFromTableName:GroupMemberTable conditions:@{@"identifier": groupId, @"address": address} fields:@[GroupMemberScope]] lastObject];
    if (!dic) {
        return nil;
    }
    AccountInfo *accountInfo = [[AccountInfo alloc] init];
    accountInfo.username = [dic safeObjectForKey:@"username"];
    accountInfo.avatar = [dic safeObjectForKey:@"avatar"];
    accountInfo.pub_key = [dic safeObjectForKey:@"pub_key"];
    accountInfo.address = [dic safeObjectForKey:@"address"];
    accountInfo.roleInGroup = [[dic safeObjectForKey:@"role"] intValue];
    accountInfo.groupNickName = [dic safeObjectForKey:@"nick"];
    return accountInfo;
}


- (BOOL)userWithAddress:(NSString *)address isinGroup:(NSString *)groupId {
    if (GJCFStringIsNull(groupId) || GJCFStringIsNull(address)) {
        return NO;
    }
    NSDictionary *dic = [[self getDatasFromTableName:GroupMemberTable conditions:@{@"identifier": groupId, @"address": address} fields:@[GroupMemberScope]] lastObject];
    return dic != nil;
}

- (void)updateGroupPublic:(BOOL)public_ reviewed:(BOOL)reviewed summary:(NSString *)summary avatar:(NSString *)avatar withGroupId:(NSString *)groupId {
    if (GJCFStringIsNull(groupId)) {
        return;
    }
    BOOL result = [self updateTableName:GroupInformationTable fieldsValues:@{@"pub": @(public_),
                    @"summary": !summary ? @"" : summary,
                    @"avatar": avatar ? avatar : @"",
                    @"verify": @(reviewed)}
                             conditions:@{@"identifier": groupId}];
    if (result) {
        DDLogInfo(@"success");
    } else {
        DDLogError(@"fail");
    }
}

- (BOOL)checkLoginUserIsGroupAdminWithIdentifier:(NSString *)identifier {
    AccountInfo *admin = [self getAdminByGroupId:identifier];
    return [admin.address isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address];
}

@end
