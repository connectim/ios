//
//  AppDelegate.h
//  Connect
//
//  Created by MoHuilin on 16/5/9.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainTabController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property(strong, nonatomic) UIWindow *window;

- (void)showMainTabPage:(id)userInfo;

@property(nonatomic, strong) AccountInfo *currentUser;

@property(nonatomic, copy) NSString *deviceToken; //apns

- (void)resetMainTabController;

/**
 * get main tab controller
 * @return
 */
- (MainTabController *)shareMainTabController;

/**
 * reset main tab controller
 */
- (void)changeLanguageResetMainTabController;

@end

