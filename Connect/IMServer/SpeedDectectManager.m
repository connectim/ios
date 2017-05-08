//
//  SpeedDectectManager.m
//  Connect
//
//  Created by MoHuilin on 2016/12/15.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import "SpeedDectectManager.h"
#import "NetWorkOperationTool.h"
#import "Protofile.pbobjc.h"
#import "GBPing.h"
#import "ConnectTool.h"


#define ServiceListsCacheKey @"ServiceListsCacheKey"
#define ServiceListsStampKey @"ServiceListsStampKey"
#define FasterServiceCacheKey @"FasterServiceCacheKey"
#define FasterServiceStampKey @"FasterServiceStampKey"

@interface SpeedDectectManager () <GBPingDelegate>

@property(strong, nonatomic) NSMutableArray *pingArray;
@property(strong, nonatomic) dispatch_queue_t socketQueue;
@property(assign, nonatomic) UInt32 seq;
@property(strong, nonatomic) NSArray *serverModels;
@property(strong, nonatomic) serverURL completion;

@end

@implementation SpeedDectectManager

static SpeedDectectManager *instance = nil;

+ (SpeedDectectManager *)instance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SpeedDectectManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.seq = 1000;
    }
    return self;
}

- (dispatch_queue_t)socketQueue {
    if (_socketQueue == nil) {
        _socketQueue = dispatch_queue_create("com.speedSocket", DISPATCH_QUEUE_CONCURRENT);
    }
    return _socketQueue;
}

- (UInt32)seq {
    _seq = _seq + 1;
    return _seq;
}

- (NSMutableArray *)socketArray {
    if (_pingArray == nil) {
        _pingArray = [[NSMutableArray alloc] init];
    }
    return _pingArray;
}

- (void)startDectect:(serverURL)complete {
    NSData *obj = [[NSUserDefaults standardUserDefaults] objectForKey:FasterServiceCacheKey];
    NSDate *date = [[NSUserDefaults standardUserDefaults] objectForKey:FasterServiceStampKey];
    NSDate *curDate = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval seconds = 10000;

    if (date != nil && curDate != nil) {
        seconds = ABS([date timeIntervalSinceDate:curDate]);
    }
    if (obj != nil && date != nil && seconds < 5) {
        ServerURLModel *m = [NSKeyedUnarchiver unarchiveObjectWithData:obj];
        complete(m, nil);
        return;
    }
    __weak typeof(self) ws = self;
    self.completion = complete;
    [ws requestServiceListsWithCache:^(NSArray *response, NSString *error) {
        ws.serverModels = response;
        for (ServerURLModel *m in response) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                GBPing *ping = [[GBPing alloc] init];
                ping.host = m.ip;
                ping.delegate = ws;
                ping.timeout = 1.0;
                ping.pingPeriod = 0.9;

                [ping setupWithBlock:^(BOOL success, NSError *error) { //necessary to resolve hostname
                    if (success) {
                        //start pinging
                        [ping startPinging];
                        //stop it after 1 seconds
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            NSLog(@"stop it");
                            [ping stop];
                            [ws calculate:ws.serverModels];
                            [ws.pingArray removeObject:ping];
                        });
                    } else {
                        NSLog(@"failed to start");
                    }
                }];
                [ws.pingArray objectAddObject:ping];
            });
        }
    }];
}


- (void)ping:(GBPing *)pinger didReceiveReplyWithSummary:(GBPingSummary *)summary {
    NSLog(@"REPLY>  %@", summary);
    for (ServerURLModel *m in self.serverModels) {
        if ([m.server isEqualToString:pinger.host]) {
            m.delay = summary.rtt * 1000;
            break;
        }
    }
}

- (void)ping:(GBPing *)pinger didSendPingWithSummary:(GBPingSummary *)summary {
    NSLog(@"SENT>   %@", summary);
}

- (void)ping:(GBPing *)pinger didTimeoutWithSummary:(GBPingSummary *)summary {
    NSLog(@"TIMOUT> %@", summary);
    for (ServerURLModel *m in self.serverModels) {
        if ([m.server isEqualToString:pinger.host]) {
            m.delay = 60 * 60;
            break;
        }
    }
}

