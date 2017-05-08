//
//  GJCFAudioRecord.m
//  GJCommonFoundation
//
//  Created by KivenLin on 14-9-16.
//  Copyright (c) 2014年 ConnectSoft. All rights reserved.
//

#import "GJCFAudioRecord.h"
#import "GJCFAudioFileUitil.h"

@interface GJCFAudioRecord ()<AVAudioRecorderDelegate>

@property (nonatomic,strong)AVAudioRecorder *audioRecord;

/* There will only be one file at a time */
@property (nonatomic,strong)GJCFAudioModel *currentRecordFile;

@property (nonatomic,strong)NSTimer *soundMouterTimer;

@property (nonatomic,assign)NSTimeInterval recordProgress;

@end

@implementation GJCFAudioRecord

- (void)dealloc
{
    if (self.soundMouterTimer) {
        
        [self.soundMouterTimer invalidate];
    }
}

#pragma mark - set up config
- (id)init
{
    if (self = [super init]) {
        
        // No default recording time limit
        self.limitRecordDuration = 0;
        
    }
    return self;
}

/* Gets the currently recorded audio file*/
- (GJCFAudioModel*)getCurrentRecordAudioFile
{
    return self.currentRecordFile;
}

- (void)createRecord
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err = nil;
    [audioSession setCategory:AVAudioSessionCategoryRecord error:&err];
    if(err){
        NSLog(@"GJCFAudioRecord audioSession: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
        return;
    }
    [audioSession setActive:YES error:&err];
    if(err){
        NSLog(@"GJCFAudioRecord audioSession: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
        return;
    }

    /* Prevent fast repetitive recording */
    if (self.audioRecord.isRecording) {
        NSError *faildError = [NSError errorWithDomain:@"gjcf.AudioManager.com" code:-236 userInfo:@{@"msg": @"GJCFAuidoRecord recording "}];
        if (self.delegate && [self.delegate respondsToSelector:@selector(audioRecord:didOccusError:)]) {
            [self.delegate audioRecord:self didOccusError:faildError];
        }
        return;
    }
    
    if (!self.recordSettings) {
        self.recordSettings = [GJCFAudioRecordSettings defaultQualitySetting];
    }
    
    if (self.currentRecordFile) {
        self.currentRecordFile = nil;
    }
    
    /* Set the timer */
    if (self.soundMouterTimer) {
        [self.soundMouterTimer invalidate];
        self.soundMouterTimer = nil;
    }
    
    /* Create a new recording file */
    self.currentRecordFile = [[GJCFAudioModel alloc]init];
    
    /* Set the new audio file to the local cache address */
    [GJCFAudioFileUitil setupAudioFileLocalStorePath:self.currentRecordFile];
    
    /* Start a new recording instance */
    if (self.audioRecord) {
        if (self.audioRecord.isRecording) {
            [self.audioRecord stop];
            [self.audioRecord deleteRecording];
        }
        self.audioRecord = nil;
    }
    
    if (!self.currentRecordFile.localStorePath) {
        NSLog(@"GJCFAudioRecord Create Error No cache path");
        return;
    }
    NSLog(@"GJCFAudioRecord Create cache path :%@",self.currentRecordFile.localStorePath);

    NSError *createRecordError = nil;
    self.audioRecord = [[AVAudioRecorder alloc]initWithURL:[NSURL URLWithString:self.currentRecordFile.localStorePath] settings:self.recordSettings.settingDict error:&createRecordError];
    self.audioRecord.delegate = self;
    self.audioRecord.meteringEnabled = YES;
    
    if (createRecordError) {
        
        NSLog(@"GJCFAudioRecord Create AVAudioRecorder Error:%@",createRecordError);
        
        [self startRecordErrorDetail];
        
        return;
    }
    
    [self.audioRecord prepareToRecord];
    
    /* Create an input volume update */
    self.soundMouterTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateSoundMouter:) userInfo:nil repeats:YES];
    [self.soundMouterTimer fire];
}

