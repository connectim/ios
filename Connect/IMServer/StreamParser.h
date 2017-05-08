//
//  StreamParser.h
//  Connect
//
//  Created by MoHuilin on 16/8/12.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.h"

@protocol ParserDelegate
@optional

- (void)parserDidReadStanza:(Message *)msg thisData:(NSData *)data;

- (void)parserDidReadThisData:(NSData *)data;

- (void)IllegalData;

@end

@interface StreamParser : NSObject

- (id)initWithDelegate:(id)aDelegate delegateQueue:(id)aDelegateQueue;

- (void)parseData:(NSData *)data;

- (void)handleData:(NSData *)data;

- (void)revert;

@end
