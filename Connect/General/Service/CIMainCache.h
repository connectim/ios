//
//  CIMainCache.h
//  Connect
//
//  Created by MoHuilin on 16/9/9.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CIMainCache : NSObject

+ (instancetype)sharedInstance;

#pragma mark - contacts
- (NSArray *)myContacts;

@end
