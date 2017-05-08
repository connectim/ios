//
//  ServerCenter.h
//  Connect
//
//  Created by MoHuilin on 16/7/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServerInfo.h"

@class GenerateTokenResponse;

@interface ServerCenter : NSObject

+ (ServerCenter *)shareCenter;

- (ServerInfo *)getCurrentServer;

- (NSString *)getCurrentServer_userEcdhkey;
// Extended key
@property (nonatomic ,strong) NSData *extensionPass;
// Built aad
@property (nonatomic ,strong) NSData *defineAad;

@property (nonatomic ,strong) NSData *httpTokenSalt;
@property (nonatomic ,strong) GenerateTokenResponse *httpTokenResponse;
// alt expiration time
@property (nonatomic ,assign) NSTimeInterval saltDeadTime;

@end
