//
//  GJCFAudioManager.m
//  GJCommonFoundation
//
//  Created by KivenLin on 14-9-16.
//  Copyright (c) 2014年 ConnectSoft. All rights reserved.
//

#import "GJCFAudioManager.h"
#import "GJCFAudioRecord.h"
#import "GJCFAudioPlayer.h"
#import "GJCFAudioNetwork.h"
#import "GJCFAudioNetworkDelegate.h"
#import "GJCFEncodeAndDecode.h"
#import "GJCFAudioFileUitil.h"

@interface GJCFAudioManager ()<GJCFAudioNetworkDelegate,GJCFAudioPlayerDelegate,GJCFAudioRecordDelegate>

@property (nonatomic,strong)GJCFAudioRecord *audioRecorder;

@property (nonatomic,strong)GJCFAudioPlayer *audioPlayer;

@property (nonatomic,strong)GJCFAudioNetwork *audioNetwork;

@property (nonatomic,strong)GJCFAudioModel *currentRecordAudioFile;

@property (nonatomic,strong)NSMutableArray *downloadAudioFileUniqueIdentifiers;

@property (nonatomic,copy)GJCFAudioManagerDidFaildUploadCurrentRecordFileBlock uploadFaildBlock;

@property (nonatomic,copy)GJCFAudioManagerDidFinishUploadCurrentRecordFileBlock uploadFinishBlock;

@property (nonatomic,copy)GJCFAudioManagerDidFaildGetRemoteFileDurationBlock durationGetFaildBlock;

@property (nonatomic,copy)GJCFAudioManagerDidFinishGetRemoteFileDurationBlock durationGetSuccessBlock;

@property (nonatomic,copy)GJCFAudioManagerShouldShowPlaySoundMouterBlock playMouterBlock;

@property (nonatomic,copy)GJCFAudioManagerShouldShowRecordSoundMouterBlock recordMouterBlock;

@property (nonatomic,copy)GJCFAudioManagerDidFinishPlayCurrentAudioBlock finishPlayBlock;

@property (nonatomic,copy)GJCFAudioManagerShouldShowPlayProgressBlock playProgressBlock;

@property (nonatomic,copy)GJCFAudioManagerShouldShowPlayProgressDetailBlock playProgressDetailBlock;

@property (nonatomic,copy)GJCFAudioManagerDidFinishRecordCurrentAudioBlock recordFinishBlock;

@property (nonatomic,copy)GJCFAudioManagerUploadAudioFileProgressBlock uploadProgressBlock;

@property (nonatomic,copy)GJCFAudioManagerUploadCompletionBlock uploadCompletionBlock;

@property (nonatomic,copy)GJCFAudioManagerStartPlayRemoteUrlBlock startPlayRemoteBlock;

@property (nonatomic,copy)GJCFAudioManagerPlayRemoteUrlFaildByDownloadErrorBlock remotePlayFaildBlock;

@property (nonatomic,copy)GJCFAudioManagerPlayFaildBlock playFaildBlock;

@property (nonatomic,copy)GJCFAudioManagerRecordFaildBlock recordFaildBlock;

@end

@implementation GJCFAudioManager

+ (GJCFAudioManager *)shareManager
{
    static GJCFAudioManager *_audioManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
       
        if (!_audioManager) {
            _audioManager = [[self alloc]init];
        }
    });
    return _audioManager;
}

- (id)init
{
    if (self = [super init]) {

        self.downloadAudioFileUniqueIdentifiers = [[NSMutableArray alloc]init];
        
        /* Recording module */
        self.audioRecorder = [[GJCFAudioRecord alloc]init];
        /* If the external set up the agent, want to take over, then let the external take over */
        if (self.recordDelegate) {
            self.audioRecorder.delegate = self.recordDelegate;
        }else{
            self.audioRecorder.delegate = self;
        }
        
        /* Play the module */
        self.audioPlayer = [[GJCFAudioPlayer alloc]init];
        
        /* If the external set up the agent, want to take over, then let the external take over */
        if (self.playerDelegate) {
            self.audioPlayer.delegate = self.playerDelegate;
        }else{
            self.audioPlayer.delegate = self;
        }
        
        /* Network data module */
        self.audioNetwork = [[GJCFAudioNetwork alloc]init];
        
        /* If the external set up the agent, want to take over, then let the external take over */
        if (self.networkDelegate) {
            
            self.audioNetwork.delegate = self.networkDelegate;
        }else{
            self.audioNetwork.delegate = self;
        }
    }
    return self;
}

