//
//  ChatPageTitleView.h
//  Connect
//
//  Created by MoHuilin on 16/10/14.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, ChatPageTitleViewStyle) {
    ChatPageTitleViewStyleNomarl = 0,
    ChatPageTitleViewStyleSnapChat,
};

@interface ChatPageTitleView : UIView

@property(nonatomic, strong) UILabel *titleLabel;

@property(nonatomic, strong) UIImageView *snapChatImageView;

@property(copy, nonatomic) NSString *title;

@property(nonatomic, assign) ChatPageTitleViewStyle chatStyle;

@end
