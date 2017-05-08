//
//  LMTranFriendLsitViewController.h
//  Connect
//
//  Created by Edwin on 16/7/23.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMBaseViewController.h"

typedef void (^friendsListHandler)(NSMutableArray *friends);

@interface LMTranFriendLsitViewController : LMBaseViewController

@property(nonatomic, strong) NSMutableArray *dataArr;

@property(nonatomic, copy) friendsListHandler friendsHandler;

@end
