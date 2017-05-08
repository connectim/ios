//
//  GJGCChatBaseCell.h
//  Connect
//
//  Created by KivenLin on 14-10-17.
//  Copyright (c) 2014年 ConnectSoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GJGCCommonFontColorStyle.h"
#import "GJGCChatBaseCell.h"
#import "GJCFCoreTextContentView.h"

#define kMaxContentHeight AUTO_HEIGHT(150)

@interface GJGCChatSystemNotiBaseCell : GJGCChatBaseCell

@property(nonatomic, strong) GJCFCoreTextContentView *timeLabel;

@property(nonatomic, strong) GJCFCoreTextContentView *titleLabel;

@property(nonatomic, strong) UIImageView *activeImageView;

@property(nonatomic, assign) CGFloat timeContentMargin;

@property(nonatomic, strong) GJCFCoreTextContentView *contentLabel;

@property(nonatomic, strong) UIImageView *accessoryIndicator;

@property(nonatomic, strong) UIImageView *stateContentView;

@property(nonatomic, assign) BOOL showAccesoryIndicator;

@property(nonatomic, assign) CGFloat contentBordMargin;

@property(nonatomic, assign) CGFloat contentInnerMargin;


- (void)tapCell;

- (CGFloat)cellHeight;

@end
