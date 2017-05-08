//
//  GJCFAudioModel.m
//  GJCommonFoundation
//
//  Created by KivenLin on 14-9-16.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJCFAudioModel.h"
#import "GJCFAudioFileUitil.h"

@implementation GJCFAudioModel

- (id)init
{
    if (self = [super init]) {
        
        self.isUploadTempEncodeFile = YES;
        self.isNeedConvertEncodeToSave = YES;
        self.isDeleteWhileFinishConvertToLocalFormate = YES;
        self.shouldPlayWhileFinishDownload = NO;
        
        _uniqueIdentifier = [self currentTimeStamp];
        self.extensionName = @"wav";
        self.tempEncodeFileExtensionName = @"amr";
        
        self.mimeType = @"audio/amr";
    }
    return self;
}

- (NSString *)currentTimeStamp
{
    NSDate *now = [NSDate date];
    NSTimeInterval timeInterval = [now timeIntervalSinceReferenceDate];
    
    NSString *timeString = [NSString stringWithFormat:@"%lf",timeInterval];
    
    return timeString;
}
- (void)deleteTempEncodeFile
{
    if (self.tempEncodeFilePath && ![self.localStorePath isEqualToString:@""]) {
        
        [GJCFAudioFileUitil deleteTempEncodeFileWithPath:self.tempEncodeFilePath];
    }
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"文件Wav路径:%@ 远程路径:%@ 临时转码文件路径:%@",self.localStorePath,self.remotePath,self.tempEncodeFilePath];
}
- (void)deleteWavFile
{
    if (self.localStorePath && ![self.localStorePath isEqualToString:@""]) {
        
        [GJCFAudioFileUitil deleteTempEncodeFileWithPath:self.localStorePath];
        if (self.remotePath) {
            
            [GJCFAudioFileUitil deleteShipForRemoteUrl:self.remotePath];
        }
    }
}


@end
