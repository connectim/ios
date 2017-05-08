//
//  GJCFFileDownloadManager.m
//  GJCommonFoundation
//
//  Created by KivenLin QQ:1003081775 on 14-9-18.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJCFFileDownloadManager.h"
#import "NetWorkTool.h"
#import "GJCFUitils.h"
#import "Protofile.pbobjc.h"
#import "GcmDataModel.h"
#import "ConnectTool.h"
#import "SingleAFNetworkManager.h"


static NSString * kGJCFFileDownloadManagerCompletionBlockKey = @"kGJCFFileUploadManagerCompletionBlockKey";

static NSString * kGJCFFileDownloadManagerProgressBlockKey = @"kGJCFFileUploadManagerProgressBlockKey";

static NSString * kGJCFFileDownloadManagerFaildBlockKey = @"kGJCFFileUploadManagerFaildBlockKey";

static NSString * kGJCFFileDownloadManagerObserverUniqueIdentifier = @"kGJCFFileDownloadManagerObserverUniqueIdentifier";

static NSString * kGJCFFileDownloadManagerQueue = @"com.gjcf.download.queue";

static dispatch_queue_t _gjcfFileDownloadManagerOperationQueue ;

@interface GJCFFileDownloadManager ()

@property (nonatomic,strong)NSMutableArray *taskArray;
@property (nonatomic,strong)NSMutableArray *taskSessionArray;

@property (nonatomic,strong)NSMutableDictionary *taskOberverAction;

@property (nonatomic ,copy) NSString *currentOberverIdentifier;

@end

@implementation GJCFFileDownloadManager

+ (GJCFFileDownloadManager *)shareDownloadManager
{
    static GJCFFileDownloadManager *_downloadManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        if (!_downloadManager) {
            _downloadManager = [[self alloc]init];
        }
    });
    return _downloadManager;
}

- (id)init
{
    if (self = [super init]) {
        
        self.taskArray = [[NSMutableArray alloc]init];
        self.taskSessionArray = [[NSMutableArray alloc]init];
        self.taskOberverAction = [[NSMutableDictionary alloc]init];
        _gjcfFileDownloadManagerOperationQueue = dispatch_queue_create(kGJCFFileDownloadManagerQueue.UTF8String, NULL);
    }
    return self;
}


#pragma mark - observer
+ (NSString*)uniqueKeyForObserver:(NSObject*)observer
{
    return [NSString stringWithFormat:@"%@_%lu",kGJCFFileDownloadManagerObserverUniqueIdentifier,(unsigned long)[observer hash]];
}

#pragma mark - public method


- (NSString *)getDownloadIdentifierWithMessageId:(NSString *)messageId{
    
    for (GJCFFileDownloadTask *dTask in self.taskArray) {
        if ([messageId isEqualToString:dTask.msgIdentifier]) {
            return dTask.taskUniqueIdentifier;
        }
    }
    return nil;
}

- (void)addTask:(GJCFFileDownloadTask *)task
{
    if (!task) {
        DDLogError(@"GJFileDownloadManager Error: Attempt to add an empty download task:%@",task);
        return;
    }
    if (![task isValidateForDownload]) {
        DDLogError(@"GJCFFileDownloadManager Error: The download task has no target download address:%@",task.downloadUrl);
        return;
    }
    
    dispatch_async(_gjcfFileDownloadManagerOperationQueue, ^{
        
        
        if (task.customUrlEncodedParams) {
            
            unichar firstChar = [task.customUrlEncodedParams characterAtIndex:0] ;
            NSString *firstCharString = [NSString stringWithFormat:@"%c",firstChar];
            
            if (![firstCharString isEqualToString:@"&"]) {
                
                task.downloadUrl = [NSString stringWithFormat:@"&%@",task.customUrlEncodedParams];
            }
        }
        for (NSString *observer in [self.taskOberverAction allKeys]) {
            [task addTaskObserverFromOtherTask:observer];
        }
        
        for (GJCFFileDownloadTask *dTask in self.taskArray) {
            if ([task isEqualToTask:dTask]) {
                for (NSString *observer in [self.taskOberverAction allKeys]) {
                    [task addTaskObserverFromOtherTask:observer];
                }
                return;
            }
        }
        AFURLSessionManager *manager = [[SingleAFNetworkManager sharedManager] sharedDownloadURLSession];
        NSURL *URL = [NSURL URLWithString:task.downloadUrl];
        NSURLRequest *request = [NSURLRequest requestWithURL:URL];
        NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
            dispatch_async(_gjcfFileDownloadManagerOperationQueue, ^{
                CGFloat downloadProgreessValue = (downloadProgress.completedUnitCount/1024.f)/(downloadProgress.totalUnitCount/1024.f);
                [self progressWithTask:task progress:downloadProgreessValue];
            });
        } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
            return [[NSURL alloc] initFileURLWithPath:task.downEncodeDataCachePath];
        } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
            dispatch_async(_gjcfFileDownloadManagerOperationQueue, ^{
                if (error) {
                    [self faildWithTask:task faild:error];
                } else{
                    [self completionWithTask:task];
                }
            });
        }];
        [downloadTask resume];
        task.taskState = GJFileDownloadStateDownloading;
        [self.taskArray objectAddObject:task];
        [self.taskSessionArray objectAddObject:downloadTask];
    });
}

