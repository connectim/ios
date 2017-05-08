//
//  WallteNetWorkTool.m
//  Connect
//
//  Created by MoHuilin on 16/8/1.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "WallteNetWorkTool.h"
#import "Protofile.pbobjc.h"
#import "UnSpentInfo.h"
#import "KeyHandle.h"
#import "NetWorkOperationTool.h"
#import "ConnectTool.h"
#import "UIAlertController+Blocks.h"
#import "NSObject+CurrentViewController.h"
#import "LMMessageExtendManager.h"

@implementation WallteNetWorkTool

+ (void)MuiltTransferWithAddress:(NSString *)address privkey:(NSString *)privkey
                             fee:(double)feeValue toAddress:(NSArray *)toAddresses
                          amount:(long long int)perAmount tips:(NSString *)tips
                        complete:(void (^)(UnspentOrderResponse *unspent, NSArray* toAddresses, NSError *error))complete{
    if (GJCFStringIsNull(privkey)) {
        if (complete) {
            complete(nil,nil,[NSError errorWithDomain:@"Private key is empty" code:-1 userInfo:nil]);
        }

        return;
    }
    
    // Verify the legitimacy of the input
    if (GJCFStringIsNull(address) || ![KeyHandle checkAddress:address]) {
        if (complete) {
            complete(nil,nil,[NSError errorWithDomain:@"Payment address is not valid" code:-1 userInfo:nil]);
        }
        return;
    }
    if (feeValue < 0) {
        feeValue = [[MMAppSetting sharedSetting] getTranferFee];
        if (feeValue < 0) {
            feeValue = [MINNER_FEE longLongValue];
        }
    }
    
    if (toAddresses.count <= 0) {
        if (complete) {
            complete(nil,nil,[NSError errorWithDomain:@"No collection address" code:-1 userInfo:nil]);
        }
        return;
    }
    
    for (NSString *address in toAddresses) {
        if (![KeyHandle checkAddress:address]) {
            if (complete) {
                complete(nil,nil,[NSError errorWithDomain:@"Collection address is not valid" code:-1 userInfo:nil]);
            }
            return;
        }
    }
    
    //Verify payment amount
    if (perAmount <= 0) {
        if (complete) {
            complete(nil,nil,[NSError errorWithDomain:@"Payment amount can not be less than the person who is equal to 0" code:-1 userInfo:nil]);
        }
        return;
    }
    NSMutableArray *perAmountAddresses = [NSMutableArray array];
    for (NSString *address in toAddresses) {
        NSDictionary *dict = @{@"address":address,
                               @"amount":[PayTool getBtcStringWithAmount:perAmount]};
        [perAmountAddresses addObject:dict];
    }
    
    [self unspentV2WithAddress:address fee:feeValue toAddress:perAmountAddresses createRawTranscationModelComplete:^(UnspentOrderResponse *unspent, NSError *error) {
        if (error) {
            if (complete) {
                complete(nil,nil,error);
            }
        } else{
            if (complete) {
                complete(unspent,perAmountAddresses,nil);
            }
        }
    }];
}

