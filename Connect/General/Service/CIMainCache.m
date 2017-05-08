//
//  CIMainCache.m
//  Connect
//
//  Created by MoHuilin on 16/9/9.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "CIMainCache.h"
#import "UserDBManager.h"

@interface CIMainCache()<NSCacheDelegate>

@property (nonatomic ,strong) NSCache *cache;

@property (nonatomic ,strong) NSMutableArray *contactAllKeys;
@property (nonatomic ,strong) NSMutableArray *contactAllValues;

@end

@implementation CIMainCache

+ (instancetype)sharedInstance
{
    static CIMainCache* instance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [CIMainCache new];
    });

    return instance;
}

- (instancetype)init{
    if (self = [super init]) {
        self.cache = [[NSCache alloc] init];
        self.cache.delegate = self;
        [self.cache setTotalCostLimit:10 * 1024 * 1024];
        
        self.contactAllKeys = [NSMutableArray array];
        self.contactAllValues = [NSMutableArray array];
    }
    
    return self;
}

- (NSArray *)myContacts{

    if (self.contactAllValues .count > 0) {
        return self.contactAllValues.copy;
    }
    
    NSArray *contacts = [[UserDBManager sharedManager] getAllUsers];
    for (AccountInfo *user in contacts) {
        if (!user && GJCFStringIsNull(user.address)) {
            continue;
        }
        [self.contactAllKeys objectAddObject:user.address];
        [self.contactAllValues objectAddObject:user];
        [self.cache setObject:user forKey:user.address];
    }
    
    return contacts;
}

- (void)upDataContact:(AccountInfo *)user{
    [self.cache setObject:user forKey:user.address];
}

- (void)cache:(NSCache *)cache willEvictObject:(id)obj{
    DDLogError(@"The global cache is released");
}

@end
