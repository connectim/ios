//
//  AesGCMTool.h
//  Connect
//
//  Created by MoHuilin on 16/5/27.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AesGCMTool : NSObject


/**
   *
   *
   * @param pass symmetric key
   * @param data requires encrypted data
   * @param iv iv
   * @param aad aad
   *
   * @return @ {@ "iv": iv,
                @ "Aad": aad,
                @ "Ciphertext": dict [@ "encryptedDatastring"],
                @ "Tag": dict [@ "tagstring"]}; this structure of the dictionary
 */
+ (NSDictionary *)AES_GCMEncodeWithPass:(NSString *)pass data:(NSString *)data iv:(NSString *)iv aad:(NSString *)aad;


/**
   *
   *
   * @param data requires encrypted data
   *
   * @return @ {@ "iv": iv,
                @ "Aad": aad,
                @ "Ciphertext": dict [@ "encryptedDatastring"],
                @ "Tag": dict [@ "tagstring"]}; this structure of the dictionary
 */
+ (NSDictionary *)AES_GCMEncodeWithCurrentAndServerWithData:(NSString *)data;


/**
   * Used to encrypt data between contacts
   *
   * @param pubkey chat is the public key of the other party
   * @param data requires encrypted data
   *
   * @return @ {@ "iv": iv,
                @ "Aad": aad,
                @ "Ciphertext": dict [@ "encryptedDatastring"],
                @ "Tag": dict [@ "tagstring"]}; this structure of the dictionary
 */
+ (NSDictionary *)getAesGCMEcodeDictWithCurrentAccountPrikeyAndPublicKey:(NSString *)pubkey data:(id)data;

@end