+ (void)doMuiltTransfer:(MuiltSendBill *)muiltBill complete:(void (^)(NSData *response, NSError *error))complete{
    
    [NetWorkOperationTool POSTWithUrlString:WallteBillingMuiltSendUrl postProtoData:muiltBill.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        
        if (hResponse.code != successCode) {
            if (complete) {
                complete(nil,[NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);

            }
            return ;
        }
        NSError *error = nil;
        NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            MuiltSendBillResp *billResp = [MuiltSendBillResp parseFromData:data error:&error];
            if (!error) {
                if (complete) {
                    complete(billResp.data,nil);
                }
            } else{
                if (complete) {
                    complete(nil,error);
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(nil,error);
        }
    }];
}

+ (void)unspentV2WithAddress:(NSString *)address
                         fee:(long long )feeValue
                   toAddress:(NSArray *)toAddresses
createRawTranscationModelComplete:(void (^)(UnspentOrderResponse *unspent,NSError *error))complete{
    // Verify the legitimacy of the input
    if (GJCFStringIsNull(address) || ![KeyHandle checkAddress:address]) {
        if (complete) {
            complete(nil,[NSError errorWithDomain:@"Payment address is not valid" code:-1 userInfo:nil]);
        }
        return;
    }
    
    if (feeValue < 0) {
        feeValue = [[MMAppSetting sharedSetting] getTranferFee];
        if (feeValue < 0) {
            feeValue = [MINNER_FEE longLongValue];
        }
    }
    if (toAddresses.count <= 0) {
        if (complete) {
            complete(nil,[NSError errorWithDomain:@"No collection address" code:-1 userInfo:nil]);
        }
        return;
    }
    for (NSDictionary *temD in toAddresses) {
        if (![KeyHandle checkAddress:[temD valueForKey:@"address"]]) {
            if (complete) {
                complete(nil,[NSError errorWithDomain:@"Collection address is not valid" code:-1 userInfo:nil]);
            }
            return;
        }
    }
    if (toAddresses.count > 100) {
        if (complete) {
            complete(nil,[NSError errorWithDomain:@"The output is not greater than 100" code:-1 userInfo:nil]);
        }
        return;
    }
    long int amount = 0;
    for (NSDictionary *temD in toAddresses) {
        NSDecimalNumber *amount_ = [NSDecimalNumber decimalNumberWithString:[temD valueForKey:@"amount"]];
        NSDecimalNumber *big = [amount_ decimalNumberByMultiplyingBy:[[NSDecimalNumber alloc] initWithLong:pow(10, 8)]];
        long long oneAmount =  big.longLongValue;
        amount += oneAmount;
    }
    if (amount <= 0) {
        if (complete) {
            complete(nil,[NSError errorWithDomain:@"Payment amount can not be less than 0" code:-1 userInfo:nil]);
        }
        return;
    }
    NSString *url = [NSString stringWithFormat:WalletUsefulUnspentQueryUrl,address];
    UnspentOrder *order = [[UnspentOrder alloc] init];
    order.amount = amount;
    order.sendToLength = (int32_t)toAddresses.count;
    BOOL autoEstimatefee = [[MMAppSetting sharedSetting] canAutoCalculateTransactionFee];
    if (!autoEstimatefee) {
        order.fee = feeValue;
    }
    [NetWorkOperationTool POSTWithUrlString:url noSignProtoData:order.data complete:^(id response) {
        NSError *error = nil;
        HttpNotSignResponse *hResponse = (HttpNotSignResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(nil,[NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
            }
            return;
        }
        error = nil;
        
        if (!hResponse.body) {
            return;
        }
        UnspentOrderResponse *unSpent = [UnspentOrderResponse parseFromData:hResponse.body error:&error];
        unSpent.amount = amount;
        if (complete) {
            complete(unSpent,nil);
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(nil,error);
        }
    }];
}

+ (void)unspentWithAddress:(NSString *)address fee:(double)feeValue
                 toAddress:(NSArray *)toAddresses
createRawTranscationComplete:(void (^)(NSArray *vtsArray, NSString *rawTransaction, NSString *errorMsg))complete{
    
    
    // Verify the legitimacy of the input
    if (GJCFStringIsNull(address) || ![KeyHandle checkAddress:address]) {
        if (complete) {
            complete(nil,nil,@"Payment address is not valid");
        }
        return;
    }
    if (feeValue < 0) {
        feeValue = [[MMAppSetting sharedSetting] getTranferFee];
        if (feeValue < 0) {
            feeValue = [MINNER_FEE longLongValue];
        }
    }
    
    if (toAddresses.count <= 0) {
        if (complete) {
            complete(nil,nil,@"No collection address");
        }
        return;
    }
    
    for (NSDictionary *temD in toAddresses) {
        if (![KeyHandle checkAddress:[temD valueForKey:@"address"]]) {
            if (complete) {
                complete(nil,nil,@"Collection address is not valid");
            }
            return;
        }
    }
    
    [NetWorkOperationTool GETWithUrlString:BlockChainUnspentUrlWithAddress(address) complete:^(id response) {
        
        long int amount = 0;
        for (NSDictionary *temD in toAddresses) {
            long int oneAmount = [[temD valueForKey:@"amount"] doubleValue] * pow(10, 8);
            amount += oneAmount;
        }
        
        // Verify payment amount
        if (amount <= 0) {
            if (complete) {
                complete(nil,nil,@"Payment amount can not be less than 0");
            }
            return;
        }
        
        long int fee = feeValue;
        
        NSError *error = nil;
        HttpNotSignResponse *hResponse = (HttpNotSignResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(nil,nil,hResponse.message);
            }
            return;
        }
        
        error = nil;
        Unspents *unSpent = [Unspents parseFromData:hResponse.body error:&error];
        
        if (error) {
            return;
        }
        
        NSMutableArray *unSpentArr = [NSMutableArray array];
        for (Unspent *uns in unSpent.unspentsArray) {
            UnSpentInfo *info = [[UnSpentInfo alloc] init];
            info.tx_hash = uns.txHash;
            info.value = uns.value;
            info.outputN = uns.txOutputN;
            info.confirmations = uns.confirmations;
            info.scriptpubkey = uns.scriptpubkey;
            [unSpentArr objectAddObject:info];
        }
        
        [unSpentArr sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            UnSpentInfo *r1 = obj1;
            UnSpentInfo *r2 = obj2;
            int long long value1 = r1.value;
            int long long value2 = r2.value;
            if (value1 < value2) {
                return NSOrderedAscending;
            } else if(value1 == value2){
                return NSOrderedSame;
            } else{
                return NSOrderedDescending;
            }
        }];
        
        // Enter the unconfirmed transaction
        NSMutableArray *inTx = [NSMutableArray array];
        long int inValue = 0;
        for (UnSpentInfo *info in unSpentArr) {
            inValue += info.value;
            [inTx objectAddObject:info];
            if (inValue > amount + fee) {
                break;
            }
        }
        if (inValue < amount + fee) {
            DDLogInfo(@"Insufficient balance of purse");
            if (complete) {
                complete(nil,nil,LMLocalizedString(@"Wallet Insufficient balance", nil));
            }
            return;
        }
        
        NSMutableArray *tvsArr = [NSMutableArray array];
        for (UnSpentInfo *info in inTx) {
            NSDictionary *tvs = @{@"vout":@(info.outputN),
                                  @"txid":info.tx_hash,
                                  @"scriptPubKey":info.scriptpubkey};
            [tvsArr objectAddObject:tvs];
            
        }
        
        
        NSInteger change = inValue - amount - fee;
        // Change the address
        NSMutableDictionary *outputs = @{}.mutableCopy;
        if (change) {
            [outputs setObject:@((change) * pow(10, -8)) forKey:address];
        }
        for (NSDictionary *temD in toAddresses) {
            [outputs setObject:[temD valueForKey:@"amount"] forKey:[temD valueForKey:@"address"]];
        }
        
        NSString *rawTransaction = [KeyHandle createRawTranscationWithTvsArray:tvsArr outputs:outputs];
    
        if (complete) {
            if (rawTransaction) {
                complete(tvsArr,rawTransaction,nil);
            } else{
                complete(nil,nil,@"createTransactionFail");
            }
        }
        
        DDLogInfo(@"rawTransaction %@",rawTransaction);

        
    } fail:^(NSError *error) {
        if (complete) {
            complete(nil,nil,LMLocalizedString(@"Network Server error", nil));
        }
    }];
}


