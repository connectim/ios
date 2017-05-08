//
//  GJGCChatSystemNotiConstans.h
//  Connect
//
//  Created by KivenLin on 14-11-5.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, GJGCChatSystemNotiType) {
    GJGCChatSystemNotiTypeSystemUnknow = 0,
    //Anocement
    GJGCChatSystemNotiTypeSystemActiveGuide
};

@interface GJGCChatSystemNotiConstans : NSObject


+ (NSString *)identifierForNotiType:(GJGCChatSystemNotiType)notiType;

+ (Class)classForNotiType:(GJGCChatSystemNotiType)notiType;

@end
