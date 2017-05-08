//
//  GJCFAudioManager.h
//  GJCommonFoundation
//
//  Created by KivenLin on 14-9-16.
//  Copyright (c) 2014年 ConnectSoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GJCFAudioPlayerDelegate.h"
#import "GJCFAudioRecordDelegate.h"
#import "GJCFAudioNetworkDelegate.h"
#import "GJCFAudioManager.h"
#import "GJCFAudioModel.h"
#import "GJCFAudioFileUitil.h"
#import "GJCFEncodeAndDecode.h"

typedef void (^GJCFAudioManagerDidFinishUploadCurrentRecordFileBlock) (NSString *remoteUrl);

typedef void (^GJCFAudioManagerDidFaildUploadCurrentRecordFileBlock) (NSError *error);

typedef void (^GJCFAudioManagerDidFinishGetRemoteFileDurationBlock) (NSString *remoteUrl, NSTimeInterval duration);

typedef void (^GJCFAudioManagerDidFaildGetRemoteFileDurationBlock) (NSString *remoteUrl, NSError *error);

typedef void (^GJCFAudioManagerShouldShowRecordSoundMouterBlock) (CGFloat recordSoundMouter);

typedef void (^GJCFAudioManagerStartPlayRemoteUrlBlock) (NSString *remoteUrl,NSString *localWavPath);

typedef void (^GJCFAudioManagerPlayRemoteUrlFaildByDownloadErrorBlock) (NSString *remoteUrl);

typedef void (^GJCFAudioManagerPlayFaildBlock) (NSString *localWavPath);

typedef void (^GJCFAudioManagerRecordFaildBlock) (NSString *localWavPath);

typedef void (^GJCFAudioManagerShouldShowPlaySoundMouterBlock) (CGFloat playSoundMouter);

typedef void (^GJCFAudioManagerShouldShowPlayProgressBlock) (NSString *audioLocalPath,CGFloat progress,CGFloat duration);

typedef void (^GJCFAudioManagerShouldShowPlayProgressDetailBlock) (NSString *audioLocalPath,NSTimeInterval playCurrentTime,NSTimeInterval duration);

typedef void (^GJCFAudioManagerDidFinishPlayCurrentAudioBlock) (NSString *audioLocalPath);

typedef void (^GJCFAudioManagerDidFinishRecordCurrentAudioBlock) (NSString *audioLocalPath,NSTimeInterval duration);

typedef void (^GJCFAudioManagerUploadAudioFileProgressBlock) (NSString *audioLocalPath,CGFloat progress);

typedef void (^GJCFAudioManagerUploadCompletionBlock) (NSString *audioLocalPath,BOOL result,NSString *remoteUrl);

@interface GJCFAudioManager : NSObject

/* If the external need to take over the playback process, then the implementation of this agent and assignment */
@property (nonatomic,weak)id<GJCFAudioPlayerDelegate> playerDelegate;

/* If the external need to take over the recording process, then the implementation of this agent and assignment */
@property (nonatomic,weak)id<GJCFAudioRecordDelegate> recordDelegate;

/* If the external need to take over the upload, download the process, then the implementation of this agent and assignment */
@property (nonatomic,weak)id<GJCFAudioNetworkDelegate> networkDelegate;

/* Create a shared singleton */
+ (GJCFAudioManager *)shareManager;

/* Access the current recording file information */
- (GJCFAudioModel *)getCurrentRecordAudioFile;

/* Access the current play file information */
- (GJCFAudioModel *)getCurrentPlayAudioFile;

/* start Record */
- (void)startRecord;

/* Start a time-limited recording */
- (void)startRecordWithLimitDuration:(NSTimeInterval)limitSeconds;

/* Complete recording */
- (void)finishRecord;

/* Cancel recording */
- (void)cancelCurrentRecord;

/* Stop play */
- (void)stopPlayCurrentAudio;

/* Pause playback */
- (void)pausePlayCurrentAudio;

/* Continue the current play */
- (void)startPlayFromLastStopTimestamp;

