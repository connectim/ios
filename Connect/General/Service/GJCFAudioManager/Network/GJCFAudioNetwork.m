//
//  GJCFAudioNetwork.m
//  GJCommonFoundation
//
//  Created by KivenLin on 14-9-16.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJCFAudioNetwork.h"

@interface GJCFAudioNetwork ()

@property (nonatomic,strong)NSMutableArray *uploadTasksArray;

@property (nonatomic,strong)NSMutableArray *downloadTasksArray;

@end

@implementation GJCFAudioNetwork

- (id)init
{
    if (self = [super init]) {
        
        self.uploadTasksArray = [[NSMutableArray alloc]init];
        self.downloadTasksArray = [[NSMutableArray alloc]init];
        
        /* Set the task upload component */
        [self setAudioUploadManager];
        
        /* Delayed one second observation task download task observation */
        [self performSelector:@selector(observeDownloadTask) withObject:nil afterDelay:1.f];
    }
    return self;
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[GJCFFileDownloadManager shareDownloadManager]clearTaskBlockForObserver:self];
}

#pragma mark - Upload task observation
- (void)setAudioUploadManager
{
    if (self.uploadManager) {
        self.uploadManager = nil;
    }
    self.uploadManager = [[GJCFFileUploadManager alloc]init];
    
    /* Set task observation */
    [self observeUploadTask];
}

- (void)observeUploadTask
{
    __weak typeof(self)weakSelf = self;
    
    [self.uploadManager setCompletionBlock:^(GJCFFileUploadTask *task, FileData *fileData) {
        [weakSelf uploadCompletionWithTask:task resultDict:nil];
        
    }];
    
    [self.uploadManager setProgressBlock:^(GJCFFileUploadTask *updateTask, CGFloat progressValue) {
       
        [weakSelf uploadProgressWithTask:updateTask progress:progressValue];
    }];
    
    [self.uploadManager setFaildBlock:^(GJCFFileUploadTask *task, NSError *error) {
       
        [weakSelf uploadFaildWithTask:task faild:error];
        
    }];
}

#pragma mark - Upload task processing
- (void)uploadCompletionWithTask:(GJCFFileUploadTask *)task resultDict:(NSDictionary *)result
{
    GJCFAudioModel *originFile = task.userInfo[@"audioFile"];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioNetwork:formateUploadResult:formateDict:)]) {
        
      GJCFAudioModel  *formatedModel = [self.delegate audioNetwork:self formateUploadResult:originFile formateDict:result];
        
        if (formatedModel) {
            
            formatedModel.isBeenUploaded = YES;

            if (self.delegate && [self.delegate respondsToSelector:@selector(audioNetwork:finishUploadAudioFile:)]) {
                
                [self.delegate audioNetwork:self finishUploadAudioFile:formatedModel];
            }
            
        }else{
            
            GJCFAudioModel *originFile = task.userInfo[@"audioFile"];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(audioNetwork:forAudioFile:uploadFaild:)]) {
                
                NSError *serverError = [NSError errorWithDomain:@"http://www.Connect" code:-123 userInfo:@{@"msg": @"参数非法"}];
                [self.delegate audioNetwork:self forAudioFile:originFile.localStorePath uploadFaild:serverError];
            }
            
        }
    }
}

- (void)uploadProgressWithTask:(GJCFFileUploadTask *)task progress:(CGFloat)progress
{
    GJCFAudioModel *originFile = task.userInfo[@"audioFile"];

    if (self.delegate && [self.delegate respondsToSelector:@selector(audioNetwork:forAudioFile:uploadProgress:)]) {
        
        [self.delegate audioNetwork:self forAudioFile:originFile.localStorePath uploadProgress:progress];
        
    }
}

- (void)uploadFaildWithTask:(GJCFFileUploadTask *)task faild:(NSError *)error
{
    GJCFAudioModel *originFile = task.userInfo[@"audioFile"];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioNetwork:forAudioFile:uploadFaild:)]) {
        
        [self.delegate audioNetwork:self forAudioFile:originFile.localStorePath uploadFaild:error];
    }
}

