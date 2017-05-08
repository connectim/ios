//
//  ConnectTool.m
//  Connect
//
//  Created by MoHuilin on 16/8/17.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "ConnectTool.h"
#import "StringTool.h"
#import "NSData+Hash.h"
#import "MMMessage.h"
#import "LMHistoryCacheManager.h"

@implementation ConnectTool

+ (GcmData *)getGcmDataWithEcdhKey:(NSString *)ecdhKey data:(id)data{
    
    if (GJCFStringIsNull(ecdhKey)) {
        return nil;
    }
    
    if (!data) {
        return nil;
    }
    
    NSString *aad = [[NSString stringWithFormat:@"%d",arc4random() % 100 + 1000] sha1String];
    NSString *iv = [[NSString stringWithFormat:@"%d",arc4random() % 100 + 1000] sha1String];
    NSDictionary *userToUserDict = nil;
    if ([data isKindOfClass:[NSString class]]) {
        userToUserDict = [KeyHandle xtalkEncodeAES_GCM:ecdhKey data:data aad:aad iv:iv];
    } else if ([data isKindOfClass:[NSData class]]){
        StructData *structData = [[StructData alloc] init];
        structData.random = [self get16_32RandData];
        structData.plainData = data;
        userToUserDict = [KeyHandle xtalkEncodeAES_GCM:ecdhKey withNSdata:structData.data aad:aad iv:iv];
    }
    
    GcmData *gcmData = [[GcmData alloc] init];
    gcmData.iv = [iv dataUsingEncoding:NSUTF8StringEncoding];
    gcmData.aad = [aad dataUsingEncoding:NSUTF8StringEncoding];
    gcmData.ciphertext = [userToUserDict[@"encryptedDatastring"] dataUsingEncoding:NSUTF8StringEncoding];
    gcmData.tag = [userToUserDict[@"tagstring"] dataUsingEncoding:NSUTF8StringEncoding];

    return gcmData;
}

+ (GcmData *)getNoStructDataGcmDataWithEcdhKey:(NSString *)ecdhKey data:(id)data{
    
    if (GJCFStringIsNull(ecdhKey)) {
        return nil;
    }
    
    if (!data) {
        return nil;
    }
    
    NSString *aad = [[NSString stringWithFormat:@"%d",arc4random() % 100 + 1000] sha1String];
    NSString *iv = [[NSString stringWithFormat:@"%d",arc4random() % 100 + 1000] sha1String];
    NSDictionary *userToUserDict = nil;
    if ([data isKindOfClass:[NSString class]]) {
        userToUserDict = [KeyHandle xtalkEncodeAES_GCM:ecdhKey data:data aad:aad iv:iv];
    } else if ([data isKindOfClass:[NSData class]]){
        userToUserDict = [KeyHandle xtalkEncodeAES_GCM:ecdhKey withNSdata:data aad:aad iv:iv];
    }
    
    GcmData *gcmData = [[GcmData alloc] init];
    gcmData.iv = [iv dataUsingEncoding:NSUTF8StringEncoding];;
    gcmData.aad = [aad dataUsingEncoding:NSUTF8StringEncoding];;
    gcmData.ciphertext = [userToUserDict[@"encryptedDatastring"] dataUsingEncoding:NSUTF8StringEncoding];
    gcmData.tag = [userToUserDict[@"tagstring"] dataUsingEncoding:NSUTF8StringEncoding];
    
    return gcmData;
}


+ (NSString *)decodeGcmDataGetStringWithEcdhKey:(NSString *)ecdhKey GcmData:(GcmData *)gcmData{
    
    if (GJCFStringIsNull(ecdhKey)) {
        return nil;
    }
    
    if (!gcmData) {
        return nil;
    }
    
    return [KeyHandle xtalkDecodeAES_GCM:ecdhKey
                                    data:[[NSString alloc] initWithData:gcmData.ciphertext encoding:NSUTF8StringEncoding]
                                     aad:[[NSString alloc] initWithData:gcmData.aad encoding:NSUTF8StringEncoding]
                                      iv:[[NSString alloc] initWithData:gcmData.iv encoding:NSUTF8StringEncoding]
                                     tag:[[NSString alloc] initWithData:gcmData.tag encoding:NSUTF8StringEncoding]];
    
}

