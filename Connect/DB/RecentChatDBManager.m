//
//  RecentChatDBManager.m
//  Connect
//
//  Created by MoHuilin on 16/8/2.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "RecentChatDBManager.h"
#import "UserDBManager.h"
#import "GroupDBManager.h"
#import "MessageDBManager.h"
#import "IMService.h"
#import "ConnectTool.h"
#import "LMBaseSSDBManager.h"
#import "LMConversionManager.h"


static RecentChatDBManager *manager = nil;

@implementation RecentChatDBManager

+ (RecentChatDBManager *)sharedManager {
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

- (void)deleteAllMessageTable {
    NSArray *recentChatArray = [self getAllRecentChat];

    for (RecentChatModel *model in recentChatArray) {
        if (GJCFStringIsNull(model.identifier)) {
            continue;
        }

        BOOL result = [self dropTableWithTableName:model.identifier.sha1String];
        if (result) {
            DDLogInfo(@"delete table failed");
        } else {
            NSString *msg = [NSString stringWithFormat:@"delete table success：%@", model.identifier.sha1String];
            DDLogInfo(msg);
        }
    }
}

- (void)deleteMessageTableByIdentifer:(NSString *)identifer {
    if (GJCFStringIsNull(identifer)) {
        return;
    }

    BOOL result = [self dropTableWithTableName:identifer.sha1String];
    if (result) {
        DDLogInfo(@"delete table failed");
    } else {
        NSString *msg = [NSString stringWithFormat:@"delete table success：%@", identifer.sha1String];
        DDLogInfo(msg);
    }
}

- (BOOL)deleteMessageTableByIdentifer:(NSString *)identifer messageid:(NSString *)messageid {
    if (GJCFStringIsNull(identifer)) {
        return NO;
    }
    if (GJCFStringIsNull(messageid)) {
        return NO;
    }


    BOOL result = [self deleteTableName:identifer.sha1String conditions:@{@"message_id": messageid}];

    if (result) {
        NSString *msg = [NSString stringWithFormat:@"delete message success ：%@ --msg id：%@", identifer.sha1String, messageid];
        DDLogInfo(@"%@", msg);
    } else {
        NSString *msg = [NSString stringWithFormat:@"delete message failed ：%@ --msgid：%@", identifer.sha1String, messageid];
        DDLogInfo(@"%@", msg);
    }

    return result;

}

- (NSArray *)getAllRecentChatWithoutSystemChat {

    return nil;
}


- (NSArray *)getAllRecentChat {

    NSString *querySql = @"select c.identifier,c.name,c.avatar,c.draft,c.stranger,c.last_time,c.unread_count,c.top,c.notice,c.type,c.content,s.snap_time,s.disturb from t_conversion c,t_conversion_setting s where c.identifier = s.identifier order by c.last_time desc";
    NSArray *resultArray = [self queryWithSql:querySql];
    NSMutableArray *recentChatArrayM = [NSMutableArray array];
    for (NSDictionary *resultDict in resultArray) {
        RecentChatModel *model = [RecentChatModel new];
        model.identifier = [resultDict safeObjectForKey:@"identifier"];
        model.name = [resultDict safeObjectForKey:@"name"];
        model.headUrl = [resultDict safeObjectForKey:@"avatar"];
        model.draft = [resultDict safeObjectForKey:@"draft"];
        model.stranger = [[resultDict safeObjectForKey:@"stranger"] boolValue];
        model.time = [resultDict safeObjectForKey:@"last_time"];
        model.unReadCount = [[resultDict safeObjectForKey:@"unread_count"] intValue];
        model.isTopChat = [[resultDict safeObjectForKey:@"top"] boolValue];
        model.groupNoteMyself = [[resultDict safeObjectForKey:@"notice"] boolValue];
        model.talkType = [[resultDict safeObjectForKey:@"type"] integerValue];
        model.content = [resultDict safeObjectForKey:@"content"];
        model.snapChatDeleteTime = [[resultDict safeObjectForKey:@"snap_time"] intValue];
        model.notifyStatus = [[resultDict safeObjectForKey:@"disturb"] boolValue];
        [recentChatArrayM addObject:model];
    }
    
    //sort
    [recentChatArrayM sortUsingSelector:@selector(comparedata:)];
    
    return recentChatArrayM;
}

- (void)getAllRecentChatWithComplete:(void (^)(NSArray *))complete {
    if (complete) {
        [GCDQueue executeInGlobalQueue:^{
            complete([self getAllRecentChat]);
        }];
    }
}

- (void)getTopChatCountWithComplete:(void (^)(int count))complete {
    [GCDQueue executeInGlobalQueue:^{
        if (complete) {
            NSString *sql = [NSString stringWithFormat:@"SELECT count(*) as count FROM %@ WHERE top_chat = 1", RecentChatTable];
            NSDictionary *dict = [[self queryWithSql:sql] lastObject];
            int count = [[dict safeObjectForKey:@"count"] intValue];
            [GCDQueue executeInMainQueue:^{
                if (complete) {
                    complete(count);
                }
            }];
        }
    }];
}

- (void)getAllBaseInfoRecentChatWithComplete:(void (^)(NSArray *recentChats))complete {

}

- (void)save:(RecentChatModel *)model {
    if (!model) {
        return;
    }
    if (GJCFStringIsNull(model.identifier)) {
        return;
    }

    NSMutableArray *bitchValues = [NSMutableArray array];
    [bitchValues objectAddObject:@[model.identifier,
            model.name,
            model.headUrl,
            model.draft,
            @(model.stranger),
            model.time,
            @(model.unReadCount),
            @(model.isTopChat),
            @(model.groupNoteMyself),
            @(model.talkType),
            model.content]];
    BOOL result = [self executeUpdataOrInsertWithTable:RecentChatTable fields:@[@"identifier", @"name", @"avatar", @"draft", @"stranger", @"last_time", @"unread_count", @"top", @"notice", @"type", @"content"] batchValues:bitchValues];
    if (result) {

        [[SessionManager sharedManager] setRecentChat:model];
        DDLogInfo(@"Save success");
    } else {
        DDLogInfo(@"Save fail");
    }

    [bitchValues removeAllObjects];
    [bitchValues objectAddObject:@[model.identifier,
            @(model.snapChatDeleteTime),
            @(model.notifyStatus)]];
    [self executeUpdataOrInsertWithTable:RecentChatTableSetting fields:@[@"identifier", @"snap_time", @"disturb"] batchValues:bitchValues];
}

- (void)deleteByIdentifier:(NSString *)identifier {

    if (GJCFStringIsNull(identifier)) {
        return;
    }

    BOOL result = [self deleteTableName:RecentChatTable conditions:@{@"identifier": identifier}];
    
//    [self deleteTableName:RecentChatTableSetting conditions:@{@"identifier": identifier}];

    //remove draft
    [self removeDraftWithIdentifier:identifier];
    if (result) {
        DDLogInfo(@"success");
    } else {
        DDLogError(@"fail");
    }
    [[LMConversionManager sharedManager] deleteConversationWithIdentifier:identifier];
}

- (void)getAllUnReadCountWithComplete:(void (^)(int count))complete {
    NSString *sql = @"select sum(c.unread_count) as unreadcount from t_conversion c,t_conversion_setting s where c.identifier = s.identifier and s.disturb = 0";
    NSDictionary *dict = [[self queryWithSql:sql] lastObject];
    id totalUnreadCount = [dict safeObjectForKey:@"unreadcount"];
    int count = 0;
    if (totalUnreadCount != [NSNull null]) {
        count = [totalUnreadCount intValue];
    }
    if (complete) {
        complete(count);
    }
}

- (void)openOrCloseSnapChatWithTime:(int)snapTime chatIdentifer:(NSString *)identifier {
    if (GJCFStringIsNull(identifier)) {
        return;
    }
    if (snapTime < 0) {
        snapTime = 0;
    }
    [self updateTableName:RecentChatTableSetting fieldsValues:@{@"snap_time": @(snapTime)} conditions:@{@"identifier": identifier}];
}

- (RecentChatModel *)getRecentModelByIdentifier:(NSString *)identifier {
    if (GJCFStringIsNull(identifier)) {
        return nil;
    }
    NSString *querySql = [NSString stringWithFormat:@"select c.identifier,c.name,c.avatar,c.draft,c.stranger,c.last_time,c.unread_count,c.top,c.notice,c.type,c.content,s.snap_time,s.disturb from t_conversion c,t_conversion_setting s where c.identifier = s.identifier and s.identifier = '%@'", identifier];
    NSArray *resultArray = [self queryWithSql:querySql];
    NSDictionary *resultDict = [resultArray lastObject];
    RecentChatModel *model = nil;
    if (resultDict) {
        model = [RecentChatModel new];
        model.identifier = [resultDict safeObjectForKey:@"identifier"];
        model.name = [resultDict safeObjectForKey:@"name"];
        model.headUrl = [resultDict safeObjectForKey:@"avatar"];
        model.draft = [resultDict safeObjectForKey:@"draft"];
        model.stranger = [[resultDict safeObjectForKey:@"stranger"] boolValue];
        model.time = [resultDict safeObjectForKey:@"last_time"];
        model.unReadCount = [[resultDict safeObjectForKey:@"unread_count"] intValue];
        model.isTopChat = [[resultDict safeObjectForKey:@"top"] boolValue];
        model.groupNoteMyself = [[resultDict safeObjectForKey:@"notice"] boolValue];
        model.talkType = [[resultDict safeObjectForKey:@"type"] integerValue];
        model.content = [resultDict safeObjectForKey:@"content"];
        model.snapChatDeleteTime = [[resultDict safeObjectForKey:@"snap_time"] intValue];
        model.notifyStatus = [[resultDict safeObjectForKey:@"disturb"] boolValue];

        [[SessionManager sharedManager] setRecentChat:model];
    }
    return model;
}


- (void)topChat:(NSString *)identifier {

    if (GJCFStringIsNull(identifier)) {
        return;
    }
    int count = (int) [self getCountFromCurrentDBWithTableName:RecentChatTable condition:@{@"identifier": identifier} symbol:0];
    if (count == 0) {
        RecentChatModel *model = [RecentChatModel new];
        model.identifier = identifier;
        LMGroupInfo *group = [[GroupDBManager sharedManager] getgroupByGroupIdentifier:identifier];
        if (group) {
            model.talkType = GJGCChatFriendTalkTypeGroup;
            model.chatGroupInfo = group;
            model.name = group.groupName;
            model.headUrl = group.avatarUrl;
        } else {
            AccountInfo *user = [[UserDBManager sharedManager] getUserByPublickey:identifier];
            if (user) {
                model.talkType = GJGCChatFriendTalkTypePrivate;
                model.chatUser = user;
                model.name = user.username;
                model.headUrl = user.avatar;
            }
        }
        model.time = [NSString stringWithFormat:@"%lld",(long long)([[NSDate date] timeIntervalSince1970] * 1000)];
        [self save:model];
    } else {
        int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
        [self                     updateTableName:RecentChatTable fieldsValues:@{@"top": @(1),
                @"last_time": @(time)} conditions:@{@"identifier": identifier}];
    }
    
    [[LMConversionManager sharedManager] chatTop:YES identifier:identifier];
}

- (void)removeTopChat:(NSString *)identifier {
    if (GJCFStringIsNull(identifier)) {
        return;
    }
    BOOL result = [self updateTableName:RecentChatTable fieldsValues:@{@"top": @(0)} conditions:@{@"identifier": identifier}];
    if (result) {
        [[LMConversionManager sharedManager] chatTop:NO identifier:identifier];
    }
}

- (BOOL)isTopChat:(NSString *)identifier {
    if (GJCFStringIsNull(identifier)) {
        return NO;
    }

    NSDictionary *temD = [[self getDatasFromTableName:RecentChatTable conditions:@{@"identifier": identifier} fields:@[@"top"]] lastObject];
    return [[temD safeObjectForKey:@"top"] boolValue];
}


- (void)updateDraft:(NSString *)draft withIdentifier:(NSString *)identifier {
    if (GJCFStringIsNull(identifier)) {
        return;
    }
    draft = draft ? draft : @"";
    //update
    NSString *key = [NSString stringWithFormat:@"%@_draft",identifier];
    LMBaseSSDBManager *manager = [LMBaseSSDBManager open:@"system_message"];
    [manager set:key string:draft];
    [manager close];
    SendNotify(SendDraftChangeNotification, (@{@"identifier": identifier,
                                               @"draft": draft}));
//    [self updateTableName:RecentChatTable fieldsValues:@{@"draft": draft} conditions:@{@"identifier": identifier}];
}

- (void)removeDraftWithIdentifier:(NSString *)identifier {
    if (GJCFStringIsNull(identifier)) {
        return;
    }
    NSString *key = [NSString stringWithFormat:@"%@_draft",identifier];
    LMBaseSSDBManager *manager = [LMBaseSSDBManager open:@"system_message"];
    [manager set:key string:@""];
    [manager close];
//    [self updateTableName:RecentChatTable fieldsValues:@{@"draft": @""} conditions:@{@"identifier": identifier}];
}

- (NSString *)getDraftWithIdentifier:(NSString *)identifier {
    if (GJCFStringIsNull(identifier)) {
        return @"";
    }
    NSString *key = [NSString stringWithFormat:@"%@_draft",identifier];
    LMBaseSSDBManager *manager = [LMBaseSSDBManager open:@"system_message"];
    NSString *draft;
    [manager get:key string:&draft];
    [manager close];
    return draft;
//    NSDictionary *temD = [[self getDatasFromTableName:RecentChatTable conditions:@{@"identifier": identifier} fields:@[@"draft"]] lastObject];
//    return [temD safeObjectForKey:@"draft"];
}

- (void)updataUnReadCount:(int)unreadCount idetifier:(NSString *)idetifier {
    if (GJCFStringIsNull(idetifier)) {
        return;
    }
    [self updateTableName:RecentChatTable fieldsValues:@{@"unread_count": @(unreadCount)} conditions:@{@"identifier": idetifier}];
}

- (void)updataStrangerStatus:(BOOL)stranger idetifier:(NSString *)idetifier{
    if (GJCFStringIsNull(idetifier)) {
        return;
    }
    [self updateTableName:RecentChatTable fieldsValues:@{@"stranger": @(stranger)} conditions:@{@"identifier": idetifier}];
}

- (void)clearUnReadCountWithIdetifier:(NSString *)idetifier {
    [self updataUnReadCount:0 idetifier:idetifier];
}

- (void)customUpdateRecentChatTableWithFieldsValues:(NSDictionary *)fieldsValues withIdentifier:(NSString *)identifier {

    if (GJCFStringIsNull(identifier)) {
        return;
    }
    [self updateTableName:RecentChatTable fieldsValues:fieldsValues conditions:@{@"identifier": identifier}];
}

- (void)setGroupNoteMyselfWithIdentifer:(NSString *)identifer {
    if (GJCFStringIsNull(identifer)) {
        return;
    }
    [self updateTableName:RecentChatTable fieldsValues:@{@"notice": @(1)} conditions:@{@"identifier": identifer}];
}

- (void)clearGroupNoteMyselfWithIdentifer:(NSString *)identifer {
    if (GJCFStringIsNull(identifer)) {
        return;
    }
    [self updateTableName:RecentChatTable fieldsValues:@{@"notice": @(0)} conditions:@{@"identifier": identifer}];
}


- (void)setMuteWithIdentifer:(NSString *)identifer {
    if (GJCFStringIsNull(identifer)) {
        return;
    }

    [self updateTableName:RecentChatTableSetting fieldsValues:@{@"disturb": @(1)} conditions:@{@"identifier": identifer}];

    [self updateTableName:RecentChatTable fieldsValues:@{@"unread_count": @(0)} conditions:@{@"identifier": identifer}];
}

- (void)removeMuteWithIdentifer:(NSString *)identifer {
    if (GJCFStringIsNull(identifer)) {
        return;
    }
    [self updateTableName:RecentChatTableSetting fieldsValues:@{@"disturb": @(0)} conditions:@{@"identifier": identifer}];
}


- (BOOL)getMuteStatusWithIdentifer:(NSString *)identifer {
    if (GJCFStringIsNull(identifer)) {
        return NO;
    }
    NSDictionary *dict = [[self getDatasFromTableName:RecentChatTableSetting conditions:@{@"identifier": identifer} fields:@[@"disturb"]] lastObject];
    return [[dict safeObjectForKey:@"disturb"] boolValue];
}

- (void)openSnapChatWithIdentifier:(NSString *)identifier snapTime:(int)snapTime openOrCloseByMyself:(BOOL)flag {
    RecentChatModel *recentChat = [[SessionManager sharedManager] getRecentChatWithIdentifier:identifier];
    if (!recentChat) {
        recentChat = [self getRecentModelByIdentifier:identifier];
    }
    if (recentChat) {
        int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
        NSString *last_time = [NSString stringWithFormat:@"%lld", time];
        if (flag) {
            recentChat.unReadCount = 0;
        } else {
            recentChat.unReadCount += 1;
        }
        recentChat.time = last_time;
        recentChat.snapChatDeleteTime = snapTime;

        [self openOrCloseSnapChatWithTime:snapTime chatIdentifer:identifier];

        NSMutableDictionary *fieldsValues = [NSMutableDictionary dictionary];
        [fieldsValues safeSetObject:@(recentChat.unReadCount) forKey:@"unread_count"];
        [fieldsValues safeSetObject:recentChat.time forKey:@"last_time"];

        [self customUpdateRecentChatTableWithFieldsValues:fieldsValues withIdentifier:identifier];
    } else {
        AccountInfo *contact = [[UserDBManager sharedManager] getUserByPublickey:identifier];
        if (!contact) {
            contact = [[UserDBManager sharedManager] getFriendRequestBy:[KeyHandle getAddressByPubkey:identifier]];
            if (!contact && contact.status == 1) {
                return;
            }
        }
        recentChat = [[RecentChatModel alloc] init];
        recentChat.headUrl = contact.avatar;
        recentChat.name = contact.username;
        int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
        recentChat.time = [NSString stringWithFormat:@"%lld", time];
        recentChat.identifier = identifier;
        recentChat.unReadCount = 0;
        recentChat.snapChatDeleteTime = snapTime;
        recentChat.chatUser = contact;

        [self save:recentChat];
    }
    if (flag) {

        [GCDQueue executeInMainQueue:^{
            SendNotify(ConnnectRecentChatChangeNotification, recentChat);
        }];
    }
}


- (void)updataRecentChatLastTimeByIdentifer:(NSString *)identifer {

    if (GJCFStringIsNull(identifer)) {
        return;
    }
    int long long time = [[NSDate date] timeIntervalSince1970];
    NSString *last_time = [NSString stringWithFormat:@"%lld", time];
    [self updateTableName:RecentChatTable fieldsValues:@{@"last_time": last_time} conditions:@{@"identifier": identifer}];
}


- (RecentChatModel *)createNewChatWithIdentifier:(NSString *)identifier groupChat:(BOOL)groupChat lastContentShowType:(int)lastContentShowType lastContent:(NSString *)content {

    RecentChatModel *recentChat = [[SessionManager sharedManager] getRecentChatWithIdentifier:identifier];
    if (!recentChat) {
        recentChat = [self getRecentModelByIdentifier:identifier];
    }

    if (recentChat) {
        int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
        NSString *last_time = [NSString stringWithFormat:@"%lld", time];
        if (![[SessionManager sharedManager].chatSession isEqualToString:identifier] && lastContentShowType == 0) {
            recentChat.unReadCount++;
        }
        recentChat.content = content;
        recentChat.time = last_time;
        recentChat.content = content;
        NSMutableDictionary *fieldsValues = [NSMutableDictionary dictionary];
        [fieldsValues safeSetObject:@(recentChat.unReadCount) forKey:@"unread_count"];
        [fieldsValues safeSetObject:recentChat.content forKey:@"content"];
        [fieldsValues safeSetObject:recentChat.time forKey:@"last_time"];
        [self customUpdateRecentChatTableWithFieldsValues:fieldsValues withIdentifier:identifier];
    } else {
        if (groupChat) {
            int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
            NSString *timeStr = [NSString stringWithFormat:@"%lld", time];
            LMGroupInfo *groupInfo = [[GroupDBManager sharedManager] getgroupByGroupIdentifier:identifier];
            if (GJCFStringIsNull(groupInfo.groupEcdhKey)) {
                return nil;
            }
            recentChat = [[RecentChatModel alloc] init];
            recentChat.talkType = GJGCChatFriendTalkTypeGroup;
            recentChat.identifier = identifier;
            recentChat.time = timeStr;
            recentChat.content = content;
            if (![[SessionManager sharedManager].chatSession isEqualToString:identifier] && lastContentShowType == 0) {
                recentChat.unReadCount = 1;
            }
            recentChat.name = groupInfo.groupName;
            recentChat.headUrl = groupInfo.avatarUrl;
            recentChat.chatGroupInfo = groupInfo;
        } else {

            AccountInfo *contact = [[UserDBManager sharedManager] getUserByPublickey:identifier];
            if (!contact) {

                contact = [[UserDBManager sharedManager] getFriendRequestBy:[KeyHandle getAddressByPubkey:identifier]];
                if (!contact && contact.status == 1) {

                    return nil;
                }
            }

            if (![contact.pub_key isEqualToString:kSystemIdendifier]) {
                [[IMService instance] addNewSessionWithAddress:contact.address complete:^(NSError *erro, id data) {
                    DDLogInfo(@"create session %@", contact.address);
                }];
                recentChat = [[RecentChatModel alloc] init];
                recentChat.headUrl = contact.avatar;
                recentChat.name = contact.normalShowName;
                int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
                recentChat.time = [NSString stringWithFormat:@"%lld", time];
                recentChat.identifier = identifier;
                recentChat.talkType = GJGCChatFriendTalkTypePrivate;
                recentChat.content = content;
                if (![[SessionManager sharedManager].chatSession isEqualToString:identifier] && lastContentShowType == 0) {
                    recentChat.unReadCount = 1;
                }
                recentChat.chatUser = contact;
            } else {
                recentChat = [[RecentChatModel alloc] init];
                recentChat.headUrl = contact.avatar;
                recentChat.name = contact.normalShowName;
                int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
                recentChat.time = [NSString stringWithFormat:@"%lld", time];
                recentChat.talkType = GJGCChatFriendTalkTypePostSystem;
                recentChat.identifier = identifier;
                recentChat.content = content;
                if (![[SessionManager sharedManager].chatSession isEqualToString:identifier] && lastContentShowType == 0) {
                    recentChat.unReadCount = 1;
                }
                recentChat.chatUser = contact;
            }
        }
        recentChat.notifyStatus = [self getMuteStatusWithIdentifer:recentChat.identifier];
        [self save:recentChat];
    }
    [GCDQueue executeInMainQueue:^{
        SendNotify(ConnnectRecentChatChangeNotification, recentChat);
    }];
    return recentChat;
}

- (void)createNewChatWithIdentifier:(NSString *)identifier groupChat:(BOOL)groupChat lastContentShowType:(int)lastContentShowType lastContent:(NSString *)content ecdhKey:(NSString *)ecdhKey talkName:(NSString *)name {
    if (GJCFStringIsNull(identifier)) {
        return;
    }
    RecentChatModel *recentChat = [[SessionManager sharedManager] getRecentChatWithIdentifier:identifier];
    if (!recentChat) {
        recentChat = [self getRecentModelByIdentifier:identifier];
    }

    if (recentChat) {
        int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
        NSString *last_time = [NSString stringWithFormat:@"%lld", time];
        if (![[SessionManager sharedManager].chatSession isEqualToString:identifier] && lastContentShowType == 0) {
            recentChat.unReadCount++;
        }
        recentChat.content = content;
        recentChat.time = last_time;

        NSMutableDictionary *fieldsValues = [NSMutableDictionary dictionary];
        [fieldsValues safeSetObject:@(recentChat.unReadCount) forKey:@"unread_count"];
        [fieldsValues safeSetObject:recentChat.content forKey:@"content"];
        [fieldsValues safeSetObject:recentChat.time forKey:@"last_time"];

        [self customUpdateRecentChatTableWithFieldsValues:fieldsValues withIdentifier:identifier];

        [GCDQueue executeInMainQueue:^{
            SendNotify(ConnnectRecentChatChangeNotification, recentChat);
        }];

    } else {
        if (groupChat) {

            int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
            NSString *timeStr = [NSString stringWithFormat:@"%lld", time];
            LMGroupInfo *groupInfo = [[GroupDBManager sharedManager] getgroupByGroupIdentifier:identifier];
            if (GJCFStringIsNull(ecdhKey)) {
                ecdhKey = groupInfo.groupEcdhKey;
                if (GJCFStringIsNull(ecdhKey)) {
                    return;
                }
            }
            recentChat = [[RecentChatModel alloc] init];
            recentChat.talkType = GJGCChatFriendTalkTypeGroup;
            recentChat.identifier = identifier;
            recentChat.time = timeStr;
            recentChat.content = content;
            if (![[SessionManager sharedManager].chatSession isEqualToString:identifier] && lastContentShowType == 0) {
                recentChat.unReadCount = 1;
            }
            recentChat.name = groupInfo.groupName;
            recentChat.headUrl = groupInfo.avatarUrl;
            recentChat.chatGroupInfo = groupInfo;

        } else {
            AccountInfo *contact = [[UserDBManager sharedManager] getUserByPublickey:identifier];
            if (!contact) {

                contact = [[UserDBManager sharedManager] getFriendRequestBy:[KeyHandle getAddressByPubkey:identifier]];
                if (!contact && contact.status == 1) {

                    return;
                }
            } else {
                [[IMService instance] addNewSessionWithAddress:contact.address complete:^(NSError *erro, id data) {
                    DDLogInfo(@"创建会话成功 %@", contact.address);
                }];
            }

            if ([contact.pub_key isEqualToString:kSystemIdendifier]) {
                recentChat = [[RecentChatModel alloc] init];
                recentChat.talkType = GJGCChatFriendTalkTypePostSystem;
                int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
                recentChat.time = [NSString stringWithFormat:@"%lld", time];
                recentChat.unReadCount = 0;
                recentChat.name = @"Connect";
                recentChat.headUrl = @"connect_logo";
                recentChat.identifier = kSystemIdendifier;
                recentChat.chatUser = contact;
                recentChat.content = content;
            } else {
                ecdhKey = [KeyHandle getECDHkeyUsePrivkey:[[LKUserCenter shareCenter] currentLoginUser].prikey PublicKey:identifier];
                recentChat = [[RecentChatModel alloc] init];
                recentChat.headUrl = contact.avatar;
                recentChat.name = contact.normalShowName;
                int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
                recentChat.time = [NSString stringWithFormat:@"%lld", time];
                recentChat.identifier = identifier;
                recentChat.talkType = GJGCChatFriendTalkTypePrivate;
                recentChat.content = content;
                if (![[SessionManager sharedManager].chatSession isEqualToString:identifier] && lastContentShowType == 0) {
                    recentChat.unReadCount = 1;
                }
                recentChat.chatUser = contact;
            }
        }
        [self save:recentChat];
        [GCDQueue executeInMainQueue:^{
            SendNotify(ConnnectNewChatChangeNotification, recentChat);
        }];
    }

}

- (void)createNewChatNoRelationShipWihtRegisterUser:(AccountInfo *)user {

    user.stranger = YES;
    RecentChatModel *recentChat = [[SessionManager sharedManager] getRecentChatWithIdentifier:user.pub_key];
    if (!recentChat) {
        recentChat = [self getRecentModelByIdentifier:user.pub_key];
    }
    if (recentChat) {
        int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
        NSString *last_time = [NSString stringWithFormat:@"%lld", time];
        if (![[SessionManager sharedManager].chatSession isEqualToString:user.pub_key]) {
            recentChat.unReadCount++;
        }
        recentChat.time = last_time;

        NSMutableDictionary *fieldsValues = [NSMutableDictionary dictionary];
        [fieldsValues safeSetObject:@(recentChat.unReadCount) forKey:@"unread_count"];
        [fieldsValues safeSetObject:recentChat.content forKey:@"content"];
        [fieldsValues safeSetObject:recentChat.time forKey:@"last_time"];

        [self customUpdateRecentChatTableWithFieldsValues:fieldsValues withIdentifier:user.pub_key];

    } else {
        recentChat = [[RecentChatModel alloc] init];
        recentChat.headUrl = user.avatar;
        recentChat.name = user.username;
        recentChat.stranger = YES;
        int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
        recentChat.time = [NSString stringWithFormat:@"%lld", time];
        recentChat.identifier = user.pub_key;
        if (![[SessionManager sharedManager].chatSession isEqualToString:recentChat.identifier]) {
            recentChat.unReadCount = 1;
        }
        recentChat.chatUser = user;
        [self save:recentChat];
    }
    [GCDQueue executeInMainQueue:^{
        SendNotify(ConnnectRecentChatChangeNotification, recentChat);
    }];
}

- (void)createConnectTermWelcomebackChatAndMessage {

    MMMessage *message = [[MMMessage alloc] init];
    message.user_name = @"Connect";
    message.type = GJGCChatFriendContentTypeText;
    message.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
    message.message_id = [ConnectTool generateMessageId];
    message.publicKey = [[LKUserCenter shareCenter] currentLoginUser].pub_key;
    message.user_id = [[LKUserCenter shareCenter] currentLoginUser].address;
    message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
    message.content = LMLocalizedString(@"Login Welcome", nil);
    message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
    ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
    chatMessage.messageId = message.message_id;
    chatMessage.createTime = (NSInteger) message.sendtime;
    chatMessage.messageType = GJGCChatFriendContentTypeText;
    chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
    chatMessage.readTime = 0;
    chatMessage.message = message;
    chatMessage.messageOwer = kSystemIdendifier;

    [[MessageDBManager sharedManager] saveBitchMessage:@[chatMessage]];

    RecentChatModel *model = [[SessionManager sharedManager] getRecentChatWithIdentifier:kSystemIdendifier];
    if (!model) {
        model = [self getRecentModelByIdentifier:kSystemIdendifier];
    }

    if (model) {
        int unRead = model.unReadCount;
        if (![[SessionManager sharedManager].chatSession isEqualToString:kSystemIdendifier]) {
            unRead++;
        }
        int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
        NSString *last_time = [NSString stringWithFormat:@"%lld", time];

        model.unReadCount = unRead;
        model.content = message.content;

        model.time = last_time;
        NSMutableDictionary *fieldsValues = [NSMutableDictionary dictionary];
        [fieldsValues safeSetObject:@(model.unReadCount) forKey:@"unread_count"];
        [fieldsValues safeSetObject:model.content forKey:@"content"];
        [fieldsValues safeSetObject:model.time forKey:@"last_time"];

        [self customUpdateRecentChatTableWithFieldsValues:fieldsValues withIdentifier:kSystemIdendifier];

    } else {
        model = [[RecentChatModel alloc] init];
        model.talkType = GJGCChatFriendTalkTypePostSystem;
        int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
        model.time = [NSString stringWithFormat:@"%lld", time];
        if (![[SessionManager sharedManager].chatSession isEqualToString:kSystemIdendifier]) {
            model.unReadCount = 1;
        }
        model.name = @"Connect";
        model.headUrl = @"connect_logo";
        model.identifier = kSystemIdendifier;
        model.content = message.content;
        [self save:model];
    }
    [GCDQueue executeInMainQueue:^{
        SendNotify(ConnnectRecentChatChangeNotification, model);
    }];
}

@end
