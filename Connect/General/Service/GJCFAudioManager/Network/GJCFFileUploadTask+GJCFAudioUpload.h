//
//  GJCFFileUploadTask+GJCFAudioUpload.h
//  GJCommonFoundation
//
//  Created by KivenLin on 14-9-18.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJCFFileUploadTask.h"
#import "GJCFAudioModel.h"

@protocol GJCFAudioUploadTaskDelegate <NSObject>

@required

/* The task back to the results of binding into a document model, how binding through the agreement to allow users to achieve their own */
- (GJCFAudioModel *)uploadTask:(GJCFFileUploadTask *)task formateReturnResult:(NSDictionary *)resultDict;

@end

@interface GJCFFileUploadTask (GJCFAudioUpload)

+ (GJCFFileUploadTask *)taskWithAudioFile:(GJCFAudioModel*)audioFile withObserver:(NSObject*)observer withTaskIdentifier:(NSString **)taskIdentifier;

@end