- (void)setRecordDelegate:(id<GJCFAudioRecordDelegate>)recordDelegate
{
    if (!recordDelegate) {
        return;
    }
    if (_recordDelegate == recordDelegate) {
        return;
    }
    _recordDelegate = recordDelegate;
    self.audioRecorder.delegate = _recordDelegate;
}

- (void)setPlayerDelegate:(id<GJCFAudioPlayerDelegate>)playerDelegate
{
    if (!playerDelegate) {
        return;
    }
    if (_playerDelegate == playerDelegate) {
        return;
    }
    _playerDelegate = playerDelegate;
    self.audioPlayer.delegate = _playerDelegate;
}

- (void)setNetworkDelegate:(id<GJCFAudioNetworkDelegate>)networkDelegate
{
    if (!networkDelegate) {
        return;
    }
    if (_networkDelegate == networkDelegate) {
        return;
    }
    _networkDelegate = networkDelegate;
    self.audioNetwork.delegate = _networkDelegate;
}

#pragma mark - public method

/* Access the current recording file information */
- (GJCFAudioModel *)getCurrentRecordAudioFile
{
    return [self.audioRecorder getCurrentRecordAudioFile];
}

/* Access the current play file information */
- (GJCFAudioModel *)getCurrentPlayAudioFile
{
    return [self.audioPlayer getCurrentPlayingAudioFile];
}

- (void)startRecord
{
    if (!self.audioRecorder) {
        
        DDLogInfo(@"GJCFAudioManager startRecord setting no audioRecord or recordDelegate");
        
        return;
    }
    
    /* If the current recording file is not uploaded, then delete this recording */
    if (!self.currentRecordAudioFile.isBeenUploaded) {
        
        /* Start the recording before the current file wav files and temporary transcoding files are deleted */
        DDLogInfo(@"GJCFAudioManager Re-start recording, clear the current recording file data start ...");
        [self.currentRecordAudioFile deleteTempEncodeFile];
        [self.currentRecordAudioFile deleteWavFile];
        DDLogInfo(@"GJCFAudioManager Re-start recording, clear the current recording file data is complete ...");
        
    }
    

    /* Start recording */
    self.audioRecorder.limitRecordDuration = 0.f;//There is no time limit by default
    [self.audioRecorder startRecord];
}

- (void)startRecordWithLimitDuration:(NSTimeInterval)limitSeconds
{
    if (!self.audioRecorder) {
        
        DDLogInfo(@"GJCFAudioManager startRecord setting no audioRecord or recordDelegate");
        
        return;
    }
    
    /* If the current recording file is not uploaded, then delete this recording */
    if (!self.currentRecordAudioFile.isBeenUploaded) {
        
        /* Start the recording before the current file wav files and temporary transcoding files are deleted */
        DDLogInfo(@"GJCFAudioManager Re-start recording, clear the current recording file data start ...");
        [self.currentRecordAudioFile deleteTempEncodeFile];
        [self.currentRecordAudioFile deleteWavFile];
        DDLogInfo(@"GJCFAudioManager Re-start recording, clear the current recording file data start ...");
        
    }
    
    /* startRecord */
    self.audioRecorder.limitRecordDuration = limitSeconds;
    [self.audioRecorder startRecord];
}