- (void)ping:(GBPing *)pinger didFailWithError:(NSError *)error {
    NSLog(@"FAIL>   %@", error);
    for (ServerURLModel *m in self.serverModels) {
        if ([m.server isEqualToString:pinger.host]) {
            m.delay = 60 * 60;
            break;
        }
    }
}

- (void)ping:(GBPing *)pinger didFailToSendPingWithSummary:(GBPingSummary *)summary error:(NSError *)error {
    NSLog(@"FSENT>  %@, %@", summary, error);
    for (ServerURLModel *m in self.serverModels) {
        if ([m.server isEqualToString:pinger.host]) {
            m.delay = 60 * 60;
            break;
        }
    }
}

- (void)calculate:(NSArray *)array {
    NSArray *sorted = [array sortedArrayUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
        ServerURLModel *m1 = obj1;
        ServerURLModel *m2 = obj2;
        if (m1.delay > m2.delay) {
            return NSOrderedDescending;
        } else {
            return NSOrderedAscending;
        }
    }];
    NSMutableArray *valuableArray = [[NSMutableArray alloc] init];
    for (ServerURLModel *m in sorted) {
        if (m.delay != 60 * 60) {      //
            [valuableArray objectAddObject:m];
        }
    }
    if (valuableArray.count == 0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.completion(nil, @"no servers");
        });
        return;
    }

    ServerURLModel *avaibleServer = [valuableArray firstObject];

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:avaibleServer];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:FasterServiceCacheKey];
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate dateWithTimeIntervalSinceNow:0] forKey:FasterServiceStampKey];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        DDLogInfo(@"user %@", avaibleServer.ip);
        self.completion(avaibleServer, nil);
    });

}

- (void)requestServiceListsWithCache:(serverURLs)complete {
    NSData *obj = [[NSUserDefaults standardUserDefaults] objectForKey:ServiceListsCacheKey];
    NSDate *date = [[NSUserDefaults standardUserDefaults] objectForKey:ServiceListsStampKey];
    NSDate *curDate = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval seconds = 24 * 60 * 60;

    if (date != nil && curDate != nil) {
        seconds = ABS([date timeIntervalSinceDate:curDate]);
    }
    if (obj == nil || date == nil || seconds > 24 * 3600) {
        [self requestServiceLists:^(NSArray *response, NSString *error) {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:response];
            [[NSUserDefaults standardUserDefaults] setObject:data forKey:ServiceListsCacheKey];
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate dateWithTimeIntervalSinceNow:0] forKey:ServiceListsStampKey];
            complete(response, nil);
        }];
    } else {
        NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:obj];
        complete(array, nil);
    }
}

- (void)requestServiceLists:(serverURLs)complete {
    ServerURLModel *defaultModel = [[ServerURLModel alloc] init];
    defaultModel.server = [NSString stringWithFormat:@"%@:%d", SOCKET_HOST, SOCKET_PORT];
    defaultModel.ip = SOCKET_HOST;
    defaultModel.port = SOCKET_PORT;

    [NetWorkOperationTool POSTWithUrlString:availableServersUrl postProtoData:nil NotSignComplete:^(id response) {
        HttpNotSignResponse *hResponse = (HttpNotSignResponse *) response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(@[defaultModel], nil);
            }
        } else {
            AvailableServersResponse *availableServers = [AvailableServersResponse parseFromData:hResponse.body error:nil];
            if ([ConnectTool vertifyWithData:availableServers.server.data sign:availableServers.sign]) {
                NSString *server = availableServers.server.server;
                NSArray *temA = [server componentsSeparatedByString:@":"];
                defaultModel.server = server;
                if (temA.count == 2) {
                    defaultModel.ip = [temA firstObject];
                    defaultModel.port = [[temA lastObject] intValue];
                }
            }
            if (complete) {
                complete(@[defaultModel], nil);
            }
        }
    }                                  fail:^(NSError *error) {
        if (complete) {
            complete(@[defaultModel], nil);
        }
    }];
}

@end

