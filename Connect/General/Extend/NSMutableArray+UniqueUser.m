//
//  NSMutableArray+UniqueUser.m
//  Connect
//
//  Created by MoHuilin on 16/9/26.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "NSMutableArray+UniqueUser.h"
#import "Protofile.pbobjc.h"

@implementation NSMutableArray (UniqueUser)

- (void)addObjectUniqueAddress:(id)object{
    if ([object isKindOfClass:[AccountInfo class]]) {
        AccountInfo *user = (AccountInfo *)object;
        for (AccountInfo *temUser in self) {
            if ([temUser.address isEqualToString:user.address]) {
                return;
            }
        }
        [self addObject:user];
    } else if ([object isKindOfClass:[GroupMember class]]) {
        GroupMember *user = (GroupMember *)object;
        for (GroupMember *temUser in self) {
            if ([temUser.address isEqualToString:user.address]) {
                return;
            }
        }
        [self addObject:user];
    }
}

@end