- (void)finishRecord
{
    if (self.audioRecorder.isRecording == NO) {
        
        return;
    }
    
    [self.audioRecorder finishRecord];
}
- (void)cancelCurrentRecord
{
    if (!self.audioRecorder) {
        return;
    }
    if (!self.audioRecorder.isRecording) {
        return;
    }
    [self.audioRecorder cancelRecord];
}
- (void)stopPlayCurrentAudio
{
    if (!self.audioPlayer) {
        return;
    }
    if (!self.audioPlayer.isPlaying) {
        return;
    }
    [self.audioPlayer stop];
}
- (void)startPlayFromLastStopTimestamp
{
    if (!self.audioPlayer) {
        return;
    }
    if (self.audioPlayer.isPlaying) {
        return;
    }
    [self.audioPlayer play];
}

- (void)pausePlayCurrentAudio
{
    if (!self.audioPlayer) {
        return;
    }
    if (!self.audioPlayer.isPlaying) {
        return;
    }
    [self.audioPlayer pause];
}

- (void)playCurrentRecodFile
{
    DDLogInfo(@"GJCFAudioManager Start playing the current recording file");

    [self.audioPlayer playAudioFile:self.currentRecordAudioFile];
}

/* Play the local specified audio file */
- (void)playLocalWavFile:(NSString *)audioFilePath
{
    if (!audioFilePath) {
        return;
    }
    GJCFAudioModel *existAudio = [[GJCFAudioModel alloc]init];
    existAudio.localStorePath = audioFilePath;
    
    [self playAudioFile:existAudio];
}

- (void)playAudioFile:(GJCFAudioModel *)audioFile
{
    if (!audioFile) {
        return;
    }
    if (!self.audioPlayer) {
        return;
    }
    
    if (!audioFile.localStorePath) {
        
        DDLogInfo(@"GJCFAudioManager Error: Play no audio file path");
        
        return;
    }
    
    NSData *fileData = [NSData dataWithContentsOfFile:audioFile.localStorePath];
    if (!fileData) {
        DDLogInfo(@"GJCFAudioManager Error: Play an audio file path without actual data");
        return;
    }
    [self.audioPlayer playAudioFile:audioFile];
}

- (void)playRemoteAudioFileByUrl:(NSString *)remoteAudioUrl
{
    if (!remoteAudioUrl) {
        return;
    }
    
    /* Detects whether the local has a corresponding wav file */
    NSString *localWavPath = [GJCFAudioFileUitil localWavPathForRemoteUrl:remoteAudioUrl];
    NSData *fileData = [NSData dataWithContentsOfFile:localWavPath];
    
    /* Make sure there is a path and have data */
    if (localWavPath && fileData) {

        GJCFAudioModel *existAudio = [[GJCFAudioModel alloc]init];
        existAudio.localStorePath = localWavPath;
        
        DDLogInfo(@"GJCFAudioManager Play the downloaded audio file:%@",existAudio.localStorePath);
        [self playAudioFile:existAudio];
        
        /* Start playing the observation call of the remote file */
        if (self.startPlayRemoteBlock) {
            self.startPlayRemoteBlock(remoteAudioUrl,localWavPath);
        }
        
        return;
    }
    
    NSString *fileIdentifier = nil;
    [self.audioNetwork downloadAudioFileWithUrl:remoteAudioUrl withFinishDownloadPlayCheck:YES withFileUniqueIdentifier:&fileIdentifier];
    [self.downloadAudioFileUniqueIdentifiers objectAddObject:fileIdentifier];
}

- (void)startUploadCurrentRecordFile
{
    DDLogInfo(@"GJCFAudioManager Start uploading the recording file");
    
    /* If the current recording file has been uploaded directly return to the successful results */
    if (self.currentRecordAudioFile.remotePath) {
        
        DDLogInfo(@"GJCFAudioManager The current recording file has been uploaded, directly return to a already uploaded audio file remote address:%@",self.currentRecordAudioFile.remotePath);
        
        if (self.uploadFinishBlock) {
            self.uploadFinishBlock(self.currentRecordAudioFile.remotePath);
        }
        if (self.uploadCompletionBlock) {
            self.uploadCompletionBlock(self.currentRecordAudioFile.localStorePath,YES,self.currentRecordAudioFile.remotePath);
        }
        return;
    }
    
    if (self.currentRecordAudioFile) {
        
        [self startUploadAudioFile:self.currentRecordAudioFile];
        
    }
}

