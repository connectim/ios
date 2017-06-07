//
//  LMLinkManDataManager.h
//  Connect
//
//  Created by bitmain on 2017/2/13.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LMLinkManDataManagerDelegate <NSObject>

- (void)listChange:(NSMutableArray *)linkDataArray withTabBarCount:(NSUInteger)count;

@end

@interface LMLinkManDataManager : NSObject
@property(weak, nonatomic) id <LMLinkManDataManagerDelegate> delegate;

// set up
+ (instancetype)sharedManager;

#pragma mark - The outside world needs the method, the contact is in use
/**
 *  get common group
 *
 */
- (NSMutableArray *)getListCommonGroup;
/**
 *  get all friend
 *
 */
- (NSMutableArray *)getListFriendsArr;
/**
 *  get sort data
 *
 */
- (NSMutableArray *)getListGroupsFriend;
/**
 *  get indexs
 *
 */
- (NSMutableArray *)getListIndexs;
/**
 *  get indexs
 *
 */
- (NSMutableArray *)getOffenFriend;
/**
 *  clear all array
 *
 */
- (void)clearArrays;
/**
 *  get user message
 *
 */
- (void)getAllLinkMan;
/**
 *  clear unread bridge
 *
 */
- (void)clearUnreadCountWithType:(int)type;
#pragma mark - The outside world needs the method to share in use
/**
 *  get share contact
 *
 */
- (NSMutableArray *)getListGroupsFriend:(AccountInfo *)shareContact;
#pragma mark - Externally provided method, select transfer contact in use
/**
 *  get Friends Arr No Connect
 *
 */
- (NSMutableArray *)getFriendsArrWithNoConnect;
#pragma mark - Externally provided method, Choose a business card in use
/**
 *  get Friends Arr No Connect
 *
 */
- (NSMutableArray *)getFriendsArrWith:(AccountInfo *)info;

@end