+ (NSString *)decodeGcmData:(GcmData *)gcmData
                  publickey:(NSString *)publickey{
    return [self decodeGcmData:gcmData withPrivkey:nil publickey:publickey];
}

+ (NSString *)decodeMessageGcmData:(GcmData *)gcmData
                  publickey:(NSString *)publickey
              needEmptySalt:(BOOL)needEmptySalt{
    
    NSString *privkey = [[LKUserCenter shareCenter] currentLoginUser].prikey;
    
    if (GJCFStringIsNull(publickey)) {
        publickey = [[ServerCenter shareCenter] getCurrentServer].data.pub_key;
    }
    NSData *ecdhKey = [KeyHandle getECDHkeyWithPrivkey:privkey publicKey:publickey];
    if (needEmptySalt) {
        // Empty salt extension
        ecdhKey = [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdhKey salt:[self get64ZeroData]];
    }
    if (!gcmData) {
        return nil;
    }
    NSData *data = [KeyHandle xtalkDecodeAES_GCMDataWithPassword:ecdhKey data:gcmData.ciphertext aad:gcmData.aad iv:gcmData.iv tag:gcmData.tag];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

}


+ (NSString *)decodeGcmData:(GcmData *)gcmData
                withPrivkey:(NSString *)privkey
                  publickey:(NSString *)publickey{
    
    if (GJCFStringIsNull(privkey)) {
        privkey = [[LKUserCenter shareCenter] currentLoginUser].prikey;
    }
    if (GJCFStringIsNull(publickey)) {
        publickey = [[ServerCenter shareCenter] getCurrentServer].data.pub_key;
    }
    NSData *ecdhKey = [KeyHandle getECDHkeyWithPrivkey:privkey publicKey:publickey];
    if (!gcmData) {
        return nil;
    }
    NSData *data = [KeyHandle xtalkDecodeAES_GCMDataWithPassword:ecdhKey data:gcmData.ciphertext aad:gcmData.aad iv:gcmData.iv tag:gcmData.tag];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
}



+ (NSData *)decodeGcmDataGetDataWithEcdhKey:(NSString *)ecdhKey GcmData:(GcmData *)gcmData{
    
    if (GJCFStringIsNull(ecdhKey)) {
        return nil;
    }
    
    if (!gcmData) {
        return nil;
    }
    return  [self decodeGcmDataWithEcdhKey:[StringTool hexStringToData:ecdhKey] GcmData:gcmData];
}



+ (IMRequest *)createRequestWithData:(GcmData *)gcmData{

    NSString *sign = [self signWithData:gcmData.data];
    IMRequest *request = [[IMRequest alloc] init];
    request.pubKey = [[LKUserCenter shareCenter] currentLoginUser].pub_key;
    request.cipherData = gcmData;
    request.sign = sign;

    
    return request;
}


+ (IMTransferData *)createTransferWithData:(GcmData *)gcmData{
    return [self createTransferWithData:gcmData privkey:[[LKUserCenter shareCenter] currentLoginUser].prikey];
}

+ (BOOL)vertifyWithData:(id)data sign:(NSString *)sign{
    return [self vertifyWithData:data sign:sign publickey:nil];
}

+ (BOOL)vertifyWithData:(id)data sign:(NSString *)sign publickey:(NSString *)publickey{
    
    if (GJCFStringIsNull(publickey)) {
        publickey = [[ServerCenter shareCenter] getCurrentServer].data.pub_key;
    }
    
    id vertiryData = nil;
    if ([data isKindOfClass:[NSString class]]) {
        vertiryData = data;
    } else if ([data isKindOfClass:[NSData class]]){
        NSData *temD = (NSData *)data;
        vertiryData = [temD hash256String];
    }
    
    if (!vertiryData) {
        return NO;
    }
    
    return [KeyHandle verifyWithPublicKey:publickey originData:vertiryData signData:sign];
}

