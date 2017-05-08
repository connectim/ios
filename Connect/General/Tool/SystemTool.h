//
//  SystemTool.h
//  Connect
//
//  Created by MoHuilin on 16/10/10.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SystemTool : NSObject

+ (void)vibrateOrVoiceNoti;

+ (void)vibrateNoti;
+ (void)soundNoti;

+ (void)showInstantMessageVoice;

+ (BOOL)isNationChannel;
+ (BOOL)neetUploadappVerinfo;

@end