/*  Play the local specified audio file  */
- (void)playLocalWavFile:(NSString *)audioFilePath;

/* Play an audio file */
- (void)playAudioFile:(GJCFAudioModel *)audioFile;

/* Play the currently recorded file */
- (void)playCurrentRecodFile;

/* Play audio with a remote audio file address */
- (void)playRemoteAudioFileByUrl:(NSString *)remoteAudioUrl;

/* Gets the length of the specified local path audio file */
- (NSTimeInterval)getDurationForLocalWavPath:(NSString *)localAudioFilePath;

/* Get the length of the network audio file */
- (void)getDurationForRemoteUrl:(NSString *)remoteUrl withFinish:(GJCFAudioManagerDidFinishGetRemoteFileDurationBlock)finishBlock withFaildBlock:(GJCFAudioManagerDidFaildGetRemoteFileDurationBlock)faildBlock;

/* Set the observed recording volume waveform */
- (void)setShowRecordSoundMouter:(GJCFAudioManagerShouldShowRecordSoundMouterBlock)recordBlock;

/* Set the observed playback volume waveform */
- (void)setShowPlaySoundMouter:(GJCFAudioManagerShouldShowPlaySoundMouterBlock)playBlock;

/* Set the parameters of the authentication type when uploading to HttpHeader */
- (void)setUploadAuthorizedParamsForHttpHeader:(NSDictionary *)headerValues;

/* Set the parameters of the authentication type when uploading to params */
- (void)setUploadAuthorizedParamsForHttpRequestParams:(NSDictionary *)params;

/* Start uploading the currently recorded audio file */
- (void)startUploadCurrentRecordFile;

/* Start uploading the currently recorded audio file */
- (void)startUploadCurrentRecordFileWithFinish:(GJCFAudioManagerDidFinishUploadCurrentRecordFileBlock)finishBlock withFaildBlock:(GJCFAudioManagerDidFaildUploadCurrentRecordFileBlock)faildBlock;

/* Start uploading the specified file */
- (void)startUploadAudioFile:(GJCFAudioModel *)audioFile;

/* Observe the progress of the play */
- (void)setCurrentAudioPlayProgressBlock:(GJCFAudioManagerShouldShowPlayProgressBlock)progressBlock;

/* Observe the progress of the broadcast */
- (void)setCurrentAudioPlayProgressDetailBlock:(GJCFAudioManagerShouldShowPlayProgressDetailBlock)progressDetailBlock;

/* Observe the current play is complete */
- (void)setCurrentAudioPlayFinishedBlock:(GJCFAudioManagerDidFinishPlayCurrentAudioBlock)finishBlock;

/* Observe the recording complete */
- (void)setFinishRecordCurrentAudioBlock:(GJCFAudioManagerDidFinishRecordCurrentAudioBlock)finishBlock;

/* Observe the progress of the upload */
- (void)setCurrentAudioUploadProgressBlock:(GJCFAudioManagerUploadAudioFileProgressBlock)progressBlock;

/* Observe the upload is complete */
- (void)setCurrentAudioUploadCompletionBlock:(GJCFAudioManagerUploadCompletionBlock)completionBlock;

/* Clear all current observation blocks */
- (void)clearAllCurrentObserverBlocks;

/* Watch the playback of the remote audio file to start playback */
- (void)setStartRemoteUrlPlayBlock:(GJCFAudioManagerStartPlayRemoteUrlBlock)startRemoteBlock;

/* Watch the remote playback failed */
- (void)setFaildPlayRemoteUrlBlock:(GJCFAudioManagerPlayRemoteUrlFaildByDownloadErrorBlock)playErrorBlock;

/* Watch the playback failed */
- (void)setFaildPlayAudioBlock:(GJCFAudioManagerPlayFaildBlock)faildPlayBlock;

/* Observe the recording failed */
- (void)setRecrodFaildBlock:(GJCFAudioManagerRecordFaildBlock)faildRecordBlock;

@end
