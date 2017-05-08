//
//  GJCFAudioFileUitil.m
//  GJCommonFoundation
//
//  Created by KivenLin on 14-9-16.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJCFAudioFileUitil.h"
#import "GJCFEncodeAndDecode.h"
#import "GJCFUitils.h"
#import "GJCFCachePathManager.h"

#import "LKUserCenter.h"

/* Main cache directory */
static NSString *  GJCFAudioFileCacheDirectory = @"AudioFileCacheDirectory";

/* Save the converted encoded audio file */
static NSString *  GJCFAudioFileCacheSubTempEncodeFileDirectory = @"AudioFileCacheSubTempEncodeFileDirectory";

/* Temporary download directory */
static NSString *  GJCFAudioAudioAmrFileCacheFileDirectory = @"AudioAmrFileCache";


/* Local audio Wav file and remote address relationship table */
static NSString *  GJCFAudioFileRemoteLocalWavFileShipList = @"AudioFileRemoteLocalWavFileShipList.plist";

@implementation GJCFAudioFileUitil

#pragma mark - Create the cache home directory
+ (NSString *)cacheDirectory
{
    /* Create a default path */
    NSString *cacheDirectory = [[GJCFCachePathManager shareManager] mainAudioCacheDirectory];
    
    /* Create a subfolder that stores temporary transcoding files */
    NSString *subTempFileDir = [cacheDirectory stringByAppendingPathComponent:GJCFAudioFileCacheSubTempEncodeFileDirectory];

    if (!GJCFFileDirectoryIsExist(subTempFileDir)) {
        GJCFFileDirectoryCreate(subTempFileDir);
    }
    
    return cacheDirectory;
}

#pragma mark - public method


/* Create a new recording file storage path */
+ (NSString*)createAudioNewRecordLocalStorePath
{
    NSString *fileName = [NSString stringWithFormat:@"%@.wav",GJCFStringCurrentTimeStamp];
    
    return [[self cacheDirectory]stringByAppendingPathComponent:fileName];
}

+ (void)setupAudioFileLocalStorePath:(GJCFAudioModel*)audioFile
{
    if (!audioFile) {
        return;
    }
    
    NSString *fileName = [NSString stringWithFormat:@"%@.%@",GJCFStringCurrentTimeStamp,audioFile.extensionName];

    audioFile.fileName = fileName;
    
    NSString *randomPath = [[self cacheDirectory]stringByAppendingPathComponent:fileName];
    
    audioFile.localStorePath = randomPath;
}

/* Set the cache address of a temporary transcoded file */
+ (void)setupAudioFileTempEncodeFilePath:(GJCFAudioModel*)audioFile
{
    if (!audioFile) {
        return;
    }
    
    NSString *fileName = [NSString stringWithFormat:@"%@.%@",GJCFStringCurrentTimeStamp,audioFile.tempEncodeFileExtensionName];

    audioFile.tempWamFilePath = fileName;
    
    NSString *tempFilePath = [[[self cacheDirectory]stringByAppendingPathComponent:GJCFAudioFileCacheSubTempEncodeFileDirectory]stringByAppendingPathComponent:fileName];
    
    audioFile.tempEncodeFilePath = tempFilePath;
    
}

+ (void)setupTempDownLoadFilePath:(GJCFAudioModel*)audioFile userAddress:(NSString *)address message_id:(NSString *)messageid{
    if (!audioFile) {
        return;
    }
    
    NSString *tempFilePath = [[[[self cacheDirectory]
                                 stringByAppendingPathComponent:GJCFAudioAudioAmrFileCacheFileDirectory]
                                stringByAppendingPathComponent:address]
                               stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].address];
    
    if (!GJCFFileDirectoryIsExist(tempFilePath)) {
        GJCFFileDirectoryCreate(tempFilePath);
    }
    
    audioFile.tempWamFilePath = [tempFilePath stringByAppendingPathComponent:messageid];
}

/*Copy the temporary encoding file of a file directly to the local cache file path */
+ (BOOL)saveAudioTempEncodeFileToLocalCacheDir:(GJCFAudioModel*)audioFile
{
    if (!audioFile) {
        return NO;
    }
    
    if (!audioFile.tempEncodeFilePath) {
        return NO;
    }
    if (!audioFile.localStorePath) {
        [GJCFAudioFileUitil setupAudioFileLocalStorePath:audioFile];
    }
    
    return GJCFFileCopyFileIsRemove(audioFile.tempEncodeFilePath, audioFile.localStorePath, audioFile.isDeleteWhileFinishConvertToLocalFormate);
}

