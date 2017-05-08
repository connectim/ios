//
//  GJCFAudioRecord.h
//  GJCommonFoundation
//
//  Created by KivenLin on 14-9-16.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "GJCFAudioRecordDelegate.h"
#import "GJCFAudioRecordSettings.h"

@interface GJCFAudioRecord : NSObject

@property (nonatomic,readonly)BOOL isRecording;

@property (nonatomic,readonly)CGFloat soundMouter;

@property (nonatomic,assign)NSTimeInterval limitRecordDuration;

/* Minimum time, the default 1 second */
@property (nonatomic,assign)NSTimeInterval minEffectDuration;

@property (nonatomic,weak)id<GJCFAudioRecordDelegate> delegate;

@property (nonatomic,strong)GJCFAudioRecordSettings *recordSettings;

/* Gets the currently recorded audio file */
- (GJCFAudioModel*)getCurrentRecordAudioFile;

- (void)startRecord;

- (void)finishRecord;

- (void)cancelRecord;

- (NSTimeInterval)currentRecordFileDuration;

@end
