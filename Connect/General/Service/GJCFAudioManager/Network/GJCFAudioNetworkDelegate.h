//
//  GJCFAudioNetworkDelegate.h
//  GJCommonFoundation
//
//  Created by KivenLin on 14-9-16.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GJCFAudioNetwork;

@protocol GJCFAudioNetworkDelegate <NSObject>

@required

/* The user must pass this to know the return result format into the GJCFAudioModel object, otherwise the upload failed */
- (GJCFAudioModel *)audioNetwork:(GJCFAudioNetwork *)audioNetwork formateUploadResult:(GJCFAudioModel *)baseResultModel formateDict:(NSDictionary *)formateDict;

@optional

/* This protocol must return the correct Audio object, you must implement the above format method */
- (void)audioNetwork:(GJCFAudioNetwork *)audioNetwork finishUploadAudioFile:(GJCFAudioModel *)audioFile;

- (void)audioNetwork:(GJCFAudioNetwork *)audioNetwork finishDownloadWithAudioFile:(GJCFAudioModel *)audioFile;

- (void)audioNetwork:(GJCFAudioNetwork *)audioNetwork forAudioFile:(NSString *)audioFileLocalPath uploadFaild:(NSError *)error;

- (void)audioNetwork:(GJCFAudioNetwork *)audioNetwork forAudioFile:(NSString *)audioFileUnique downloadFaild:(NSError *)error;

- (void)audioNetwork:(GJCFAudioNetwork *)audioNetwork forAudioFile:(NSString *)audioFileLocalPath uploadProgress:(CGFloat)progress;

- (void)audioNetwork:(GJCFAudioNetwork *)audioNetwork forAudioFile:(NSString *)audioFileUnique downloadProgress:(CGFloat)progress;

@end
