//
//  LMUnspentCheckTool.m
//  Connect
//
//  Created by MoHuilin on 2017/1/12.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMUnspentCheckTool.h"
#import "BtcTool.h"

@implementation LMUnspentCheckTool

+ (LMRawTransactionModel *)getRawTransactionWithUnspent:(UnspentOrderResponse *)unSpent
                                          changeAddress:(NSString *)address
                                            toAddresses:(NSArray *)toAddresses
                                           addDustToFee:(BOOL)addDustToFee{
    
    BOOL autoCaluateFee = [[MMAppSetting sharedSetting] canAutoCalculateTransactionFee];
    
    LMRawTransactionModel *tranction = [LMRawTransactionModel new];
    if (!unSpent.package) {
        tranction.unspentErrorType = UnspentErrorTypeUnpackage;
        return tranction;
    }
    
    if (autoCaluateFee) {
        // The automatic calculation fee is greater than the set value
        if (unSpent.fee > [[MMAppSetting sharedSetting] getMaxTranferFee]) {
            tranction.unspentErrorType = UnspentErrorTypeAutoFeeTooLarge;
            tranction.autoFee = unSpent.fee;
            return tranction;
        }
    }
    
    int64_t allAmount = 0;
    NSMutableArray *tvsArr = [NSMutableArray array];
    for (Unspent *info in unSpent.unspentsArray) {
        NSDictionary *tvs = @{@"vout":@(info.txOutputN),
                              @"txid":info.txHash,
                              @"scriptPubKey":info.scriptpubkey};
        [tvsArr objectAddObject:tvs];
        allAmount += info.value;
    }
    
    // The results of the local calculation and server calculations are inconsistent
    if (allAmount != unSpent.unspentAmount) {
        tranction.unspentErrorType = UnspentErrorTypeLackofBalance;
        return tranction;
    }
        
    NSInteger change = unSpent.unspentAmount - unSpent.amount - unSpent.fee;
    if (change < 0 || !unSpent.completed) {
        tranction.unspentErrorType = UnspentErrorTypeLackofBalance;
        return tranction;
    }
    BOOL changeIsDust = [BtcTool haveDustWithAmount:change];
    // Change the amount of the address is too small
    if (!addDustToFee && change > 0 && changeIsDust) {
        tranction.unspentErrorType = UnspentErrorTypeChangeDust;
        tranction.change = change;
        return tranction;
    }
    
    if (GJCFStringIsNull(address) || [KeyHandle checkAddress:address]) {
        address = [[LKUserCenter shareCenter] currentLoginUser].address;
    }
    
    
    
    // Change the address
    NSMutableDictionary *outputs = @{}.mutableCopy;
    NSInteger sendToLen = toAddresses.count;
    if (!addDustToFee && change > 0) {
        [outputs setObject:@([[[NSDecimalNumber alloc] initWithLongLong:change]
                              decimalNumberByDividingBy:[[NSDecimalNumber alloc] initWithLongLong:pow(10, 8)]].floatValue) forKey:address];
        sendToLen += 1;
    }
    for (NSDictionary *temD in toAddresses) {
        // Calculate whether there is a dirty deal in the transfer amount
        NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:[temD valueForKey:@"amount"]];
        if ([BtcTool haveDustWithAmount:[[[NSDecimalNumber alloc] initWithLongLong:pow(10, 8)]
                                         decimalNumberByMultiplyingBy:amount].longLongValue]) {
            tranction.unspentErrorType = UnspentErrorTypeTransferAmountDust;
            return tranction;
        }
        [outputs setObject:@([NSDecimalNumber decimalNumberWithString:[temD valueForKey:@"amount"]].floatValue) forKey:[temD valueForKey:@"address"]];
    }
    NSString *rawTransaction = [KeyHandle createRawTranscationWithTvsArray:tvsArr outputs:outputs];
    tranction.vtsArray = tvsArr;
    tranction.rawTrancation = rawTransaction;
    
    // The fee is too low
    if (!autoCaluateFee) {
        NSInteger estimateFee = [BtcTool estimateFeeWithUnspentLength:tvsArr.count sendLength:sendToLen];
        if (estimateFee > unSpent.fee) {
            tranction.unspentErrorType = UnspentErrorTypeSmallFee;
            return tranction;
        }
    }
    return tranction;
    
}

// To determine whether it can be packaged
+ (BOOL)checkPackgeWithRawTrancation:(LMRawTransactionModel *)rawTrancation{
    return rawTrancation.unspent.package;
}

// Determine whether the amount is sufficient
+ (BOOL)checkBlanceEnoughWithRawTrancation:(LMRawTransactionModel *)rawTrancation{
    BOOL serverCheck = rawTrancation.unspent.completed;
    BOOL localCheck = rawTrancation.unspent.unspentAmount >= rawTrancation.unspent.amount + rawTrancation.unspent.fee;
    return serverCheck && localCheck;
}


