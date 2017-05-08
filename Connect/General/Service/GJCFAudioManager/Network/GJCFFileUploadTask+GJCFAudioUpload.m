//
//  GJCFFileUploadTask+GJCFAudioUpload.m
//  GJCommonFoundation
//
//  Created by KivenLin on 14-9-18.
//  Copyright (c) 2014年 ConnectSoft. All rights reserved.
//

#import "GJCFFileUploadTask+GJCFAudioUpload.h"

@implementation GJCFFileUploadTask (GJCFAudioUpload)

+ (GJCFFileUploadTask *)taskWithAudioFile:(GJCFAudioModel*)audioFile withObserver:(NSObject*)observer withTaskIdentifier:(NSString *__autoreleasing *)taskIdentifier
{
    GJCFFileUploadTask *task = [GJCFFileUploadTask taskWithFilePath:audioFile.tempEncodeFilePath withFileName:@"image.amr" withFormName:@"image" taskObserver:nil getTaskUniqueIdentifier:taskIdentifier];
    
    //Custom request header
    NSString* timeStamp = [NSString stringWithFormat:@"%lld", (long long)[[NSDate date] timeIntervalSinceReferenceDate]];
    /*  There is also a need for a userId, which requires an external setting */
    NSDictionary *customRequestHeader = @{@"ClientTimeStamp":timeStamp,@"interface":@"UploadImages"};
    task.customRequestHeader = customRequestHeader;
    
    //Custom request parameters
    NSString* jsonArgs = [NSString stringWithFormat:@"{\"imageCount\":\"1\",\"nowatermark\":\"1\"}"];
    task.customRequestParams = @{@"jsonArgs": jsonArgs};
    
    //Set the original file object
    task.userInfo = @{@"audioFile": audioFile};

    return task;
}

@end
