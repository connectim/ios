//
//  GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem.h
//  Connect
//
//  Created by KivenLin on 15/6/4.
//  Copyright (c) 2015年 ConnectSoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GJGCChatInputConst.h"

@interface GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem : NSObject

@property(nonatomic, strong) NSString *faceEmojiIconName; //nomarl

@property(nonatomic, copy) NSString *faceEmojiSelectName;

@property(nonatomic, assign) GJGCChatInputExpandEmojiType emojiType;

@property(nonatomic, strong) NSString *emojiListFilePath;

@property(nonatomic, strong) NSArray *emojiArrays;

@property(nonatomic, strong) NSString *packagePrefix;

@property(nonatomic, assign) BOOL isNeedShowSendButton;

@property(nonatomic, assign) BOOL isNeedShowRightSideLine;

@end
