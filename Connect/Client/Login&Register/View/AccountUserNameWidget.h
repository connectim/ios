//
//  AccountUserNameWidget.h
//  Connect
//
//  Created by MoHuilin on 16/5/12.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AccountInfo.h"

@interface AccountUserNameWidget : UIControl

@property(nonatomic, strong) AccountInfo *account;

- (void)loadData;

@end
