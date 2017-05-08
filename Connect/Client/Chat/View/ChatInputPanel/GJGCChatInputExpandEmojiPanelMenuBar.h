//
//  GJGCChatInputExpandEmojiPanelMenuBar.h
//  Connect
//
//  Created by KivenLin on 15/6/4.
//  Copyright (c) 2015年 Connect. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GJGCChatInputExpandEmojiPanelMenuBarDataSource.h"

@interface GJGCChatInputExpandEmojiPanelMenuBarItem : UIView

@property(nonatomic, strong) UIImageView *backImgView;

@property(nonatomic, strong) UIButton *iconImgView;

@property(nonatomic, strong) UIImageView *rightSeprateLine;

- (instancetype)initWithIconName:(NSString *)iconName selectedIconName:(NSString *)selectedIcon;

- (instancetype)initWithIconName:(NSString *)iconName selectedIconName:(NSString *)selectedIcon height:(CGFloat)height;

- (void)setSeprateLineShow:(BOOL)state;

- (void)switchToSelected;

- (void)switchToNormal;

@end

@class GJGCChatInputExpandEmojiPanelMenuBar;

@protocol GJGCChatInputExpandEmojiPanelMenuBarDelegate <NSObject>

- (void)emojiPanelMenuBar:(GJGCChatInputExpandEmojiPanelMenuBar *)bar didChoose:(GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem *)emojiSourceItem selectIndex:(NSInteger)selectIndex;

@end

@interface GJGCChatInputExpandEmojiPanelMenuBar : UIView

@property(nonatomic, strong) NSArray *itemSourceArray;

@property(nonatomic, readonly) NSInteger selectedIndex;

@property(nonatomic, weak) id <GJGCChatInputExpandEmojiPanelMenuBarDelegate> delegate;

- (instancetype)initWithDelegate:(id <GJGCChatInputExpandEmojiPanelMenuBarDelegate>)aDelegate height:(CGFloat)height;

- (instancetype)initWithDelegate:(id <GJGCChatInputExpandEmojiPanelMenuBarDelegate>)aDelegate;

- (instancetype)initWithDelegateForCommentBarStyle:(id <GJGCChatInputExpandEmojiPanelMenuBarDelegate>)aDelegate;


- (void)selectAtIndex:(NSInteger)index;

@end
