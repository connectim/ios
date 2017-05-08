//
//  GJGCGIFLoadManager.m
//  Connect
//
//  Created by KivenLin on 15/6/18.
//  Copyright (c) 2015年 ConnectSoft. All rights reserved.
//

#import "GJGCGIFLoadManager.h"

#define GJGCGIFEmojiDownloadCacheDirectory @"GJGCGIFEmojiDownloadCacheDirectory"

@implementation GJGCGIFLoadManager

+ (NSString *)createGifCacheDirectory {
    NSString *gifEmojiCacheDirectory = [[GJCFCachePathManager shareManager] createOrGetSubCacheDirectoryWithName:GJGCGIFEmojiDownloadCacheDirectory];

    if (!GJCFFileDirectoryIsExist(gifEmojiCacheDirectory)) {

        GJCFFileDirectoryCreate(gifEmojiCacheDirectory);
    }

    return gifEmojiCacheDirectory;
}

+ (BOOL)gifEmojiIsExistById:(NSString *)gifEmojiId {

    return GJCFFileIsExist([self gifCachePathById:gifEmojiId]);
}

+ (NSData *)getCachedGifDataById:(NSString *)gifEmojiId {
    NSString *gifName = [NSString stringWithFormat:@"%@.gif", gifEmojiId];
    NSData *gifData = [NSData dataWithContentsOfFile:GJCFMainBundlePath(gifName)];
    if (gifData) {
        return gifData;
    } else {
        return [NSData dataWithContentsOfFile:[self gifCachePathById:gifEmojiId]];
    }
}

+ (NSString *)gifCachePathById:(NSString *)gifEmojiId {
    if (GJCFStringIsNull(gifEmojiId)) {
        return nil;
    }

    NSString *fileName = [NSString stringWithFormat:@"%@.gif", gifEmojiId];

    return [[self createGifCacheDirectory] stringByAppendingPathComponent:fileName];
}

@end
