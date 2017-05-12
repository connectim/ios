//
//  LMUnspentCheckTool.h
//  Connect
//
//  Created by MoHuilin on 2017/1/12.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Protofile.pbobjc.h"

typedef NS_ENUM(NSInteger ,UnspentErrorType) {
    UnspentErrorTypeNoError = 0,
    UnspentErrorTypeSmallFee,
    UnspentErrorTypeChangeDust,
    UnspentErrorTypeTransferAmountDust,//Transfer amount is too small
    UnspentErrorTypeUnpackage,// The number of transactions is greater than 100 pen
    UnspentErrorTypeLackofBalance,
    UnspentErrorTypeAutoFeeTooLarge,
};

@interface LMRawTransactionModel : NSObject

@property (nonatomic ,copy) NSString *rawTrancation;

@property (nonatomic ,strong) NSArray *vtsArray;

@property (nonatomic ,assign) UnspentErrorType unspentErrorType;

@property (nonatomic ,assign) NSInteger change;

@property (nonatomic ,assign) NSInteger autoFee;

@property (nonatomic ,strong) UnspentOrderResponse *unspent;

@property (nonatomic ,strong) NSArray *toAddresses; 

@end

@interface LMUnspentCheckTool : NSObject


+ (NSInteger)estimateFeeWithUnspentLength:(NSInteger)len sendLength:(NSInteger)sendLen;

+ (BOOL)haveDustWithAmount:(long long)amount;

// To determine whether it can be packaged
+ (BOOL)checkPackgeWithRawTrancation:(LMRawTransactionModel *)rawTrancation;

+ (BOOL)checkBlanceEnoughWithRawTrancation:(LMRawTransactionModel *)rawTrancation;

// Judgment fee problem
+ (LMRawTransactionModel *)checkFeeWithRawTrancation:(LMRawTransactionModel *)rawTrancation toAddresses:(NSArray *)toAddresses;

// To determine whether the balance is sufficient
+ (BOOL)checkBlanceEnoughithRawTrancation:(LMRawTransactionModel *)rawTrancation;

// To determine whether the zero address is dirty
+ (LMRawTransactionModel *)checkChangeDustWithRawTrancation:(LMRawTransactionModel *)rawTrancation;

// To determine whether the amount of transfer address is dirty
+ (BOOL)checkToAddressAmountDustWithToAddresses:(NSArray *)toAddresses;

+ (LMRawTransactionModel *)createRawTransactionWithRawTrancation:(LMRawTransactionModel *)rawTrancation
                                                    addDustToFee:(BOOL)addDustToFee;

@end
