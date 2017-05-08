//
//  GJGCChatInputExpandEmojiPanel.h
//  Connect
//
//  Created by KivenLin on 14-10-28.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GJGCChatContentEmojiParser.h"
#import "GJGCChatInputExpandEmojiPanelMenuBarDataSource.h"

@class GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem;

#define kMeunBarHeight AUTO_HEIGHT(370)

@interface GJGCChatInputExpandEmojiPanel : UIView

+ (instancetype)sharedInstance;

- (void)removeEmojiOberverWithIdentifier:(NSString *)identifier;

- (void)addEmojiOberverWithIdentifier:(NSString *)identifier;

@end
