//
//  AesGCMTool.m
//  Connect
//
//  Created by MoHuilin on 16/5/27.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "AesGCMTool.h"
#import "KeyHandle.h"

#import "AppDelegate.h"
#import "AccountInfo.h"

@implementation AesGCMTool

+ (NSDictionary *)AES_GCMEncodeWithPass:(NSString *)pass data:(NSString *)data iv:(NSString *)iv aad:(NSString *)aad{
    //encryption
    NSDictionary *dict = [KeyHandle xtalkEncodeAES_GCM:pass data:data aad:aad iv:iv];
    
    DDLogInfo(@"iv:%@ , add:%@ ,encodeString:%@ ,tag:%@ ,password:%@",iv,aad,dict[@"encryptedDatastring"],dict[@"tagstring"],pass);
    
    NSString *string = [KeyHandle xtalkDecodeAES_GCM:pass data:dict[@"encryptedDatastring"] aad:aad iv:iv tag:dict[@"tagstring"]];
    
    if ([string isEqualToString:data]) {
        DDLogInfo(@"本地AES加解密成功");
    } else{
        
    }
    
    NSDictionary *encryptionDict = @{@"iv":iv,
                                     @"aad":aad,
                                     @"ciphertext":dict[@"encryptedDatastring"],
                                     @"tag":dict[@"tagstring"]};
    
    return encryptionDict;
}

+ (NSDictionary *)getAesGCMEcodeDictWithCurrentAccountPrikeyAndPublicKey:(NSString *)pubkey data:(id)data{
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    AccountInfo *currentUser = app.currentUser;
    
    NSString *aad = [[NSString stringWithFormat:@"%d",arc4random() % 100 + 1000] sha1String];
    NSString *iv = [[NSString stringWithFormat:@"%d",arc4random() % 100 + 1000] sha1String];
    
    NSString *userPass = [KeyHandle getECDHkeyUsePrivkey:currentUser.prikey PublicKey:pubkey];
    NSDictionary *messageEncodeDict = [self AES_GCMEncodeWithPass:userPass data:data iv:iv aad:aad];
    
    return messageEncodeDict;
}

@end
