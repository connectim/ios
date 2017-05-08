//
//  GJCFFileDownloadTask.m
//  GJCommonFoundation
//
//  Created by KivenLin on 14-9-18.
//  Copyright (c) 2014年 ConnectSoft. All rights reserved.
//

#import "GJCFFileDownloadTask.h"
#import "GJCFFileDownloadManager.h"
#import "GJCFUitils.h"

@interface GJCFFileDownloadTask ()

@property (nonatomic,strong)NSMutableArray *innerTaskObserverArray;

@property (nonatomic,strong)NSMutableArray *innerTaskCachePathArray;

@end

@implementation GJCFFileDownloadTask

- (id)init
{
    if (self = [super init]) {
        
        self.taskState = GJFileDownloadStateNeverBegin;
        self.innerTaskObserverArray = [[NSMutableArray alloc]init];
        self.innerTaskCachePathArray = [[NSMutableArray alloc]init];
        self.useDowloadManagerHost = NO;
        _taskUniqueIdentifier = [GJCFFileDownloadTask currentTimeStamp];
    }
    return self;
}


+ (GJCFFileDownloadTask *)taskWithDownloadUrl:(NSString *)downloadUrl withCachePath:(NSString*)cachePath withObserver:(NSObject*)observer getTaskIdentifer:(NSString *__autoreleasing *)taskIdentifier
{
    GJCFFileDownloadTask *task = [[self alloc]init];
    task.downloadUrl = downloadUrl;
    task.downEncodeDataCachePath = cachePath;
    if(taskIdentifier){
        *taskIdentifier = task.taskUniqueIdentifier;
    }
    [task addTaskObserver:observer];
    
    return task;
}

+ (NSString *)currentTimeStamp
{
    NSDate *now = [NSDate date];
    NSTimeInterval timeInterval = [now timeIntervalSinceReferenceDate];
    
    NSString *timeString = [NSString stringWithFormat:@"%lf",timeInterval];
    timeString = [timeString stringByReplacingOccurrencesOfString:@"." withString:@"_"];

    return timeString;
}

- (NSArray*)taskObservers
{
    return self.innerTaskObserverArray;
}

#pragma mark - 公开方法

- (void)addTaskObserver:(NSObject*)observer
{
    if (!observer) {
        return;
    }
    NSString *observerUniqueIdentifier = [GJCFFileDownloadManager uniqueKeyForObserver:observer];
    
    [self.innerTaskObserverArray objectAddObject:observerUniqueIdentifier];
}

- (void)addTaskObserverFromOtherTask:(NSString *)observeIdentifier
{
    if (!observeIdentifier) {
        return;
    }
    if (![self.innerTaskObserverArray containsObject:observeIdentifier]) {
        [self.innerTaskObserverArray objectAddObject:observeIdentifier];
    }
}

- (void)addTaskCachePath:(NSString *)cachePath
{
    if (GJCFStringIsNull(cachePath)) {
        return;
    }
    
    for (NSString *existCachePath in self.innerTaskCachePathArray) {
        
        if ([existCachePath isEqualToString:cachePath]) {
            
            return;
        }
    }
    
    [self.innerTaskCachePathArray objectAddObject:cachePath];
}

- (NSArray *)cacheToPaths
{
    return self.innerTaskCachePathArray;
}

- (void)removeTaskObserver:(NSObject*)observer
{
    if (!observer) {
        return;
    }
    NSString *observerUniqueIdentifier = [GJCFFileDownloadManager uniqueKeyForObserver:observer];

    [self.innerTaskObserverArray removeObject:observerUniqueIdentifier];
}

- (BOOL)isValidateForDownload
{
    if (self.unEncodeData) {
        if (self.downloadUrl) {
            return YES;
        } else{
            return NO;
        }
    } else{
        if (!self.downloadUrl || !self.ecdhkey || self.ecdhkey.length <= 0) {
            
            return NO;
            
        }else{
            
            return YES;
        }
    }
}

- (BOOL)isEqualToTask:(GJCFFileDownloadTask *)task
{
    if (!task) {
        return NO;
    }
    
    if ([task.downloadUrl isEqualToString:self.downloadUrl]) {
        
        return YES;
        
    }
    
     return NO;
    
}


@end
