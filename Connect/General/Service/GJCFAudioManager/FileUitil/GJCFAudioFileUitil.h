//
//  GJCFAudioFileUitil.h
//  GJCommonFoundation
//
//  Created by KivenLin on 14-9-16.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GJCFAudioModel.h"

@interface GJCFAudioFileUitil : NSObject

/* Set the local cache path */
+ (void)setupAudioFileLocalStorePath:(GJCFAudioModel*)audioFile;

/* Set the cache address of a temporary transcoded file */
+ (void)setupAudioFileTempEncodeFilePath:(GJCFAudioModel*)audioFile;

/* Set up a temporary download file directory */
+ (void)setupTempDownLoadFilePath:(GJCFAudioModel*)audioFile userAddress:(NSString *)address message_id:(NSString *)messageid;

/* Copy the temporary encoding file of a file directly to the local cache file path */
+ (BOOL)saveAudioTempEncodeFileToLocalCacheDir:(GJCFAudioModel*)audioFile;

/* Remote address and local wav file to establish a relationship */
+ (BOOL)createRemoteUrl:(NSString*)remoteUrl relationWithLocalWavPath:(NSString*)localWavPath;

/* Delete a correspondence */
+ (BOOL)deleteShipForRemoteUrl:(NSString *)remoteUrl;

/* Check the local there is no corresponding wav file, to avoid repeated download */
+ (NSString *)localWavPathForRemoteUrl:(NSString *)remoteUrl;

/* Delete the temporary transcoding file */
+ (BOOL)deleteTempEncodeFileWithPath:(NSString *)tempEncodeFilePath;

/* Delete the Wav file for the corresponding address */
+ (BOOL)deleteWavFileByUrl:(NSString *)remoteUrl;

@end
