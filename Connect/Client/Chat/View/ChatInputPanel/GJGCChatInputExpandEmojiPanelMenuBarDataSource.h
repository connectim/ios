//
//  GJGCChatInputExpandEmojiPanelMenuBarDataSource.h
//  Connect
//
//  Created by KivenLin on 15/6/4.
//  Copyright (c) 2015年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem.h"


@interface LMEmotionModel : NSObject

@property(nonatomic, copy) NSString *text;//like：[food]
@property(nonatomic, copy) NSString *localText;// like：[食物] [food] [other languge]
@property(nonatomic, copy) NSString *imagePNG;
@property(nonatomic, copy) NSString *imageGIF;

@end

@interface GJGCChatInputExpandEmojiPanelMenuBarDataSource : NSObject

+ (NSArray *)menuBarItems;

+ (NSArray *)commentBarItems;

@end