#pragma mark - 请求的三个状态

- (void)completionWithTask:(GJCFFileDownloadTask *)task filePath:(NSURL *)filePath
{
    NSArray *taskObservers = task.taskObservers;
    task.taskState = GJFileDownloadStateSuccess;
    NSData *downloadDecodeData = nil;
    DDLogInfo(@"GJCFFileDownloadManager :%@ for TaskUrl:%@",taskObservers,task.downloadUrl);
    BOOL cacheState = NO;
    NSData *downloadData = [NSData dataWithContentsOfURL:filePath];
    if (downloadData) {
        if (task.unEncodeData) {
            // Write to the source file address
            cacheState = GJCFFileWrite(downloadData, task.temOriginFilePath);
        } else{
            GcmData *gcmData = [GcmData parseFromData:downloadData error:nil];
            downloadDecodeData = [ConnectTool decodeGcmDataWithEcdhKey:task.ecdhkey GcmData:gcmData];
            // Write to the source file address
            cacheState = GJCFFileWrite(downloadDecodeData, task.temOriginFilePath);
            //Delete the downloaded encrypted data
            GJCFFileDeleteFile(task.downEncodeDataCachePath);
        }
    }
    
    
    NSMutableDictionary *actionDict = [self.taskOberverAction objectForKey:self.currentOberverIdentifier];
    
    if (actionDict) {
        
        GJCFFileDownloadManagerCompletionBlock completionBlcok = [actionDict objectForKey:kGJCFFileDownloadManagerCompletionBlockKey];
        
        
        if (completionBlcok) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                completionBlcok(task,[NSData dataWithContentsOfFile:task.temOriginFilePath],task.temOriginFilePath,cacheState);
                
            });
            
        }
        
    }
    
    [self.taskArray removeObject:task];
    [self cancelSameUrlDownloadTaskForTask:task];
}


- (void)completionWithTask:(GJCFFileDownloadTask *)task
{
    NSArray *taskObservers = task.taskObservers;
    task.taskState = GJFileDownloadStateSuccess;
    NSData *downloadDecodeData = nil;
    BOOL cacheState = NO;
    NSData *downloadData = GJCFFileRead(task.downEncodeDataCachePath);
    if (downloadData) {
        if (task.unEncodeData) {
            // Write to the source file address
            cacheState = GJCFFileWrite(downloadData, task.temOriginFilePath);
        } else{
            GcmData *gcmData = [GcmData parseFromData:downloadData error:nil];
            downloadDecodeData = [ConnectTool decodeGcmDataWithEcdhKey:task.ecdhkey GcmData:gcmData];
            //
            cacheState = GJCFFileWrite(downloadDecodeData, task.temOriginFilePath);
            // Delete the downloaded encrypted data
            GJCFFileDeleteFile(task.downEncodeDataCachePath);
        }
    }
    
    
    NSMutableDictionary *actionDict = [self.taskOberverAction objectForKey:self.currentOberverIdentifier];
    
    if (actionDict) {
        
        GJCFFileDownloadManagerCompletionBlock completionBlcok = [actionDict objectForKey:kGJCFFileDownloadManagerCompletionBlockKey];
        
        
        if (completionBlcok) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                completionBlcok(task,[NSData dataWithContentsOfFile:task.temOriginFilePath],task.temOriginFilePath,cacheState);
                
            });
            
        }
        
    }
    
    [self.taskArray removeObject:task];
    [self cancelSameUrlDownloadTaskForTask:task];
}

- (void)progressWithTask:(GJCFFileDownloadTask *)task progress:(CGFloat)progress
{
    
    NSMutableDictionary *actionDict = [self.taskOberverAction objectForKey:self.currentOberverIdentifier];
    
    if (actionDict) {
        
        GJCFFileDownloadManagerProgressBlock progressBlcok = [actionDict objectForKey:kGJCFFileDownloadManagerProgressBlockKey];
        
        if (progressBlcok) {
            dispatch_async(dispatch_get_main_queue(), ^{
                progressBlcok(task,progress);
            });
        }
    }
    
}

