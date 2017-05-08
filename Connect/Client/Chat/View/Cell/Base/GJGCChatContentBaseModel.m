//
//  GJGCChatContentBaseModel.m
//  Connect
//
//  Created by KivenLin on 14-11-3.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJGCChatContentBaseModel.h"

@implementation GJGCChatContentBaseModel

- (instancetype)init {
    if (self = [super init]) {

        _uniqueIdentifier = GJCFStringCurrentTimeStamp;

    }
    return self;
}

- (NSComparisonResult)compareContent:(GJGCChatContentBaseModel *)contentModel {
    NSComparisonResult result = [@(self.sendTime) compare:@(contentModel.sendTime)];

    if (result == NSOrderedSame) {

        return [@([self.localMsgId longLongValue]) compare:@([contentModel.localMsgId longLongValue])];

    } else {

        return result;
    }
}

@end