/* Remote address and local wav file to establish a relationship */
+ (BOOL)createRemoteUrl:(NSString*)remoteUrl relationWithLocalWavPath:(NSString*)localWavPath
{
    NSString *shipListFilePath = [[self cacheDirectory]stringByAppendingPathComponent:GJCFAudioFileRemoteLocalWavFileShipList];
    
    if (![[NSFileManager defaultManager]fileExistsAtPath:shipListFilePath]) {
        
        NSMutableDictionary *shipList = [NSMutableDictionary dictionary];
        [shipList setObject:localWavPath forKey:remoteUrl];
        
        NSData *archieveData = [NSKeyedArchiver archivedDataWithRootObject:shipList];
        
       return [archieveData writeToFile:shipListFilePath atomically:YES];
    }
    
    NSData *listData = [NSData dataWithContentsOfFile:shipListFilePath];
    NSMutableDictionary *shipListDict = [NSKeyedUnarchiver unarchiveObjectWithData:listData];
    
    [shipListDict setObject:localWavPath forKey:remoteUrl];
    
    NSData *archieveData = [NSKeyedArchiver archivedDataWithRootObject:shipListDict];

    return [archieveData writeToFile:shipListFilePath atomically:YES];
}

/* Delete a correspondence */
+ (BOOL)deleteShipForRemoteUrl:(NSString *)remoteUrl
{
    NSString *shipListFilePath = [[self cacheDirectory]stringByAppendingPathComponent:GJCFAudioFileRemoteLocalWavFileShipList];
    if (![[NSFileManager defaultManager]fileExistsAtPath:shipListFilePath]) {
        
        return YES;
    }
    
    NSData *listData = [NSData dataWithContentsOfFile:shipListFilePath];
    NSMutableDictionary *shipListDict = [NSKeyedUnarchiver unarchiveObjectWithData:listData];
    
    [shipListDict removeObjectForKey:remoteUrl];
    
    NSData *archieveData = [NSKeyedArchiver archivedDataWithRootObject:shipListDict];
    
    return [archieveData writeToFile:shipListFilePath atomically:YES];
}

/* Check the local there is no corresponding wav file, to avoid repeated download */
+ (NSString *)localWavPathForRemoteUrl:(NSString *)remoteUrl
{
    NSString *shipListFilePath = [[self cacheDirectory]stringByAppendingPathComponent:GJCFAudioFileRemoteLocalWavFileShipList];
    if (!shipListFilePath) {
        
        return nil;
    }
    
    NSData *listData = [NSData dataWithContentsOfFile:shipListFilePath];
    NSMutableDictionary *shipListDict = [NSKeyedUnarchiver unarchiveObjectWithData:listData];
    
    return [shipListDict objectForKey:remoteUrl];
}

/* Check the local there is no corresponding wav file, to avoid repeated download */
+ (BOOL)deleteTempEncodeFileWithPath:(NSString *)tempEncodeFilePath
{
    if (!tempEncodeFilePath || [tempEncodeFilePath isEqualToString:@""]) {
        return YES;
    }
    
    if (![[NSFileManager defaultManager]fileExistsAtPath:tempEncodeFilePath]) {
        return YES;
    }
    
    NSError *deleteError = nil;
    [[NSFileManager defaultManager] removeItemAtPath:tempEncodeFilePath error:&deleteError];
    
    if (deleteError) {
        return NO;
        
    }else{

        return YES;
    }
}

/* Delete the Wav file for the corresponding address */
+ (BOOL)deleteWavFileByUrl:(NSString *)remoteUrl
{
    if (!remoteUrl) {
        return YES;
    }
    
    /* Gets the corresponding wav address */
    NSString *wavPath = [GJCFAudioFileUitil localWavPathForRemoteUrl:remoteUrl];
    
    if (!wavPath) {
        return YES;
    }
    
    /* Delete Files */
    BOOL deleteFileResult = [self deleteTempEncodeFileWithPath:wavPath];
    
    if (deleteFileResult) {
        
        /* Delete the local correspondence */
       [self deleteShipForRemoteUrl:remoteUrl];
        
        return YES;
        
    }else{
        
        return YES;
    }
    
}

@end
