//
//  SocketManager.h
//  Connect
//
//  Created by MoHuilin on 2016/12/15.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "Message.h"

@protocol SocketManagerDelegate <NSObject>

- (void)socket:(GCDAsyncSocket *)socket didReadData:(NSData *)data message:(Message *)message;

- (void)socket:(GCDAsyncSocket *)socket didConnect:(NSString *)host port:(uint16_t)port;

- (void)socketDidDisconnect:(GCDAsyncSocket *)socket withError:(NSError *)err;

- (void)socketDidDisconnectByIllegalData;

@end

@interface SocketManager : NSObject

@property(strong, nonatomic) dispatch_queue_t receiveQueue;
@property(strong, nonatomic) dispatch_queue_t socketQueue;
@property(assign, nonatomic) BOOL isAutomatic;//load balance
@property(weak, nonatomic) id <SocketManagerDelegate> delegate;

+ (instancetype)sharedInstance;

/**
 * Automatically find the best server and connect
 * @param completion
 */
- (void)connectAutomatic:(void (^)())completion;

/**
 * connect to server
 * @param host
 * @param port
 */
- (void)startIMServerWithHost:(NSString *)host port:(int)port;

/**
 * disConnect
 */
- (void)disConnect;

/**
 * status
 * @return
 */
- (BOOL)status;

/**
 * stopIMServer
 */
- (void)stopIMServer;

/**
 * connect default host
 */
- (void)startIMServerWithDefaultHost;

/**
 * reconnect
 */
- (void)reconnect;

/**
 * send data
 * @param data
 */
- (void)sendData:(NSData *)data;


@end
