//
//  LMReciptNotesViewController.h
//  Connect
//
//  Created by Edwin on 16/8/10.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMBaseViewController.h"
#import "Protofile.pbobjc.h"

@interface LMReciptNotesViewController : LMBaseViewController

@property(nonatomic, strong) Bill *bill;

@property(nonatomic, strong) AccountInfo *user;

/**
 *  Payment status yes yes paid no for unpaid
 */
@property(nonatomic, assign) BOOL PayStatus;

@end