+ (NSString *)signWithData:(id)data{
    return [self signWithData:data Privkey:nil];
}

+ (NSString *)signWithData:(id)data Privkey:(NSString *)privkey{
    if (GJCFStringIsNull(privkey)) {
        privkey = [[LKUserCenter shareCenter] currentLoginUser].prikey;
    }
    NSString *signDataString = data;
    if ([data isKindOfClass:[NSData class]]) {
        signDataString = [data hash256String];
    }
    NSString *sign = [KeyHandle signHashWithPrivkey:privkey
                                               data:signDataString];
    
    return sign;
}



+ (IMRequest *)createRequestWithEcdhKey:(NSString *)ecdhKey data:(id)data{
    GcmData *gcmData = [self getGcmDataWithEcdhKey:ecdhKey data:data];
    if (!gcmData) {
        return nil;
    }
    
    return [self createRequestWithData:gcmData];
}


+ (NSData *)get16_32RandData{
    NSData *randomData = [KeyHandle createRandom512bits];
    int loc = arc4random() % 32;
    int len = arc4random() % 16 + 16;
    randomData = [randomData subdataWithRange:NSMakeRange(loc, len)];
    return randomData;
}

+ (NSData *)getIvData{
    NSData *ivData = [KeyHandle createRandom512bits];
    ivData = [ivData subdataWithRange:NSMakeRange(0, 16)];
    return ivData;
}


#pragma mark - New encryption and decryption methods
+ (IMRequest *)createRequestWithEcdhKey:(NSData *)ecdhKey
                                   data:(NSData *)data
                                    aad:(NSData *)aad{
    if (!aad) {
        aad = [ServerCenter shareCenter].defineAad;
        if (!aad) {
            aad = [self getIvData];
        }
    }
    GcmData *gcmData = [self createGcmDataWithEcdhkey:ecdhKey data:[self createStructDataWithData:data] aad:aad];
    if (!gcmData) {
        return nil;
    }
    return [self createRequestWithData:gcmData privkey:[[LKUserCenter shareCenter] currentLoginUser].prikey publickKey:[[LKUserCenter shareCenter] currentLoginUser].pub_key];
}

+ (IMTransferData *)createTransferWithEcdhKey:(NSData *)ecdhKey
                                         data:(id)data
                                          aad:(NSData *)aad{
    if (!aad) {
        aad = [ServerCenter shareCenter].defineAad;
        if (!aad) {
            aad = [self getIvData];
        }
    }
    GcmData *gcmData = [self createGcmDataWithEcdhkey:ecdhKey data:[self createStructDataWithData:data] aad:aad];
    if (!gcmData) {
        return nil;
    }
    return [self createTransferWithData:gcmData];
}

+ (NSData *)decodeGcmDataWithEcdhKey:(NSData *)ecdhKey
                             GcmData:(GcmData *)gcmData{
    if (!ecdhKey) {
        return nil;
    }
    NSData *data = [KeyHandle xtalkDecodeAES_GCMDataWithPassword:ecdhKey data:gcmData.ciphertext aad:gcmData.aad iv:gcmData.iv tag:gcmData.tag];
    return [self getPlainDataWithData:data];
}

+ (NSData *)decodeGcmDataWithEcdhKey:(NSData *)ecdhKey
                             GcmData:(GcmData *)gcmData
                      haveStructData:(BOOL)haveStructData{
    if (!ecdhKey) {
        return nil;
    }
    NSData *data = [KeyHandle xtalkDecodeAES_GCMDataWithPassword:ecdhKey data:gcmData.ciphertext aad:gcmData.aad iv:gcmData.iv tag:gcmData.tag];
    if (haveStructData) {
        return [self getPlainDataWithData:data];
    } else{
        return data;
    }
}


+ (NSString *)decodeGroupGcmDataWithEcdhKey:(NSString *)ecdhKey
                             GcmData:(GcmData *)gcmData{
    if (!ecdhKey) {
        return nil;
    }
    NSData *data = [KeyHandle xtalkDecodeAES_GCMDataWithPassword:[StringTool hexStringToData:ecdhKey] data:gcmData.ciphertext aad:gcmData.aad iv:gcmData.iv tag:gcmData.tag];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}


