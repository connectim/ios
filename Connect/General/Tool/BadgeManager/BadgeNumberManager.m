//
//  BadgeNumberManager.m
//  Connect
//
//  Created by MoHuilin on 16/9/21.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BadgeNumberManager.h"

@implementation BadgeNumberManager

+ (instancetype)shareManager
{
    static dispatch_once_t onceToken;
    static BadgeNumberManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[BadgeNumberManager alloc]init];
    });
    return  instance;
}


//-----------------------------------------
#pragma mark -- Exposure method --
//-----------------------------------------
/**
   * Set badgeNumber
   * (Asynchronous)
 */
- (void)setBadgeNumber:(BadgeNumber *)badgeNumber Completion:(setBadgeCompletion)completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        BOOL result = [[BadgeNumberStore shareManager] setBadgeNumber:badgeNumber];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            SendNotify(BadgeNumberManagerBadgeChangeNotification, nil);
            if (completion) {
                completion(result);
            }
        });
    });
}

/**
 *  Asynchronous return BadgeNumber
 */
- (void)getBadgeNumber:(NSUInteger)type Completion:(getBadgeCompletion)completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        BadgeNumber * badge = [[BadgeNumberStore shareManager]getBadgeNumber:type];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(badge);
            }
        });
    });
}

/**
 *  Asynchronous access to count
 */
- (void)getBadgeNumberCountWithMin:(NSUInteger)typeMin max:(NSUInteger)typeMax Completion:(getBadgeCountCompletion)completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSUInteger count = [[BadgeNumberStore shareManager]getBadgeNumberCountWithMin:typeMin max:typeMax];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(count);
            }
        });
    });
}

/**
 *  Asynchronous Clear BadgeNumber
 */
- (void)clearBadgeNumber:(NSUInteger)type Completion:(clearBadgeCompletion)completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [[BadgeNumberStore shareManager] clearBadgeNumber:type];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            SendNotify(BadgeNumberManagerBadgeChangeNotification, nil);
            
            if (completion) {
                completion();
            }
        });
    });
}


@end
