//
//  SpeedDectectManager.h
//  Connect
//
//  Created by MoHuilin on 2016/12/15.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServerURLModel.h"

typedef void (^serverURL)(ServerURLModel *response, NSString *error);

typedef void (^serverURLs)(NSArray *response, NSString *error);

@interface SpeedDectectManager : NSObject

+ (SpeedDectectManager *)instance;

/**
 * Find the fastest server, the default cache 300 seconds
 * @param complete
 */
- (void)startDectect:(serverURL)complete;

/**
 * Get the server list, the default cache 1 days
 * @param complete
 */
- (void)requestServiceListsWithCache:(serverURLs)complete;

@end
