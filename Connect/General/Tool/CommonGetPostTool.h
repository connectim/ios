//
//  CommonGetPostTool.h
//  Connect
//
//  Created by MoHuilin on 16/6/1.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AccountInfo.h"
#import "ServerInfo.h"

#import "AesGCMTool.h"

@interface CommonGetPostTool : NSObject

/**
   * @param dataDict requires an encrypted post / get dictionary
   *
   * @return @ {@ "sign": sign,
   @ "Pub_key": currentUser.pub_key,
   @ "Data": encryptionDict};
 */
+ (NSDictionary *)signWithDecodeDataDict:(NSDictionary *)dataDict;


/**
   * Returns the URL request get
   *
   * @param apiUrl api
   *
   * @return @ "% @ sign =% @ & pub_key =% @ & timestamp =% @", apiUrl, sign, currentUser.pub_key, timestampStr
 */
+ (NSString *)getSignPubkeyAndTimestampWithAPI:(NSString *)apiUrl;

/**
 *
 *
 *  @return returns the current logged on user
 */
+ (AccountInfo *)getLoginAccountInfo;

/**
 *
 *
 *  @return returns the current server information
 */
+ (ServerInfo *)getServerInfo;

/**
   *
   * @param dataDict encapsulates the parameters
   *
   * @return @ {@ "sign": sign,
                 @ "Pub_key": currentUser.pub_key,
                 @ "Data": encryptionDict};
 */
+ (NSDictionary *)getRequestBodyDictWithDataDict:(NSDictionary *)dataDict;

@end
