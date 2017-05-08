//
//  ServerURLModel.m
//  Connect
//
//  Created by MoHuilin on 2016/12/15.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import "ServerURLModel.h"

@implementation ServerURLModel

- (instancetype)init {
    if (self = [super init]) {
        self.ip = nil;
        self.loadFactor = 10000000;
        self.delay = 10000000;
        self.connectCount = 10000000;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.ip forKey:@"ip"];
    [aCoder encodeObject:self.server forKey:@"server"];
    [aCoder encodeObject:@(self.port) forKey:@"port"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.ip = [aDecoder decodeObjectForKey:@"ip"];
        self.server = [aDecoder decodeObjectForKey:@"server"];
        self.port = [[aDecoder decodeObjectForKey:@"port"] integerValue];
    }
    return self;
}

@end
