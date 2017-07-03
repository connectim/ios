//
//  LKUserCenter.h
//  Connect
//
//  Created by MoHuilin on 16/6/21.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AccountInfo.h"

typedef void (^LKUserCenterLoginCompleteBlock)(NSString *privkey,NSError *error);

@interface LKUserCenter : NSObject

@property (nonatomic ,assign) BOOL isFristLogin; //注册新用户，

+ (LKUserCenter *)shareCenter;

- (void)LoginUserWithAccountUser:(AccountInfo *)loginUser
               withPassword:(NSString *)password
                    withComplete:(LKUserCenterLoginCompleteBlock)complete;
- (BOOL)isLogin;


/**
   * Currently logged in to the user
   *
   * @return
 */
- (AccountInfo *)currentLoginUser;

/**
   * The locally encrypted key
   *
   * @return
 */
- (NSString *)getLocalGCDEcodePass;

/**
 *  loginout
 */
- (void)loginOutByServerWithInfo:(id)info;

/**
 *  update user message
 *
 *  @param user login user
 */
- (void)updateUserInfo:(AccountInfo *)user;

/**
 *  Bind a new phone
 *
 *  @param phone new phone
 */
- (void)bindNewPhone:(NSString *)phone;


/**
   * Register a new user
   *
   * @param user
 */
- (void)registerUser:(AccountInfo *)user;


- (void)showCurrentPage;

- (NSString *)getLastUserPassword;

- (void)createUserTable;

- (void)updateNickname:(NSString *)nickname;

- (void)updateAvatar:(NSString *)imageUrl;

- (void)autoLogin;

- (void)createUser;

- (void)updateUsers;

- (void)deleteUser;

- (void)queryUser;

@end