+ (void)TrandPackageWithAddresses:(NSArray *)addresses
                              fee:(double)feeValue
                        toAddress:(NSArray *)toAddresses
     createRawTranscationComplete:(void (^)(NSArray *vtsArray, NSString *rawTransaction, NSString *errorMsg))complete{
    
    // Verify the legitimacy of the input
    for (NSString *address in addresses) {
        
        if (GJCFStringIsNull(address) || ![KeyHandle checkAddress:address]) {
            if (complete) {
                complete(nil,nil,@"Payment address is not valid");
            }
            return;
        }
    }

    if (feeValue < 0) {
        feeValue = [[MMAppSetting sharedSetting] getTranferFee];
        if (feeValue < 0) {
            feeValue = [MINNER_FEE longLongValue];
        }
    }
    
    if (toAddresses.count <= 0) {
        if (complete) {
            complete(nil,nil,@"No collection address");
        }
        return;
    }
    
    for (NSDictionary *temD in toAddresses) {
        if (![KeyHandle checkAddress:[temD valueForKey:@"address"]]) {
            if (complete) {
                complete(nil,nil,@"Collection address is not valid");
            }
            return;
        }
    }

    // The length of the input (the length of the output address)
    int sendLength = (int)toAddresses.count;
    
    long int amount = 0;
    for (NSDictionary *temD in toAddresses) {
        long int oneAmount = [[temD valueForKey:@"amount"] doubleValue] * pow(10, 8);
        amount += oneAmount;
    }
    
    // Verify payment amount
    if (amount <= 0) {
        if (complete) {
            complete(nil,nil,@"Payment amount can not be less than 0");
        }
        
        return;
    }

    
    long int __block fee = feeValue;

    ComposeRequest *comRequest = [[ComposeRequest alloc] init];
    comRequest.addressesArray = [NSMutableArray arrayWithArray:addresses];
    comRequest.amount = amount;
    comRequest.sendLength = sendLength;
    
    [NetWorkOperationTool POSTWithUrlString:BlockChaincomposeUrl noSignProtoData:comRequest.data complete:^(id response) {
        
        HttpNotSignResponse *noSignResponse = (HttpNotSignResponse *)response;
        if (noSignResponse.code != successCode) {
            if (complete) {
                complete(nil,nil,noSignResponse.message);
            }
            return;
        }
        
        NSError *error = nil;
        Composes *comes = [Composes parseFromData:noSignResponse.body error:&error];
        if (error) {
            return;
        }
        
        if (fee <= 0) {
            if (fee < comes.estimateFee) {
                fee = comes.estimateFee;
            }
        }
        
        
        NSMutableArray *unSpentArr = [NSMutableArray array];
        for (Compose *com in comes.composesArray) {
            for (Unspent *uns in com.unspentsArray) {
                UnSpentInfo *info = [[UnSpentInfo alloc] init];
                info.tx_hash = uns.txHash;
                info.value = uns.value;
                info.outputN = uns.txOutputN;
                info.confirmations = uns.confirmations;
                info.scriptpubkey = uns.scriptpubkey;
                [unSpentArr objectAddObject:info];
            }
        }
        
        
        // Enter the unconfirmed transaction
        long int inValue = 0;
        for (UnSpentInfo *info in unSpentArr) {
            inValue += info.value;
        }
        
        if ((inValue - amount - fee) < 0) {
            DDLogInfo(@"Insufficient balance of purse");
            if (complete) {
                complete(nil,nil,@"Insufficient balance of purse");
            }
            return;
        }

        
        NSMutableArray *tvsArr = [NSMutableArray array];
        for (UnSpentInfo *info in unSpentArr) {
            NSDictionary *tvs = @{@"vout":@(info.outputN),
                                  @"txid":info.tx_hash,
                                  @"scriptPubKey":info.scriptpubkey};
            [tvsArr objectAddObject:tvs];
            
        }
        
        NSString *address = [addresses firstObject];
        NSMutableDictionary *outputs = @{address:@((inValue - amount - fee) * pow(10, -8))}.mutableCopy;
        for (NSDictionary *temD in toAddresses) {
            [outputs setObject:[temD valueForKey:@"amount"] forKey:[temD valueForKey:@"address"]];
        }
        
        NSString *rawTransaction = [KeyHandle createRawTranscationWithTvsArray:tvsArr outputs:outputs];
        
        if (complete) {
            if (rawTransaction) {
                complete(tvsArr,rawTransaction,nil);
            } else{
                complete(nil,nil,@"createTransactionFail");
            }
        }

    } fail:^(NSError *error) {
        if (complete) {
            complete(nil,nil,LMLocalizedString(@"Network Server error", nil));
        }
    }];
    
}