- (void)faildWithTask:(GJCFFileDownloadTask *)task faild:(NSError*)error
{
    
    NSMutableDictionary *actionDict = [self.taskOberverAction objectForKey:self.currentOberverIdentifier];
    
    if (actionDict) {
        
        GJCFFileDownloadManagerFaildBlock faildBlcok = [actionDict objectForKey:kGJCFFileDownloadManagerFaildBlockKey];
        
        
        if (faildBlcok) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                faildBlcok(task,error);
                
            });
        }
        
    }

    task.taskState = GJFileDownloadStateHadFaild;
    [self.taskArray removeObject:task];
}

#pragma mark - Set the task observer
/*
 *  Set the observer to complete the method
 */
- (void)setDownloadCompletionBlock:(GJCFFileDownloadManagerCompletionBlock)completionBlock forObserver:(NSObject*)observer
{
    if (!observer) {
        return;
    }
    
    NSString *observerUnique = [GJCFFileDownloadManager uniqueKeyForObserver:observer];
    self.currentOberverIdentifier = observerUnique;
    NSMutableDictionary *observerActionDict = nil;
    if (![self.taskOberverAction objectForKey:observerUnique]) {
        
        observerActionDict = [NSMutableDictionary dictionary];
        
    }else{
        
        observerActionDict = [self.taskOberverAction objectForKey:observerUnique];
    }
    
    [observerActionDict setObject:completionBlock forKey:kGJCFFileDownloadManagerCompletionBlockKey];
    [self.taskOberverAction setObject:observerActionDict forKey:observerUnique];
}

/*
 *  Set the observer progress method
 */
- (void)setDownloadProgressBlock:(GJCFFileDownloadManagerProgressBlock)progressBlock forObserver:(NSObject*)observer
{
    if (!observer) {
        return;
    }
    
    NSString *observerUnique = [GJCFFileDownloadManager uniqueKeyForObserver:observer];
    self.currentOberverIdentifier = observerUnique;
    NSMutableDictionary *observerActionDict = nil;
    if (![self.taskOberverAction objectForKey:observerUnique]) {
        
        observerActionDict = [NSMutableDictionary dictionary];
        
    }else{
        
        observerActionDict = [self.taskOberverAction objectForKey:observerUnique];
    }
    
    [observerActionDict setObject:progressBlock forKey:kGJCFFileDownloadManagerProgressBlockKey];
    [self.taskOberverAction setObject:observerActionDict forKey:observerUnique];
}

/*
 *  Set the observer's failure method
 */
- (void)setDownloadFaildBlock:(GJCFFileDownloadManagerFaildBlock)faildBlock forObserver:(NSObject*)observer
{
    if (!observer) {
        return;
    }
    
    NSString *observerUnique = [GJCFFileDownloadManager uniqueKeyForObserver:observer];
    self.currentOberverIdentifier = observerUnique;
    NSMutableDictionary *observerActionDict = nil;
    if (![self.taskOberverAction objectForKey:observerUnique]) {
        
        observerActionDict = [NSMutableDictionary dictionary];
        
    }else{
        
        observerActionDict = [self.taskOberverAction objectForKey:observerUnique];
    }
    
    [observerActionDict setObject:faildBlock forKey:kGJCFFileDownloadManagerFaildBlockKey];
    [self.taskOberverAction setObject:observerActionDict forKey:observerUnique];
}

/*
 *  The observer's block is cleared
 */
- (void)clearTaskBlockForObserver:(NSObject *)observer
{
    if (!observer) {
        return;
    }
    self.currentOberverIdentifier = nil;
    NSString *observerUnique = [GJCFFileDownloadManager uniqueKeyForObserver:observer];
    if (![self.taskOberverAction.allKeys containsObject:observerUnique]) {
        return;
    }
    
    [self.taskOberverAction removeObjectForKey:observerUnique];
}

- (NSInteger)taskIndexForUniqueIdentifier:(NSString *)identifier
{
    NSInteger resultIndex = NSNotFound;
    for (int i = 0; i < self.taskArray.count ; i++) {
        
        GJCFFileDownloadTask *task = [self.taskArray objectAtIndex:i];
        
        if ([task.taskUniqueIdentifier isEqualToString:identifier]) {
            
            resultIndex = i;
            
            break;
        }
    }
    return resultIndex;
}

- (void)cancelTask:(NSString *)taskUniqueIdentifier
{
    if (GJCFStringIsNull(taskUniqueIdentifier)) {
        return;
    }
    
    dispatch_async(_gjcfFileDownloadManagerOperationQueue, ^{
        
        NSInteger taskIndex = [self taskIndexForUniqueIdentifier:taskUniqueIdentifier];
        if (taskIndex == NSNotFound) {
            return;
        }
        GJCFFileDownloadTask *task = [self.taskArray objectAtIndex:taskIndex];
        
        [task.taskObservers enumerateObjectsUsingBlock:^(NSString *observerIdentifier, NSUInteger idx, BOOL *stop) {
            
            [self clearTaskBlockForObserver:observerIdentifier];
            
        }];

        
        for (int i = 0 ; i < self.taskSessionArray.count ;i ++) {
            HYBURLSessionTask *session = self.taskSessionArray[i];
            GJCFFileDownloadTask *destTask = self.taskArray[i];
            if ([task.taskUniqueIdentifier isEqualToString:destTask.taskUniqueIdentifier]) {
                

                [session suspend];
                
                [self.taskArray removeObjectAtIndexCheck:taskIndex];
                [self.taskSessionArray removeObjectAtIndexCheck:taskIndex];
                break;
            }
        }
    });
    
}

