//
//  GJCFFileDownloadTask.h
//  GJCommonFoundation
//
//  Created by KivenLin on 14-9-18.
//  Copyright (c) 2014年 ConnectSoft. All rights reserved.
//

#import "NetWorkTool.h"

typedef NS_ENUM(NSUInteger, GJCFFileDownloadState) {
    
    /* Has never performed this task */
    GJFileDownloadStateNeverBegin = 0,
    
    /* The task has failed */
    GJFileDownloadStateHadFaild = 1,
    
    /* The task is executing */
    GJFileDownloadStateDownloading = 2,
    
    /* Task execution has been successful */
    GJFileDownloadStateSuccess = 3,
    
    /* The task was canceled */
    GJFileDownloadStateCancel = 4,
};

@interface GJCFFileDownloadTask : NSObject

/* Task unique identifier*/
@property (nonatomic,readonly)NSString *taskUniqueIdentifier;

/* Task execution state */
@property (nonatomic,assign)GJCFFileDownloadState taskState;

/* Task observer */
@property (nonatomic,readonly)NSArray *taskObservers;

@property (nonatomic ,strong) NSData *ecdhkey;

@property (nonatomic ,assign) BOOL unEncodeData;

/**
 *  Message Unique ID
 */
@property (nonatomic ,copy) NSString *msgIdentifier;

/**
 *  The downloaded encrypted data specifies the cache path that needs to be deleted
 */
@property (nonatomic ,copy) NSString *downEncodeDataCachePath;

/**
 *  Temporary source files are enriched, used in UI display, where the interface burns is needed to be removed
 */
@property (nonatomic ,copy) NSString *temOriginFilePath;

/* Download the custom parameters specified by the task, usually when URLEncode is required after the url */
@property (nonatomic,strong)NSString *customUrlEncodedParams;

/* The path to the file to be downloaded */
@property (nonatomic,strong)NSString *downloadUrl;

/* Whether to use the host address of the download manager, which is not used by default */
@property (nonatomic,assign)BOOL useDowloadManagerHost;

/* User-defined content */
@property (nonatomic,strong)NSDictionary *userInfo;

/* Download the task group ID that can be used to exit a set of requests */
@property (nonatomic,strong)NSString *groupTaskIdentifier;

- (void)addTaskObserver:(NSObject*)observer;

- (void)addTaskObserverFromOtherTask:(NSString *)observeIdentifier;

- (void)addTaskCachePath:(NSString *)cachePath;

- (void)removeTaskObserver:(NSObject*)observer;

+ (GJCFFileDownloadTask *)taskWithDownloadUrl:(NSString *)downloadUrl withCachePath:(NSString*)cachePath withObserver:(NSObject*)observer getTaskIdentifer:(NSString **)taskIdentifier;

/* Whether the task self-test can be downloaded */
- (BOOL)isValidateForDownload;

- (BOOL)isEqualToTask:(GJCFFileDownloadTask *)task;

@end