+ (void)queryBillInfoWithTransactionhashId:(NSString *)hashid complete:(void (^)(NSError *erro ,Bill *bill))complete{
    
    
    BillHashId *bill = [[BillHashId alloc] init];
    bill.hash_p = hashid;

    [NetWorkOperationTool POSTWithUrlString:WallteQueryBillInfoUrl postProtoData:bill.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        
        if (hResponse.code != successCode) {
            if (complete) {
                complete([NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil],nil);
            }
            return;
        }
        NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            NSError *error = nil;
            
            Bill *detailBill = [Bill parseFromData:data error:&error];
            
            if (!error) {
                DDLogInfo(@"%@",detailBill);
                [[LMMessageExtendManager sharedManager] updateMessageExtendStatus:detailBill.status withHashId:detailBill.hash_p];
                if (complete) {
                    complete(nil,detailBill);
                }
            } else{
                error = nil;
                    if (!error) {
                        if (complete) {
                            complete(nil,detailBill);
                        }
                    } else{
                        if (complete) {
                            complete(error,nil);
                        }
                    }
                }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(error,nil);
        }
    }];
}


+ (void)queryAmountByAddress:(NSString *)address complete:(void (^)(NSError *erro ,long long int amount, NSString *errorMsg))complete{
    
    
    // Verify the legitimacy of the input
    if (GJCFStringIsNull(address) || ![KeyHandle checkAddress:address]) {
        if (complete) {
            complete(nil,0,@"Payment address is not valid");
        }
        return;
    }
    [NetWorkOperationTool GETWithUrlString:BlockChainUnspentUrlWithAddress(address) complete:^(id response) {
        
        NSError *error = nil;
        HttpNotSignResponse *hResponse = (HttpNotSignResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete([NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil],0,nil);
            }
            return;
        }
        
        error = nil;
        Unspents *unSpent = [Unspents parseFromData:hResponse.body error:&error];
        
        if (error) {
            return;
        }
        
        long int inValue = 0;
        for (Unspent *uns in unSpent.unspentsArray) {
            inValue += uns.value;
        }
        
        // save
        [[MMAppSetting sharedSetting] saveBalance:inValue];
        
        if (complete) {
            complete(error,inValue,nil);
        }
        
    } fail:^(NSError *error) {
        DDLogError(@"error %@",error);
        if (complete) {
            complete(error,0,LMLocalizedString(@"Network Server error", nil));
        }
    }];

}

