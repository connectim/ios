//
//  LocalAccountLoginPage.h
//  Connect
//
//  Created by MoHuilin on 16/5/12.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseViewController.h"

@interface LocalAccountLoginPage : BaseViewController

/**
 *  Mobile download users use this method to create
 *
 *  @param downUser download user
 *
 *  @return 
 */
- (instancetype)initWithUser:(AccountInfo *)downUser;


/**
 *  Mobile local users
 *
 *  @param
 *
 *  @return
 */
- (instancetype)initWithLocalUsers:(NSArray *)users;

- (void)showLogoutTipWithInfo:(id)info;

@end
