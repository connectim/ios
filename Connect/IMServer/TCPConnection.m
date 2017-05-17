//
//  TCPConnection.m
//  podcasting
//
//  Created by houxh on 15/6/25.
//  Copyright (c) 2015年 beetle. All rights reserved.
//

#import "TCPConnection.h"
#import "LMSocketConnection.h"
#import "AFNetworkReachabilityManager.h"

@interface TCPConnection () <LMSocketConnectionDelegate>

@property(nonatomic, strong) dispatch_source_t connectTimer;
@property(nonatomic, strong) dispatch_source_t heartbeatTimer;
@property(nonatomic, assign) int heartbeatHZ;
@property(nonatomic, assign) BOOL suspended;
@property(nonatomic, assign) BOOL isBackground;
@property(nonatomic) time_t pingTimestamp;
@property(nonatomic) int connectFailCount;
@property(nonatomic) NSHashTable *connectionObservers;

@end


@implementation TCPConnection
- (id)init {
    self = [super init];
    if (self) {
        dispatch_queue_t queue = dispatch_get_main_queue();
        self.connectTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        dispatch_source_set_event_handler(self.connectTimer, ^{
            [self connect];
        });
        self.heartbeatTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        dispatch_source_set_event_handler(self.heartbeatTimer, ^{
            [self ping];
        });
        self.connectionObservers = [NSHashTable weakObjectsHashTable];
        self.connectState = STATE_UNCONNECTED;
        self.suspended = YES;
        self.isBackground = NO;
        self.heartbeatHZ = 9;
        //socket代理
        [LMSocketConnection sharedInstance].delegate = self;
    }
    return self;
}

- (void)dealloc {
    if (self.heartbeatTimer) {
        dispatch_source_cancel(self.heartbeatTimer);
        self.heartbeatTimer = nil;
    }
    if (self.connectTimer) {
        dispatch_source_cancel(self.connectTimer);
        self.connectTimer = nil;
    }
    [LMSocketConnection sharedInstance].delegate = nil;
    RemoveNofify;

    AFNetworkReachabilityManager *reachabilityManager = [AFNetworkReachabilityManager sharedManager];
    [reachabilityManager stopMonitoring];
}

- (void)startRechabilityNotifier {
    TCPConnection *wself = self;
    AFNetworkReachabilityManager *reachabilityManager = [AFNetworkReachabilityManager sharedManager];
    [reachabilityManager startMonitoring];
    [reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
            case AFNetworkReachabilityStatusNotReachable: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    wself.reachable = NO;
                    if (wself != nil) {
                        [wself suspend];
                    }
                });
            }
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
            case AFNetworkReachabilityStatusReachableViaWiFi: {
                NSLog(@"net work status %ld", (long) status);
                dispatch_async(dispatch_get_main_queue(), ^{
                    wself.reachable = YES;
                    if (!wself.isBackground) {
                        [wself resume];
                    }
                });
            }
                break;
            default:
                break;
        }
    }];
}

- (void)enterForeground {
    DDLogInfo(@"im service enter foreground");
    self.isBackground = NO;
    if (self.reachable) {
        [self resume];
    }
}

- (void)enterBackground {
    DDLogInfo(@"im service enter background");
    self.isBackground = YES;
    [self suspend];
}

- (void)start {
    [self resume];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];

    RegisterNotify(UIApplicationDidEnterBackgroundNotification, @selector(enterBackground));
    RegisterNotify(UIApplicationWillEnterForegroundNotification, @selector(enterForeground));

    [self startRechabilityNotifier];
}

- (void)quitUser {

    [self suspend];
    [self onClose];

    [self close];

    AFNetworkReachabilityManager *reachabilityManager = [AFNetworkReachabilityManager sharedManager];
    [reachabilityManager stopMonitoring];

    self.connectState = STATE_UNCONNECTED;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}


- (void)suspend {
    if (self.suspended) {
        return;
    }
    self.suspended = YES;
    dispatch_suspend(self.connectTimer);
    dispatch_suspend(self.heartbeatTimer);
    [self onClose];
    [self close];
}

