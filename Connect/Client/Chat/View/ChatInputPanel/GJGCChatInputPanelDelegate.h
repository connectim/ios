//
//  GJGCChatInputPanelDelegate.h
//  Connect
//
//  Created by KivenLin on 14-10-28.
//  Copyright (c) 2014年 ConnectSoft. All rights reserved.
//

@class GJGCChatInputPanel;

#import "GJCFAudioModel.h"

@protocol GJGCChatInputPanelDelegate <NSObject>

@optional

/**
 *  did choose menu action
 *
 *  @param panel
 *  @param actionType GJGCChatInputMenuPanelActionType
 */
- (void)chatInputPanel:(GJGCChatInputPanel *)panel didChooseMenuAction:(GJGCChatInputMenuPanelActionType)actionType;

/**
 *  didFinishRecord
 *
 *  @param panel
 *  @param audioFile
 */
- (void)chatInputPanel:(GJGCChatInputPanel *)panel didFinishRecord:(GJCFAudioModel *)audioFile;

/**
 *  sendTextMessage
 *
 *  @param panel
 *  @param text  
 */
- (void)chatInputPanel:(GJGCChatInputPanel *)panel sendTextMessage:(NSString *)text;

/**
 *  sendGIFMessage
 *
 *  @param panel
 *  @param gifCode 
 */
- (void)chatInputPanel:(GJGCChatInputPanel *)panel sendGIFMessage:(NSString *)gifCode;

/**
 *  chatInputPanelRequiredCurrentConfigData
 *
 *  @param panel
 *  @param configData
 *
 *  @return 
 */
- (GJGCChatInputExpandMenuPanelConfigModel *)chatInputPanelRequiredCurrentConfigData:(GJGCChatInputPanel *)panel;

/**
 *  didChangeToInputBarAction
 *
 *  @param panel
 *  @param action
 */
- (void)chatInputPanel:(GJGCChatInputPanel *)panel didChangeToInputBarAction:(GJGCChatInputBarActionType)action;

@end
