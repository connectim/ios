//
//  NSDictionary+LMSafety.h
//  Connect
//
//  Created by MoHuilin on 2017/1/4.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (LMSafety)
- (id)safeObjectForKey:(id)aKey;
- (void)safeSetObject:(id)object forKey:(id)aKey;

@end
