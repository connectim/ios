//
//  BtcTool.h
//  Connect
//
//  Created by MoHuilin on 16/7/28.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

extern const NSString *BTCPrivkeyKey;
extern const NSString *BTCAddressKey;
extern const NSString *BTCPublicKey;


@interface BtcTool : NSObject

/**
   * Create a BTC
   Extern const NSString * BTCPrivkeyKey;
   Extern const NSString * BTCAddressKey;
   Extern const NSString * BTCPublicKey;
   *
   * @return
 */
+ (NSDictionary *)createNewBTC;

/**
   * User-defined random number to create BTC
   * Extern const NSString * BTCPrivkeyKey;
   Extern const NSString * BTCAddressKey;
   Extern const NSString * BTCPublicKey;
 
   * @param randomString random number
 *
 *  @return
 */
+ (NSDictionary *)createNewBTCWithCustomRandomString:(NSString *)randomString;

+ (NSInteger)estimateFeeWithUnspentLength:(NSInteger)len sendLength:(NSInteger)sendLen;

+ (BOOL)haveDustWithAmount:(long long)amount;

@end
