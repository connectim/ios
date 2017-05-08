//
//  ConnectTool.h
//  Connect
//
//  Created by MoHuilin on 16/8/17.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Protofile.pbobjc.h"

@class MMMessage;

@interface ConnectTool : NSObject

+ (GcmData *)getGcmDataWithEcdhKey:(NSString *)ecdhKey data:(id)data;

+ (GcmData *)getNoStructDataGcmDataWithEcdhKey:(NSString *)ecdhKey data:(id)data;

+ (IMRequest *)createRequestWithEcdhKey:(NSString *)ecdhKey data:(id)data;

+ (IMRequest *)createRequestWithData:(GcmData *)gcmData;



+ (IMTransferData *)createTransferWithData:(GcmData *)gcmData;


+ (NSString *)signWithData:(id)data;
+ (NSString *)signWithData:(id)data Privkey:(NSString *)privkey;

+ (BOOL)vertifyWithData:(id)data sign:(NSString *)sign;
+ (BOOL)vertifyWithData:(id)data sign:(NSString *)sign publickey:(NSString *)publickey;


+ (NSString *)decodeGcmDataGetStringWithEcdhKey:(NSString *)ecdhKey GcmData:(GcmData *)gcmData;
+ (NSString *)decodeMessageGcmData:(GcmData *)gcmData
                         publickey:(NSString *)publickey
                     needEmptySalt:(BOOL)needEmptySalt;

//p2p
+ (NSString *)decodeGcmData:(GcmData *)gcmData
                  publickey:(NSString *)publickey;
+ (NSString *)decodeGcmData:(GcmData *)gcmData
                withPrivkey:(NSString *)privkey
                  publickey:(NSString *)publickey;
+ (NSString *)decodeGroupGcmDataWithEcdhKey:(NSString *)ecdhKey
                                    GcmData:(GcmData *)gcmData;


+ (NSData *)decodeGcmDataGetDataWithEcdhKey:(NSString *)ecdhKey GcmData:(GcmData *)gcmData;

+ (GcmData *)createGcmWithData:(id)data
                     publickey:(NSString *)publickey
                 needEmptySalt:(BOOL)needEmptySalt;
+ (GcmData *)createGcmDataWithEcdhkey:(NSData *)ecdhKey
                                 data:(NSData *)data
                                  aad:(NSData *)aad;
+ (GcmData *)createGcmWithData:(id)data
                     publickey:(NSString *)publickey;
+ (GcmData *)createGcmWithData:(id)data
                           aad:(NSData *)aad;
+ (GcmData *)createGcmWithData:(id)data
                       privkey:(NSString *)privkey
                     publickey:(NSString *)publickey
                           aad:(NSData *)aad
                 needEmptySalt:(BOOL)needEmptySalt;
+ (GcmData *)createGcmDataWithStructDataEcdhkey:(NSData *)ecdhKey
                                           data:(NSData *)data
                                            aad:(NSData *)aad;
+ (GcmData *)createGcmWithData:(id)data
                       ecdhKey:(NSData *)ecdhKey
                 needEmptySalt:(BOOL)needEmptySalt;



+ (NSData *)createStructDataWithData:(NSData *)data;
+ (IMRequest *)createRequestWithEcdhKey:(NSData *)ecdhKey data:(NSData *)data aad:(NSData *)aad;
+ (IMRequest *)createRequestWithData:(GcmData *)gcmData privkey:(NSString *)privkey publickKey:(NSString *)publickey;


+ (NSData *)decodeGcmDataWithEcdhKey:(NSData *)ecdhKey GcmData:(GcmData *)gcmData;
+ (NSData *)decodeGcmDataWithGcmData:(GcmData *)gcmData
                           publickey:(NSString *)publickey;
+ (NSData *)decodeGcmDataWithGcmData:(GcmData *)gcmData
                           publickey:(NSString *)publickey
                       needEmptySalt:(BOOL)needEmptySalt;
+ (NSData *)decodeGcmDataWithGcmData:(GcmData *)gcmData
                             privkey:(NSString *)privkey
                           publickey:(NSString *)publickey;
+ (NSData *)decodeGcmDataWithEcdhKey:(NSData *)ecdhKey
                             GcmData:(GcmData *)gcmData
                      haveStructData:(BOOL)haveStructData;


+ (IMTransferData *)createTransferWithEcdhKey:(NSData *)ecdhKey data:(id)data aad:(NSData *)aad;
+ (MessagePost *)createMessagePostWithEcdhKey:(NSData *)ecdhkey messageString:(MMMessage *)message;


/**
 Verify the signature and decrypt it
   Private key
   Public key
 */
+ (NSData *)decodeHttpResponse:(HttpResponse *)hResponse
                   withPrivkey:(NSString *)privkey
                     publickey:(NSString *)publickey;

+ (NSData *)decodeHttpResponse:(HttpResponse *)hResponse
                   withPrivkey:(NSString *)privkey
                     publickey:(NSString *)publickey
                     emptySalt:(BOOL)emptySalt;


/**
 Verify the signature and decrypt it
   Collaborative key
 */
+ (NSData *)decodeHttpResponse:(HttpResponse *)hResponse
                   withEcdhKey:(NSData *)ecdhKey;

/**
The default is their own private key and the server's public key to do collaborative key
 */
+ (NSData *)decodeHttpResponse:(HttpResponse *)hResponse;

/**
 The default is the private key and the server's public key to do the co-key, salt is not nil
 */
+ (NSData *)decodeHttpResponseWithEmptySalt:(HttpResponse *)hResponse;


+ (NSData *)decodeHttpNotSignResponse:(HttpNotSignResponse *)hResponse;

/**
 Verify and decrypt the data
 */
+ (NSData *)decodeIMTransferData:(IMTransferData *)imTransferData
                extensionEcdhKey:(NSData *)ecdhKey;

+ (NSData *)decodeIMResponse:(IMResponse *)imResponse
            extensionEcdhKey:(NSData *)ecdhKey;

+ (NSData *)get16_32RandData;
+ (NSData *)get64ZeroData;

+ (NSString *)generateMessageId;


/**
 * The other party's ChatCookie expires, using unilateral random
 */
+ (GcmData *)createHalfRandomPeerIMGcmWithData:(NSString *)data chatPubkey:(NSString *)chatPubkey;
+ (NSString *)decodeHalfRandomPeerImMessageGcmData:(GcmData *)gcmData
                                         publickey:(NSString *)publickey
                                              salt:(NSData *)salt;

/**
 * Use temporary co-key encryption
 */
+ (GcmData *)createPeerIMGcmWithData:(NSString *)data chatPubkey:(NSString *)chatPubkey;
+ (NSString *)decodePeerImMessageGcmData:(GcmData *)gcmData
                               publickey:(NSString *)publickey
                                    salt:(NSData *)salt
                                     ver:(NSData *)ver;

@end
