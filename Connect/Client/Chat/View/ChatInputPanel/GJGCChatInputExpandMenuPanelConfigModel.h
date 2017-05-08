//
//  GJGCChatInputExpandMenuPanelConfigModel.h
//  Connect
//
//  Created by KivenLin on 15/4/21.
//  Copyright (c) 2015年 ConnectSoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GJGCChatFriendTalkModel.h"

@interface GJGCChatInputExpandMenuPanelConfigModel : NSObject

@property(nonatomic, assign) GJGCChatFriendTalkType talkType;

@property(nonatomic, strong) NSArray *disableItems;

@end