- (void)startUploadAudioFile:(GJCFAudioModel *)audioFile
{
    if (!audioFile) {
        return;
    }

    if (self.audioNetwork) {
        
        /* Usually in order to upload after the cache does not occupy, we will transcode the temporary file after the completion of the deletion */
        audioFile.isDeleteWhileUploadFinish = YES;
        [self.audioNetwork uploadAudioFile:audioFile];
    }
}

/* Gets the length of the specified local path audio file */
- (NSTimeInterval)getDurationForLocalWavPath:(NSString *)localAudioFilePath
{
    return [self.audioPlayer getLocalWavFileDuration:localAudioFilePath];
}

/* Get the length of the network audio file */
- (void)getDurationForRemoteUrl:(NSString *)remoteUrl withFinish:(GJCFAudioManagerDidFinishGetRemoteFileDurationBlock)finishBlock withFaildBlock:(GJCFAudioManagerDidFaildGetRemoteFileDurationBlock)faildBlock
{
    if (!remoteUrl) {
        if (faildBlock) {
            NSError *error = [NSError errorWithDomain:@"gjcf.AuidoManager.com" code:-235 userInfo:@{@"msg": @"没有远程地址"}];
            faildBlock(remoteUrl,error);
        }
        return;
    }
    
    NSString *localWavPath = [GJCFAudioFileUitil localWavPathForRemoteUrl:remoteUrl];
    
    if (localWavPath && [NSData dataWithContentsOfFile:localWavPath]) {
        
        NSTimeInterval duration = [self getDurationForLocalWavPath:localWavPath];
        
        if (finishBlock) {
            finishBlock(remoteUrl,duration);
        }
        return;
    }
    
    /* Block assignment */
    if (self.durationGetSuccessBlock) {
        self.durationGetSuccessBlock = nil;
    }
    self.durationGetSuccessBlock = finishBlock;
    if (self.durationGetFaildBlock) {
        self.durationGetFaildBlock = nil;
    }
    self.durationGetFaildBlock = faildBlock;

    /* Go to download this audio file to the local */
    NSString *fileIdentifier = nil;
    [self.audioNetwork downloadAudioFileWithUrl:remoteUrl withFinishDownloadPlayCheck:NO withFileUniqueIdentifier:&fileIdentifier];
    [self.downloadAudioFileUniqueIdentifiers objectAddObject:fileIdentifier];
}

/* Start uploading the currently recorded audio file */
- (void)startUploadCurrentRecordFileWithFinish:(GJCFAudioManagerDidFinishUploadCurrentRecordFileBlock)finishBlock withFaildBlock:(GJCFAudioManagerDidFaildUploadCurrentRecordFileBlock)faildBlock
{
    if (!self.currentRecordAudioFile) {
        return;
    }
    
    if (self.uploadFinishBlock) {
        self.uploadFinishBlock = nil;
    }
    if (self.uploadFaildBlock) {
        self.uploadFaildBlock = nil;
    }
    self.uploadFaildBlock = faildBlock;
    self.uploadFinishBlock = finishBlock;
    
    [self startUploadCurrentRecordFile];
}

/* Set the observed recording volume waveform */
- (void)setShowRecordSoundMouter:(GJCFAudioManagerShouldShowRecordSoundMouterBlock)recordBlock
{
    if (self.recordMouterBlock) {
        self.recordMouterBlock = nil;
    }
    self.recordMouterBlock = recordBlock;
}

/* Set the observed playback volume waveform */
- (void)setShowPlaySoundMouter:(GJCFAudioManagerShouldShowPlaySoundMouterBlock)playBlock
{
    if (self.playMouterBlock) {
        self.playMouterBlock = nil;
    }
    self.playMouterBlock = playBlock;
}



