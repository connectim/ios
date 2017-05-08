//
//  GJCFEncodeAndDecode.m
//  GJCommonFoundation
//
//  Created by KivenLin on 14-9-16.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJCFEncodeAndDecode.h"
#import "VoiceConverter.h"
#import "GJCFAudioFileUitil.h"

@implementation GJCFEncodeAndDecode

/* Changing the audio file to AMR format creates an AMR-encoded temporary file for it*/
+ (BOOL)convertAudioFileToAMR:(GJCFAudioModel *)audioFile
{
    /* If there is no WAV cache path, then it can not be transferred */
    if (!audioFile.localStorePath) {
        
        NSLog(@"GJCFEncodeAndDecode 错误:没有可转码的本地Wav文件路径");
        
        return NO;
    }
    
    /* Set the path of an amr temporary encoding file */
    if (!audioFile.tempEncodeFilePath) {
        
        [GJCFAudioFileUitil setupAudioFileTempEncodeFilePath:audioFile];

    }
    
    if (!audioFile.tempEncodeFilePath) {
        
        NSLog(@"GJCFEncodeAndDecode Error: There is no way to save transcoded audio files");
        
        return NO;
    }
    
    /* Start conversion */
    int result = [VoiceConverter wavToAmr:audioFile.localStorePath amrSavePath:audioFile.tempEncodeFilePath];
    
    if (result) {
        
        NSLog(@"GJCFEncodeAndDecode wavToAmr succeeded:%@",audioFile.tempEncodeFilePath);
        
    }else{
        NSLog(@"GJCFEncodeAndDecode wavToAmr failed:%@",audioFile.tempEncodeFilePath);
    }
    return result;
}

/* Change the audio file to WAV format */
+ (BOOL)convertAudioFileToWAV:(GJCFAudioModel *)audioFile
{
    /* If there is no temporary encoding file cache path, then it can not be transferred */
    if (!audioFile.tempWamFilePath) {
        
        DDLogInfo(@"TempWamFilePath Error: There is no temporary audio file that can be used to transcode");
        
        return NO;
    }
    
    /* Set up a path that needs to be converted to Wav */
    if (!audioFile.localAMRStorePath) {
        
        DDLogInfo(@"LocalAMRStorePath Error: There is no temporary audio file that can be used for transcoding");

    }
    
    /* Start conversion */
    int result = [VoiceConverter amrToWav:audioFile.localAMRStorePath wavSavePath:audioFile.tempWamFilePath];
    
    if (result) {
        
        
        DDLogInfo(@"GJCFEncodeAndDecode amrToWav transcode successful:%@",audioFile.tempWamFilePath);
        
        return YES;
        
    }else{
        
        NSLog(@"GJCFEncodeAndDecode amrToWav faild");
        
        return NO;
        
    }
    
    return result;
}


@end