+ (NSData *)decodeGcmDataWithGcmData:(GcmData *)gcmData
                           publickey:(NSString *)publickey{
    return [self decodeGcmDataWithGcmData:gcmData privkey:nil publickey:publickey];
}

+ (NSData *)decodeGcmDataWithGcmData:(GcmData *)gcmData
                           publickey:(NSString *)publickey
                       needEmptySalt:(BOOL)needEmptySalt{
    return [self decodeGcmDataWithGcmData:gcmData privkey:nil publickey:publickey needEmptySalt:needEmptySalt];
}


+ (NSData *)decodeGcmDataWithGcmData:(GcmData *)gcmData
                             privkey:(NSString *)privkey
                           publickey:(NSString *)publickey{
    return [self decodeGcmDataWithGcmData:gcmData privkey:privkey publickey:publickey needEmptySalt:NO];
}

+ (NSData *)decodeGcmDataWithGcmData:(GcmData *)gcmData
                             privkey:(NSString *)privkey
                           publickey:(NSString *)publickey
                       needEmptySalt:(BOOL)needEmptySalt{
    if (GJCFStringIsNull(privkey)) {
        privkey = [[LKUserCenter shareCenter] currentLoginUser].prikey;
    }
    if (GJCFStringIsNull(publickey)) {
        publickey = [[ServerCenter shareCenter] getCurrentServer].data.pub_key;
    }
    NSData *ecdhKey = [KeyHandle getECDHkeyWithPrivkey:privkey publicKey:publickey];
    if (needEmptySalt) {
        ecdhKey = [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdhKey salt:[self get64ZeroData]];
    }
    return  [self decodeGcmDataWithEcdhKey:ecdhKey GcmData:gcmData];
}



+ (NSData *)createStructDataWithData:(NSData *)data{
    StructData *structData = [[StructData alloc] init];
    structData.random = [self get16_32RandData];
    structData.plainData = data;
    return structData.data;
}

+ (NSData *)getPlainDataWithData:(NSData *)data{
    StructData *structData = [StructData parseFromData:data error:nil];
    return structData.plainData;
}

+ (GcmData *)createGcmDataWithEcdhkey:(NSData *)ecdhKey
                                 data:(NSData *)data
                                  aad:(NSData *)aad{
    
    if (!aad) {
        aad = [ServerCenter shareCenter].defineAad;
        if (!aad) {
            aad = [self getIvData];
        }
    }
    NSDictionary *cipTagDict = [KeyHandle xtalkEncodeAES_GCMWithPassword:ecdhKey originData:data aad:aad];
    GcmData *gcmData = [[GcmData alloc] init];
    gcmData.iv = [cipTagDict valueForKey:@"iv"];
    gcmData.aad = aad;
    gcmData.ciphertext = [cipTagDict valueForKey:@"ciphertext"];
    gcmData.tag = [cipTagDict valueForKey:@"tag"];
    return gcmData;
}

+ (GcmData *)createGcmDataWithStructDataEcdhkey:(NSData *)ecdhKey
                                 data:(NSData *)data
                                  aad:(NSData *)aad{
    
    if (!aad) {
        aad = [ServerCenter shareCenter].defineAad;
        if (!aad) {
            aad = [self getIvData];
        }
    }
    
    NSDictionary *cipTagDict = [KeyHandle xtalkEncodeAES_GCMWithPassword:ecdhKey originData:[self createStructDataWithData:data] aad:aad];
    GcmData *gcmData = [[GcmData alloc] init];
    gcmData.iv = [cipTagDict valueForKey:@"iv"];
    gcmData.aad = aad;
    gcmData.ciphertext = [cipTagDict valueForKey:@"ciphertext"];
    gcmData.tag = [cipTagDict valueForKey:@"tag"];
    return gcmData;
}


+ (GcmData *)createGcmWithData:(id)data
                     publickey:(NSString *)publickey
                 needEmptySalt:(BOOL)needEmptySalt{
    return [self createGcmWithData:data privkey:nil publickey:publickey aad:nil needEmptySalt:needEmptySalt];
}


