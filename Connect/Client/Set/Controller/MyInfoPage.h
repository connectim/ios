//
//  MyInfoPage.h
//  Connect
//
//  Created by MoHuilin on 16/7/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//


#import "BaseSetViewController.h"
#import "AccountInfo.h"

typedef void (^ChangeIdBlock)();

@interface MyInfoPage : BaseSetViewController

- (instancetype)initWithUserInfo:(AccountInfo *)userInfo;

@property(strong, nonatomic) ChangeIdBlock changeIdBlock;

@end
