//
//  MainTabController.h
//  Connect
//
//  Created by MoHuilin on 16/5/22.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainTabController : UITabBarController

- (void)chatWithFriend:(AccountInfo *)chatUser;

- (void)chatWithFriend:(AccountInfo *)user withObject:(NSDictionary *)obj;

- (void)changeLanguageResetController;

@end
