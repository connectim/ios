//
//  GJGCChatContentEmojiParser.h
//  Connect
//
//  Created by KivenLin on 14-11-26.
//  Copyright (c) 2014年 ConnectSoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GJGCChatContentEmojiParser : NSObject

/**
 * sharedParser
 * @return
 */
+ (GJGCChatContentEmojiParser *)sharedParser;

/**
 * parse text content to express\phone\url
 * @param string
 * @return
 */
- (NSDictionary *)parseContent:(NSString *)string;

/**
 * check string is wallet url
 * @param sourceString
 * @return
 */
- (BOOL)isWalletUrlString:(NSString *)sourceString;

/**
 * get image by image name
 * @param pngName
 * @return
 */
- (UIImage *)imageForEmotionPNGName:(NSString *)pngName;

/**
 * prepareResources in backgroup theard
 */
- (void)prepareResources;

/**
 * get emoji
 * @param path
 * @return
 */
- (NSArray *)getEmojiArrayWithPath:(NSString *)path;
/**
 * get emoji groups
 * @return
 */
- (NSArray *)getEmojiGroups;

/**
 * parse text message content
 * @param originString
 * @param tempString
 * @param resultArray
 */
- (void)parseEmoji:(NSMutableString *)originString withEmojiTempString:(NSMutableString *)tempString withResultArray:(NSMutableArray *)resultArray;

@end
