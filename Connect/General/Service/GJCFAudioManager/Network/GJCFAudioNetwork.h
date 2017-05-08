//
//  GJCFAudioNetwork.h
//  GJCommonFoundation
//
//  Created by KivenLin on 14-9-16.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GJCFFileUploadManager.h"
#import "GJCFFileDownloadManager.h"
#import "GJCFAudioModel.h"
#import "GJCFFileUploadTask+GJCFAudioUpload.h"
#import "GJCFFileDownloadTask+GJCFAudioDownload.h"
#import "GJCFAudioNetworkDelegate.h"

@interface GJCFAudioNetwork : NSObject

@property (nonatomic,strong)GJCFFileUploadManager *uploadManager;

@property (nonatomic,weak)id<GJCFAudioNetworkDelegate> delegate;

- (void)uploadAudioFile:(GJCFAudioModel *)audioFile;

- (void)downloadAudioFile:(GJCFAudioModel *)audioFile;

/* Download whether to immediately play the parameters to judge */
- (void)downloadAudioFileWithUrl:(NSString *)remoteAudioUrl withFinishDownloadPlayCheck:(BOOL)finishPlay withFileUniqueIdentifier:(NSString **)fileUniqueIdentifier;

/* Download the audio file at the specified address */
- (void)downloadAudioFileWithUrl:(NSString *)remoteAudioUrl withFileUniqueIdentifier:(NSString **)fileUniqueIdentifier;

@end
