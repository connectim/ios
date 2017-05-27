//
//  TCPConnection.h
//  podcasting
//
//  Created by houxh on 15/6/25.
//  Copyright (c) 2015年 beetle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.h"

#define STATE_UNCONNECTED 0
#define STATE_CONNECTING 1
#define STATE_CONNECTED 2
#define STATE_AUTHING 3
#define STATE_GETOFFLINE 4
#define STATE_CONNECTFAIL 5

@protocol TCPConnectionObserver <NSObject>
@optional

/**
 * connect state change
 * @param state
 */
- (void)onConnectState:(int)state;

@end

@interface TCPConnection : NSObject
//public
@property(nonatomic, assign) int connectState;
@property(nonatomic) BOOL reachable;

//subclass override
- (BOOL)sendPing;

- (BOOL)handleData:(NSData *)data message:(Message *)message;

- (void)onConnect;

- (void)onClose;

- (void)connecting;

//public method
- (void)write:(NSData *)data;

/**
 * start imserver
 */
- (void)start;

/**
 * heartbeat ack
 */
- (void)pong;

/**
 * imserver close
 */
- (void)close;

/**
 * user quit
 */
- (void)quitUser; //用户退出

/**
 * enterForeground
 */
- (void)enterForeground;

/**
 * enterBackground
 */
- (void)enterBackground;

/**
 * add Connectionstatue Observer
 * @param ob
 */
- (void)addConnectionObserver:(id <TCPConnectionObserver>)ob;

/**
 * remove Connection Observer
 * @param ob
 */
- (void)removeConnectionObserver:(id <TCPConnectionObserver>)ob;

/**
 * startRechabilityNotifier
 */
- (void)startRechabilityNotifier;

/**
 * publish Connect State
 * @param state
 */
- (void)publishConnectState:(int)state;
@end