// Judgment fee problem
+ (LMRawTransactionModel *)checkFeeWithRawTrancation:(LMRawTransactionModel *)rawTrancation toAddresses:(NSArray *)toAddresses{
    BOOL autoCaluateFee = [[MMAppSetting sharedSetting] canAutoCalculateTransactionFee];
    if (autoCaluateFee) {
        // The automatic calculation fee is greater than the set value
        if (rawTrancation.unspent.fee > [[MMAppSetting sharedSetting] getMaxTranferFee]) {
            rawTrancation.unspentErrorType = UnspentErrorTypeAutoFeeTooLarge;
            rawTrancation.autoFee = rawTrancation.unspent.fee;
        }else{
            rawTrancation.unspentErrorType = UnspentErrorTypeNoError;
        }
    } else{
        NSInteger estimateFee = [BtcTool estimateFeeWithUnspentLength:rawTrancation.unspent.unspentsArray.count sendLength:toAddresses.count + 1];
        if (estimateFee > rawTrancation.unspent.fee) {
            rawTrancation.unspentErrorType = UnspentErrorTypeSmallFee;
        }else{
            rawTrancation.unspentErrorType = UnspentErrorTypeNoError;
        }
    }
    return rawTrancation;
}

// To determine whether the balance is sufficient
+ (BOOL)checkBlanceEnoughithRawTrancation:(LMRawTransactionModel *)rawTrancation{
    NSInteger change = rawTrancation.unspent.unspentAmount - rawTrancation.unspent.amount - rawTrancation.unspent.fee;
    if (change < 0) {
        return NO;
    }
    return YES;
}

//To determine whether the zero address is dirty
+ (LMRawTransactionModel *)checkChangeDustWithRawTrancation:(LMRawTransactionModel *)rawTrancation{
    NSInteger change = rawTrancation.unspent.unspentAmount - rawTrancation.unspent.amount - rawTrancation.unspent.fee;
    
    for (NSDictionary *temD in rawTrancation.toAddresses) {
        NSString *address = [temD valueForKey:@"address"];
        if ([address isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
            change += [[NSDecimalNumber decimalNumberWithString:[temD valueForKey:@"amount"]] decimalNumberByMultiplyingBy:[[NSDecimalNumber alloc] initWithLongLong:pow(10, 8)]].longLongValue;
            break;
        }
    }

    BOOL changeIsDust = [BtcTool haveDustWithAmount:change];
    // Change the amount of the address is too small
    if (change > 0 && changeIsDust) {
        rawTrancation.unspentErrorType = UnspentErrorTypeChangeDust;
        rawTrancation.change = change;
    } else{
        rawTrancation.unspentErrorType = UnspentErrorTypeNoError;
    }
    return rawTrancation;
}

//  To determine whether the amount of transfer address is dirty
+ (BOOL)checkToAddressAmountDustWithToAddresses:(NSArray *)toAddresses{
    for (NSDictionary *temD in toAddresses) {
        // Calculate whether there is a dirty deal in the transfer amount
        NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:[temD valueForKey:@"amount"]];
        if ([BtcTool haveDustWithAmount:[[[NSDecimalNumber alloc] initWithLongLong:pow(10, 8)]
                                         decimalNumberByMultiplyingBy:amount].longLongValue]) {
            
            return YES;
        }
    }
    return NO;
}

+ (LMRawTransactionModel *)createRawTransactionWithRawTrancation:(LMRawTransactionModel *)rawTrancation
                                                    addDustToFee:(BOOL)addDustToFee{
    NSMutableArray *tvsArr = [NSMutableArray array];
    for (Unspent *info in rawTrancation.unspent.unspentsArray) {
        NSDictionary *tvs = @{@"vout":@(info.txOutputN),
                              @"txid":info.txHash,
                              @"scriptPubKey":info.scriptpubkey};
        [tvsArr objectAddObject:tvs];
    }
    int64_t change = rawTrancation.unspent.unspentAmount - rawTrancation.unspent.amount - rawTrancation.unspent.fee;
    NSMutableDictionary *outputs = @{}.mutableCopy;
    for (NSDictionary *temD in rawTrancation.toAddresses) {
        NSString *address = [temD valueForKey:@"address"];
        if ([address isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
            change += [[NSDecimalNumber decimalNumberWithString:[temD valueForKey:@"amount"]] decimalNumberByMultiplyingBy:[[NSDecimalNumber alloc] initWithLongLong:pow(10, 8)]].longLongValue;
        } else{
            [outputs setObject:@([NSDecimalNumber decimalNumberWithString:[temD valueForKey:@"amount"]].floatValue) forKey:address];
        }
    }
    if (!addDustToFee && change > 0) {
        [outputs setObject:@([[[NSDecimalNumber alloc] initWithLongLong:change]
                              decimalNumberByDividingBy:[[NSDecimalNumber alloc] initWithLongLong:pow(10, 8)]].floatValue) forKey:[[LKUserCenter shareCenter] currentLoginUser].address];
    }

    NSString *rawTransaction = [KeyHandle createRawTranscationWithTvsArray:tvsArr outputs:outputs];
    rawTrancation.vtsArray = tvsArr;
    rawTrancation.rawTrancation = rawTransaction;

    return rawTrancation;
}

+ (LMRawTransactionModel *)getRawTransactionAddDustChangeToFeeWithUnspent:(UnspentOrderResponse *)unspent
                                                              toAddresses:(NSArray *)toAddresses{
    return [self getRawTransactionWithUnspent:unspent changeAddress:nil toAddresses:toAddresses addDustToFee:YES];
}

+ (LMRawTransactionModel *)getRawTransactionSetMaxFeeWithUnspent:(UnspentOrderResponse *)unspent
                                                              toAddresses:(NSArray *)toAddresses{
    unspent.fee = [[MMAppSetting sharedSetting] getMaxTranferFee];
    return [self getRawTransactionWithUnspent:unspent changeAddress:nil toAddresses:toAddresses addDustToFee:NO];
}

@end


@implementation LMRawTransactionModel
@end
