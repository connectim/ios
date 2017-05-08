//
//  GJCFAudioRecordSettings.h
//  GJCommonFoundation
//
//  Created by KivenLin on 14-9-16.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface GJCFAudioRecordSettings : NSObject

//采样率
@property (nonatomic,assign)CGFloat sampleRate;

/*
kAudioFormatLinearPCM               = 'lpcm',
kAudioFormatAC3                     = 'ac-3',
kAudioFormat60958AC3                = 'cac3',
kAudioFormatAppleIMA4               = 'ima4',
kAudioFormatMPEG4AAC                = 'aac ',
kAudioFormatMPEG4CELP               = 'celp',
kAudioFormatMPEG4HVXC               = 'hvxc',
kAudioFormatMPEG4TwinVQ             = 'twvq',
kAudioFormatMACE3                   = 'MAC3',
kAudioFormatMACE6                   = 'MAC6',
kAudioFormatULaw                    = 'ulaw',
kAudioFormatALaw                    = 'alaw',
kAudioFormatQDesign                 = 'QDMC',
kAudioFormatQDesign2                = 'QDM2',
kAudioFormatQUALCOMM                = 'Qclp',
kAudioFormatMPEGLayer1              = '.mp1',
kAudioFormatMPEGLayer2              = '.mp2',
kAudioFormatMPEGLayer3              = '.mp3',
kAudioFormatTimeCode                = 'time',
kAudioFormatMIDIStream              = 'midi',
kAudioFormatParameterValueStream    = 'apvs',
kAudioFormatAppleLossless           = 'alac',
kAudioFormatMPEG4AAC_HE             = 'aach',
kAudioFormatMPEG4AAC_LD             = 'aacl',
kAudioFormatMPEG4AAC_ELD            = 'aace',
kAudioFormatMPEG4AAC_ELD_SBR        = 'aacf',
kAudioFormatMPEG4AAC_ELD_V2         = 'aacg',
kAudioFormatMPEG4AAC_HE_V2          = 'aacp',
kAudioFormatMPEG4AAC_Spatial        = 'aacs',
kAudioFormatAMR                     = 'samr',
kAudioFormatAudible                 = 'AUDB',
kAudioFormatiLBC                    = 'ilbc',
kAudioFormatDVIIntelIMA             = 0x6D730011,
kAudioFormatMicrosoftGSM            = 0x6D730031,
kAudioFormatAES3                    = 'aes3'
*/
@property (nonatomic,assign)NSInteger Formate;

//Sampling bits default 16 / * value is an integer, one of: 8, 16, 24, 32 */
@property (nonatomic,assign)NSInteger LinearPCMBitDepth;

//The number of channels
@property (nonatomic,assign)NSInteger numberOfChnnels;

//Big end or small end is the organization of memory
@property (nonatomic,assign)BOOL  LinearPCMIsBigEndian;

//Whether the sampled signal is an integer or a floating point
@property (nonatomic,assign)BOOL  LinearPCMIsFloat;

/* Returns the current set of dictionaries */
@property (nonatomic,readonly)NSDictionary *settingDict;

/*
AVAudioQualityMin    = 0,
AVAudioQualityLow    = 0x20,
AVAudioQualityMedium = 0x40,
AVAudioQualityHigh   = 0x60,
AVAudioQualityMax    = 0x7F
*/
//Audio coding quality
@property (nonatomic,assign)NSInteger EncoderAudioQuality;


+ (GJCFAudioRecordSettings *)defaultQualitySetting;

+ (GJCFAudioRecordSettings *)lowQualitySetting;

+ (GJCFAudioRecordSettings *)highQualitySetting;

+ (GJCFAudioRecordSettings *)MaxQualitySetting;

@end
