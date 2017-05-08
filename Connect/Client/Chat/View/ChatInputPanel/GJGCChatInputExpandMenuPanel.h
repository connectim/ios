//
//  GJGCChatInputExpandMenuPanel.h
//  ZYChat
//
//  Created by KivenLin on 14-10-28.
//  Copyright (c) 2014年 ConnectSoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GJGCChatInputExpandMenuPanelItem.h"
#import "GJGCChatInputExpandMenuPanelDataSource.h"
#import "GJGCChatInputExpandMenuPanelConfigModel.h"
#import "GJGCChatInputConst.h"

@class GJGCChatInputExpandMenuPanel;

@protocol GJGCChatInputExpandMenuPanelDelegate <NSObject>

- (void)menuPanel:(GJGCChatInputExpandMenuPanel *)panel didChooseAction:(GJGCChatInputMenuPanelActionType)action;

- (GJGCChatInputExpandMenuPanelConfigModel *)menuPanelRequireCurrentConfigData:(GJGCChatInputExpandMenuPanel *)panel;

@end


@interface GJGCChatInputExpandMenuPanel : UIView

@property(nonatomic, weak) id <GJGCChatInputExpandMenuPanelDelegate> delegate;
@property(nonatomic, assign) NSInteger rowCount;
@property(nonatomic, assign) NSInteger columnCount;

- (instancetype)initWithFrame:(CGRect)frame withDelegate:(id <GJGCChatInputExpandMenuPanelDelegate>)aDelegate;

@end