/* Observe the progress of the play*/
- (void)setCurrentAudioPlayProgressBlock:(GJCFAudioManagerShouldShowPlayProgressBlock)progressBlock
{
    if (self.playProgressBlock) {
        self.playProgressBlock = nil;
    }
    self.playProgressBlock = progressBlock;
}

/* Observe the progress of the broadcast */
- (void)setCurrentAudioPlayProgressDetailBlock:(GJCFAudioManagerShouldShowPlayProgressDetailBlock)progressDetailBlock
{
    if (self.playProgressDetailBlock) {
        self.playProgressDetailBlock = nil;
    }
    self.playProgressDetailBlock = progressDetailBlock;
}
- (void)setCurrentAudioPlayFinishedBlock:(GJCFAudioManagerDidFinishPlayCurrentAudioBlock)finishBlock
{
    if (self.finishPlayBlock) {
        self.finishPlayBlock = nil;
    }
    self.finishPlayBlock = finishBlock;
}

- (void)setFinishRecordCurrentAudioBlock:(GJCFAudioManagerDidFinishRecordCurrentAudioBlock)finishBlock
{
    if (self.recordFinishBlock) {
        self.recordFinishBlock = nil;
    }
    self.recordFinishBlock = finishBlock;
}

- (void)setCurrentAudioUploadProgressBlock:(GJCFAudioManagerUploadAudioFileProgressBlock)progressBlock
{
    if (self.uploadProgressBlock) {
        self.uploadProgressBlock = nil;
    }
    self.uploadProgressBlock = progressBlock;
}
- (void)setCurrentAudioUploadCompletionBlock:(GJCFAudioManagerUploadCompletionBlock)completionBlock
{
    if (self.uploadCompletionBlock) {
        self.uploadCompletionBlock = nil;
    }
    self.uploadCompletionBlock = completionBlock;
}
- (void)setStartRemoteUrlPlayBlock:(GJCFAudioManagerStartPlayRemoteUrlBlock)startRemoteBlock
{
    if (self.startPlayRemoteBlock) {
        self.startPlayRemoteBlock = nil;
    }
    self.startPlayRemoteBlock = startRemoteBlock;
}
- (void)setFaildPlayRemoteUrlBlock:(GJCFAudioManagerPlayRemoteUrlFaildByDownloadErrorBlock)playErrorBlock
{
    if (self.remotePlayFaildBlock) {
        self.remotePlayFaildBlock = nil;
    }
    self.remotePlayFaildBlock = playErrorBlock;
}
- (void)setFaildPlayAudioBlock:(GJCFAudioManagerPlayFaildBlock)faildPlayBlock
{
    if (self.playFaildBlock) {
        self.playFaildBlock = nil;
    }
    self.playFaildBlock = faildPlayBlock;
}
- (void)setRecrodFaildBlock:(GJCFAudioManagerRecordFaildBlock)faildRecordBlock
{
    if (self.recordFaildBlock) {
        self.recordFaildBlock = nil;
    }
    self.recordFaildBlock = faildRecordBlock;
}
- (void)clearAllCurrentObserverBlocks
{
    /* Clear the recording action being performed */
    [self.audioPlayer stop];
    [self.audioRecorder cancelRecord];
    
    if (self.durationGetSuccessBlock) {
        self.durationGetSuccessBlock = nil;
    }
    
    if (self.durationGetFaildBlock) {
        self.durationGetFaildBlock = nil;
    }
    
    if (self.uploadFinishBlock) {
        self.uploadFinishBlock = nil;
    }
    
    if (self.uploadFaildBlock) {
        self.uploadFaildBlock = nil;
    }
    
    if (self.recordMouterBlock) {
        self.recordMouterBlock = nil;
    }
    
    if (self.playMouterBlock) {
        self.playMouterBlock = nil;
    }
    
    if (self.playProgressBlock) {
        self.playProgressBlock = nil;
    }
    
    if (self.finishPlayBlock) {
        self.finishPlayBlock = nil;
    }
    
    if (self.recordFinishBlock) {
        self.recordFinishBlock = nil;
    }
    
    if (self.uploadProgressBlock) {
        self.uploadProgressBlock = nil;
    }
    
    if (self.uploadCompletionBlock) {
        self.uploadCompletionBlock = nil;
    }

    
}
#pragma mark - Network data upload proxy

