//
//  BadgeNumberStore.h
//  Connect
//
//  Created by MoHuilin on 16/9/21.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BadgeNumber.h"

@interface BadgeNumberStore : NSObject

#define BadgeNumberPlistName @"appBadgeNumber.plist"
#define TypeChatMappingPlistName @"typeChatMapping.plist"

/** singleton */
+ (instancetype)shareManager;

- (BadgeNumber *)getBadgeNumber:(NSUInteger) type;

- (BadgeNumber *)getBadgeNumberWithChatIdentifier:(NSString *)identifier;

- (NSUInteger)getMessageBadgeNumber; //Message total badge

- (NSUInteger)getBadgeNumberCountWithMin:(NSUInteger)typeMin max:(NSUInteger)typeMax;

- (BOOL)setBadgeNumber:(BadgeNumber *)badgeNumber;

- (void)clearBadgeNumber:(NSUInteger) type;

@end