+ (GcmData *)createHalfRandomPeerIMGcmWithData:(NSString *)data chatPubkey:(NSString *)chatPubkey{
    NSString * privkey = [SessionManager sharedManager].loginUserChatCookie.chatPrivkey;
    NSData *ecdhKey = [KeyHandle getECDHkeyWithPrivkey:privkey publicKey:chatPubkey];
    // Extended
    ecdhKey = [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdhKey salt:[SessionManager sharedManager].loginUserChatCookie.salt];
    return [self createGcmDataWithEcdhkey:ecdhKey data:[data dataUsingEncoding:NSUTF8StringEncoding] aad:nil];
}

+ (NSString *)decodeHalfRandomPeerImMessageGcmData:(GcmData *)gcmData
                               publickey:(NSString *)publickey
                                    salt:(NSData *)salt{
    if (GJCFStringIsNull(publickey) ||
        salt.length != 64 ||
        !gcmData) {
        return @"";
    }
    NSData *ecdhKey = [KeyHandle getECDHkeyWithPrivkey:[[LKUserCenter shareCenter] currentLoginUser].prikey publicKey:publickey];
    ecdhKey = [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdhKey salt:salt];
    NSData *data = [KeyHandle xtalkDecodeAES_GCMDataWithPassword:ecdhKey data:gcmData.ciphertext aad:gcmData.aad iv:gcmData.iv tag:gcmData.tag];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (GcmData *)createPeerIMGcmWithData:(NSString *)data chatPubkey:(NSString *)chatPubkey{
    
    ChatCookieData *chatCookie = [[SessionManager sharedManager] getChatCookieWithChatSession:chatPubkey];
    NSString * privkey = [SessionManager sharedManager].loginUserChatCookie.chatPrivkey;
    NSData *ecdhKey = [KeyHandle getECDHkeyWithPrivkey:privkey publicKey:chatCookie.chatPubKey];

    // Salt or
    NSData *exoData = [StringTool DataXOR1:[SessionManager sharedManager].loginUserChatCookie.salt DataXOR2:chatCookie.salt];

    ecdhKey = [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdhKey salt:exoData];
    return [self createGcmDataWithEcdhkey:ecdhKey data:[data dataUsingEncoding:NSUTF8StringEncoding] aad:nil];
}

+ (NSString *)decodePeerImMessageGcmData:(GcmData *)gcmData
                               publickey:(NSString *)publickey
                                    salt:(NSData *)salt
                                     ver:(NSData *)ver{
    ChatCacheCookie *cacheCookie = nil;
    if ([ver isEqualToData:[SessionManager sharedManager].loginUserChatCookie.salt]) {
        cacheCookie = [SessionManager sharedManager].loginUserChatCookie;
    } else{
        // Local does not explain this moment, can not resolve the message
        cacheCookie = [[LMHistoryCacheManager sharedManager] getChatCookieWithSaltVer:ver];
    }
    if (!cacheCookie) {
        DDLogError(@"Parse failed ：cacheCookie");
        return @"";
    }
    NSData *ecdhKey = [KeyHandle getECDHkeyWithPrivkey:cacheCookie.chatPrivkey publicKey:publickey];
    
    DDLogInfo(@"hhh:::random ecdhKey %@",[StringTool hexStringFromData:ecdhKey]);
    
    // Salt or
    NSData *exoData = [StringTool DataXOR1:salt DataXOR2:ver];
    
    DDLogInfo(@"hhh:::exoData %@",[StringTool hexStringFromData:exoData]);
    
    ecdhKey = [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdhKey salt:exoData];
    if (!gcmData) {
        return @"";
    }
    DDLogInfo(@"hhh:::ecdhKey %@",[StringTool hexStringFromData:ecdhKey]);
    NSData *data = [KeyHandle xtalkDecodeAES_GCMDataWithPassword:ecdhKey data:gcmData.ciphertext aad:gcmData.aad iv:gcmData.iv tag:gcmData.tag];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}




+ (GcmData *)createGcmWithData:(id)data
                     publickey:(NSString *)publickey{
    return [self createGcmWithData:data privkey:nil publickey:publickey aad:nil needEmptySalt:NO];
}

+ (GcmData *)createGcmWithData:(id)data
                           aad:(NSData *)aad{
    return [self createGcmWithData:data privkey:nil publickey:nil aad:aad needEmptySalt:NO];
}

+ (GcmData *)createGcmWithData:(id)data
                           ecdhKey:(NSData *)ecdhKey
                 needEmptySalt:(BOOL)needEmptySalt{
    if (needEmptySalt) {
        // Empty salt extension
        ecdhKey = [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdhKey salt:[self get64ZeroData]];
    }
    
    if ([data isKindOfClass:[NSString class]]) {
        data = [data dataUsingEncoding:NSUTF8StringEncoding];
    } else{
        StructData *structData = [StructData new];
        structData.plainData = data;
        structData.random = [self get16_32RandData];
        data = structData.data;
    }
    return [self createGcmDataWithEcdhkey:ecdhKey data:data aad:nil];
}

+ (GcmData *)createGcmWithData:(id)data
                       privkey:(NSString *)privkey
                     publickey:(NSString *)publickey
                           aad:(NSData *)aad
                 needEmptySalt:(BOOL)needEmptySalt{
    if (GJCFStringIsNull(privkey)) {
        privkey = [[LKUserCenter shareCenter] currentLoginUser].prikey;
    }
    
    if (GJCFStringIsNull(publickey)) {
        publickey = [[ServerCenter shareCenter] getCurrentServer].data.pub_key;
    }
    
    NSData *ecdhKey = [KeyHandle getECDHkeyWithPrivkey:privkey publicKey:publickey];
    
    if (needEmptySalt) {
        // Empty salt extension
        ecdhKey = [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdhKey salt:[self get64ZeroData]];
    }
    
    if ([data isKindOfClass:[NSString class]]) {
        data = [data dataUsingEncoding:NSUTF8StringEncoding];
    } else{
        StructData *structData = [StructData new];
        structData.plainData = data;
        structData.random = [self get16_32RandData];
        data = structData.data;
    }
    return [self createGcmDataWithEcdhkey:ecdhKey data:data aad:aad];
}

+ (MessagePost *)createMessagePostWithEcdhKey:(NSData *)ecdhkey
                                messageString:(MMMessage *)message{
    
    NSString *messageString = [message mj_JSONString];
    
    NSData *aad = nil;
    if (!aad) {
        aad = [ServerCenter shareCenter].defineAad;
        if (!aad) {
            aad = [self getIvData];
        }
    }
    GcmData *messageGcmData = [self createGcmDataWithEcdhkey:ecdhkey data:[messageString dataUsingEncoding:NSUTF8StringEncoding] aad:aad];
    
    MessageData *messageData = [[MessageData alloc] init];
    messageData.cipherData = messageGcmData;
    messageData.receiverAddress = message.publicKey;
    messageData.msgId = message.message_id;
    messageData.typ = message.type;
    
    
    NSString *sign = [KeyHandle signHashWithPrivkey:[[LKUserCenter shareCenter] currentLoginUser].prikey data:[KeyHandle hexStringFromData:[messageData data]]];
    
    MessagePost *messagePost = [[MessagePost alloc] init];
    messagePost.sign = sign;
    messagePost.pubKey = [[LKUserCenter shareCenter] currentLoginUser].pub_key;
    messagePost.msgData = messageData;
    
    return messagePost;
}


+ (IMRequest *)createRequestWithData:(GcmData *)gcmData
                             privkey:(NSString *)privkey
                          publickKey:(NSString *)publickey{
    NSString *sign = [self signWithData:gcmData.data Privkey:privkey];
    IMRequest *request = [[IMRequest alloc] init];
    request.pubKey = publickey;
    request.cipherData = gcmData;
    request.sign = sign;
    return request;
}

+ (IMTransferData *)createTransferWithData:(GcmData *)gcmData
                                   privkey:(NSString *)privkey{
    NSString *sign = [self signWithData:gcmData.data Privkey:privkey];
    IMTransferData *request = [[IMTransferData alloc] init];
    request.cipherData = gcmData;
    request.sign = sign;
    return request;
}

+ (NSData *)decodeHttpResponse:(HttpResponse *)hResponse{
    return [self decodeHttpResponse:hResponse withPrivkey:nil publickey:nil];
}

+ (NSData *)decodeHttpNotSignResponse:(HttpNotSignResponse *)hResponse{
    return [self getPlainDataWithData:hResponse.body];
}

+ (NSData *)decodeHttpResponseWithEmptySalt:(HttpResponse *)hResponse{
    return [self decodeHttpResponse:hResponse withPrivkey:nil publickey:nil emptySalt:YES];
}

+ (NSData *)decodeHttpResponse:(HttpResponse *)hResponse
                   withPrivkey:(NSString *)privkey
                     publickey:(NSString *)publickey{
    return [self decodeHttpResponse:hResponse withPrivkey:privkey publickey:publickey emptySalt:NO];
}

+ (NSData *)decodeHttpResponse:(HttpResponse *)hResponse
                   withPrivkey:(NSString *)privkey
                     publickey:(NSString *)publickey
                     emptySalt:(BOOL)emptySalt{
    if (GJCFStringIsNull(publickey)) {
        publickey = [[ServerCenter shareCenter] getCurrentServer].data.pub_key;
    }
    if (GJCFStringIsNull(privkey)) {
        privkey = [[LKUserCenter shareCenter] currentLoginUser].prikey;
    }
    NSData *ecdhKey = [KeyHandle getECDHkeyWithPrivkey:privkey publicKey:publickey];
    
    NSData *salt = [self get64ZeroData];
    if (!emptySalt) {
        salt = [ServerCenter shareCenter].httpTokenSalt;
    }
    ecdhKey = [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdhKey salt:salt];
    
    return [self decodeHttpResponse:hResponse withEcdhKey:ecdhKey];
}



+ (NSData *)decodeHttpResponse:(HttpResponse *)hResponse
                   withEcdhKey:(NSData *)ecdhKey{
    if (!ecdhKey) {
        return nil;
    }
    if (hResponse.code == successCode) {
        IMResponse *imresponse = (IMResponse *)hResponse.body;
        if ([KeyHandle verifyWithPublicKey:[[ServerCenter shareCenter] getCurrentServer].data.pub_key originData:[imresponse.cipherData.data hash256String] signData:imresponse.sign]) {
            NSData *decodeData = [ConnectTool decodeGcmDataWithEcdhKey:ecdhKey GcmData:imresponse.cipherData];
            return decodeData;
        }
    }
    return nil;
}


+ (NSData *)decodeIMTransferData:(IMTransferData *)imTransferData extensionEcdhKey:(NSData *)ecdhKey{
    if ([self vertifyWithData:imTransferData.cipherData.data sign:imTransferData.sign]) {
        NSData *data = [ConnectTool decodeGcmDataWithEcdhKey:ecdhKey GcmData:imTransferData.cipherData];
        return data;
    }
    return nil;
}

+ (NSData *)decodeIMResponse:(IMResponse *)imResponse extensionEcdhKey:(NSData *)ecdhKey{
    if ([self vertifyWithData:imResponse.cipherData.data sign:imResponse.sign]) {
        NSData *data = [ConnectTool decodeGcmDataWithEcdhKey:ecdhKey GcmData:imResponse.cipherData];
        return data;
    }
    return nil;
}


+ (NSData *)get64ZeroData{
    
    NSMutableData *mData = [NSMutableData data];
    
    const char zeroChar = 0x00;
    int len = 64;
    while (len > 0) {
        [mData appendBytes:&zeroChar length:sizeof(zeroChar)];
        len --;
    }
    return [NSData dataWithData:mData];
}

+ (NSString *)generateMessageId{
    return [NSString stringWithFormat:@"%lld%d",(int long long)([[NSDate date] timeIntervalSince1970] * 1000),(arc4random() % 999) + 101];
}

@end
