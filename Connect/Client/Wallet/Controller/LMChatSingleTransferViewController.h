//
//  LMChatSingleTransferViewController.h
//  Connect
//
//  Created by Edwin on 16/7/26.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMBaseViewController.h"
#import "AccountInfo.h"

@interface LMChatSingleTransferViewController : LMBaseViewController

/**
 *  transfer message
 */
@property(nonatomic, strong) AccountInfo *info;

/**
 *  get transfer message
 */
@property(nonatomic, copy) void (^didGetTransferMoney)(NSString *money, NSString *hashId, NSString *notes);
@end
