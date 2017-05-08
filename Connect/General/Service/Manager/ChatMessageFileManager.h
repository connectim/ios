//
//  ChatMessageFileManager.h
//  Connect
//
//  Created by MoHuilin on 16/7/17.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ChatMessageFileManager : NSObject

/**
   * The main picture of the current session directory
   *
   * @param address The address of the session object
   *
   * @return
 */
+ (NSString *)mainImageCacheWithTalkUserAddress:(NSString *)address;

/**
   * The main video directory of the current session
   *
   * @param address The address of the session object
   *
   * @return
 */
+ (NSString *)mainVideoCacheWithTalkUserAddress:(NSString *)address;


/**
   * The main conversation directory of the current session
   *
   * @param address The address of the session object
   *
   * @return
 */
+ (NSString *)mainAudioCacheWithTalkUserAddress:(NSString *)address;

/**
   * Delete all message files for the current session
   *
   * @param address Address of the session object
   *
   * @return
 */
+ (BOOL)deleteRecentChatAllMessageFilesByAddress:(NSString *)address;

/**
   * Delete the corresponding message file
   *
   * @param messageID Message ID
   * @param address The session object address
   *
   * @return
 */
+ (BOOL)deleteRecentChatMessageFileByMessageID:(NSString *)messageID Address:(NSString *)address;



/**
   * Delete all chat files
   *
   * @return
 */
+ (BOOL)deleteAllMessageFile;

@end