- (GJCFAudioModel *)audioNetwork:(GJCFAudioNetwork *)audioNetwork formateUploadResult:(GJCFAudioModel *)baseResultModel formateDict:(NSDictionary *)formateDict
{
    DDLogInfo(@"GJCFAudioManager upload finish:%@",formateDict);

    /* Here have to judge whether the upload is really successful */
    if ([[formateDict objectForKey:@"status"] intValue] == 0) {
        
        /* According to the current content of the IM format to deal with the object Model */
        baseResultModel.remotePath = [formateDict objectForKey:@"data"];
        
        /* Remote file and local file to establish a relationship */
        [GJCFAudioFileUitil createRemoteUrl:baseResultModel.remotePath relationWithLocalWavPath:baseResultModel.localStorePath];
        self.currentRecordAudioFile.remotePath = baseResultModel.remotePath;
        
        /* Upload completed if you want to delete the temporary transcoding file*/
        if (baseResultModel.isDeleteWhileUploadFinish) {
            
            if (baseResultModel.tempEncodeFilePath) {
                
                
                BOOL deleteTempEncodeFileResult = [GJCFAudioFileUitil deleteTempEncodeFileWithPath:baseResultModel.tempEncodeFilePath];
                
                /* The transcoded file has been deleted */
                if (deleteTempEncodeFileResult) {
                    
                    baseResultModel.tempEncodeFilePath = nil;
                }
                
            }
        }
        
        return baseResultModel;

    }else{
        
        /* upload failure */
        return nil;
    }
}

- (void)audioNetwork:(GJCFAudioNetwork *)audioNetwork finishUploadAudioFile:(GJCFAudioModel *)audioFile
{
    DDLogInfo(@"GJCFAudioManager upload success:%@",audioFile);
    
    if (self.uploadFinishBlock) {
        
        self.uploadFinishBlock(audioFile.remotePath);
    }

    if (self.uploadCompletionBlock) {
        self.uploadCompletionBlock(audioFile.localStorePath,YES,audioFile.remotePath);
    }
}

- (void)audioNetwork:(GJCFAudioNetwork *)audioNetwork forAudioFile:(NSString *)audioFileLocalPath uploadFaild:(NSError *)error
{
    DDLogInfo(@"GJCFAudioManager upload failure:%@",error);
    
    if (self.uploadFaildBlock) {
        
        self.uploadFaildBlock(error);
    }
    
    if (self.uploadCompletionBlock) {
        self.uploadCompletionBlock(audioFileLocalPath,NO,nil);
    }

}

- (void)audioNetwork:(GJCFAudioNetwork *)audioNetwork forAudioFile:(NSString *)audioFileLocalPath uploadProgress:(CGFloat)progress
{
    DDLogInfo(@"GJCFAudioManager upload progress:%f",progress);
    if (self.uploadProgressBlock) {
        
        self.uploadProgressBlock(audioFileLocalPath,progress);
    }
}

