//
//  BadgeNumber.m
//  Connect
//
//  Created by MoHuilin on 16/9/21.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BadgeNumber.h"

@implementation BadgeNumber

- (NSString *)description
{
    return [NSString stringWithFormat:@"{ type = %lu , count = %lu , displayMode = %lu }",self.type,self.count,self.displayMode];
}



- (instancetype)init
{
    self = [super init];
    if (self) {
        self.displayMode = ALDisplayMode_Dot;
    }
    return self;
}


@end