+ (void)queryAmountByAddressV2:(NSString *)address complete:(void (^)(NSError *erro ,UnspentAmount *unspentAmount))complete{
    
    
    // Verify the legitimacy of the input
    if (GJCFStringIsNull(address) || ![KeyHandle checkAddress:address]) {
        if (complete) {
            complete(nil,nil);
        }
        return;
    }
    [NetWorkOperationTool GETWithUrlString:WalletUnspentQueryV2Url(address) complete:^(id response) {
        
        NSError *error = nil;
        HttpNotSignResponse *hResponse = (HttpNotSignResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete([NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil],nil);
            }
            return;
        }
        
        error = nil;
        UnspentAmount *unSpent = [UnspentAmount parseFromData:hResponse.body error:&error];
        
        if (error) {
            return;
        }
        // save
        [[MMAppSetting sharedSetting] saveBalance:unSpent.amount];
        
        if (complete) {
            complete(error,unSpent);
        }
        
    } fail:^(NSError *error) {
        //。code = -1011 is null address
    
        DDLogError(@"error %@",error);
        if (complete) {
            complete(error,nil);
        }
    }];
}



+ (void)createCrowdfuningBillWithGroupId:(NSString *)groupid totalAmount:(long long int)totalAmount size:(int)size tips:(NSString *)tips complete:(void (^)(NSError *erro,NSString *hashId))complete{
    
    if (GJCFStringIsNull(groupid)) {
        if (complete) {
            complete([NSError errorWithDomain:@"Group ID is empty" code:-1 userInfo:nil],nil);
        }
        return;
    }
    
    if (size <= 0) {
        if (complete) {
            complete([NSError errorWithDomain:@"At least one person" code:-1 userInfo:nil],nil);
        }
        return;
    }
    
    if (totalAmount <= 0) {
        if (complete) {
            complete([NSError errorWithDomain:@"The amount of money is greater than 0" code:-1 userInfo:nil],nil);
        }
        return;
    }

    
    
    LaunchCrowdfunding *crowdFunding = [[LaunchCrowdfunding alloc] init];
    crowdFunding.groupHash = groupid;
    crowdFunding.size = size;
    crowdFunding.tips = tips;
    crowdFunding.total = totalAmount;
    
    [NetWorkOperationTool POSTWithUrlString:WallteBillCrowdfuningUrl postProtoData:crowdFunding.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete([NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil],nil);
            }
            return;
        }
        NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            NSError *error = nil;
            Crowdfunding *detailBill = [Crowdfunding parseFromData:data error:&error];
            if (!error) {
                if (complete) {
                    complete(nil,detailBill.hashId);
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(error,nil);
        }
        
    }];
}

