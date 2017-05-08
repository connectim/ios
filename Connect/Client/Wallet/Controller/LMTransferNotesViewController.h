//
//  LMTransferNotesViewController.h
//  Connect
//
//  Created by Edwin on 16/8/10.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMBaseViewController.h"
#import "AccountInfo.h"
#import "Protofile.pbobjc.h"

@interface LMTransferNotesViewController : LMBaseViewController

/**
 *  transfer
 */
@property(nonatomic, strong) AccountInfo *reciverUser;

@property(nonatomic, strong) Bill *bill;

@property(nonatomic, assign) BOOL PayStatus;
// The result is a callback, and the user interface displays a record
@property(nonatomic, copy) void (^PayResultBlock)(BOOL result);

@end
