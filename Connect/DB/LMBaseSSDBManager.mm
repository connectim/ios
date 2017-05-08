//
//  LMBaseSSDBManager.m
//  Connect
//
//  Created by MoHuilin on 2017/1/2.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseSSDBManager.h"
#import "ssdb/ssdb.h"


@interface LMBaseSSDBManager ()

@property(nonatomic) SSDB *ssdb;

@end

@implementation LMBaseSSDBManager

+ (LMBaseSSDBManager *)open:(NSString *)path {
    if ([path characterAtIndex:0] != '/') {
        path = [NSString stringWithFormat:@"Documents/%@", path];
        path = [NSHomeDirectory() stringByAppendingPathComponent:path];
    }
    Options opt;
    opt.compression = "yes";
    LMBaseSSDBManager *ssdbManager = [[LMBaseSSDBManager alloc] init];
    ssdbManager.ssdb = SSDB::open(opt, path.UTF8String);
    if (!ssdbManager.ssdb) {
        return nil;
    }
    return ssdbManager;
}

+ (LMBaseSSDBManager *)openSystemSSDB {
    NSString *path = [NSString stringWithFormat:@"Documents/system_message"];
    path = [NSHomeDirectory() stringByAppendingPathComponent:path];
    Options opt;
    opt.compression = "yes";
    LMBaseSSDBManager *ssdbManager = [[LMBaseSSDBManager alloc] init];
    ssdbManager.ssdb = SSDB::open(opt, path.UTF8String);
    if (!ssdbManager.ssdb) {
        return nil;
    }
    return ssdbManager;
}


- (void)close {
    delete _ssdb;
}

#pragma mark - KV

- (BOOL)set:(NSString *)key string:(NSString *)string {
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [self set:key data:data];
}

- (BOOL)set:(NSString *)key data:(NSData *)data {
    std::string k(key.UTF8String);
    std::string v((const char *) data.bytes, data.length);
    int ret = _ssdb->set(k, v);
    if (ret == 0) {
        return YES;
    }
    return NO;
}

- (BOOL)get:(NSString *)key string:(NSString **)string {
    NSData *data = nil;
    BOOL ret = [self get:key data:&data];
    if (ret && data != nil) {
        *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return ret;
}

- (BOOL)get:(NSString *)key data:(NSData **)data {
    std::string k(key.UTF8String);
    std::string v;
    int ret = _ssdb->get(k, &v);
    if (ret == 0) {
        *data = nil;
        return YES;
    } else if (ret == 1) {
        *data = [NSData dataWithBytes:(const void *) v.data() length:(NSUInteger) v.size()];
        return YES;
    }
    return NO;
}

- (BOOL)del:(NSString *)key {
    std::string k(key.UTF8String);
    int ret = _ssdb->del(k);
    if (ret == 0) {
        return YES;
    }
    return NO;
}

#pragma mark hashmap

- (BOOL)hsetname:(NSString *)name key:(NSString *)key string:(NSString *)string {
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [self hsetname:name key:key data:data];
}

- (BOOL)hsetname:(NSString *)name key:(NSString *)key data:(NSData *)data {
    std::string n(name.UTF8String);
    std::string k(key.UTF8String);
    std::string v((const char *) data.bytes, data.length);
    int ret = _ssdb->hset(n, k, v);
    if (ret == 0) {
        return YES;
    }
    return NO;
}

- (BOOL)hgetname:(NSString *)name key:(NSString *)key string:(NSString **)string {
    NSData *data = nil;
    BOOL ret = [self hgetname:name key:key data:&data];
    if (ret && data != nil) {
        *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return ret;
}

- (BOOL)hgetname:(NSString *)name key:(NSString *)key data:(NSData **)data {
    std::string n(name.UTF8String);
    std::string k(key.UTF8String);
    std::string v;
    int ret = _ssdb->hget(n, k, &v);
    if (ret == 0) {
        *data = nil;
        return YES;
    } else if (ret == 1) {
        *data = [NSData dataWithBytes:(const void *) v.data() length:(NSUInteger) v.size()];
        return YES;
    }
    return NO;
}

- (NSArray *)hliststartName:(NSString *)sname endName:(NSString *)ename limit:(int)limit {
    std::string sn(sname.UTF8String);
    std::string en(ename.UTF8String);
    std::vector<std::string> vector;

    int ret = _ssdb->hlist(sn, en, limit, &vector);
    if (ret == 0) {
        return nil;
    } else if (ret == 1) {
        int count = (int) vector.size();
        NSMutableArray *resultArry = [NSMutableArray array];
        for (int i = 0; i < count; i++) {
            std::string str = vector[i];
            NSString *ocStr = [[NSString alloc] initWithBytes:(const void *) str.data() length:(NSUInteger) str.size() encoding:NSUTF8StringEncoding];
            [resultArry objectAddObject:ocStr];
        }
        return resultArry;
    }
    return nil;
}


- (BOOL)hdelname:(NSString *)name key:(NSString *)key {
    std::string n(name.UTF8String);
    std::string k(key.UTF8String);
    int ret = _ssdb->hdel(n, k);
    if (ret == 0) {
        return YES;
    }
    return NO;
}

- (int)qsize:(NSString *)name {
    std::string n(name.UTF8String);
    int64_t size = _ssdb->qsize(n);
    return (int) size;
}

- (NSString *)qback:(NSString *)name {
    std::string n(name.UTF8String);
    std::string v;
    int ret = _ssdb->qback(n, &v);

    if (ret == 1) {
        NSString *value = [NSString stringWithCString:v.c_str() encoding:[NSString defaultCStringEncoding]];
        return value;
    }
    return nil;
}

- (NSString *)qfront:(NSString *)name {
    std::string n(name.UTF8String);
    std::string v;
    int ret = _ssdb->qfront(n, &v);

    if (ret == 1) {
        NSString *value = [NSString stringWithCString:v.c_str() encoding:[NSString defaultCStringEncoding]];
        return value;
    }
    return nil;
}

- (BOOL)qpush_back:(NSString *)name values:(NSArray *)values {
    std::string n(name.UTF8String);

    for (int i = 0; i < [values count]; i++) {
        NSString *item = values[i];
        std::string v(item.UTF8String);
        int64_t ret = _ssdb->qpush_back(n, v);
        if (ret == 1) {

        }
    }
    return false;
}

- (int)incr:(NSString *)name {
    std::string n(name.UTF8String);
    int64_t number;
    int ret = _ssdb->incr(n, 1, &number);
    if (ret > 0) {
        return (int) number;
    }
    return nil;
}


@end
