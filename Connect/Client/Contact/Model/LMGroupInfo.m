//
//  LMGroupInfo.m
//  Connect
//
//  Created by MoHuilin on 16/7/27.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMGroupInfo.h"

@implementation LMGroupInfo


- (BOOL)isEqual:(id)object{
    if (object == self) {
        return YES;
    }
    if (![object isKindOfClass:[LMGroupInfo class]]) {
        return NO;
    }
    LMGroupInfo *entity = (LMGroupInfo *)object;
    if ([entity.groupIdentifer isEqualToString:self.groupIdentifer]) {
        return YES;
    }
    else {
        return NO;
    }
}


- (NSString *)summary{
    if (!_summary) {
        _summary = @"";
    }
    
    return _summary;
}

- (AccountInfo *)admin{
    if (!_admin) {
        _admin = [self.groupMembers firstObject];
    }
    return _admin;
}

- (NSMutableDictionary *)addressMemberDict{
    if (!_addressMemberDict) {
        _addressMemberDict = [NSMutableDictionary dictionary];
        for (AccountInfo *mem in self.groupMembers) {
            [_addressMemberDict setObject:mem forKey:mem.address];
        }
    }
    return _addressMemberDict;
}

- (NSString *)avatarUrl{
    // TODO group avatar server change ,cannot use ip address
    NSString *base_server = @"https://short.connect.im";
    return [NSString stringWithFormat:@"%@/avatar/%@/group/%@.jpg",base_server,APIVersion,self.groupIdentifer];
}

@end