- (NSArray *)groupTaskByUniqueIdentifier:(NSString *)groupTaskIdnetifier
{
    NSMutableArray *groupTaskArray = [NSMutableArray array];
    
    for (GJCFFileDownloadTask *task in self.taskArray) {
        
        if ([task.groupTaskIdentifier isEqualToString:groupTaskIdnetifier]) {
            
            [groupTaskArray objectAddObject:task];
        }
    }
    
    return groupTaskArray;
}

- (void)cancelGroupTask:(NSString *)groupTaskUniqueIdentifier
{
    if (!groupTaskUniqueIdentifier || [groupTaskUniqueIdentifier isKindOfClass:[NSNull class]] || groupTaskUniqueIdentifier.length == 0 || [groupTaskUniqueIdentifier isEqualToString:@""]) {
        return;
    }
    
    dispatch_async(_gjcfFileDownloadManagerOperationQueue, ^{
        
        NSArray *groupTaskArray = [self groupTaskByUniqueIdentifier:groupTaskUniqueIdentifier];
        if (groupTaskArray.count == 0) {
            return;
        }
        
        for (GJCFFileDownloadTask *task in groupTaskArray) {
            
            [task.taskObservers enumerateObjectsUsingBlock:^(NSString *observerIdentifier, NSUInteger idx, BOOL *stop) {
                
                [self clearTaskBlockForObserver:observerIdentifier];
                
            }];
            
            for (int i = 0 ; i < self.taskSessionArray.count ;i ++) {
                HYBURLSessionTask *session = self.taskSessionArray[i];
                GJCFFileDownloadTask *destTask = self.taskArray[i];
                if ([task.taskUniqueIdentifier isEqualToString:destTask.taskUniqueIdentifier]) {
                    
                    [session cancel];
                    
                    [self.taskArray removeObject:destTask];
                    [self.taskSessionArray removeObject:session];
                    break;
                }
            }
        }
    });
}

- (void)cancelTaskWithCompletion:(NSString *)taskUniqueIdentifier
{
    if (GJCFStringIsNull(taskUniqueIdentifier)) {
        return;
    }
    
    dispatch_async(_gjcfFileDownloadManagerOperationQueue, ^{
        
        NSInteger taskIndex = [self taskIndexForUniqueIdentifier:taskUniqueIdentifier];
        if (taskIndex == NSNotFound) {
            return;
        }
        GJCFFileDownloadTask *task = [self.taskArray objectAtIndex:taskIndex];
        
        for (int i = 0 ; i < self.taskSessionArray.count ;i ++) {
            HYBURLSessionTask *session = self.taskSessionArray[i];
            GJCFFileDownloadTask *destTask = self.taskArray[i];
            if ([task.taskUniqueIdentifier isEqualToString:destTask.taskUniqueIdentifier]) {
                
                [session cancel];
                break;
            }
        }
        
        BOOL cacheState = YES;
        NSData *downloadData = [NSData dataWithContentsOfFile:task.temOriginFilePath];
        
        [task.taskObservers enumerateObjectsUsingBlock:^(NSString *observeUniqueIdentifier, NSUInteger idx, BOOL *stop) {
            
            NSMutableDictionary *actionDict = [self.taskOberverAction objectForKey:observeUniqueIdentifier];
            
            
            if (actionDict) {
                
                GJCFFileDownloadManagerCompletionBlock completionBlcok = [actionDict objectForKey:kGJCFFileDownloadManagerCompletionBlockKey];
                
                if (completionBlcok) {
                    
                    completionBlcok(task,downloadData,nil,cacheState);
                }
                
            }
            
        }];
        
        [task.taskObservers enumerateObjectsUsingBlock:^(NSString *observerIdentifier, NSUInteger idx, BOOL *stop) {
            
            [self clearTaskBlockForObserver:observerIdentifier];
            
        }];
        
        [self.taskArray removeObjectAtIndexCheck:taskIndex];
        
    });
    
}

- (void)cancelSameUrlDownloadTaskForTask:(GJCFFileDownloadTask *)task
{
    for (GJCFFileDownloadTask *dTask in self.taskArray) {
        
        if ([task isEqualToTask:dTask]) {
            
            [self cancelTaskWithCompletion:dTask.taskUniqueIdentifier];
        }
    }
}

@end
