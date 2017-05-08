//
//  ChatMessageFileManager.m
//  Connect
//
//  Created by MoHuilin on 16/7/17.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "ChatMessageFileManager.h"

@implementation ChatMessageFileManager

+ (NSString *)mainImageCacheWithTalkUserAddress:(NSString *)address{
    
    if (GJCFStringIsNull(address)) {
        return nil;
    }

    
    NSString *cacheDirPath = [[GJCFCachePathManager shareManager] mainImageCacheDirectory];
    cacheDirPath = [[cacheDirPath stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].address]
                 stringByAppendingPathComponent:address];
    
    if (!GJCFFileDirectoryIsExist(cacheDirPath)) {
        BOOL result = GJCFFileDirectoryCreate(cacheDirPath);
        if (result) {
            DDLogInfo(cacheDirPath);
            return cacheDirPath;
        }
    }
    
    return cacheDirPath;
}

+ (NSString *)mainAudioCacheWithTalkUserAddress:(NSString *)address{
    
    if (GJCFStringIsNull(address)) {
        return nil;
    }

    
    NSString *cacheDirPath = [[GJCFCachePathManager shareManager] mainAudioCacheDirectory];
    cacheDirPath = [[cacheDirPath stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].address]
                 stringByAppendingPathComponent:address];
    
    if (!GJCFFileDirectoryIsExist(cacheDirPath)) {
        BOOL result = GJCFFileDirectoryCreate(cacheDirPath);
        if (result) {
            DDLogInfo(cacheDirPath);
            return cacheDirPath;
        }
    }
    
    return cacheDirPath;

}

+ (NSString *)mainVideoCacheWithTalkUserAddress:(NSString *)address{
    
    if (GJCFStringIsNull(address)) {
        return nil;
    }

    
    NSString *cacheDirPath = [[GJCFCachePathManager shareManager] mainVideoCacheDirectory];
    cacheDirPath = [[cacheDirPath stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].address]
                 stringByAppendingPathComponent:address];
    
    if (!GJCFFileDirectoryIsExist(cacheDirPath)) {
        BOOL result = GJCFFileDirectoryCreate(cacheDirPath);
        if (result) {
            DDLogInfo(cacheDirPath);
            return cacheDirPath;
        }
    }
    return cacheDirPath;

}

+ (BOOL)deleteRecentChatAllMessageFilesByAddress:(NSString *)address{
    
    
    if (GJCFStringIsNull(address)) {
        return NO;
    }
    
    NSString *mainVideoCache = [self mainVideoCacheWithTalkUserAddress:address];
    NSString *mainImageCache = [self mainImageCacheWithTalkUserAddress:address];
    NSString *mainAudioCache = [self mainAudioCacheWithTalkUserAddress:address];

    
    if (GJCFFileDirectoryIsExist(mainVideoCache)) {
        GJCFFileDeleteDirectory(mainVideoCache);
    }
    
    if (GJCFFileDirectoryIsExist(mainImageCache)) {
        GJCFFileDeleteDirectory(mainImageCache);
    }

    if (GJCFFileDirectoryIsExist(mainAudioCache)) {
        GJCFFileDeleteDirectory(mainAudioCache);
    }

    return YES;
}


+ (BOOL)deleteRecentChatMessageFileByMessageID:(NSString *)messageID Address:(NSString *)address{
    
    if (GJCFStringIsNull(address) || GJCFStringIsNull(messageID)) {
        return NO;
    }
    
    NSString *mainVideoCache = [self mainVideoCacheWithTalkUserAddress:address];
    
    NSArray *temA = [GJCFFileManager contentsOfDirectoryAtPath:mainVideoCache error:nil];
    for (NSString *path in temA) {
        if ([path hasPrefix:messageID]) {
            GJCFFileDeleteFile([mainVideoCache stringByAppendingPathComponent:path]);
        }
    }
    
    
    NSString *mainImageCache = [self mainImageCacheWithTalkUserAddress:address];
    
    temA = [GJCFFileManager contentsOfDirectoryAtPath:mainImageCache error:nil];
    for (NSString *path in temA) {
        if ([path hasPrefix:messageID]) {
            GJCFFileDeleteFile([mainImageCache stringByAppendingPathComponent:path]);
        }
    }

    
    NSString *mainAudioCache = [self mainAudioCacheWithTalkUserAddress:address];
    temA = [GJCFFileManager contentsOfDirectoryAtPath:mainAudioCache error:nil];
    for (NSString *path in temA) {
        if ([path hasPrefix:messageID]) {
            GJCFFileDeleteFile([mainAudioCache stringByAppendingPathComponent:path]);
        }
    }

    
    return YES;
}

+ (BOOL)deleteAllMessageFile{
    NSString *imageDire = [[GJCFCachePathManager shareManager] mainCacheDirectory];
    
    return GJCFFileDeleteDirectory(imageDire);
}

@end
