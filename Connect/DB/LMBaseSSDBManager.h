//
//  LMBaseSSDBManager.h
//  Connect
//
//  Created by MoHuilin on 2017/1/2.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMBaseSSDBManager : NSObject

+ (LMBaseSSDBManager *)open:(NSString *)path;

+ (LMBaseSSDBManager *)openSystemSSDB;

- (void)close;


- (BOOL)set:(NSString *)key string:(NSString *)string;

- (BOOL)set:(NSString *)key data:(NSData *)data;

/**
 * found:     ret=YES & string != nil
 * not_found: ret=YES & string == nil
 * error:     ret=NO
 */
- (BOOL)get:(NSString *)key string:(NSString **)string;

- (BOOL)get:(NSString *)key data:(NSData **)data;

- (BOOL)del:(NSString *)key;


//- (NSArray *)qpop_front:(NSString *)name size:(int)size;
//- (BOOL)qpush_back:(NSString *)name values:(NSArray *)values;
//- (int)incr:(NSString *)name;
//- (NSString *)qfront:(NSString *)name;
//- (NSString *)qback:(NSString *)name;
//- (int)qsize:(NSString *)name;

@end
