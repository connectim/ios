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

#pragma mark - 外界需要的方法

// get common group
- (NSMutableArray *)getListCommonGroup;

// get all friend
- (NSMutableArray *)getListFriendsArr;

// get sort data
- (NSMutableArray *)getListGroupsFriend;

// get indexs
- (NSMutableArray *)getListIndexs;

// clear all array
- (void)clearArrays;

// get user message
- (void)getAllLinkMan;

- (void)clearUnreadCountWithType:(int)type;

@end
