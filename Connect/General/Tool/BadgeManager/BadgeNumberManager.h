//
//  BadgeNumberManager.h
//  Connect
//
//  Created by MoHuilin on 16/9/21.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BadgeNumberStore.h"

typedef void(^setBadgeCompletion)(BOOL result);
typedef void(^getBadgeCompletion)(BadgeNumber * badgeNumber);
typedef void(^getBadgeCountCompletion)(NSUInteger count);
typedef void(^clearBadgeCompletion)();

@interface BadgeNumberManager : NSObject

/** singletion */
+ (instancetype)shareManager;

/**
   * Set badgeNumber
   * (Asynchronous)
 */
- (void)setBadgeNumber:(BadgeNumber *)badgeNumber Completion:(setBadgeCompletion)completion;

/**
 *  Asynchronous return BadgeNumber
 */
- (void)getBadgeNumber:(NSUInteger)type Completion:(getBadgeCompletion)completion;

/**
 *  Asynchronous access to count
 */
- (void)getBadgeNumberCountWithMin:(NSUInteger)typeMin max:(NSUInteger)typeMax Completion:(getBadgeCountCompletion)completion;

/**
 *  Asynchronous Clear BadgeNumber
 */
- (void)clearBadgeNumber:(NSUInteger)type Completion:(clearBadgeCompletion)completion;

@end