#pragma mark - Recording error handling
- (void)startRecordErrorDetail
{
    NSError *faildError = [NSError errorWithDomain:@"gjcf.AudioManager.com" code:-238 userInfo:@{@"msg": @"GJCFAuidoRecord Start recording failed"}];
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioRecord:didOccusError:)]) {
        [self.delegate audioRecord:self didOccusError:faildError];
    }
    
    /* Stop updating */
    if (self.soundMouterTimer) {
        [self.soundMouterTimer invalidate];
        self.soundMouterTimer = nil;
    }
}

#pragma mark - Recording action
- (void)startRecord
{
    /* Whether to support recording */
    [self createRecord];
    
    if (self.limitRecordDuration > 0) {
        
      _isRecording = [self.audioRecord recordForDuration:self.limitRecordDuration];
        
        if (_isRecording) {
            
            NSLog(@"GJCFAudioRecord Limit start....");
            
        }else{
            
            [self startRecordErrorDetail];
            
            NSLog(@"GJCFAudioRecord Limit start error....");
        }
        
        return;
    }
    _isRecording = [self.audioRecord record];

    if (_isRecording) {
        
        NSLog(@"GJCFAudioRecord start....");
        
    }else{
        
        [self startRecordErrorDetail];
        
        NSLog(@"GJCFAudioRecord start error....");
    }
}

- (void)updateSoundMouter:(NSTimer *)timer
{
    
    [self.audioRecord updateMeters];
    
    float soundLoudly = [self.audioRecord averagePowerForChannel:0];
    
    
    _soundMouter = pow(10, (0.05 * soundLoudly));
    
    
    if (self.delegate) {
        [self.delegate audioRecord:self soundMeter:_soundMouter];
    }
    
    /* This time is not available when the recording is complete or stopped */
    self.currentRecordFile.duration = self.audioRecord.currentTime;
    
    /* Limit the recording time to observe the progress */
    if (self.limitRecordDuration > 0) {
        
        self.recordProgress = self.audioRecord.currentTime;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(audioRecord:limitDurationProgress:)]) {
            
            [self.delegate audioRecord:self limitDurationProgress:self.recordProgress];
        }
        
        if (self.audioRecord.currentTime >= self.limitRecordDuration) {
            [self finishRecord];
            return;
        }
    }
}

- (void)finishRecord
{
    if ([self.audioRecord isRecording]) {
        [self.audioRecord stop];
        _isRecording = NO;
    }
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err = nil;
    [audioSession setCategory:AVAudioSessionCategoryAmbient error:&err];
    [audioSession setActive:NO error:&err];
}

- (void)cancelRecord
{
    if (!self.audioRecord) {
        return;
    }
    if (!_isRecording) {
        return;
    }
    
    [self.audioRecord stop];
    _isRecording = NO;
    self.currentRecordFile = nil;
    [self.audioRecord deleteRecording];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioRecordDidCancel:)]) {
        
        [self.delegate audioRecordDidCancel:self];
    }
}

- (NSTimeInterval)currentRecordFileDuration
{
    return self.currentRecordFile.duration;
}

#pragma mark - AVAudioRecorder Delegate

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    if (self.soundMouterTimer) {
        [self.soundMouterTimer invalidate];
        self.soundMouterTimer = nil;
    }
    
    if (flag) {
        
        /* If the recording time is less than the minimum required time */
        if (self.recordProgress < self.minEffectDuration) {
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(audioRecord:didFaildByMinRecordDuration:)]) {
                
                [self.delegate audioRecord:self didFaildByMinRecordDuration:self.minEffectDuration];
                
                _isRecording = NO;

            }
            
            return;
        }
        
        /* finish record */
        if (self.delegate && [self.delegate respondsToSelector:@selector(audioRecord:finishRecord:)]) {
            
            _isRecording = NO;

            if (self.currentRecordFile) {
                
                [self.delegate audioRecord:self finishRecord:self.currentRecordFile];
                
            }else{
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(audioRecordDidCancel:)]) {
                    
                    [self.delegate audioRecordDidCancel:self];
                }
            }
        }
        
    }
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioRecord:didOccusError:)]) {
        
        _isRecording = NO;

        [self.delegate audioRecord:self didOccusError:error];
    }
}

- (void)audioRecorderBeginInterruption:(AVAudioRecorder *)recorder
{
    
}

- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder withOptions:(NSUInteger)flags
{
    
}


@end
