//
//  GJCFFileDownloadTask+GJCFAudioDownload.h
//  GJCommonFoundation
//
//  Created by KivenLin on 14-9-18.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJCFFileDownloadTask.h"
#import "GJCFAudioModel.h"


@interface GJCFFileDownloadTask (GJCFAudioDownload)

+ (GJCFFileDownloadTask *)taskWithAudioFile:(GJCFAudioModel*)audioFile withObserver:(NSObject*)observer getTaskIdentifier:(NSString **)taskIdentifier;

@end
