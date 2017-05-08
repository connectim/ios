//
//  SetUserInfoPage.h
//  Connect
//
//  Created by MoHuilin on 16/5/11.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseViewController.h"

@interface SetUserInfoPage : BaseViewController

// new method
- (instancetype)initWithStr:(NSString *)dataStr;

- (instancetype)initWithPrikey:(NSString *)prikey;

- (instancetype)initWithStr:(NSString *)str mobile:(NSString *)mobile token:(NSString *)token;

@end
