//
//  LMMessageExtendManager.m
//  Connect
//
//  Created by Connect on 2017/4/14.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMMessageExtendManager.h"

#define MessageExtenTable @"t_transactiontable"


static LMMessageExtendManager *manager = nil;

@implementation LMMessageExtendManager

+ (LMMessageExtendManager *)sharedManager {
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

- (void)dealloc {
    DDLogInfo(@"释放对象");
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

- (void)saveBitchMessageExtend:(NSArray *)array {
    if (array.count <= 0) {
        return;
    }
    NSMutableArray *temArray = [NSMutableArray array];
    for (NSDictionary *dic  in array) {
        [temArray addObject:@[[dic safeObjectForKey:@"message_id"], [dic safeObjectForKey:@"hashid"], @([[dic safeObjectForKey:@"status"] intValue]), @([[dic safeObjectForKey:@"pay_count"] intValue]), @([[dic safeObjectForKey:@"crowd_count"] intValue])]];
    }
    [self batchInsertTableName:MessageExtenTable fields:@[@"message_id", @"hashid", @"status", @"pay_count", @"crowd_count"] batchValues:temArray];

}

- (void)saveBitchMessageExtendDict:(NSDictionary *)dic {

    if (!dic) {
        return;
    }
    if ([self isExisetWithHashId:[dic safeObjectForKey:@"hashid"]]) {
        [self                                                                   updateTableName:MessageExtenTable fieldsValues:@{@"message_id": [dic safeObjectForKey:@"message_id"],
                @"status": @([[dic safeObjectForKey:@"status"] intValue]),
                @"pay_count": @([[dic safeObjectForKey:@"pay_count"] intValue]),
                @"crowd_count": @([[dic safeObjectForKey:@"crowd_count"] intValue])} conditions:@{@"hashid": [dic safeObjectForKey:@"hashid"]}];
    } else {
        NSMutableArray *temArray = [NSMutableArray array];
        [temArray addObject:@[[dic safeObjectForKey:@"message_id"], [dic safeObjectForKey:@"hashid"], @([[dic safeObjectForKey:@"status"] intValue]), @([[dic safeObjectForKey:@"pay_count"] intValue]), @([[dic safeObjectForKey:@"crowd_count"] intValue])]];
        [self batchInsertTableName:MessageExtenTable fields:@[@"message_id", @"hashid", @"status", @"pay_count", @"crowd_count"] batchValues:temArray];
    }
}

- (void)updateMessageExtendStatus:(int)status withHashId:(NSString *)hashId {
    if (GJCFStringIsNull(hashId)) {
        return;
    }
    [self updateTableName:MessageExtenTable fieldsValues:@{@"status": @(status)} conditions:@{@"hashid": hashId}];

}

- (void)updateMessageExtendPayCount:(int)payCount withHashId:(NSString *)hashId {

    if (GJCFStringIsNull(hashId)) {
        return;
    }
    [self updateTableName:MessageExtenTable fieldsValues:@{@"pay_count": @(payCount)} conditions:@{@"hashid": hashId}];

}

- (void)updateMessageExtendPayCount:(int)payCount status:(int)status withHashId:(NSString *)hashId {
    if (GJCFStringIsNull(hashId)) {
        return;
    }
    [self updateTableName:MessageExtenTable fieldsValues:@{@"pay_count": @(payCount), @"status": @(status)} conditions:@{@"hashid": hashId}];

}

- (BOOL)isExisetWithHashId:(NSString *)hashId {
    if (GJCFStringIsNull(hashId)) {
        return NO;
    }
    NSDictionary *temD = [[self getDatasFromTableName:MessageExtenTable conditions:@{@"hashid": hashId} fields:@[@"hashid"]] lastObject];

    if (!temD) {
        return NO;
    } else {
        return YES;
    }
}

- (int)getStatus:(NSString *)hashId {
    if (GJCFStringIsNull(hashId)) {
        return 0;
    }
    NSDictionary *dic = [[self getDatasFromTableName:MessageExtenTable conditions:@{@"hashid": hashId} fields:@[@"status"]] lastObject];
    if (!dic) {
        return 0;
    } else {
        return [[dic safeObjectForKey:@"status"] intValue];
    }

}

- (int)getPayCount:(NSString *)hashId {
    if (GJCFStringIsNull(hashId)) {
        return 0;
    }
    NSDictionary *dic = [[self getDatasFromTableName:MessageExtenTable conditions:@{@"hashid": hashId} fields:@[@"pay_count"]] lastObject];
    if (!dic) {
        return 0;
    } else {
        return [[dic safeObjectForKey:@"pay_count"] intValue];
    }
}

- (NSString *)getMessageId:(NSString *)hashId {
    if (GJCFStringIsNull(hashId)) {
        return nil;
    }
    NSDictionary *dic = [[self getDatasFromTableName:MessageExtenTable conditions:@{@"hashid": hashId} fields:@[@"message_id"]] lastObject];
    if (!dic) {
        return nil;
    } else {
        return [dic safeObjectForKey:@"message_id"];
    }

}

@end