+ (void)payWithHashID:(NSString *)hashId amount:(long long int)amount
            toAddress:(NSString *)address
             complete:(void (^)(UnspentOrderResponse *unspent,NSArray* toAddresses,NSError *error))complete{
    NSArray* toAddresses = @[@{@"address":address,@"amount":[[[NSDecimalNumber alloc] initWithLongLong:amount]
                                                             decimalNumberByDividingBy:
                                                             [[NSDecimalNumber alloc] initWithLongLong:pow(10, 8)]].stringValue}];
    
    [self unspentV2WithAddress:[[LKUserCenter shareCenter] currentLoginUser].address
                           fee:[[MMAppSetting sharedSetting] getTranferFee]
                     toAddress:toAddresses
createRawTranscationModelComplete:^(UnspentOrderResponse *unspent, NSError *error) {
        if (error) {
            if (complete) {
                complete(nil,nil,error);
            }
        }else
        {
            if (complete) {
                complete(unspent,toAddresses,nil);
            }
        }
    }];
}

+ (void)crowdfuningInfoWithHashID:(NSString *)hashId complete:(void (^)(NSError *erro ,Crowdfunding *crowdInfo))complete{
    
    CrowdfundingInfo *crowIdentifer = [[CrowdfundingInfo alloc] init];
    crowIdentifer.hashId = hashId;
    
    [NetWorkOperationTool POSTWithUrlString:WallteCrowdfuningInfoUrl postProtoData:crowIdentifer.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete([NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil],nil);
            }
            return;
        }
        NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            NSError *error = nil;
            Crowdfunding *detailBill = [Crowdfunding parseFromData:data error:&error];
            
            if (!error) {
                // update db
                
                [[LMMessageExtendManager sharedManager]updateMessageExtendPayCount:(int)(detailBill.size - detailBill.remainSize) status:(int)detailBill.status withHashId:detailBill.hashId];
                if (complete) {
                    complete(nil,detailBill);
                }
            } else{
                if (!error) {
                    if (complete) {
                        complete(nil,detailBill);
                    }
                } else{
                    if (complete) {
                        complete(error,nil);
                    }
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(error,nil);
        }
    }];
}


