//
//  CommandOutTimeTool.m
//  Connect
//
//  Created by MoHuilin on 16/8/22.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "CommandOutTimeTool.h"

@interface CommandOutTimeTool ()

@property(nonatomic, strong) NSMutableDictionary *concurrentMsgDict;
@property(nonatomic, assign) BOOL isSupspend;
@property(nonatomic, strong) dispatch_queue_t sendConcurrentQueue;
@property(nonatomic, strong) dispatch_source_t reflashSendStatusSource;
@property(nonatomic, assign) BOOL reflashSendStatusSourceActive;

@end


static CommandOutTimeTool *manager = nil;

@implementation CommandOutTimeTool

+ (CommandOutTimeTool *)sharedManager {
    @synchronized (self) {
        if (manager == nil) {
            manager = [[[self class] alloc] init];
        }
    }
    return manager;
}


- (void)revert {
    [self.concurrentMsgDict removeAllObjects];
    [self.concurrentMsgCompleteBlockDict removeAllObjects];
    [self suspend];
}

- (void)resume {
    if (self.isSupspend) {
        self.isSupspend = NO;
        dispatch_resume(self.sendConcurrentQueue);
    }
}

- (void)suspend {
    if (!self.isSupspend) {
        self.isSupspend = YES;
        dispatch_suspend(self.sendConcurrentQueue);
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


- (instancetype)init {
    if (self = [super init]) {
        self.concurrentMsgDict = [NSMutableDictionary dictionary];
        self.concurrentMsgCompleteBlockDict = [NSMutableDictionary dictionary];
        if (!self.sendConcurrentQueue) {
            self.sendConcurrentQueue = dispatch_queue_create("_commond_send_handle_queue", DISPATCH_QUEUE_CONCURRENT);
        }
        dispatch_queue_t globalQueue = dispatch_get_global_queue(0, 0);
        __weak __typeof(&*self) weakSelf = self;
        if (!self.reflashSendStatusSource) {
            self.reflashSendStatusSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, globalQueue);
            dispatch_source_set_timer(_reflashSendStatusSource, dispatch_walltime(NULL, 0), 3 * NSEC_PER_SEC, 0);
            dispatch_source_set_event_handler(_reflashSendStatusSource, ^{
                if (weakSelf.concurrentMsgDict.allKeys.count <= 0) {
                    DDLogInfo(@"Send all command");
                    dispatch_suspend(_reflashSendStatusSource);
                    weakSelf.reflashSendStatusSourceActive = NO;
                }
                [weakSelf checkTimeOutMessage];
            });

            dispatch_resume(self.reflashSendStatusSource);
            self.reflashSendStatusSourceActive = YES;
        }
    }

    return self;
}

- (void)addToSendConcurrentQueue:(Message *)msg complete:(CompleteBlock)complete {

    CommandCallbackModel *callBack = [[CommandCallbackModel alloc] init];
    callBack.completeBlock = complete;
    [self.concurrentMsgCompleteBlockDict setObject:callBack forKey:msg.msgIdentifer];
    [self.concurrentMsgDict setObject:msg forKey:msg.msgIdentifer];
    if (!self.reflashSendStatusSourceActive) {
        dispatch_resume(self.reflashSendStatusSource);
        self.reflashSendStatusSourceActive = YES;
    }
}

- (void)removeSuccessMessage:(Message *)msg {
    if (!msg) {
        return;
    }
    [self.concurrentMsgDict removeObjectForKey:msg.msgIdentifer];
}

- (void)checkTimeOutMessage {
    for (NSString *identifier in self.concurrentMsgDict.allKeys) {
        Message *msg = [self.concurrentMsgDict valueForKey:identifier];
        DDLogInfo(@"msg id:%@ type:%d exetension:%d", msg.msgIdentifer, msg.typechar, msg.extension);
        int long long sendTime = [[msg.msgIdentifer substringToIndex:10] integerValue];
        int long long currentTime = [[NSDate date] timeIntervalSince1970];
        int long long time = currentTime - sendTime;
        if (time > 20 && time < 30) {
            CommandCallbackModel *callBack = (CommandCallbackModel *) [self.concurrentMsgCompleteBlockDict objectForKey:msg.msgIdentifer];
            if (callBack.completeBlock) {
                callBack.completeBlock([NSError errorWithDomain:@"out time" code:-1 userInfo:nil], nil);
            }
            [self.concurrentMsgCompleteBlockDict removeObjectForKey:msg.msgIdentifer];
            [self.concurrentMsgDict removeObjectForKey:identifier];
        } else if (time > 60 * 60 * 24) {
            [self.concurrentMsgDict removeObjectForKey:identifier];
        }
    }
}


- (Message *)getMessageByIdentifer:(NSString *)identifer {
    if (GJCFStringIsNull(identifer)) {
        return nil;
    }
    return [self.concurrentMsgDict valueForKey:identifer];
}


@end


@implementation CommandCallbackModel

@end

