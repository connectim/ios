//
//  SessionManager.m
//  Connect
//
//  Created by MoHuilin on 2016/11/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "SessionManager.h"
#import "LMGroupInfo.h"
#import "RecentChatModel.h"
#import "NSMutableArray+MoveObject.h"

@interface SessionManager ()

@property (nonatomic ,strong) NSMutableDictionary *chatCookieDict;
@property (nonatomic ,strong) NSMutableDictionary *sessionEcdhCacheDict;
@property (nonatomic ,strong) NSMutableDictionary *sessionEcdhCacheExpireDict;

@end

static SessionManager *manager = nil;
@implementation SessionManager


+ (SessionManager *)sharedManager{
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
    if (self = [super init]) {
        self.chatCookieDict = [NSMutableDictionary dictionary];
        self.sessionEcdhCacheDict = [NSMutableDictionary dictionary];
        self.sessionEcdhCacheExpireDict = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)setChatSession:(NSString *)chatSession{
    _chatSession = chatSession;
}

- (void)removeChatCookieWithChatSession:(NSString *)chatSession{
    if (GJCFStringIsNull(chatSession)) {
        return;
    }
    return [self.chatCookieDict removeObjectForKey:chatSession];
}

- (ChatCookieData *)getChatCookieWithChatSession:(NSString *)chatSession{
    if (GJCFStringIsNull(chatSession)) {
        return nil;
    }
    return [self.chatCookieDict valueForKey:chatSession];
}
- (void)setChatCookie:(ChatCookieData *)chatCookie chatSession:(NSString *)chatSession{
    if (GJCFStringIsNull(chatSession) ||
        !chatCookie) {
        return ;
    }
    [self.chatCookieDict setValue:chatCookie forKey:chatSession];
}

- (BOOL)chatCookieExpire:(NSString *)chatSession{
    if (GJCFStringIsNull(chatSession)) {
        return nil;
    }
    return [[self.sessionEcdhCacheExpireDict valueForKey:chatSession] boolValue];
}
- (void)chatCookie:(BOOL)expire chatSession:(NSString *)chatSession{
    if (GJCFStringIsNull(chatSession)) {
        return ;
    }
    [self.sessionEcdhCacheExpireDict setValue:@(expire) forKey:chatSession];
}

- (void)setChatObject:(id)chatObject{
    _chatObject = chatObject;
    if ([chatObject isKindOfClass:[AccountInfo class]]) {
        AccountInfo *model = (AccountInfo *)chatObject;
        self.chatSession = model.pub_key;
    } else if([chatObject isKindOfClass:[LMGroupInfo class]]){
        LMGroupInfo *model = (LMGroupInfo *)chatObject;
        self.chatSession = model.groupIdentifer;
    }
}

- (void)setRecentChats:(NSArray *)recentChats{
    recentChats = [recentChats sortedArrayUsingSelector:@selector(comparedata:)];    
    [self.allRecentChats removeAllObjects];
    [self.allRecentChats addObjectsFromArray:recentChats];
}

- (RecentChatModel *)getRecentChatWithIdentifier:(NSString *)identifier{
    if (GJCFStringIsNull(identifier)) {
        return nil;
    }
    RecentChatModel *findModel = nil;
    for (RecentChatModel *model in self.allRecentChats) {
        if ([model.identifier isEqualToString:identifier]) {
            findModel = model;
            break;
        }
    }
    return findModel;
}

- (void)clearAllModel{
    self.chatObject = nil;
    self.chatSession = nil;
    self.topChatCount = 0;
    [self.allRecentChats removeAllObjects];
}

- (void)removeRecentChatWithIdentifier:(NSString *)identifier{
    if (GJCFStringIsNull(identifier)) {
        return;
    }
    
    RecentChatModel *findModel = nil;
    for (RecentChatModel *model in self.allRecentChats) {
        if ([model.identifier isEqualToString:identifier]) {
            findModel = model;
            break;
        }
    }
    if (findModel) {
        [self.allRecentChats removeObject:findModel];
    }
}

- (void)setRecentChat:(RecentChatModel *)model{
    if(!model){
        return ;
    }
    if (GJCFStringIsNull(model.identifier)) {
        return;
    }
    if ([self.allRecentChats containsObject:model]) {
        [self.allRecentChats repleteObject:model withObj:model];
    } else{
        [self.allRecentChats objectAddObject:model];
    }
}

- (NSMutableArray *)allRecentChats{
    if (!_allRecentChats) {
        _allRecentChats = [NSMutableArray array];
    }
    return _allRecentChats;
}

- (int)allRecentChatsUnreadCount{
    
    int count = 0;
    for (RecentChatModel *model in self.allRecentChats) {
        count += model.unReadCount;
    }
    return count;
}


- (void)setCurrentNewVersionInfo:(VersionResponse *)currentNewVersionInfo{
    _currentNewVersionInfo = currentNewVersionInfo;
    if (currentNewVersionInfo && self.GetNewVersionInfoCallback) {
        self.GetNewVersionInfoCallback(currentNewVersionInfo);
    }
}

@end