+ (void)getPendingInfoComplete:(void (^)(PendingPackage *pendRedBag ,NSError *error))complete{
    [NetWorkOperationTool POSTWithUrlString:ExternalPendingUrl postProtoData:nil complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        
        if (hResponse.code != successCode) {
            if (complete) {
                complete(nil,[NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
            }
            return;
        }
        NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            NSError *error = nil;
            PendingPackage *pendRedBag = [PendingPackage parseFromData:data error:&error];
            if (!error) {
                if (complete) {
                    complete(pendRedBag,nil);
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(nil,error);
        }
    }];
}



+ (void)sendExternalBillWithSendAddress:(NSString *)address
                                privkey:(NSString *)privkey
                                fee:(double)fee money:(long long int)money
                                tips:(NSString *)tips complete:(void (^)(OrdinaryBilling *billing,UnspentOrderResponse *unspent,NSArray* toAddresses,NSError *error))complete{
    [self getPendingInfoComplete:^(PendingPackage *pendRedBag, NSError *error) {
        if (error) {
            if (complete) {
                complete(nil,nil,nil,error);
            }
            return;
        }
        OrdinaryBilling *ordinaryRed = [[OrdinaryBilling alloc] init];
        ordinaryRed.hashId = pendRedBag.hashId;
        ordinaryRed.tips = tips;
        ordinaryRed.money = money;
        NSArray* toAddressArray = @[@{@"address":pendRedBag.address,
                                      @"amount":[[[NSDecimalNumber alloc] initWithLongLong:ordinaryRed.money + fee]
                                                                               decimalNumberByDividingBy:
                                                 [[NSDecimalNumber alloc] initWithLongLong:pow(10, 8)]].stringValue}];
        
        [WallteNetWorkTool unspentV2WithAddress:[[LKUserCenter shareCenter] currentLoginUser].address
                           fee:fee
                           toAddress:toAddressArray
                           createRawTranscationModelComplete:^(UnspentOrderResponse *unspent, NSError *error) {
                               if (error) {
                                   if (complete) {
                                       complete(nil,nil,nil,error);
                                   }
                               } else{
                                   if (complete) {
                                       complete(ordinaryRed,unspent,toAddressArray,nil);
                                   }
                               }
                }];
    }];

}


+ (void)cancelExternalWithHashid:(NSString *)hashid complete:(void (^)(NSError *error))complete{
    BillHashId *bill = [[BillHashId alloc] init];
    bill.hash_p = hashid;
    [NetWorkOperationTool POSTWithUrlString:ExternalBillCancelUrl postProtoData:bill.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete([NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
            }
        } else{
            if (complete) {
                complete(nil);
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(error);
        }
    }];
}


+ (void)externalTransferHistoryWithPageIndex:(int)page size:(int)size complete:(void (^)(NSError *error,ExternalBillingInfos *externalBillInfos))complete{
    History *his = [[History alloc] init];
    his.pageIndex = page;
    his.pageSize = size;
    
    [NetWorkOperationTool POSTWithUrlString:ExternalTransferHistoryUrl postProtoData:his.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete([NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil],nil);
            }
        } else{
            if (complete) {
                NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
                if (data) {
                    NSError *error = nil;
                    ExternalBillingInfos *exterBill = [ExternalBillingInfos parseFromData:data error:&error];
                    complete(nil,exterBill);
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(error,nil);
        }
    }];
}

+ (void)externalRedPacketHistoryWithPageIndex:(int)page size:(int)size complete:(void (^)(NSError *error,RedPackageInfos *redPackages))complete{
    History *his = [[History alloc] init];
    his.pageIndex = page;
    his.pageSize = size;
    [NetWorkOperationTool POSTWithUrlString:ExternalRedPackageHistoryUrl postProtoData:his.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete([NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil],nil);
            }
        } else{
            if (complete) {
                NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
                if (data) {
                    NSError *error = nil;
                    RedPackageInfos *redPackages = [RedPackageInfos parseFromData:data error:&error];
                    complete(nil,redPackages);
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(error,nil);
        }
    }];
}



+ (void)queryOuterBillInfoWithTransactionhashId:(NSString *)hashid complete:(void (^)(NSError *erro ,Bill *bill))complete{
    BillHashId *bill = [[BillHashId alloc] init];
    bill.hash_p = hashid;
    
    [NetWorkOperationTool POSTWithUrlString:ExternalBillInfoUrl postProtoData:bill.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        
        if (hResponse.code != successCode) {
            if (complete) {
                complete([NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil],nil);
            }
            return;
        }
        NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            NSError *error = nil;
            
            Bill *detailBill = [Bill parseFromData:data error:&error];
            
            if (!error) {
                DDLogInfo(@"%@",detailBill);
                
                [[LMMessageExtendManager sharedManager] updateMessageExtendStatus:detailBill.status withHashId:detailBill.hash_p];
                if (complete) {
                    complete(nil,detailBill);
                }
            } else{
                if (!error) {
                    if (complete) {
                        complete(nil,detailBill);
                    }
                } else{
                    if (complete) {
                        complete(error,nil);
                    }
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(error,nil);
        }
    }];
}



@end
