//
//  LMQrcodeViewController.h
//  Connect
//
//  Created by Edwin on 16/7/17.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMBaseViewController.h"

@interface LMQrcodeViewController : LMBaseViewController

@property(nonatomic, copy) void (^didGetScanResult)(NSString *result, NSError *error);
@property(nonatomic, assign) BOOL isScanAddressBook;
@end
