//
//  LMChatRedLuckyViewController.h
//  Connect
//
//  Created by Edwin on 16/7/27.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMBaseViewController.h"
#import "LMRedLuckyShowView.h"

@class AccountInfo;
typedef enum LMChatRedLuckyStyle : NSInteger {
    LMChatRedLuckyStyleSingle = 0, // signle redpack
    LMChatRedLuckyStyleGroup = 1,  // grpoup redapck
    LMChatRedLuckyStyleOutRedBag = 2  // outer redpack
} redLuckyStyle;

@interface LMChatRedLuckyViewController : LMBaseViewController

/**
 *  Construction of red envelopes controller
 */
@property(nonatomic, copy) void (^didGetRedLuckyMoney)(NSString *money, NSString *hashId, NSString *tips);

/**
 *  @brief Construction of red envelopes controller。
 *  @param style : Construct a controller style (0. a single red envelope or a group of red envelopes)）
 *  @param reciverIdentifier : Group ID or user address
 *  @see LMChatRedLuckyStyle
 */
- (instancetype)initChatRedLuckyViewControllerWithStyle:(redLuckyStyle)style reciverIdentifier:(NSString *)reciverIdentifier;

@property(nonatomic, assign) redLuckyStyle style;            // Controller type

@property(nonatomic, strong) AccountInfo *userInfo; // users
@end
