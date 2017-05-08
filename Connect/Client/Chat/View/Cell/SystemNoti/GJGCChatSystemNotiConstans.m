//
//  GJGCChatSystemNotiConstans.m
//  Connect
//
//  Created by KivenLin on 14-11-5.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJGCChatSystemNotiConstans.h"

@implementation GJGCChatSystemNotiConstans

+ (NSDictionary *)chatCellIdentifierDict {
    return @{
            @"GJGCChatSystemActiveGuideCell": @"GJGCChatSystemActiveGuideCellIdentifier",
    };

}

+ (NSDictionary *)chatCellNotiTypeDict {
    return @{
            @(GJGCChatSystemNotiTypeSystemActiveGuide): @"GJGCChatSystemActiveGuideCell",
    };
}

+ (NSString *)identifierForCellClass:(NSString *)className {
    return [[GJGCChatSystemNotiConstans chatCellIdentifierDict] objectForKey:className];
}

+ (Class)classForNotiType:(GJGCChatSystemNotiType)notiType {
    NSDictionary *notiNotiTypeDict = [GJGCChatSystemNotiConstans chatCellNotiTypeDict];
    NSString *className = [notiNotiTypeDict objectForKey:@(notiType)];

    return NSClassFromString(className);
}

+ (NSString *)identifierForNotiType:(GJGCChatSystemNotiType)notiType {
    NSDictionary *notiNotiTypeDict = [GJGCChatSystemNotiConstans chatCellNotiTypeDict];
    NSString *className = [notiNotiTypeDict objectForKey:@(notiType)];

    return [GJGCChatSystemNotiConstans identifierForCellClass:className];
}


@end
