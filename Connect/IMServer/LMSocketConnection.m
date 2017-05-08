//
//  LMSocketConnection.m
//  Connect
//
//  Created by MoHuilin on 2017/2/6.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMSocketConnection.h"
#import "StreamParser.h"
#import "LMHistoryCacheManager.h"

@interface LMSocketConnection () <GCDAsyncSocketDelegate,
        ParserDelegate>

@property(strong, nonatomic) GCDAsyncSocket *socket;
@property(strong, nonatomic) NSString *host;
@property(assign, nonatomic) UInt16 port;
@property(assign, nonatomic) BOOL isConnecting;

@property(nonatomic, strong) StreamParser *parser;
@property(nonatomic, assign) int connectFailureCount;
@property(nonatomic, assign) int closeByRemoteServerCount;

@end

@implementation LMSocketConnection

CREATE_SHARED_INSTANCE(LMSocketConnection)

- (instancetype)init {
    self = [super init];
    if (self) {
        self.parser = [[StreamParser alloc] initWithDelegate:self delegateQueue:self.receiveQueue];
        self.isConnecting = false;
    }
    return self;
}


- (void)resetSocket {
    [self disConnect];

    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.socketQueue];
    self.socket.IPv6Enabled = true;
    self.socket.IPv4Enabled = true;
    self.socket.IPv4PreferredOverIPv6 = false;
}


- (void)disConnect {
    self.socket.delegate = nil;
    [self.socket disconnect];
    self.socket.delegate = self;
    self.socket = nil;
    self.socketQueue = nil;
    self.receiveQueue = nil;
}

- (void)reconnect {
    if (self.host && !self.isConnecting) {
        _connectFailureCount++;
        if (_connectFailureCount >= 50) {
            return;
        }
        int sleepInterval = 1;
        if (_connectFailureCount > 6) {
            sleepInterval = [self getReconnectTimeByConnectFailTime:_connectFailureCount - 6];
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (sleepInterval * NSEC_PER_SEC)), self.socketQueue, ^{
            [self startIMServerWithHost:self.host port:self.port];
        });
    }
}

- (void)startIMServerWithHost:(NSString *)host port:(int)port {
    //ipv6
    [self convertHostToAddress:host callBackBlock:^(NSString *hostIp) {
        self.host = hostIp;
        self.port = port;
        [self resetSocket];
        NSError *error = nil;
        self.isConnecting = true;
        [self.socket connectToHost:self.host onPort:self.port withTimeout:SOCKET_TIME_OUT error:&error];
        if (error != nil) {
            NSLog(@"connect error：%@", error);
        }
    }];
}

- (void)startIMServerWithDefaultHost {
    [self startIMServerWithHost:SOCKET_HOST port:SOCKET_PORT];
}

- (void)stopIMServer {
    [self disConnect];
    _connectFailureCount = 0;
    self.isConnecting = NO;
}


- (void)sendData:(NSData *)data {
    dispatch_async(self.socketQueue, ^{
        [self.socket readDataWithTimeout:SOCKET_READ_TIME_OUT tag:100];
        [self.socket writeData:data withTimeout:SOCKET_TIME_OUT tag:100];
    });
}


#pragma mark - parse data

- (void)parserDidReadStanza:(Message *)msg thisData:(NSData *)data {
    NSLog(@"parse data message:%@", msg);
    if (self.delegate && [self.delegate respondsToSelector:@selector(socket:didReadData:message:)]) {
        [self.delegate socket:self.socket didReadData:data message:msg];
    }
    [self.socket readDataWithTimeout:SOCKET_READ_TIME_OUT tag:100];
}

- (void)IllegalData {
    NSLog(@"illegal data");
    if (self.delegate && [self.delegate respondsToSelector:@selector(socketDidDisconnectByIllegalData)]) {
        [self.delegate socketDidDisconnectByIllegalData];
    }
}


