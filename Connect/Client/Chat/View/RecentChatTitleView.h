//
//  RecentChatTitleView.h
//  Connect
//
//  Created by MoHuilin on 16/6/25.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  链接状态
 #define STATE_UNCONNECTED 0
 #define STATE_CONNECTING 1
 #define STATE_CONNECTED 2
 #define STATE_AUTHING 3
 #define STATE_GETOFFLINE 4
 #define STATE_CONNECTFAIL 5
 */
typedef NS_ENUM(NSUInteger, RecentChatConnectState) {
    RecentChatConnectStateFaild = 0,
    RecentChatConnectStateConnecting,
    RecentChatConnectStateSuccess,
    RecentChatConnectStateAuthing,
    RecentChatConnectStateGetOffline,
};

@interface RecentChatTitleView : UIView

@property(nonatomic, strong) UILabel *titleLabel;

@property(nonatomic, strong) UIActivityIndicatorView *indicatorView;

@property(nonatomic, assign) RecentChatConnectState connectState;

@end