- (void)resume {
    if (!self.suspended) {
        return;
    }
    self.suspended = NO;

    dispatch_time_t w = dispatch_walltime(NULL, 0);
    dispatch_source_set_timer(self.connectTimer, w, DISPATCH_TIME_FOREVER, 0);
    dispatch_resume(self.connectTimer);

    w = dispatch_walltime(NULL, self.heartbeatHZ);
    dispatch_source_set_timer(self.heartbeatTimer, w, self.heartbeatHZ * NSEC_PER_SEC, self.heartbeatHZ * NSEC_PER_SEC / 2);
    dispatch_resume(self.heartbeatTimer);
}

- (void)close {

    self.connectState = STATE_UNCONNECTED;
    [GCDQueue executeInMainQueue:^{
        [self publishConnectState:self.connectState];
    }];

    [[LMSocketConnection sharedInstance] stopIMServer];
}

- (BOOL)handleData:(NSData *)data message:(Message *)message {
    NSAssert(NO, @"not implmented");
    return NO;
}

- (void)write:(NSData *)data {
    [[LMSocketConnection sharedInstance] sendData:data];
}


- (void)connect {
    if (self.connectState == STATE_CONNECTED || self.connectState == STATE_AUTHING || self.connectState == STATE_GETOFFLINE) {
        return;
    }
    self.connectState = STATE_CONNECTING;
    [GCDQueue executeInMainQueue:^{
        [self publishConnectState:self.connectState];
    }];
    [self connecting];
    [[LMSocketConnection sharedInstance] startIMServerWithDefaultHost];
}

#pragma mark -LMSocketConnectionDelegate

- (void)socket:(GCDAsyncSocket *)socket didConnect:(NSString *)host port:(uint16_t)port {
    self.connectFailCount = 0;
    [self onConnect];
}

- (void)socketDidDisconnectByIllegalData {
    [GCDQueue executeInMainQueue:^{
        SendNotify(SocketDataVerifyIllegalityNotification, nil);
    }];
}

- (void)socket:(GCDAsyncSocket *)socket didReadData:(NSData *)data message:(Message *)message {
    [self handleData:data message:message];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)socket withError:(NSError *)err {
    self.connectState = STATE_UNCONNECTED;
    [self publishConnectState:self.connectState];
}

#pragma mark -recive server heart ack

- (void)pong {
    self.pingTimestamp = 0;
}

#pragma mark -send ping

- (BOOL)sendPing {
    NSAssert(NO, @"not implemented");
    return NO;
}

- (void)ping {
    if (![self sendPing]) {
        return;
    }
    if (self.pingTimestamp == 0) {

        self.pingTimestamp = time(NULL);

        dispatch_time_t checkTime = dispatch_time(DISPATCH_TIME_NOW, self.heartbeatHZ * NSEC_PER_SEC);
        dispatch_after(checkTime, dispatch_get_main_queue(), ^{
            time_t now = time(NULL);
            //heart beat overtime
            if (self.pingTimestamp > 0 && now - self.pingTimestamp >= self.heartbeatHZ) {
                if (self.connectState != STATE_CONNECTED || self.connectState != STATE_AUTHING || self.connectState != STATE_GETOFFLINE) {
                    self.pingTimestamp = 0;
                    [[LMSocketConnection sharedInstance] reconnect];
                }
            }
        });
    }
}

- (void)onConnect {

}

- (void)onClose {

}

- (void)connecting {

}

- (void)addConnectionObserver:(id <TCPConnectionObserver>)ob {
    [self.connectionObservers addObject:ob];
    [self publishConnectState:self.connectState];
}

- (void)removeConnectionObserver:(id <TCPConnectionObserver>)ob {
    [self.connectionObservers removeObject:ob];
}

- (void)publishConnectState:(int)state {
    self.connectState = state;
    [GCDQueue executeInMainQueue:^{
        for (id <TCPConnectionObserver> ob in self.connectionObservers) {
            if ([ob respondsToSelector:@selector(onConnectState:)]) {
                [ob onConnectState:state];
            }
        }
    }];
}

@end
