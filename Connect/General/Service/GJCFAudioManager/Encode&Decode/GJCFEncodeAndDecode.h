//
//  GJCFEncodeAndDecode.h
//  GJCommonFoundation
//
//  Created by KivenLin on 14-9-16.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GJCFAudioModel.h"

/*
 * IOS support its own format is Wav format,
 * We will need to convert files into Wav format are considered to be temporary encoding files
 */
@interface GJCFEncodeAndDecode : NSObject

/* Changing the audio file to AMR format creates an AMR-encoded temporary file for it */
+ (BOOL)convertAudioFileToAMR:(GJCFAudioModel *)audioFile;

/* Change the audio file to WAV format */
+ (BOOL)convertAudioFileToWAV:(GJCFAudioModel *)audioFile;

@end