#pragma mark - Network data download agent
- (void)audioNetwork:(GJCFAudioNetwork *)audioNetwork finishDownloadWithAudioFile:(GJCFAudioModel *)audioFile
{

    DDLogInfo(@"GJCFAudioManager Need transcoding files:%d",audioFile.isNeedConvertEncodeToSave);
    
    DDLogInfo(@"GJCFAudioManager Need transcoding to complete the play:%d",audioFile.shouldPlayWhileFinishDownload);
    
    /* Judgment is not the type of transcoding */
    if (audioFile.isNeedConvertEncodeToSave) {
        
        BOOL convertEncodeResult = [GJCFEncodeAndDecode convertAudioFileToWAV:audioFile];
        
        DDLogInfo(@"GJCFAudioManager Transcoding results:%d",convertEncodeResult);
        
        /* Transcoding Successful acquisition of audio */
        if (convertEncodeResult) {
            
            if (self.durationGetSuccessBlock) {
                
                NSTimeInterval duration = [self getDurationForLocalWavPath:audioFile.localStorePath];
                
                self.durationGetSuccessBlock(audioFile.remotePath,duration);
            }
            
        }else{
            
            if (self.durationGetFaildBlock) {
                
                NSError *faildError = [NSError errorWithDomain:@"gjcf.AudioManager.com" code:-234 userInfo:@{@"msg": @"GJCFAuidoManager Transcoding failed"}];
                self.durationGetFaildBlock(audioFile.remotePath,faildError);
            }
        }
        
        /* Transcoding */
        if (convertEncodeResult) {
            
            /* Transcoding after the establishment of a remote address and local wav to establish a relationship, to avoid duplication of downloads */
            BOOL shipCreateState =[GJCFAudioFileUitil createRemoteUrl:audioFile.remotePath relationWithLocalWavPath:audioFile.localStorePath];
            if (shipCreateState) {
                
                DDLogInfo(@"GJCFAudioManager Remote address and local transcode after the wav file to establish a successful relationship");
                
            }else{
                
                DDLogInfo(@"GJCFAudioManager Remote address and local transcode after the wav file to establish a relationship failure");
                
            }
            
        }
        
        
        /* If transcoding is successful */
        if (convertEncodeResult) {
            
            if (audioFile.shouldPlayWhileFinishDownload) {
                
                DDLogInfo(@"GJCFAudioManager download finish:%@",audioFile);

                /* Call the player to play*/
                [self.audioPlayer playAudioFile:audioFile];
                
                if (self.startPlayRemoteBlock) {
                    self.startPlayRemoteBlock(audioFile.remotePath,audioFile.localStorePath);
                }
                
                DDLogInfo(@"GJCFAudioManager Transcoding:%@",audioFile.localStorePath);

                return;
            }
            
        }else{
            
            
        }
    }
    
    DDLogInfo(@"GJCFAudioManager Download completed:%@",audioFile);

    /* If you do not need transcoding, request to play immediately */
    if (audioFile.shouldPlayWhileFinishDownload) {
        
        /* Call the player to play */
        [self.audioPlayer playAudioFile:audioFile];
        
        if (self.startPlayRemoteBlock) {
            self.startPlayRemoteBlock(audioFile.remotePath,audioFile.localStorePath);
        }
        
        DDLogInfo(@"GJCFAudioManager Not transcoding play:%@",audioFile.localStorePath);

    }
    

}

- (void)audioNetwork:(GJCFAudioNetwork *)audioNetwork forAudioFile:(NSString *)audioFileUnique downloadProgress:(CGFloat)progress
{
    DDLogInfo(@"GJCFAudioManager dowmload :%@ progress:%f",audioFileUnique,progress);
}

- (void)audioNetwork:(GJCFAudioNetwork *)audioNetwork forAudioFile:(NSString *)audioFileUnique downloadFaild:(NSError *)error
{
    DDLogInfo(@"GJCFAudioManager download :%@ error :%@",audioFileUnique,error);
    if (self.durationGetFaildBlock) {
        self.durationGetFaildBlock(audioFileUnique,error);
    }
    if (self.remotePlayFaildBlock) {
        self.remotePlayFaildBlock(audioFileUnique);
    }
}

#pragma mark - Recording management
- (void)audioRecord:(GJCFAudioRecord *)audioRecord didFaildByMinRecordDuration:(NSTimeInterval)minDuration
{
    DDLogInfo(@"GJCFAudioManager The recording reaches the limit time:%lf",minDuration);
    if (self.recordFaildBlock) {
        self.recordFaildBlock([audioRecord getCurrentRecordAudioFile].localStorePath);
    }
}

