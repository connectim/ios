//
//  PayTool.h
//  Connect
//
//  Created by MoHuilin on 16/9/14.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>
@class UnspentAmount;

@interface PayTool : NSObject

+ (instancetype)sharedInstance;


@property (nonatomic ,copy)  NSString *symbol;
// such as  RMB //USD RUB....
@property (nonatomic ,copy) NSString *code;

/**
   * Get wallet balance
   *
   * @param complete
 */
- (void)getBlanceWithComplete:(void (^)(NSString *blance,UnspentAmount *unspentAmount,NSError *error))complete;


/**
   * Get exchange rate
   *
   * @param complete
 */
- (void)getRateComplete:(void (^)(NSDecimalNumber *rate,NSError *error))complete;

/**
 *  pay vertification
 */
- (void)payVerfifyWithMoney:(NSString *)money controller:(UIViewController *)controller withComplete:(void (^)(BOOL result,NSString *errorMsg))complete;

- (void)payVerfifyWithMoney:(NSString *)money controller:(UIViewController *)controller withComplete:(void (^)(BOOL result,NSString *errorMsg))complete resultCallBack:(void (^)(BOOL result))resultCallBack;


- (void)payVerfifyFingerWithComplete:(void (^)(BOOL result,NSString *errorMsg))complete;


- (void)openFingerPayComplete:(void (^)(BOOL result))complete;


+ (NSString *)getBtcStringWithAmount:(long long)amount;
+ (long long)getPOW8AmountWithText:(NSString *)amountText;
+ (long long)getPOW8Amount:(NSDecimalNumber *)amount;
+ (float)getSmallAmount:(NSDecimalNumber *)amount;
+ (float)getDiviPow8SmallAmount:(NSDecimalNumber *)amount;
+ (NSString *)getBtcStringWithDecimalAmount:(NSDecimalNumber *)amount;

@end
