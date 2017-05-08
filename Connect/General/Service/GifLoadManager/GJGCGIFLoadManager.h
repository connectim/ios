//
//  GJGCGIFLoadManager.h
//  Connect
//
//  Created by KivenLin on 15/6/18.
//  Copyright (c) 2015年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GJGCGIFLoadManager : NSObject

+ (BOOL)gifEmojiIsExistById:(NSString *)gifEmojiId;

+ (NSData *)getCachedGifDataById:(NSString *)gifEmojiId;

+ (NSString *)gifCachePathById:(NSString *)gifEmojiId;

@end
