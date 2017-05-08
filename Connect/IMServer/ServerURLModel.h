//
//  ServerURLModel.h
//  Connect
//
//  Created by MoHuilin on 2016/12/15.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>

// 服务器地址类
@interface ServerURLModel : NSObject <NSCoding>

@property(strong, nonatomic) NSString *server; //IP + port

@property(strong, nonatomic) NSString *ip;
@property(assign, nonatomic) int port;

@property(assign, nonatomic) UInt32 loadFactor;
@property(assign, nonatomic) UInt32 connectCount;
@property(assign, nonatomic) UInt32 delay;

- (instancetype)init;

@end