#pragma mark - download task observer
- (void)observeDownloadTask
{
    __weak typeof(self)weakSelf = self;
    [[GJCFFileDownloadManager shareDownloadManager]setDownloadCompletionBlock:^(GJCFFileDownloadTask *task, NSData *fileData, NSString *localPath, BOOL isFinishCache) {
        
        [weakSelf downloadCompletion:task withFileData:fileData isFinishCached:isFinishCache];
        
    } forObserver:self];
    
    [[GJCFFileDownloadManager shareDownloadManager]setDownloadProgressBlock:^(GJCFFileDownloadTask *task, CGFloat progress) {
        
        [weakSelf downloadProgress:task withPorgress:progress];
        
    } forObserver:self];
    
    [[GJCFFileDownloadManager shareDownloadManager]setDownloadFaildBlock:^(GJCFFileDownloadTask *task, NSError *error) {
        
        [weakSelf downloadFaild:task faild:error];
        
    } forObserver:self];
}

#pragma mark - download deal
- (void)downloadCompletion:(GJCFFileDownloadTask *)task withFileData:(NSData *)fileData isFinishCached:(BOOL)finishCache
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioNetwork:finishDownloadWithAudioFile:)]) {
        
        GJCFAudioModel *audioFile = task.userInfo[@"audioFile"];
        
        [self.delegate audioNetwork:self finishDownloadWithAudioFile:audioFile];
    }
}

- (void)downloadProgress:(GJCFFileDownloadTask *)task withPorgress:(CGFloat)progress
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioNetwork:forAudioFile:downloadProgress:)]) {
        
        GJCFAudioModel *audioFile = task.userInfo[@"audioFile"];

        [self.delegate audioNetwork:self forAudioFile:audioFile.uniqueIdentifier downloadProgress:progress];
    }
}

- (void)downloadFaild:(GJCFFileDownloadTask *)task faild:(NSError *)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioNetwork:forAudioFile:downloadFaild:)]) {
        
        GJCFAudioModel *audioFile = task.userInfo[@"audioFile"];

        [self.delegate audioNetwork:self forAudioFile:audioFile.remotePath downloadFaild:error];
        
    }
    
}

- (void)uploadAudioFile:(GJCFAudioModel *)audioFile
{
    NSString *taskIdentifier = nil;
    GJCFFileUploadTask *task = [GJCFFileUploadTask taskWithAudioFile:audioFile withObserver:self withTaskIdentifier:&taskIdentifier];
    
    if (!task) {
        return;
    }
    
    [self.uploadTasksArray objectAddObject:taskIdentifier];
    
    if (self.uploadManager) {
        
        [self.uploadManager addTask:task];
    }
    
}

- (void)downloadAudioFile:(GJCFAudioModel *)audioFile
{
    /* Create a download task to start the download */
    NSString *taskIdentifier = nil;
    GJCFFileDownloadTask *task = [GJCFFileDownloadTask taskWithAudioFile:audioFile withObserver:self getTaskIdentifier:&taskIdentifier];
    
    [self.downloadTasksArray objectAddObject:taskIdentifier];
    
    [[GJCFFileDownloadManager shareDownloadManager] addTask:task];
    
    NSLog(@"GJCFAudioNetwork task:%@ begin dowload .... ",taskIdentifier);
}

- (void)downloadAudioFileWithUrl:(NSString *)remoteAudioUrl withFinishDownloadPlayCheck:(BOOL)finishPlay withFileUniqueIdentifier:(NSString **)fileUniqueIdentifier
{
    GJCFAudioModel *audioFile = [[GJCFAudioModel alloc]init];
    audioFile.remotePath = remoteAudioUrl;
    audioFile.isNeedConvertEncodeToSave = YES;
    audioFile.shouldPlayWhileFinishDownload = finishPlay;
    audioFile.isDeleteWhileFinishConvertToLocalFormate = YES;
    *fileUniqueIdentifier = audioFile.uniqueIdentifier;
    
    [self downloadAudioFile:audioFile];
}

- (void)downloadAudioFileWithUrl:(NSString *)remoteAudioUrl withFileUniqueIdentifier:(NSString **)fileUniqueIdentifier
{
    [self downloadAudioFileWithUrl:remoteAudioUrl withFinishDownloadPlayCheck:NO withFileUniqueIdentifier:fileUniqueIdentifier];
}

@end