#pragma mark - socket delegata

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"socket connect");
    _connectFailureCount = 0;
    dispatch_async(self.receiveQueue, ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(socket:didConnect:port:)]) {
            [self.delegate socket:sock didConnect:host port:port];
        }
        if (_isConnecting == true) {
            _isConnecting = false;
        }
        [self.socket readDataWithTimeout:SOCKET_READ_TIME_OUT tag:100];
    });
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"socket disconnect err:%@", err);
    switch (err.code) {
        case GCDAsyncSocketReadTimeoutError:
        case GCDAsyncSocketWriteTimeoutError:
        case GCDAsyncSocketReadMaxedOutError:
        case GCDAsyncSocketClosedError:
        case 57: //In the WiFi switch to the mobile phone network, it may be reported 57 of the connection error code, direct trigger reconnection
            [self.parser revert];
            if (_isConnecting == true) {
                _isConnecting = false;
            }
            if (err.code == GCDAsyncSocketClosedError) {
                self.closeByRemoteServerCount++;
            }
            if (self.closeByRemoteServerCount > 5) {
                self.closeByRemoteServerCount = 0;
                dispatch_async(self.receiveQueue, ^{
                    if (self.delegate && [self.delegate respondsToSelector:@selector(socketDidDisconnect:withError:)]) {
                        [self.delegate socketDidDisconnect:sock withError:err];
                    }
                    self.socket = nil;
                });
            } else {
                [self startIMServerWithHost:self.host port:self.port];
            }
            break;
        default: {
            if (_isConnecting == true) {
                _isConnecting = false;
            }
            dispatch_async(self.receiveQueue, ^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(socketDidDisconnect:withError:)]) {
                    [self.delegate socketDidDisconnect:sock withError:err];
                }
                self.socket = nil;
            });
        }
            break;
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSLog(@"read data success");
    dispatch_async(self.receiveQueue, ^{
        [self.parser parseData:data];
        [self.socket readDataWithTimeout:SOCKET_READ_TIME_OUT tag:100];
    });
    _connectFailureCount = 0;
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"write data success");
    [self.socket readDataWithTimeout:SOCKET_READ_TIME_OUT tag:100];
}


#pragma mark - get set

- (dispatch_queue_t)socketQueue {
    if (_socketQueue == nil) {
        _socketQueue = dispatch_queue_create("com.sendSocket", DISPATCH_QUEUE_SERIAL);
    }
    return _socketQueue;
}

- (dispatch_queue_t)receiveQueue {
    if (_receiveQueue == nil) {
        _receiveQueue = dispatch_queue_create("com.receiveSocket", DISPATCH_QUEUE_SERIAL);
    }
    return _receiveQueue;
}

/**
 * dns parse
 * @param host
 * @param callBackBlock
 */
- (void)convertHostToAddress:(NSString *)host
               callBackBlock:(void (^)(NSString *host))callBackBlock {
    [GCDQueue executeInQueue:self.socketQueue block:^{
        NSError *err = nil;
        NSMutableArray *addresses = [GCDAsyncSocket lookupHost:host port:0 error:&err];
        NSLog(@"address%@", addresses);
        NSData *address4 = nil;
        NSData *address6 = nil;
        for (NSData *address in addresses) {
            if (!address4 && [GCDAsyncSocket isIPv4Address:address]) {
                address4 = address;
            } else if (!address6 && [GCDAsyncSocket isIPv6Address:address]) {
                address6 = address;
            }
        }
        NSString *ip;
        if (address6) {
            ip = [GCDAsyncSocket hostFromAddress:address6];
        } else {
            ip = [GCDAsyncSocket hostFromAddress:address4];
        }

        if (GJCFStringIsNull(ip)) {
            ip = [[LMHistoryCacheManager sharedManager] getSocketIPCache];
        } else {
            [[LMHistoryCacheManager sharedManager] cacheIP:ip];
        }

        if (callBackBlock) {
            callBackBlock(ip);
        }
    }];
}

/**
 * reconnect time
 * @param failTime
 * @return
 */
- (int)getReconnectTimeByConnectFailTime:(int)failTime {
    if (failTime == 0) {
        return 0;
    }
    if (failTime == 1) {
        return 1;
    }

    return [self getReconnectTimeByConnectFailTime:failTime - 1] + [self getReconnectTimeByConnectFailTime:failTime - 2];
}

@end
