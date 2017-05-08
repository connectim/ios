//
//  LMSocketConnection.h
//  Connect
//
//  Created by MoHuilin on 2017/2/6.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "Message.h"

@protocol LMSocketConnectionDelegate <NSObject>

- (void)socket:(GCDAsyncSocket *)socket didReadData:(NSData *)data message:(Message *)message;

- (void)socket:(GCDAsyncSocket *)socket didConnect:(NSString *)host port:(uint16_t)port;

- (void)socketDidDisconnect:(GCDAsyncSocket *)socket withError:(NSError *)err;

- (void)socketDidDisconnectByIllegalData;

@end

@interface LMSocketConnection : NSObject

+ (instancetype)sharedInstance;

/**
 * stop imserver
 */
- (void)stopIMServer;

/**
 * start connect to server
 * @param host
 * @param port
 */
- (void)startIMServerWithHost:(NSString *)host port:(int)port;

/**
 * start connect to default server
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


@property(weak, nonatomic) id <LMSocketConnectionDelegate> delegate;
@property(strong, nonatomic) dispatch_queue_t receiveQueue;
@property(strong, nonatomic) dispatch_queue_t socketQueue;

@end
