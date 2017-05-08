//
//  RecentChatStyle.h
//  Connect
//
//  Created by MoHuilin on 16/6/25.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RecentChatStyle : NSObject

+ (NSAttributedString *)formateName:(NSString *)name;

+ (NSAttributedString *)formateTime:(long long)time;

+ (NSAttributedString *)formateContent:(NSString *)content;

@end
