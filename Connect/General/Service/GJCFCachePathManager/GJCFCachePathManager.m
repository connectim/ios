//
//  GJCFCachePathManager.m
//  GJCommonFoundation
//
//  Created by KivenLin on 14-11-19.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJCFCachePathManager.h"
#import "GJCFUitils.h"

#define GJCFCachePathManagerMainCacheDirectory @"MainCache"

#define GJCFCachePathManagerMainImageCacheDirectory @"MainImageCache"

#define GJCFCachePathManagerMainAudioCacheDirectory @"MainAudioCache"

#define GJCFCachePathManagerMainVideoCacheDirectory @"MainVideoCache"

static NSString *  GJCFAudioFileCacheSubTempEncodeFileDirectory = @"AudioFileCacheSubTempAmrCache";

@implementation GJCFCachePathManager

+ (GJCFCachePathManager *)shareManager
{
    static GJCFCachePathManager *_pathManager = nil;
    static dispatch_once_t onceToken;
    GJCFDispatchOnce(onceToken, ^{
        _pathManager = [[self alloc]init];
    });
    return _pathManager;
}

- (instancetype)init
{
    if (self = [super init]) {
        
        [self setupCacheDirectorys];
    }
    return self;
}

- (void)setupCacheDirectorys
{
    /* Main cache directory */
    if (!GJCFFileDirectoryIsExist([self mainCacheDirectory])) {
        GJCFFileDirectoryCreate([self mainCacheDirectory]);
    }
    
    /* Main picture cache directory */
    if (!GJCFFileDirectoryIsExist([self mainImageCacheDirectory])) {
        GJCFFileDirectoryCreate([self mainImageCacheDirectory]);
    }
    
    /* Main audio cache directory */
    if (!GJCFFileDirectoryIsExist([self mainAudioCacheDirectory])) {
        GJCFFileDirectoryCreate([self mainAudioCacheDirectory]);
    }
    
    /* Main video cache directory */
    if (!GJCFFileDirectoryIsExist([self mainVideoCacheDirectory])) {
        GJCFFileDirectoryCreate([self mainVideoCacheDirectory]);
    }
}

- (NSString *)mainCacheDirectory
{
    return GJCFAppCachePath(GJCFCachePathManagerMainCacheDirectory);
}

- (NSString *)mainImageCacheDirectory
{
    return [[self mainCacheDirectory]stringByAppendingPathComponent:GJCFCachePathManagerMainImageCacheDirectory];
}

- (NSString *)mainAudioCacheDirectory
{
    return [[self mainCacheDirectory]stringByAppendingPathComponent:GJCFCachePathManagerMainAudioCacheDirectory];
}

- (NSString *)mainVideoCacheDirectory
{
    return [[self mainCacheDirectory]stringByAppendingPathComponent:GJCFCachePathManagerMainVideoCacheDirectory];
}

/* Main picture cache under file path */
- (NSString *)mainImageCacheFilePath:(NSString *)fileName
{
    if (GJCFStringIsNull(fileName)) {
        return nil;
    }
    return [[self mainImageCacheDirectory]stringByAppendingPathComponent:fileName];
}

/* The main audio cache file path*/
- (NSString *)mainAudioCacheFilePath:(NSString *)fileName
{
    if (GJCFStringIsNull(fileName)) {
        return nil;
    }
    return [[self mainAudioCacheDirectory]stringByAppendingPathComponent:fileName];
}

/* Create or return the directory path of the specified name under the main cache directory */
- (NSString *)createOrGetSubCacheDirectoryWithName:(NSString *)dirName
{
    if (GJCFStringIsNull(dirName)) {
        return nil;
    }
    NSString *dirPath = [[self mainCacheDirectory] stringByAppendingPathComponent:dirName];
    if (GJCFFileDirectoryIsExist(dirPath)) {
        return dirPath;
    }else{
        GJCFFileDirectoryCreate(dirPath);
        return dirPath;
    }
}

/* Return or create a directory path for the specified directory name in the main picture cache directory */
- (NSString *)createOrGetSubImageCacheDirectoryWithName:(NSString *)dirName
{
    if (GJCFStringIsNull(dirName)) {
        return nil;
    }
    NSString *dirPath = [[self mainImageCacheDirectory] stringByAppendingPathComponent:dirName];
    if (GJCFFileDirectoryIsExist(dirPath)) {
        return dirPath;
    }else{
        GJCFFileDirectoryCreate(dirPath);
        return dirPath;
    }
}

/* Return or create a directory path for the specified directory name in the main audio cache directory*/
- (NSString *)createOrGetSubAudioCacheDirectoryWithName:(NSString *)dirName
{
    if (GJCFStringIsNull(dirName)) {
        return nil;
    }
    NSString *dirPath = [[self mainAudioCacheDirectory] stringByAppendingPathComponent:dirName];
    if (GJCFFileDirectoryIsExist(dirPath)) {
        return dirPath;
    }else{
        GJCFFileDirectoryCreate(dirPath);
        return dirPath;
    }
}

/* Whether there is a file named fileName in the main picture cache directory */
- (BOOL)mainImageCacheFileExist:(NSString *)fileName
{
    return GJCFFileIsExist([self mainImageCacheFilePath:fileName]);
}

/* Whether the file named fileName exists in the main audio cache directory */
- (BOOL)mainAudioCacheFileExist:(NSString *)fileName
{
    return GJCFFileIsExist([self mainAudioCacheFilePath:fileName]);
}

/* Returns the cache path for an image link address */
- (NSString *)mainImageCacheFilePathForUrl:(NSString *)url
{
    if (GJCFStringIsNull(url)) {
        return nil;
    }
    NSString *fileName = [url stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    return [self mainImageCacheFilePath:fileName];
}

/* Returns the cache path for a voice address */
- (NSString *)mainAudioCacheFilePathForUrl:(NSString *)url
{
    if (GJCFStringIsNull(url)) {
        return nil;
    }
    NSString *fileName = [url stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    return [self mainAudioCacheFilePath:fileName];
}

/* Determine whether the main picture cache under the link for the url file cache  */
- (BOOL)mainImageCacheFileIsExistForUrl:(NSString *)url
{
    return GJCFFileIsExist([self mainImageCacheFilePathForUrl:url]);
}

/* Determine whether there is a file cache for the url in the main voice cache */
- (BOOL)mainAudioCacheFileIsExistForUrl:(NSString *)url
{
    return GJCFFileIsExist([self mainAudioCacheFilePathForUrl:url]);
}

- (NSString *)mainAudioTempEncodeFile:(NSString *)fileName
{
    return [[self createOrGetSubAudioCacheDirectoryWithName:GJCFAudioFileCacheSubTempEncodeFileDirectory]stringByAppendingPathComponent:fileName];
}

@end