- (void)audioRecord:(GJCFAudioRecord *)audioRecord didOccusError:(NSError *)error
{
    DDLogInfo(@"GJCFAudioManager Recording error:%@",error);
    if (self.recordFaildBlock) {
        self.recordFaildBlock([audioRecord getCurrentRecordAudioFile].localStorePath);
    }

}

- (void)audioRecord:(GJCFAudioRecord *)audioRecord finishRecord:(GJCFAudioModel *)resultAudio
{
    self.currentRecordAudioFile = resultAudio;
    
    /* Create an AMR transcoding file */
    [GJCFEncodeAndDecode convertAudioFileToAMR:self.currentRecordAudioFile];
    
    /* Get the recording time */
    if (self.recordFinishBlock) {
        
        GJCFAudioModel *currentRecordFile = [audioRecord getCurrentRecordAudioFile];
        
        self.recordFinishBlock(currentRecordFile.localStorePath,currentRecordFile.duration);
    }
    
}

- (void)audioRecord:(GJCFAudioRecord *)audioRecord limitDurationProgress:(CGFloat)progress
{
    DDLogInfo(@"GJCFAudioManager record progress :%f",progress);

}

- (void)audioRecord:(GJCFAudioRecord *)audioRecord soundMeter:(CGFloat)soundMeter
{
    DDLogInfo(@"GJCFAudioManager Recording input :%f",soundMeter);
    if (self.recordMouterBlock) {
        self.recordMouterBlock(soundMeter*100);
    }
}

- (void)audioRecordDidCancel:(GJCFAudioRecord *)audioRecord
{
    DDLogInfo(@"GJCFAudioManager Recording canceled");
}

#pragma mark - Play management
- (void)audioPlayer:(GJCFAudioPlayer *)audioPlay didFinishPlayAudio:(GJCFAudioModel *)audioFile
{
    DDLogInfo(@"GJCFAudioManager Play done:%@",audioFile.localStorePath);
    
    if (self.finishPlayBlock) {
        self.finishPlayBlock(audioFile.localStorePath);
    }
}

- (void)audioPlayer:(GJCFAudioPlayer *)audioPlay didOccusError:(NSError *)error
{
    DDLogInfo(@"GJCFAudioManager Play error:%@",error);
    if (self.playFaildBlock) {
        self.playFaildBlock ([audioPlay getCurrentPlayingAudioFile].localStorePath);
    }
}

- (void)audioPlayer:(GJCFAudioPlayer *)audioPlay playingProgress:(CGFloat)progressValue
{
    DDLogInfo(@"GJCFAudioManager Play progress:%f",progressValue);
    if (self.playProgressBlock) {
        
        NSString *currentPlayFilePath = [audioPlay currentPlayAudioFileLocalPath];
        
        NSTimeInterval currentFileDuration = [audioPlay currentPlayAudioFileDuration];
        
        self.playProgressBlock(currentPlayFilePath,progressValue,currentFileDuration);
    }
}

- (void)audioPlayer:(GJCFAudioPlayer *)audioPlay playingProgress:(NSTimeInterval)playCurrentTime duration:(NSTimeInterval)duration
{
    DDLogInfo(@"GJCFAudioManager Detailed play progress:%f s",playCurrentTime);

    if (self.playProgressDetailBlock) {
        
        NSString *currentPlayFilePath = [audioPlay currentPlayAudioFileLocalPath];

        self.playProgressDetailBlock(currentPlayFilePath,playCurrentTime,duration);
    }
}

- (void)audioPlayer:(GJCFAudioPlayer *)audioPlay didUpdateSoundMouter:(CGFloat)soundMouter
{
    DDLogInfo(@"GJCFAudioManager Play the volume waveform:%f",soundMouter);
    if (self.playMouterBlock) {
        self.playMouterBlock(soundMouter*100);
    }
}


@end
