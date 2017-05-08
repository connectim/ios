//
//  BtcTool.m
//  Connect
//
//  Created by MoHuilin on 16/7/28.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BtcTool.h"
#import "KeyHandle.h"

NSString *BTCPrivkeyKey = @"btc_privkey_key";
NSString *BTCAddressKey = @"btc_address_key";
NSString *BTCPublicKey = @"btc_publickey_key";


@implementation BtcTool

+ (NSDictionary *)createNewBTC{
    
    NSString *randomString = [KeyHandle createRandom512bits];
    
    NSString *privkey = [KeyHandle creatNewPrivkeyByRandomStr:randomString];
    
    NSString *address = [KeyHandle getAddressByPrivKey:privkey];
    
    NSString *publicKey = [KeyHandle createPubkeyByPrikey:privkey];
    
    return @{BTCPublicKey:publicKey,
             BTCAddressKey:address,
             BTCPrivkeyKey:privkey};
    
}


+ (NSInteger)estimateFeeWithUnspentLength:(NSInteger)txs_length sendLength:(NSInteger)sentToLength{
    
    // Add a zero address
    sentToLength += 1;
    
    NSInteger txSize = 148 * txs_length + 34 * sentToLength + 10;
    double estimateFee = (txSize + 20 + 4 + 34 + 4) / 1000.0 * [[MMAppSetting sharedSetting] getEstimatefee];
    return estimateFee * pow(10, 8);
}

+ (BOOL)haveDustWithAmount:(long long)amount{
    return (amount * 1000 / (3 * 182)) < [[MMAppSetting sharedSetting] getEstimatefee] * pow(10, 8) * 5 / 10;
}


@end
