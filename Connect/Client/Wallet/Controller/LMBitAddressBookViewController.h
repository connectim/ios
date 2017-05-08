//
//  LMBitAddressBookViewController.h
//  Connect
//
//  Created by Edwin on 16/7/21.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMBaseViewController.h"

@interface LMBitAddressBookViewController : LMBaseViewController

@property(nonatomic, copy) void (^didGetBitAddress)(NSString *address);
@property(nonatomic, copy) NSString *mainBitAddress;
@end
