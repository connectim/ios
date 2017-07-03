//
//  LMIMHelper.h
//  Connect-IM-Encryption
//
//  Created by MoHuilin on 2017/6/13.
//  Copyright © 2017年 connect. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMIMHelper : NSObject

/**
 * Create a new private key
 *
 */
+ (NSString *)creatNewPrivkey;

/**
 * Create a new private key
 *
 */
+ (NSString *)creatNewPrivkeyByRandom:(NSString *)random;

/**
 * Get the public key through the private key
 *
 */
+ (NSString *)getPubkeyByPrikey:(NSString *)prikey;

/**
 * A method of obtaining an address from a private key
 *
 */
+ (NSString *)getAddressByPrivKey:(NSString *)prvkey;

/**
 * Get the address through the public key
 *
 */
+ (NSString *)getAddressByPubkey:(NSString *)pubkey;

/**
 * Check private key
 *
 */
+ (BOOL)checkPrivkey:(NSString *)privkey;

/**
 *  Check the legitimacy of the address
 */
+ (BOOL)checkAddress:(NSString *)address;

/**
 * Generate random numbers
 *
 */
+ (NSData *)createRandom512bits;

/**
 * decode encypt prikey with password
 *
 */
+ (NSDictionary *)decodeEncryptPrikey:(NSString *)encryptPrikey withPassword:(NSString *)password;

/**
 * encode privkey
 */
+ (NSString *)encodeWithPrikey:(NSString *)privkey address:(NSString *)address password:(NSString *)password;

/**
 *  ECDH shared key generation ,eg:group ecdh
 */
+ (NSString *)getECDHkeyUsePrivkey:(NSString *)privkey PublicKey:(NSString *)pubkey;

/**
 * get bytes ecdh key eg:peer chat ecdh
 */
+ (NSData *)getECDHkeyWithPrivkey:(NSString *)privkey publicKey:(NSString *)pubkey;

/**
 * get extend by salt bytes ecdhkey
 */
+ (NSData *)getAes256KeyByECDHKeyAndSalt:(NSData *)password salt:(NSData *)salt;


/**
 * encode chat string
 */
+ (NSDictionary *)xtalkEncodeAES_GCM:(NSString *)password data:(NSString *)dataStr aad:(NSString *)add iv:(NSString *)iv;

/**
 * encode chat data
 */
+ (NSDictionary *)xtalkEncodeAES_GCM:(NSString *)password withNSdata:(NSData *)data aad:(NSString *)aad iv:(NSString *)iv;

/**
 * decode chat string
 */
+ (NSString *)xtalkDecodeAES_GCM:(NSString *)password data:(NSString *)dataStr aad:(NSString *)add iv:(NSString *)iv tag:(NSString *)tagin;

/**
 * decode chat data
 */
+ (NSData *)xtalkDecodeAES_GCMWithPassword:(NSString *)password data:(NSString *)dataStr aad:(NSString *)aad iv:(NSString *)iv tag:(NSString *)tagin;

/**
 * sign data with privkey
 */
+ (NSString *)signHashWithPrivkey:(NSString *)privkey data:(NSString *)data;

/**
 * verfiy data by publickey
 */
+ (BOOL)verifyWithPublicKey:(NSString *)publicKey originData:(NSString *)data signData:(NSString *)signData;


/**
 * encode data with password
 */
+ (NSDictionary *)xtalkEncodeAES_GCMWithPassword:(NSData *)password originData:(NSData *)data aad:(NSData *)aad;

/**
 * decode data with password
 */
+ (NSData *)xtalkDecodeAES_GCMDataWithPassword:(NSData *)password data:(NSData *)data aad:(NSData *)aad iv:(NSData *)iv tag:(NSData *)tag;

@end
