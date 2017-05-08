//
//  GJCFFileDownloadTask+GJCFAudioDownload.m
//  GJCommonFoundation
//
//  Created by KivenLin on 14-9-18.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJCFFileDownloadTask+GJCFAudioDownload.h"
#import "GJCFAudioFileUitil.h"

@implementation GJCFFileDownloadTask (GJCFAudioDownload)

+ (GJCFFileDownloadTask *)taskWithAudioFile:(GJCFAudioModel*)audioFile withObserver:(NSObject*)observer getTaskIdentifier:(NSString *__autoreleasing *)taskIdentifier
{
    if (!audioFile.remotePath) {
        return nil;
    }
    
    /* Set the cache path */
    if (!audioFile.tempEncodeFilePath) {
        [GJCFAudioFileUitil setupAudioFileTempEncodeFilePath:audioFile];
    }
    
    GJCFFileDownloadTask *task = [GJCFFileDownloadTask taskWithDownloadUrl:audioFile.remotePath withCachePath:audioFile.tempEncodeFilePath withObserver:observer getTaskIdentifer:taskIdentifier];
    task.userInfo = @{@"audioFile": audioFile};
    
    
    return task;
}

@end
