//
//  SystemTool.m
//  Connect
//
//  Created by MoHuilin on 16/10/10.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "SystemTool.h"
#import <AudioToolbox/AudioToolbox.h>

/**
 *  Callback after system ringtone playback is complete
 */
void _SystemSoundFinishedPlayingCallback(SystemSoundID sound_id, void* user_data)
{
    AudioServicesDisposeSystemSoundID(sound_id);
}


@implementation SystemTool


+ (void)vibrateOrVoiceNoti{
#if (TARGET_IPHONE_SIMULATOR)
    
    // In the case of simulators
    
#else
    // In the case of real machine
    if ([[MMAppSetting sharedSetting]  canVibrateNoti]) {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    };
    if ([[MMAppSetting sharedSetting]  canVoiceNoti]) {
        AudioServicesPlaySystemSound(1007);
    }
#endif
}

+ (void)vibrateNoti{
#if (TARGET_IPHONE_SIMULATOR)
    
    // In the case of simulators
    
#else
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
#endif
}

+ (void)soundNoti{
#if (TARGET_IPHONE_SIMULATOR)
    
    // In the case of simulators
    
#else
    AudioServicesPlaySystemSound(1007);
#endif
}

+ (void)showInstantMessageVoice{
#if (TARGET_IPHONE_SIMULATOR)
    // in the case of simulators
#else
    // In the case of real machine
    if ([[MMAppSetting sharedSetting]  canVibrateNoti]) {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    };
    if ([[MMAppSetting sharedSetting]  canVoiceNoti]) {
        [self playShortSound:@"instant_message" soundExtension:@"wav"];
    }
#endif
}

// Play short sound
+ (void)playShortSound:(NSString *)soundName soundExtension:(NSString *)soundExtension {
#if (TARGET_IPHONE_SIMULATOR)
    // in the case of simulators
#else
    // In the case of real machine
    if ([[MMAppSetting sharedSetting]  canVoiceNoti]) {
        NSURL *audioPath = [[NSBundle mainBundle] URLForResource:soundName withExtension:soundExtension];
        // Create a system sound while returning an ID
        SystemSoundID soundID;
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)(audioPath), &soundID);
        // Register the sound completion callback.
        AudioServicesAddSystemSoundCompletion(soundID,
                                              NULL, // uses the main run loop
                                              NULL, // uses kCFRunLoopDefaultMode
                                              _SystemSoundFinishedPlayingCallback, // the name of our custom callback function
                                              NULL // for user data, but we don't need to do that in this case, so we just pass NULL
                                              );
        
        AudioServicesPlaySystemSound(soundID);
    }
#endif
}

+ (BOOL)isNationChannel{
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary]; //CFBundleIdentifier
    NSString *boundId = [infoDict objectForKey:@"CFBundleIdentifier"];
    if ([boundId isEqualToString:@"dev.connect.im"]) {
        return YES;
    }
    return NO;
}


+ (BOOL)neetUploadappVerinfo{
    NSString *key = @"NeedUpdateVersionString";
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *lastVersion = [defaults stringForKey:key];
    NSString *currentVersion = [NSBundle mainBundle].infoDictionary[key];
    if ([currentVersion isEqualToString:lastVersion]) {
        return NO;
    } else {
        [defaults setObject:currentVersion forKey:key];
        [defaults synchronize];
        return YES;
    }
}


@end
