//
//  GJCFCachePathManager.h
//  GJCommonFoundation
//
//  Created by KivenLin on 14-11-19.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GJCFCachePathManager : NSObject

+ (GJCFCachePathManager *)shareManager;

/* Main cache directory */
- (NSString *)mainCacheDirectory;

/* Image main cache directory */
- (NSString *)mainImageCacheDirectory;

/* Audio main cache directory */
- (NSString *)mainAudioCacheDirectory;


/* Video main cache directory */
- (NSString *)mainVideoCacheDirectory;

/* Main picture cache under file path */
- (NSString *)mainImageCacheFilePath:(NSString *)fileName;

/* The main audio cache file path */
- (NSString *)mainAudioCacheFilePath:(NSString *)fileName;

/* Create or return the directory path of the specified name under the main cache directory */
- (NSString *)createOrGetSubCacheDirectoryWithName:(NSString *)dirName;

/* Return or create a directory path for the specified directory name in the main picture cache directory */
- (NSString *)createOrGetSubImageCacheDirectoryWithName:(NSString *)dirName;

/* Return or create a directory path for the specified directory name in the main audio cache directory */
- (NSString *)createOrGetSubAudioCacheDirectoryWithName:(NSString *)dirName;

/* Whether there is a file named fileName in the main picture cache directory */
- (BOOL)mainImageCacheFileExist:(NSString *)fileName;

/* Whether the file named fileName exists in the main audio cache directory */
- (BOOL)mainAudioCacheFileExist:(NSString *)fileName;

/* Returns the cache path for an image link address */
- (NSString *)mainImageCacheFilePathForUrl:(NSString *)url;

/* Returns the cache path for a voice address */
- (NSString *)mainAudioCacheFilePathForUrl:(NSString *)url;

/* Determine whether the main picture cache under the link for the url file cache  */
- (BOOL)mainImageCacheFileIsExistForUrl:(NSString *)url;

/* Determine whether there is a file cache for the url in the main voice cache */
- (BOOL)mainAudioCacheFileIsExistForUrl:(NSString *)url;

/* Gets the temporary encoding file path under the main voice cache */
- (NSString *)mainAudioTempEncodeFile:(NSString *)fileName;

@end
