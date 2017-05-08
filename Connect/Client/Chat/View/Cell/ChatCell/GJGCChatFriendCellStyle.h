//
//  GJGCChatFirendCellStyle.h
//  Connect
//
//  Created by KivenLin on 14-11-10.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GJGCChatFriendCellStyle : NSObject

+ (NSString *)imageTag;

/**
 * formart text
 * @param messageText
 * @return
 */
+ (NSDictionary *)formateSimpleTextMessage:(NSString *)messageText;

/**
 *  formart audio duration time
 *
 *  @param duration
 *
 *  @return 
 */
+ (NSAttributedString *)formateAudioDuration:(NSString *)duration;

/**
 * formart group chat name
 * @param senderName
 * @return
 */
+ (NSAttributedString *)formateGroupChatSenderName:(NSString *)senderName;

@end
