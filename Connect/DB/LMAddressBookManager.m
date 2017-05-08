//
//  LMAddressBookManager.m
//  Connect
//
//  Created by Connect on 2017/4/13.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMAddressBookManager.h"

static LMAddressBookManager *manager = nil;

@implementation LMAddressBookManager
+ (LMAddressBookManager *)sharedManager {
    @synchronized (self) {
        if (manager == nil) {
            manager = [[[self class] alloc] init];
        }

        return manager;
    }
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

- (void)saveAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return;
    }
    long long int time = [[NSDate date] timeIntervalSince1970] * 1000;
    NSMutableDictionary *fieldsValues = @{@"address": address}.mutableCopy;
    [fieldsValues safeSetObject:@"" forKey:@"tag"];
    [fieldsValues safeSetObject:@(time) forKey:@"create_time"];
    [self saveToCuttrentDBTableName:AddressBookTable fieldsValues:fieldsValues];
}

- (void)saveBitchAddressBook:(NSArray *)addressBooks {
    if (addressBooks.count <= 0) {
        return;
    }
    NSMutableArray *bitchValues = [NSMutableArray array];
    for (AddressBookInfo *addressBook in addressBooks) {
        if (GJCFStringIsNull(addressBook.address)) {
            continue;
        }
        long long int time = [[NSDate date] timeIntervalSince1970] * 1000;
        [bitchValues addObject:@[addressBook.address, addressBook.tag == nil ? @"" : addressBook.tag, @(time)]];
    }
    [self batchInsertTableName:AddressBookTable fields:@[@"address", @"tag", @"create_time"] batchValues:bitchValues];

}

- (NSArray *)getAllAddressBooks {
    NSArray *temA = [self getAllDatasFromTableName:AddressBookTable fields:@[@"address", @"tag"]];

    NSMutableArray *temM = @[].mutableCopy;
    for (NSDictionary *temD in temA) {
        AddressBookInfo *info = [[AddressBookInfo alloc] init];
        info.address = [temD safeObjectForKey:@"address"];
        info.tag = [temD safeObjectForKey:@"tag"];
        [temM objectAddObject:info];
    }
    return temM;
}

- (void)updateAddressTag:(NSString *)tag address:(NSString *)address {
    if (GJCFStringIsNull(tag) || GJCFStringIsNull(address)) {
        return;
    }
    [self updateTableName:AddressBookTable fieldsValues:@{@"tag": tag} conditions:@{@"address": address}];
}

- (void)deleteAddressBookWithAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return;
    }
    [self deleteTableName:AddressBookTable conditions:@{@"address": address}];
}

- (void)clearAllAddress{
   BOOL result = [self deleteTableName:AddressBookTable conditions:nil];
    if (result) {
        DDLogInfo(@"delete success");
    }
}

@end
