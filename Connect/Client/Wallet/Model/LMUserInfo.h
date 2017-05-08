//
//  LMUserInfo.h
//  Connect
//
//  Created by Edwin on 16/7/16.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMUserInfo : NSObject

@property(nonatomic, copy) NSString *imageUrl;
// Multiplayer avatar collection
@property(nonatomic, strong) NSArray *imageUrls;
@property(nonatomic, copy) NSString *userName;
@property(nonatomic, copy) NSString *createdAt;
@property(nonatomic, assign) long long int balance;
@property(nonatomic, copy) NSString *category;
// confirmation status
@property(nonatomic, assign) BOOL confirmation;
@property(nonatomic, copy) NSString *hashId;
@property(nonatomic, assign) int txType;

@end
