//
//  RedBagNetWorkTool.h
//  Connect
//
//  Created by MoHuilin on 16/8/29.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Protofile.pbobjc.h"

@interface RedBagNetWorkTool : NSObject


// System red envelopes
+ (void)grabSystemRedBagWithHashId:(NSString *)hashId complete:(void (^)(GrabRedPackageResp *response,NSError *error))complete;
+ (void)getSystemRedBagDetailWithHashId:(NSString *)hashId complete:(void (^)(RedPackageInfo *bagInfo,NSError *error))complete;

// Grab a red envelope
+ (void)grabRedBagWithHashId:(NSString *)hashId complete:(void (^)(GrabRedPackageResp *response,NSError *error))complete;

/**
   * Send a red envelope
   *
   * @param address
   * @param privkey private key
   * @ Param fee
   * @param identifier object ID
   * @amam money
   * @param size number of red envelopes
   * @param category red envelope type
   * @param tips tips text
 *  @param complete
 */
+ (void)sendRedBagWithSendAddress:(NSString *)address privkey:(NSString *)privkey fee:(long long)fee identifer:(NSString *)identifier money:(long long int)money size:(int)size category:(int)category type:(int)type tips:(NSString *)tips complete:(void (^)(OrdinaryRedPackage *ordinaryRed,UnspentOrderResponse *unspent, NSArray *toAddresses,NSError *error))complete;


/**
   * Check the red envelope details
   *
   * @param hashId query ID
   * @param complete
 */
+ (void)getRedBagDetailWithHashId:(NSString *)hashId complete:(void (^)(RedPackageInfo *bagInfo,NSError *error))complete;

@end
