//
//  KeyHandle.m
//  BitMainWallet_Hot
//
//  Created by xunianqiang on 15-1-15.
//  Copyright (c) 2015年 xunianqiang. All rights reserved.
//

#import "KeyHandle.h"
//Note: This class does not reference too many other methods of the class. May be encapsulated
#define sUserDefaults [NSUserDefaults standardUserDefaults]

extern "C" {
#include "bip39.h"
#include "ecies.h"
#include "pbkdf2.h"
}
#include "key.h"
#include <sstream>

#include "base58.h"
#include "script.h"
#include "uint256.h"
#include "util.h"
#include "keydb.h"


#include <string>
#include <vector>

#include <openssl/aes.h>
#include <openssl/evp.h>
#include <openssl/bn.h>
#include <openssl/ecdsa.h>
#include <openssl/obj_mac.h>
#include <openssl/rand.h>
#include <openssl/hmac.h>
#include <openssl/md5.h>


#include <boost/algorithm/string.hpp>
#include <boost/assign/list_of.hpp>
#include "json_spirit_reader_template.h"
#include "json_spirit_utils.h"
#include "json_spirit_writer_template.h"
#include "json_spirit_value.h"
#import "Protofile.pbobjc.h"
#include <CommonCrypto/CommonCrypto.h>



@implementation KeyHandle

+(instancetype)defautKey
{
    static id dc = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        dc = [[[self class]alloc]init];
    });
    return dc;
}

- (instancetype)init
{
    if (self = [super init]) {

    }
    return self;
}

#pragma mark - External method

//  Data is converted to hexadecimalData is converted to hexadecimal
+ (NSString *)hexStringFromData:(NSData *)data{
    
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    
    CC_SHA256(data.bytes, (int32_t)data.length, result);
    
    NSData *newData = [[NSData alloc] initWithBytes:result length:CC_SHA256_DIGEST_LENGTH];
    
    unsigned char Nresult[CC_SHA256_DIGEST_LENGTH];
    
    CC_SHA256(newData.bytes, (int32_t)newData.length, Nresult);
    
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH*2];
    for (int i = 0; i<CC_SHA256_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x",Nresult[i]];
    }
    return ret;

}


// Create a new private key
+ (NSString *)creatNewPrivkey
{
    char privkey[256];
    CreateNewPrivKey(privkey);
    return [NSString stringWithFormat:@"%s",privkey];
}

+ (NSString *)creatNewPrivkeyByRandomStr:(NSString *)randomStr{
    
    char myRand[129] = {0};
    char *randomC = (char *)[randomStr UTF8String];
    sprintf(myRand,"%s",randomC);
    char privKey[512];
    GetPrivKeyFromSeedBIP44(myRand,privKey,44,0,0,0,0);
    return [NSString stringWithFormat:@"%s",privKey];
}
/**
 *  Create a public key with a private key
 */
+(NSString *)createPubkeyByPrikey:(NSString *)prikey
{
    char pubkey[256];
    GetPubKeyFromPrivKey((char *)[prikey UTF8String],pubkey);
    DDLogInfo(@"%s",pubkey);
    return [NSString stringWithFormat:@"%s",pubkey];
}
/**
 *  Get the address through the public key
 */
+(NSString *)getAddressByPubkey:(NSString *)pubkey
{
    char myaddress[128];
    char *myPubkey = (char *)[pubkey UTF8String];
    GetBTCAddrFromPubKey(myPubkey,myaddress);
    return [NSString stringWithFormat:@"%s",myaddress];
}

/**
 *  Access the address via the private key
 *
 */
+ (NSString *)getAddressByPrivKey:(NSString *)prvkey{
    char *cPrivkey = (char *)[prvkey UTF8String];
    char pubKey[128];
    GetPubKeyFromPrivKey(cPrivkey, pubKey);
    char address[128];
    GetBTCAddrFromPubKey(pubKey, address);
//    printf("get address is :%s\n",address);
    return [NSString stringWithFormat:@"%s",address];
}

+(NSString *)getSHA256WithString:(NSString *)string{
    char outstr[256];
    char *cStr = (char *)[string UTF8String];
    GetHash256Str(cStr, outstr);
    return [NSString stringWithFormat:@"%s",outstr];
}


+(NSString *)getEncodePrikey:(NSString *)privkey withBitAddress :(NSString *) bitAddress password:(NSString *)password{
    char usrID_BtcAddress[256];
    char privKey_HexString[65];
    char pass[64];
    int n=17;
    string bitAddressString = [bitAddress UTF8String];
    char * privkeyStr22 = (char *)[privkey UTF8String];
    GetRawPrivKey(privKey_HexString, privkeyStr22);

    sprintf(usrID_BtcAddress,bitAddressString.c_str());
    std::string passwordStr = [password UTF8String];
    sprintf(pass,passwordStr.c_str());
    
    std::string retString=xtalkUsrPirvKeyEncrypt_String(usrID_BtcAddress, privKey_HexString, pass, n, 1);
    printf("xtalk encrypted = %s\n",retString.c_str());
    
    return [NSString stringWithFormat:@"%s",retString.c_str()];
}

+ (NSDictionary *)decodePrikeyGetDict:(NSString *) encodeStr withPassword:(NSString *)password{
    
    if (GJCFStringIsNull(encodeStr) || GJCFStringIsNull(password)) {
        return @{@"is_success":@(NO)};
    }

    
    std::string retString = [encodeStr UTF8String];
    char usrID2_BtcAddress[256];
    char privKey2_HexString[65];
    char privKey[52];
    char pass[64];
    
    string passwordStr = [password UTF8String];
    sprintf(pass,(char *)passwordStr.c_str());
    BOOL isSuccess = NO;
    int ret = xtalkUsrPirvKeyDecrypt_String((char *)retString.c_str(), pass, 1, usrID2_BtcAddress, privKey2_HexString);
    if(ret != 1){
        printf("xtalk decrypted error!\n");
        return nil;
    }
    else
    {
        printf("decrypted userID=%s\n",usrID2_BtcAddress);
        
        printf("decrypted privKey=%s\n",privKey2_HexString);
        GetBtcPrivKeyFromRawPrivKey(privKey, privKey2_HexString);
        printf("%s",privKey);
        isSuccess = YES;
    }
    return @{@"address":[NSString stringWithCString:usrID2_BtcAddress encoding:NSUTF8StringEncoding],
             @"is_success":@(isSuccess),
             @"prikey":[NSString stringWithUTF8String:privKey]};
}


+ (BOOL)decodePrikey:(NSString *) encodeStr withPassword:(NSString *)password{
    std::string retString = [encodeStr UTF8String];
    char usrID2_BtcAddress[256];
    char privKey2_HexString[65];
    char pass[64];
 
    string passwordStr = [password UTF8String];
    sprintf(pass,(char *)passwordStr.c_str());
    int ret = xtalkUsrPirvKeyDecrypt_String((char *)retString.c_str(), pass, 1, usrID2_BtcAddress, privKey2_HexString);
    if(ret != 1){
        printf("xtalk decrypted error!\n");
        return 0;
    }
    else
    {
        printf("decrypted userID=%s\n",usrID2_BtcAddress);
        printf("decrypted privKey=%s\n",privKey2_HexString);
        char privKey[52];
        GetBtcPrivKeyFromRawPrivKey(privKey, privKey2_HexString);
        printf("%s",privKey);
    }
    return 1;
}

+ (NSString *)getBtcPrivKeyFromRawPrivKey:(NSString *)rawPrivkey{

    char *rawP = (char *)[rawPrivkey UTF8String];
    char privKey[52];
    GetBtcPrivKeyFromRawPrivKey(privKey, rawP);
    
    NSString *pri = [NSString stringWithUTF8String:privKey];
    
    return pri;
}

+(NSString *)getPrikeyWithEncodePrivkey:(NSString *) encodeStr withPassword:(NSString *)password{
    std::string retString = [encodeStr UTF8String];
    char usrID2_BtcAddress[36];
    char privKey2_HexString[65];
    char pass[64];
    
    
    char privKey[52];
    string passwordStr = [password UTF8String];
    sprintf(pass,(char *)passwordStr.c_str());
    int ret = xtalkUsrPirvKeyDecrypt_String((char *)retString.c_str(), pass, 1, usrID2_BtcAddress, privKey2_HexString);
    if(ret != 1){
        printf("xtalk decrypted error!\n");
        return nil;
    }
    else
    {
        printf("decrypted userID=%s\n",usrID2_BtcAddress);
        printf("decrypted privKey=%s\n",privKey2_HexString);
        GetBtcPrivKeyFromRawPrivKey(privKey, privKey2_HexString);
    }
    return [NSString stringWithFormat:@"%s",privKey];
}

+(NSString *)getUserIDWithEncodePrivkey:(NSString *) encodeStr withPassword:(NSString *)password{
    std::string retString = [encodeStr UTF8String];
    char usrID2_BtcAddress[36];
    char privKey2_HexString[65];
    char pass[64];
    string passwordStr = [password UTF8String];
    sprintf(pass,(char *)passwordStr.c_str());
    int ret = xtalkUsrPirvKeyDecrypt_String((char *)retString.c_str(), pass, 1, usrID2_BtcAddress, privKey2_HexString);
    if(ret != 1){
        printf("xtalk decrypted error!\n");
        return nil;
    }
    return [NSString stringWithFormat:@"%s",usrID2_BtcAddress];
}

/**
 *  IOS side through openssl get the specified bit length random number
 */
void RNG_openssl(unsigned char *buf, int bits){
    RAND_bytes(buf, bits/8);
}
/**
 *  The IOS side obtains a random number of the specified bit length through the ios system call
 */
void RNG_ios(unsigned char *buf, int bits){
    SecRandomCopyBytes(kSecRandomDefault, bits/8, buf);
}
/**
 *  XOR two data blocks of the same bit length, writing the result to another data block
 */
void XORbits(const void * buf1, const void *buf2, int bits, void *res) {
    for(int i=0; i<bits/8; ++i) {
        ((uint8_t*)res)[i] = ((uint8_t*)buf1)[i]^((uint8_t*)buf2)[i];
    }
}

/**
 *  The APP side generates a random number of cryptographic security
 */
void xtalkRNG(void *buf, int bits){
    // get randnum by openssl
    uint8_t fromOpenssl[bits/8];
    RNG_openssl(fromOpenssl, bits);
    // get randnum by ios
    uint8_t fromIOS[bits/8];
    RNG_ios(fromIOS, bits);
    // mix(xor) two randnum into buf
    XORbits(fromOpenssl, fromIOS, bits, buf);
}

+(NSData *)createRandom512bits {
    uint8_t randNum[512/8];
    xtalkRNG(randNum, 512);
    return [NSData dataWithBytes:randNum length:512/8];
}



+(NSString *)getMaxRandomWithGesture:(NSString *)gestureStr andSysRandomStr:(NSString *)sysRandomStr{
    NSString *newGestureStr = [gestureStr substringWithRange:NSMakeRange(0,16)];
    NSString *newSysRandomStr = [sysRandomStr substringWithRange:NSMakeRange(16,16)];
    
    return [newGestureStr stringByAppendingString:newSysRandomStr];
}

/**
 * Check the legitimacy of the private key
 * // check privkey -1: invalid privkey 0: valid privkey
   Int CheckPrivKey (char * privKey)
 */
+(BOOL) checkPrivkey:(NSString *)privkey{
    char *cPrivkey = (char *)[privkey UTF8String];
    int result = CheckPrivKey(cPrivkey);
    return result==0?YES:NO;
}
/**
 * Check if the address is legal
 *
   // check address -1: invalid address 0: valid address
   Int CheckAddress (char * addr)
 */
+(BOOL) checkAddress:(NSString *)address{
    // Adapt the btc.com sweep results
    address = [address stringByReplacingOccurrencesOfString:@"bitcoin:" withString:@""];
    char *cAddress = (char *)[address UTF8String];
    int result = CheckAddress(cAddress);
    return result == 0?YES:NO;
}

#pragma mark -ECC
/**
 *  ECC encryption
 */
+(NSString *)ECC_EncryptWithPrivkey:(NSString *)privkey_ Pubkey:(NSString *)pubkey_ InputStr:(NSString *)inputStr_
{
    char *privkey = (char *)[privkey_ UTF8String];
    char *pubkey = (char *)[pubkey_ UTF8String];
    //    char *inputStr = (char *)[inputStr_ UTF8String];
    NSString *strUTF8 = [inputStr_ stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    char *inputStr = (char *)[strUTF8 cStringUsingEncoding:NSUTF8StringEncoding];
    
    NSLog(@"inputStr %s",inputStr);
    char *outputStr;
    ECC_encryptEx(privkey, pubkey, inputStr, &outputStr);
    NSLog(@"encrypt out putStr %s",outputStr);
    
    //    ecc
    
    NSString *outPutStr_ = [NSString stringWithFormat:@"%s",outputStr];
    
    free(outputStr);
    
    return outPutStr_;
}

/**
 *ECC unecncryption
 */
+(NSString *)ECC_DecryptWithPrivkey:(NSString *)privkey_ Pubkey:(NSString *)pubkey_ InputEncryptStr:(NSString *)inputEncryptStr_
{
    char *privkey = (char *)[privkey_ UTF8String];
    char *pubkey = (char *)[pubkey_ UTF8String];
    char *inputStr = (char *)[inputEncryptStr_ UTF8String];
    
    char *outputStr;
    ECC_decryptEx(privkey, pubkey, inputStr, &outputStr);
    NSLog(@"decrypt out putStr %s",outputStr);
    
    NSString *outPutStr_ = [NSString stringWithFormat:@"%s",outputStr];
    NSString *DeUTF8Str = [outPutStr_ stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    free(outputStr);
    
    return DeUTF8Str;
}

/**
 *  ECDH Shared key generation
 */

+ (NSString *)getECDHkeyUsePrivkey:(NSString *)privkey PublicKey:(NSString *)pubkey{
    
    char *privkeyc = (char *)[privkey UTF8String];
    char *pubkeyc = (char *)[pubkey UTF8String];
        unsigned char ecdh_key[32];
//    int result = xtalk_getECDHkey(privkeyc, pubkeyc, ecdh_key);
    int len =  xtalk_getRawECDHkey(privkeyc, pubkeyc, ecdh_key);
    if(len == 32){
        
        
        std::vector<unsigned char> outdata;
        outdata.resize(32);
        for(int i=0;i<32;i++)
            outdata[i]=ecdh_key[i];
        std::string str;
        str = BinToHexString(outdata);
        
        str = bytestohexstring((char *)ecdh_key, 32);

        NSString *result =  [NSString stringWithFormat:@"%s",str.c_str()];
        return result;
    }
    
    return @"";
}


+ (NSString *)ORXWithAstring:(NSString *)astr Bstring:(NSString *)bstr{
    NSData *aData = [astr dataUsingEncoding:NSUTF8StringEncoding];
    NSData *bData = [bstr dataUsingEncoding:NSUTF8StringEncoding];
    long int lena = aData.length;
    long int lenb = aData.length;
    
    char *abytes = (char *)[aData bytes];
    char *bbytes = (char *)[bData bytes];
    
    NSMutableString *strM = [[NSMutableString alloc] init];
    
    if(lena == lenb){
        for(int i = 0; i< lena;i++){
            int ch = (int)abytes[i] ^ (int)bbytes[i];
            DDLogInfo(@"%@",[NSString stringWithFormat:@"%d",ch]);
            [strM appendString:[NSString stringWithFormat:@"%d",ch]];
        }
        return strM.copy;
    }
    return @"";
}


+ (NSString *)cdxtalkPBKDF2HMACSHA512Password:(NSString *)pwd salt:(NSString *) salt{
    
    int n = 16;
    
    NSData *pwdData = [pwd dataUsingEncoding:NSUTF8StringEncoding];
    long int pwdLen = pwdData.length;
    
    NSData *saltData = [salt dataUsingEncoding:NSUTF8StringEncoding];
    long int saltLen = saltData.length;
    unsigned char *pwdBytes = (unsigned char *)[pwdData bytes];
    unsigned char *saltBytes = (unsigned char *)[saltData bytes];
    
    unsigned char key[256/8];
    xtalkPBKDF2_HMAC_SHA512(pwdBytes, pwdLen, saltBytes, 64, key, 256, n);
    
//    NSData *keyData = [NSData dataWithBytes:key length:32];
    string str = bytestohexstring((char *)key, 32);
    NSString *keyStr = [NSString stringWithUTF8String:str.c_str()];
 
    return  keyStr;
}


#pragma mark -AES

+ (NSDictionary *)xtalkEncodeAES_GCM:(NSString *)password data:(NSString *)dataStr aad:(NSString *)aad iv:(NSString *) iv{
    
    unsigned char *encryptedData;

    //IV
    std::vector<unsigned char> IVByte;
    IVByte=HexStringToBin([iv UTF8String]);
    
    
    // key
    std::vector<unsigned char> KeyByte;
    KeyByte=HexStringToBin([password UTF8String]);
    
 
    //aad
    std::vector<unsigned char> aadByte;
    aadByte=HexStringToBin([aad UTF8String]);

    std::vector<unsigned char> inDataByte;
    int len;
    unsigned char * indata = (unsigned char *)[dataStr UTF8String];
    string indataStr = (char *)indata;
    len = indataStr.size();
    inDataByte.resize(len);
    for(int i=0;i<len;i++)
        inDataByte[i]=indata[i];

    // accept tag
    unsigned char tag[16];
    
    int encryptedLen=xtalkEncodeAES_gcm(&inDataByte[0],len, &aadByte[0], aadByte.size(), &KeyByte[0], &IVByte[0], IVByte.size(), &encryptedData, tag);

    
    std::string tagstring=HexStr(&tag[0],&tag[16]);
    
    std::string encryptedDatastring=HexStr(&encryptedData[0],&encryptedData[encryptedLen]);
    
    if(encryptedData)
        free(encryptedData);
    
    NSDictionary *resultD = @{
                              @"encryptedDatastring":[[NSString alloc] initWithUTF8String:encryptedDatastring.c_str()],
                              @"tagstring":[[NSString alloc] initWithUTF8String:tagstring.c_str()]
                              };

    return resultD;
}

+ (GcmData *)xtalkEncodeAES_GCMWithPassword:(NSData *)password data:(NSData *)data aad:(NSData *)aad{
    
    if(!data || !password || !aad){
        return nil;
    }
    
    unsigned char *encryptedData;
    
    NSData *ivData = [self createRandom512bits];
    ivData = [ivData subdataWithRange:NSMakeRange(0, 16)];
    
    //IV
    Byte *ivdata = (Byte *)[ivData bytes];
    
    // key
    Byte *keydata = (Byte *)[password bytes];

    //aad
    Byte *aaddata = (Byte *)[aad bytes];
    
    // perapre indata
    Byte *indata = (Byte *)[data bytes];

    //accept tag
    unsigned char tag[16];
    
    int encryptedLen=xtalkEncodeAES_gcm(indata,(int)data.length, aaddata,(int)aad.length, keydata,ivdata,(int)ivData.length, &encryptedData, tag);
    
    if(encryptedLen == -1){
        return nil;
    }
    
    if(encryptedData)
        free(encryptedData);
    
    GcmData *gcmData = [[GcmData alloc] init];
    gcmData.iv = ivData;
    gcmData.aad = aad;
    NSData* ciphertextData = [NSData dataWithBytes:(const void *)encryptedData length:sizeof(unsigned char)*encryptedLen];
    gcmData.ciphertext = ciphertextData;
    NSData* tagData = [NSData dataWithBytes:(const void *)tag length:sizeof(unsigned char)*16];
    gcmData.tag = tagData;
    
    return gcmData;
}

#pragma mark new method

/**
 *  ECDH Shared key generation
 */

+ (NSData *)getECDHkeyWithPrivkey:(NSString *)privkey publicKey:(NSString *)pubkey{
    char *privkeyc = (char *)[privkey UTF8String];
    char *pubkeyc = (char *)[pubkey UTF8String];
    unsigned char ecdh_key[32];
    int len =  xtalk_getRawECDHkey(privkeyc, pubkeyc, ecdh_key);
    if(len == 32){
        NSData* ecdhData = [NSData dataWithBytes:(const void *)ecdh_key length:sizeof(unsigned char)*32];
        return ecdhData;
    }
    return nil;
}


+ (NSDictionary *)xtalkEncodeAES_GCMWithPassword:(NSData *)password originData:(NSData *)data aad:(NSData *)aad{
    
    if(!data || data.length <= 0 || !password  || password.length <= 0 || !aad || aad.length <= 0){
        return nil;
    }
    
    unsigned char *encryptedData;
    
    NSData *ivData = [self createRandom512bits];
    ivData = [ivData subdataWithRange:NSMakeRange(0, 16)];
    
    //IV
    unsigned char *ivdata = (unsigned char *)[ivData bytes];
    
    // key
    unsigned char *keydata = (unsigned char *)[password bytes];
    
    //aad
    unsigned char *aaddata = (unsigned char *)[aad bytes];
    
    // perapre indata
    unsigned char *indata = (unsigned char *)[data bytes];
    
    //接受tag
    unsigned char tag[16];
    
    int encryptedLen=xtalkEncodeAES_gcm(indata,data.length, aaddata,aad.length, keydata,ivdata,ivData.length, &encryptedData, tag);
    
    if(encryptedLen == -1){
        return nil;
    }

    NSData* ciphertextData = [NSData dataWithBytes:(const void *)encryptedData length:sizeof(unsigned char)*encryptedLen];
    NSData* tagData = [NSData dataWithBytes:(const void *)tag length:sizeof(unsigned char)*16];
    
    NSDictionary *cipTagDict = @{@"ciphertext":ciphertextData,
                                 @"tag":tagData,
                                 @"iv":ivData};
    if(encryptedData)
        free(encryptedData);
    
    return cipTagDict;
}

+ (NSData *)get16_32RandData{
    NSData *randomData = [self createRandom512bits];
    int loc = arc4random() % 32;
    int len = arc4random() % 16 + 16;
    randomData = [randomData subdataWithRange:NSMakeRange(loc, len)];
    return randomData;
}




+ (NSDictionary *)xtalkEncodeAES_GCM:(NSString *)password withNSdata:(NSData *)data aad:(NSString *)aad iv:(NSString *) iv{
    
    if(!data){
        return nil;
    }
    if(GJCFStringIsNull(password)){
        return nil;
    }
    
    
    unsigned char *encryptedData;
    unsigned char *decryptedData;
    
    //IV
    std::vector<unsigned char> IVByte;
    IVByte=HexStringToBin([iv UTF8String]);
    
    
    // key
    std::vector<unsigned char> KeyByte;
    KeyByte=HexStringToBin([password UTF8String]);
    
    
    //aad
    std::vector<unsigned char> aadByte;
    aadByte=HexStringToBin([aad UTF8String]);
    
    
    
    // perapre indata
    int indatalen = data.length;
    Byte *indata = (Byte *)[data bytes];
    
    unsigned char tag[16];

    int encryptedLen=xtalkEncodeAES_gcm(indata,indatalen, &aadByte[0], aadByte.size(), &KeyByte[0], &IVByte[0], IVByte.size(), &encryptedData, tag);
    if(encryptedLen == -1){
        return nil;
    }
    
    std::string tagstring=HexStr(&tag[0],&tag[16]);
    
    std::string encryptedDatastring=HexStr(&encryptedData[0],&encryptedData[encryptedLen]);
    
    if(encryptedData)
        free(encryptedData);
    
    NSDictionary *resultD = @{
                              @"encryptedDatastring":[[NSString alloc] initWithUTF8String:encryptedDatastring.c_str()],
                              @"tagstring":[[NSString alloc] initWithUTF8String:tagstring.c_str()]
                              };

    
    return resultD;
}




+ (NSData *)xtalkDecodeAES_GCMWithPassword:(NSString *)password data:(NSString *)dataStr aad:(NSString *)aad iv:(NSString *) iv tag:(NSString *)tagin{
    unsigned char *decryptedData;
    
    
    std::vector<unsigned char> IVByte;
    IVByte=HexStringToBin([iv UTF8String]);
    
    // key
    std::vector<unsigned char> KeyByte;
    KeyByte=HexStringToBin([password UTF8String]);
    
    //aad
    std::vector<unsigned char> aadByte;
    aadByte=HexStringToBin([aad UTF8String]);
    
    // perapre indata
    string indataStr = [dataStr UTF8String];
    
    std::vector<unsigned char> inDataByte;
    inDataByte = HexStringToBin(indataStr);
    
    
    std::vector<unsigned char> tagByte;
    tagByte=HexStringToBin([tagin UTF8String]);
    
    
    int decryptedLen=xtalkDecodeAES_gcm(&inDataByte[0], inDataByte.size(), &aadByte[0], aadByte.size(), &tagByte[0], &KeyByte[0], &IVByte[0], IVByte.size(), &decryptedData);
    
    
    NSData *result = nil;
    
    if(decryptedLen < 0){
        return result;
    }
    std::vector<unsigned char> resultData;
    resultData.resize(decryptedLen);
    for(int i=0;i<decryptedLen;i++){
        resultData[i]=decryptedData[i];
    }
    
    if(decryptedLen>0)
    {
        result = [[NSData alloc] initWithBytes:&resultData[0]  length:decryptedLen];
    }
    else
    {
        std::string error=xtalk_getErrInfo();
        printf("Error: %s\n",error.c_str());
    }
    
    if(decryptedData)
        free(decryptedData);
    
    return result;
}


+ (NSData *)xtalkDecodeAES_GCMDataWithPassword:(NSData *)password data:(NSData *)data aad:(NSData *)aad iv:(NSData *)iv tag:(NSData *)tag{
    
    unsigned char *decryptedData;
    
    
    unsigned char *IVByte = (unsigned char*)[iv bytes];
    
    unsigned char *KeyByte = (unsigned char*)[password bytes];
    
    unsigned char *inDataByte = (unsigned char*)[data bytes];
    
    unsigned char *aadByte = (unsigned char*)[aad bytes];
    
    unsigned char *tagByte = (unsigned char*)[tag bytes];

    
    int decryptedLen=xtalkDecodeAES_gcm(inDataByte, data.length, aadByte, aad.length, tagByte, KeyByte, IVByte, iv.length, &decryptedData);
    
    NSData *result = nil;
    
    if(decryptedLen>0)
    {
        result = [[NSData alloc] initWithBytes:&decryptedData[0]  length:decryptedLen];
    }
    else
    {
        std::string error=xtalk_getErrInfo();
        printf("Error: %s\n",error.c_str());
    }
    
    if(decryptedData)
        free(decryptedData);
    
    return result;
}


+ (NSString *)xtalkDecodeAES_GCM:(NSString *)password data:(NSString *)dataStr aad:(NSString *)aad iv:(NSString *) iv tag:(NSString *)tagin{
    unsigned char *decryptedData;
    
    
    std::vector<unsigned char> IVByte;
    IVByte=HexStringToBin([iv UTF8String]);

    // key
    std::vector<unsigned char> KeyByte;
    KeyByte=HexStringToBin([password UTF8String]);
    
    //aad
    std::vector<unsigned char> aadByte;
    aadByte=HexStringToBin([aad UTF8String]);
    
    // perapre indata
    string indataStr = [dataStr UTF8String];
    std::vector<unsigned char> inDataByte;
    inDataByte = HexStringToBin(indataStr);
    
    
    std::vector<unsigned char> tagByte;
    tagByte=HexStringToBin([tagin UTF8String]);
    
    
    int decryptedLen=xtalkDecodeAES_gcm(&inDataByte[0], inDataByte.size(), &aadByte[0], aadByte.size(), &tagByte[0], &KeyByte[0], &IVByte[0], IVByte.size(), &decryptedData);
    
    
    NSString *result = @"";
    
    if(decryptedLen < 0){
        return result;
    }
    std::vector<unsigned char> resultData;
    resultData.resize(decryptedLen);
    for(int i=0;i<decryptedLen;i++){
        resultData[i]=decryptedData[i];
    }
    
    if(decryptedLen>0)
    {
        result = [[NSString alloc] initWithBytes:&resultData[0] length:decryptedLen encoding:NSUTF8StringEncoding];
    }
    else
    {
        std::string error=xtalk_getErrInfo();
        printf("Error: %s\n",error.c_str());
    }
    
    if(decryptedData)
        free(decryptedData);
    
    return result;
}



+ (NSString *)xtalkEncodeAES:(NSString *)password data:(NSString *)dataStr{
    unsigned char *encryptedData;
    
    // key
    std::vector<unsigned char> KeyByte;
    KeyByte=HexStringToBin([password UTF8String]);
    
    // perapre indata
    unsigned char * indata = (unsigned char *)[dataStr UTF8String];
    string indataStr = (char *)indata;
    int len = indataStr.size();
    
    std::vector<unsigned char> inData1;
    inData1.resize(len);
    for(int i=0;i<len;i++)
        inData1[i]=indata[i];
    
    
    
    int encryptedLen=xtalkEncodeAES_cbc(&KeyByte[0],32,&inData1[0],len,&encryptedData);
    
    printf("indata[40] encrypted len = %d\n encryptedData is %s",encryptedLen,encryptedData);
    
    std::vector<unsigned char> outdata;
    outdata.resize(encryptedLen);
    for(int i=0;i<encryptedLen;i++)
        outdata[i]=encryptedData[i];
    std::string str;
    str=BinToHexString(outdata);
    
    NSString *result = [[NSString alloc] initWithUTF8String:(const char *)str.c_str()];
    free(encryptedData);
    
    return result;
}

+ (NSString *)xtalkDecodeAES:(NSString *)password data:(NSString *)dataStr{
    unsigned char *decryptedData;
    
    std::vector<unsigned char> KeyByte;
    KeyByte=HexStringToBin([password UTF8String]);
    string indata = [dataStr UTF8String];
    
    unsigned long int len = indata.length() / 2;
    
    std::vector<unsigned char> bytedata;
    bytedata=HexStringToBin(indata);
    
    int decryptedLen=xtalkDecodeAES_cbc(&KeyByte[0],32,&bytedata[0],len,&decryptedData);

    std::vector<unsigned char> resultData;
    resultData.resize(decryptedLen);
    for(int i=0;i<decryptedLen;i++){
        resultData[i]=decryptedData[i];
    }
    printf("====%s   ，len %lu==",&resultData[0],resultData.size());
    
    
    printf("Test dencrypted len = %d\n decryptedData is :%s",decryptedLen,decryptedData);
    
    NSString *result = [[NSString alloc] initWithBytes:&resultData[0] length:decryptedLen encoding:NSUTF8StringEncoding];
    free(decryptedData);
    return result;
}

#pragma mark - 原始私钥

+ (NSString *)getRawPrivkey:(NSString *)privkey{
    char *privkey_ = (char *)[privkey UTF8String];

    char rawPrivKey[256];
    GetRawPrivKey(rawPrivKey,privkey_);
    
    return [NSString stringWithUTF8String:rawPrivKey];
}

#pragma mark - sign math
+ (NSString *)signHashWithPrivkey:(NSString *)privkey data:(NSString *)data
{
    
    
    if (GJCFStringIsNull(privkey) || !data) {
        return nil;
    }
    
    char *privkey_ = (char *)[privkey UTF8String];
    char *hashstr = (char *)[data UTF8String];
    char signStr[256];
    int result = SignHash(privkey_, hashstr, signStr);
    if(result == 0){
        return [NSString stringWithUTF8String:signStr];
    }
    
    return nil;
    
}


+ (BOOL)verfyWithPublicKey:(NSString *)pub signData:(NSString *)signData
{
    NSString *data = @"abcd";
    char *data_ = (char *)[data UTF8String];
    char *publicKey_ = (char *)[pub UTF8String];
    char *signData_ = (char *)[signData UTF8String];
    char hashstr[256];
    GetHash256Str(data_, hashstr);
    int result = VerifySign(publicKey_,hashstr,signData_);
    if(result == 1){
        return YES;
    }
    return NO;
}

+ (NSString *)getHash256:(NSString *)string{
    char hashstr[256];
    char *data = (char *)[string UTF8String];
    GetHash256Str(data, hashstr);
    return [NSString stringWithUTF8String:hashstr];
}

+ (NSString *)getHash256Byte:(NSData *)string{
    char hashstr[256];
    char *data = (char *)[string bytes];
    GetHash256Str(data, hashstr);
    
    
    return [NSString stringWithUTF8String:hashstr];
}

+ (BOOL)verifyWithPublicKey:(NSString *)publicKey originData:(NSString *)data signData:(NSString *)signData
{
    if (GJCFStringIsNull(publicKey) || GJCFStringIsNull(signData)) {
        return NO;
    }
    char *publicKey_ = (char *)[publicKey UTF8String];
    char *signData_ = (char *)[signData UTF8String];
    char *hashstr_ = (char *)[data UTF8String];
    int result = VerifySign(publicKey_,hashstr_,signData_);
    if(result == 1){
        return YES;
    }
    return NO;
}


+ (NSString *)getPassByPrikey:(NSString *)prikey{
 
    return [self getHash256:prikey];
}


#pragma mark - hex to bin /// bin to hex

unsigned char strToChar (char a, char b)
{
    char encoder[3] = {'\0','\0','\0'};
    encoder[0] = a;
    encoder[1] = b;
    return (char) strtol(encoder,NULL,16);
}

+ (NSData *)hexStringToData:(NSString *)hex{
    
    std::vector<unsigned char> binByte;
    binByte=HexStringToBin([hex UTF8String]);
    
    NSData * data = [[NSData alloc]
                   initWithBytesNoCopy:binByte.data()
                   length:binByte.size()
                   freeWhenDone:YES];

    return data;


}

#pragma mark - c++ Auxiliary code

#pragma mark - Hexadecimal string char array conversion


std::string BinToHexString(std::vector<unsigned char> data)
{
    return HexStr(data);
}

std::vector<unsigned char> HexStringToBin(std::string str)
{
    return ParseHex(str);
}

char* hextostr(const std::string& hexStr)
{
    size_t len = hexStr.length();
    int k=0;
    if (len & 1) return NULL;
    
    char* output = new char[(len/2)+1];
    for (size_t i = 0; i < len; i+=2)
    {
        output[k++] = (((hexStr[i] >= 'A')? (hexStr[i] - 'A' + 10): (hexStr[i] - '0')) << 4) |
        (((hexStr[i+1] >= 'A')? (hexStr[i+1] - 'A' + 10): (hexStr[i+1] - '0')));
    }
    output[k] = '\0';
    return output;
}

int hexCharToInt(char c)
{
    if (c >= '0' && c <= '9') return (c - '0');
    if (c >= 'A' && c <= 'F') return (c - 'A' + 10);
    if (c >= 'a' && c <= 'f') return (c - 'a' + 10);
    return 0;
}

char* hexstringToBytes(string s)
{
    int sz = s.length();
    char *ret = new char[sz/2];
    for (int i=0 ; i <sz ; i+=2) {
        ret[i/2] = (char) ((hexCharToInt(s.at(i)) << 4)
                           | hexCharToInt(s.at(i+1)));
    }
    return ret;
}

string bytestohexstring(char* bytes,int bytelength)
{
    string str("");
    string str2("0123456789abcdef");
    for (int i=0;i<bytelength;i++) {
        int b;
        b = 0x0f&(bytes[i]>>4);
        char s1 = str2.at(b);
        str.append(1,str2.at(b));
        b = 0x0f & bytes[i];
        str.append(1,str2.at(b));
        char s2 = str2.at(b);
    }
    return str;
}

#pragma mark -

char *ossl_err_as_string (void)
{ BIO *bio = BIO_new (BIO_s_mem ());
    ERR_print_errors (bio);
    char *buf = NULL;
    size_t len = BIO_get_mem_data (bio, &buf);
    char *ret = (char *) calloc (1, 1 + len);
    if (ret)
        memcpy (ret, buf, len);
    BIO_free (bio);
    return ret;
}

std::string xtalk_getErrInfo()
{
    char *perror=ossl_err_as_string();
    std::string err=perror;
    free(perror);
    return err;
}

unsigned int xtalkEncodeAES_cbc_IV(unsigned char *IV, unsigned char *password, int passlen, unsigned char *data, unsigned int dataLen, unsigned char **out_data)
{
    unsigned char initval_hex[16]={0x23,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x33};
    AES_KEY aes_key;
    
    *out_data=NULL;
    
    if(AES_set_encrypt_key((const unsigned char*)password, passlen * 8, &aes_key) < 0)
    {
        assert(false);
        return -1;
    }
    if(IV)
        memcpy(initval_hex,IV,16);
    
    unsigned char *data_bak;
    unsigned int ret_len = dataLen;
    //  if (dataLen % AES_BLOCK_SIZE > 0)
    {
        ret_len +=  AES_BLOCK_SIZE - (dataLen % AES_BLOCK_SIZE);
    }
    data_bak=(unsigned char *)malloc(ret_len);
    memset(data_bak,AES_BLOCK_SIZE - (dataLen % AES_BLOCK_SIZE),ret_len);	// padding as PKCS7
    memcpy(data_bak,data,dataLen);
    
    *out_data=(unsigned char *)malloc(ret_len);	// malloc for encrypted data to return
    unsigned char *pOut = *out_data;
    
    for(unsigned int i = 0; i < ret_len/AES_BLOCK_SIZE; i++)
    {
        unsigned char out[AES_BLOCK_SIZE];
        ::memset(out, 0, AES_BLOCK_SIZE);
        //AES_encrypt((const unsigned char*)(&data_bak[i*AES_BLOCK_SIZE]), out, &aes_key);
        AES_cbc_encrypt(&data_bak[AES_BLOCK_SIZE*i], out, AES_BLOCK_SIZE,&aes_key,initval_hex, AES_ENCRYPT);
        memcpy(&pOut[i*AES_BLOCK_SIZE], out, AES_BLOCK_SIZE);
    }
    free(data_bak);
    
    return ret_len;
}

int xtalkDecodeAES_cbc_IV(unsigned char *IV, unsigned char *password, int passlen, unsigned char *data, unsigned int dataLen, unsigned char **out_data)
{
    unsigned char initval_hex[16]={0x23,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x33};
    AES_KEY aes_key;
    
    *out_data=NULL;
    if(AES_set_decrypt_key((const unsigned char*)password, passlen * 8, &aes_key) < 0)
    {
        assert(false);
        return 0;
    }
    
    if(IV)
        memcpy(initval_hex,IV,16);
    
    if (dataLen % AES_BLOCK_SIZE > 0)
    {
        // must be AES_BLOCK_SIZE's multiplier
        assert(false);
        return 0;
    }
    *out_data=(unsigned char *)malloc(dataLen);	// malloc for encrypted data to return
    unsigned char *pOut = *out_data;
    
    for(unsigned int i = 0; i < dataLen/AES_BLOCK_SIZE; i++)
    {
        unsigned char out[AES_BLOCK_SIZE];
        ::memset(out, 0, AES_BLOCK_SIZE);
        //    AES_cbc_encrypt(&data[AES_BLOCK_SIZE*i], out, &aes_key);
        AES_cbc_encrypt(&data[AES_BLOCK_SIZE*i], out,AES_BLOCK_SIZE,&aes_key,initval_hex, AES_DECRYPT);
        memcpy(&pOut[AES_BLOCK_SIZE*i],out, AES_BLOCK_SIZE);
    }
    return dataLen-pOut[dataLen-1];	// decrease the PKCS padding length
}


int xtalkEncodeAES_gcm(unsigned char *plaintext, int plaintext_len, unsigned char *aad,
                       int aad_len, unsigned char *key, unsigned char *iv, int ivlen,
                       unsigned char **cipherret, unsigned char *tag)
{
    EVP_CIPHER_CTX *ctx;
    
    int len;
    unsigned char *ciphertext;
    int ciphertext_len;
    
    unsigned char initval_hex[16]={0x23,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x33};
    
    if((!iv) || ivlen<=0)
    {
        iv=initval_hex;
        ivlen=16;
    }
    
    *cipherret=(unsigned char *)malloc(plaintext_len);
    ciphertext=*cipherret;
    
    /* Create and initialise the context */
    if(!(ctx = EVP_CIPHER_CTX_new()))
    {
        printf("EVP_CIPHER_CTX_new error!\n");
        free(ciphertext);
        *cipherret=NULL;
        return -1;
    }
    
    /* Initialise the encryption operation. */
    if(1 != EVP_EncryptInit_ex(ctx, EVP_aes_256_gcm(), NULL, NULL, NULL))
    {
        printf("EVP_EncryptInit_ex error!\n");
        free(ciphertext);
        *cipherret=NULL;
        return -1;
    }
    
    /* Set IV length if default 12 bytes (96 bits) is not appropriate */
    if(1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, ivlen, NULL))
    {
        printf("EVP_CIPHER_CTX_ctrl error!\n");
        free(ciphertext);
        *cipherret=NULL;
        return -1;
    }
    
    /* Initialise key and IV */
    if(1 != EVP_EncryptInit_ex(ctx, NULL, NULL, key, iv))
    {
        printf("EVP_EncryptInit_ex error!\n");
        free(ciphertext);
        *cipherret=NULL;
        return -1;
    }
    
    /* Provide any AAD data. This can be called zero or more times as
     * required
     */
    if(1 != EVP_EncryptUpdate(ctx, NULL, &len, aad, aad_len))
    {
        printf("EVP_EncryptUpdate error!\n");
        free(ciphertext);
        *cipherret=NULL;
        return -1;
    }
    
    /* Provide the message to be encrypted, and obtain the encrypted output.
     * EVP_EncryptUpdate can be called multiple times if necessary
     */
    if(1 != EVP_EncryptUpdate(ctx, ciphertext, &len, plaintext, plaintext_len))
    {
        printf("EVP_EncryptUpdate error!\n");
        free(ciphertext);
        *cipherret=NULL;
        return -1;
    }
    ciphertext_len = len;
    
    /* Finalise the encryption. Normally ciphertext bytes may be written at
     * this stage, but this does not occur in GCM mode
     */
    if(1 != EVP_EncryptFinal_ex(ctx, ciphertext + len, &len))
    {
        printf("EVP_EncryptFinal_ex error!\n");
        free(ciphertext);
        *cipherret=NULL;
        return -1;
    }
    ciphertext_len += len;
    
    /* Get the tag */
    if(1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_GET_TAG, 16, tag))
    {
        printf("EVP_CIPHER_CTX_ctrl error!\n");
        free(ciphertext);
        *cipherret=NULL;
        return -1;
    }
    
    /* Clean up */
    EVP_CIPHER_CTX_free(ctx);
    
    return ciphertext_len;
}

int xtalkDecodeAES_gcm(unsigned char *ciphertext, int ciphertext_len, unsigned char *aad,
                       int aad_len, unsigned char *tag, unsigned char *key, unsigned char *iv, int ivlen,
                       unsigned char **plainret)
{
    EVP_CIPHER_CTX *ctx;
    int len;
    unsigned char *plaintext;
    int plaintext_len;
    int ret;
    
    unsigned char initval_hex[16]={0x23,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x33};
    
    if((!iv) || ivlen<=0)
    {
        iv=initval_hex;
        ivlen=16;
    }
    
    *plainret=(unsigned char *)malloc(ciphertext_len);
    plaintext=*plainret;
    
    /* Create and initialise the context */
    if(!(ctx = EVP_CIPHER_CTX_new()))
    {
        printf("EVP_CIPHER_CTX_new error!\n");
        free(plaintext);
        *plainret=NULL;
        return -1;
    }
    
    /* Initialise the decryption operation. */
    if(!EVP_DecryptInit_ex(ctx, EVP_aes_256_gcm(), NULL, NULL, NULL))
    {
        printf("EVP_DecryptInit_ex error!\n");
        free(plaintext);
        *plainret=NULL;
        return -1;
    }
    
    /* Set IV length. Not necessary if this is 12 bytes (96 bits) */
    if(!EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, ivlen, NULL))
    {
        printf("EVP_CIPHER_CTX_ctrl error!\n");
        free(plaintext);
        *plainret=NULL;
        return -1;
    }
    
    /* Initialise key and IV */
    if(!EVP_DecryptInit_ex(ctx, NULL, NULL, key, iv))
    {
        printf("EVP_DecryptInit_ex error!\n");
        free(plaintext);
        *plainret=NULL;
        return -1;
    }
    
    /* Provide any AAD data. This can be called zero or more times as
     * required
     */
    if(!EVP_DecryptUpdate(ctx, NULL, &len, aad, aad_len))
    {
        printf("EVP_DecryptUpdate error!\n");
        free(plaintext);
        *plainret=NULL;
        return -1;
    }
    
    /* Provide the message to be decrypted, and obtain the plaintext output.
     * EVP_DecryptUpdate can be called multiple times if necessary
     */
    if(!EVP_DecryptUpdate(ctx, plaintext, &len, ciphertext, ciphertext_len))
    {
        printf("EVP_DecryptUpdate error!\n");
        free(plaintext);
        *plainret=NULL;
        return -1;
    }
    plaintext_len = len;
    
    /* Set expected tag value. Works in OpenSSL 1.0.1d and later */
    if(!EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, 16, tag))
    {
        printf("EVP_CIPHER_CTX_ctrl error!\n");
        free(plaintext);
        *plainret=NULL;
        return -1;
    }	
    
    /* Finalise the decryption. A positive return value indicates success,
     * anything else is a failure - the plaintext is not trustworthy.
     */
    ret = EVP_DecryptFinal_ex(ctx, plaintext + len, &len);
    
    /* Clean up */
    EVP_CIPHER_CTX_free(ctx);
    
    if(ret > 0)
    {
        /* Success */
        plaintext_len += len;
        return plaintext_len;
    }
    else
    {
        /* Verify failed */
        printf("GCM Verify failed!\n");
        free(plaintext);
        *plainret=NULL;
        return -1;
    }
}

#pragma mark - wallet


+ (NSString *)createRawTranscationWithTvsArray:(NSArray *)tvsArray outputs:(NSDictionary *)outputs{
    
    // checkout format
    for (NSDictionary *temD in tvsArray) {
        if (![temD isKindOfClass:[NSDictionary class]]) {
            return nil;
        }
        if (![temD.allKeys containsObject:@"vout"]) {
            return nil;
        }
        if (![temD.allKeys containsObject:@"txid"]) {
            return nil;
        }
        if (![temD.allKeys containsObject:@"scriptPubKey"]) {
            return nil;
        }
    }
    
    NSString *tvsJson = [self ObjectTojsonString:tvsArray];
    NSString *outputJson = [self ObjectTojsonString:outputs];
    NSString *inparamStr_ = [NSString stringWithFormat:@"%@ %@",tvsJson,outputJson];
    
    
    char *rawtrans_str;
    char inparam[1024 * 100];
    
    const char *inparam1 = [inparamStr_ UTF8String];// Naked trading data
    strcpy(inparam,inparam1);
    printf("start to call: createrawtransaction  %s\n",inparam);
    
    createRawTranscation(inparam,&rawtrans_str);
    printf("createRawTranscation=%s\n",rawtrans_str);
    
    NSString *rawTranscation = [NSString stringWithUTF8String:rawtrans_str];
    free(rawtrans_str);
    return rawTranscation;
}


+ (NSString *)signRawTranscationWithTvsArray:(NSArray *)tvsArray privkeys:(NSArray *)privkeys rawTranscation:(NSString *)rawTranscation{
    
    for (NSDictionary *temD in tvsArray) {
        if (![temD isKindOfClass:[NSDictionary class]]) {
            return nil;
        }
        if (![temD.allKeys containsObject:@"vout"]) {
            return nil;
        }
        if (![temD.allKeys containsObject:@"txid"]) {
            return nil;
        }
        if (![temD.allKeys containsObject:@"scriptPubKey"]) {
            return nil;
        }
    }
    
    NSString *tvsJson = [self ObjectTojsonString:tvsArray];
    
    
    const char *rawtrans_str = [rawTranscation UTF8String];
    char *signedtrans_ret;
    char inparam[1024 * 100];
    
    NSArray * privkeyArr_ =  privkeys;//
    // Signature parameters json data
    NSMutableString *signParamStr = [NSMutableString stringWithFormat:@"%s",rawtrans_str];
    [signParamStr appendString:@" "];
    [signParamStr appendString:tvsJson];
    [signParamStr appendString:@" "];
    NSString *privKeyJson = [self ObjectTojsonString:privkeyArr_];
    [signParamStr appendString:privKeyJson];
    const char *inparam2 = [signParamStr UTF8String];//sign data
    strcpy(inparam,inparam2);
    
    
    signRawTranscation(inparam,&signedtrans_ret);
    printf("signRawTranscation=%s\n",signedtrans_ret);
    
    NSString *signedStr = [NSString stringWithFormat:@"%s",signedtrans_ret];
    
    
    free(signedtrans_ret);
    
    NSError *error;
    NSDictionary *completeDic = [NSJSONSerialization JSONObjectWithData:[signedStr dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
    BOOL b = [[completeDic objectForKey:@"complete"] boolValue];
    if (b) {
        NSString *result = [completeDic objectForKey:@"hex"];
        
        return result;
    }
    NSLog(@"signRawTranscation is failure,please check!");
    
    return nil;
    
}


+ (NSString *)packTransactionWithTvsArray:(NSArray *)tvsArray outputs:(NSDictionary *)outputs privkeys:(NSArray *)privkeys serverFee:(double)serverFee{


    if (tvsArray.count != privkeys.count) {
        return nil;
    }
    
    // check format
    for (NSDictionary *temD in tvsArray) {
        if (![temD isKindOfClass:[NSDictionary class]]) {
            return nil;
        }
        if (![temD.allKeys containsObject:@"vout"]) {
            return nil;
        }
        if (![temD.allKeys containsObject:@"txid"]) {
            return nil;
        }
        if (![temD.allKeys containsObject:@"scriptPubKey"]) {
            return nil;
        }
    }
    
    if (serverFee < 0) {
        serverFee = 0.f;
    }
    
    NSString *tvsJson = [self ObjectTojsonString:tvsArray];
    NSString *outputJson = [self ObjectTojsonString:outputs];
    NSString *inparamStr_ = [NSString stringWithFormat:@"%@ %@",tvsJson,outputJson];
    
    
    char *rawtrans_str;
    char *signedtrans_ret;
    char inparam[1024 * 100];

    
    const char *inparam1 = [inparamStr_ UTF8String];// Naked trading data
    strcpy(inparam,inparam1);
    printf("start to call: createrawtransaction  %s\n",inparam);
    
    createRawTranscation(inparam,&rawtrans_str);
    printf("createRawTranscation=%s\n",rawtrans_str);
    
    NSArray * privkeyArr_ =  privkeys;//
    // Signature parameters json data
    NSMutableString *signParamStr = [NSMutableString stringWithFormat:@"%s",rawtrans_str];
    [signParamStr appendString:@" "];
    [signParamStr appendString:tvsJson];
    [signParamStr appendString:@" "];
    NSString *privKeyJson = [self ObjectTojsonString:privkeyArr_];
    [signParamStr appendString:privKeyJson];
    const char *inparam2 = [signParamStr UTF8String];// sign data
    strcpy(inparam,inparam2);
    
    
    signRawTranscation(inparam,&signedtrans_ret);
    printf("signRawTranscation=%s\n",signedtrans_ret);
    
    NSString *signedStr = [NSString stringWithFormat:@"%s",signedtrans_ret];
    
    free(rawtrans_str);
    free(signedtrans_ret);
    
    NSError *error;
    NSDictionary *completeDic = [NSJSONSerialization JSONObjectWithData:[signedStr dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
    BOOL b = [[completeDic objectForKey:@"complete"] boolValue];
    if (b) {
        NSString *result = [completeDic objectForKey:@"hex"];
        
        return result;
    }
    NSLog(@"signRawTranscation is failure,please check!");
    
    return nil;
    
}


/**
  * Multiple signature generation transaction recipients
 */
+(NSDictionary *)createMultiSignTranscationWithTVS:(NSArray *)tvsArray PrivKeys:(NSArray*)privkeyArr Hex:(NSString *)hex
{
    
    //    char *rawtrans_str;
    char *signedtrans_ret;
    char *inparam;
    
    // Generate naked transaction parameters json data
    NSString *tvsJson = [self ObjectTojsonString:tvsArray];// Need to use twice the tvs json data
    
    
    // Signature parameters json data
    NSMutableString *signParamStr = [NSMutableString stringWithFormat:@"%@",hex];
    [signParamStr appendString:@" "];
    [signParamStr appendString:tvsJson];
    [signParamStr appendString:@" "];
    NSString *privKeyJson = [self ObjectTojsonString:privkeyArr];
    [signParamStr appendString:privKeyJson];
    const char *inparam2 = [signParamStr UTF8String];// sign data
    inparam = (char *)malloc(strlen(inparam2)+1);
    strcpy(inparam,inparam2);
    NSLog(@"inparam - %s",inparam);
    
    signRawTranscation(inparam,&signedtrans_ret);
    printf("signRawTranscation=%s\n",signedtrans_ret);
    free(inparam);
    NSString *signedStr = [NSString stringWithFormat:@"%s",signedtrans_ret];
    
    //    free(rawtrans_str);
    free(signedtrans_ret);
    
    NSError *error;
    NSDictionary *completeDic = [NSJSONSerialization JSONObjectWithData:[signedStr dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
    //    BOOL b = [[completeDic objectForKey:@"complete"] boolValue];
    //    if (b) {
    return completeDic;
    //    }
    //    NSLog(@"signRawTranscation is failure,please check!");
    //    return nil;
}



+ (void)testSignTransfer{
    
    char *rawtrans_str;
    char *signedtrans_ret;
    char inparam[3072];
    
    NSString *inparamStr_ = @"[{\"scriptPubKey\":\"76a9142dafb30480fa55f1cc7c817023c55ebc301ee50588ac\",\"txid\":\"af0b8dc829cbffc49071a844afbe66de2349746de1385847b6e8d1771909a987\",\"vout\":0},{\"scriptPubKey\":\"76a9143bc26a7ad8e757a5237c6c07f7bb12ec5339909a88ac\",\"txid\":\"87a9091977d1e8b6475838e16d744923de66beaf44a87190c4ffcb29c88d0baf\",\"vout\":0}] {\"16SymaJKNozkcG7K9eQhGKhyjnaHGBEY3u\":0.0008,\"18ms9eXC61cEkFSkpAZk8RzreBGGETFUuC\":0.0002,\"15AZtS7D1SRt35KDQdzv96tGU2wCfqMjQq\":0.0005}";
    
    NSString *tvsJson = @"[{\"scriptPubKey\":\"76a9142dafb30480fa55f1cc7c817023c55ebc301ee50588ac\",\"txid\":\"af0b8dc829cbffc49071a844afbe66de2349746de1385847b6e8d1771909a987\",\"vout\":0},{\"scriptPubKey\":\"76a9143bc26a7ad8e757a5237c6c07f7bb12ec5339909a88ac\",\"txid\":\"87a9091977d1e8b6475838e16d744923de66beaf44a87190c4ffcb29c88d0baf\",\"vout\":0}]";

    
    const char *inparam1 = [inparamStr_ UTF8String];// Naked trading data
    strcpy(inparam,inparam1);
    printf("start to call: createrawtransaction  %s\n",inparam);
    
    createRawTranscation(inparam,&rawtrans_str);
    printf("createRawTranscation=%s\n",rawtrans_str);

    NSArray * privkeyArr_ = @[@"L3WVS5eLfMxhKBEg8qg9zY4eKyN8px9B78BhzJy7RxEbMvEARj2b",@"KykaH6eUEg11q3kZjoZMTHoYVPBntD9cHm932gmFstd3hqtbTRwC"];//
    // Signature parameters json data

    
    NSMutableString *signParamStr = [NSMutableString stringWithFormat:@"%s",rawtrans_str];
    [signParamStr appendString:@" "];
    [signParamStr appendString:tvsJson];
    [signParamStr appendString:@" "];
    NSString *privKeyJson = [self ObjectTojsonString:privkeyArr_];
    [signParamStr appendString:privKeyJson];
    const char *inparam2 = [signParamStr UTF8String];
    strcpy(inparam,inparam2);
    
    
    signRawTranscation(inparam,&signedtrans_ret);
    printf("signRawTranscation=%s\n",signedtrans_ret);
    
    NSString *signedStr = [NSString stringWithFormat:@"%s",signedtrans_ret];
    
    free(rawtrans_str);
    free(signedtrans_ret);
    
    NSError *error;
    NSDictionary *completeDic = [NSJSONSerialization JSONObjectWithData:[signedStr dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
    BOOL b = [[completeDic objectForKey:@"complete"] boolValue];
    if (b) {
        NSString *result = [completeDic objectForKey:@"hex"];
    }
    NSLog(@"signRawTranscation is failure,please check!");
    return ;
    
}

// Data is converted to JsonString type
+(NSString*)ObjectTojsonString:(id)object
{
    if (object == nil) {
        return nil;
    }
    NSString *jsonString = [[NSString alloc]init];
    
    
    // The system comes with the method
    // /*
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
    NSRange range = {0,jsonString.length};
    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
    NSRange range2 = {0,mutStr.length};
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    //  */
    
    
    return mutStr;
}


#pragma mark - Increase the AES common encryption and decryption function
unsigned int xtalkEncodeAES_cbc( unsigned char *password, int passlen, unsigned char *data, unsigned int dataLen, unsigned char **out_data)
{
    unsigned char initval_hex[16]={0x23,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x33};
    AES_KEY aes_key;
    if(AES_set_encrypt_key((const unsigned char*)password, passlen * 8, &aes_key) < 0)
    {
        assert(false);
        return -1;
    }
    
    unsigned char *data_bak;
    unsigned int ret_len = dataLen;
    //  if (dataLen % AES_BLOCK_SIZE > 0)
    {
        ret_len +=  AES_BLOCK_SIZE - (dataLen % AES_BLOCK_SIZE);
    }
    data_bak=(unsigned char *)malloc(ret_len);
    memset(data_bak,AES_BLOCK_SIZE - (dataLen % AES_BLOCK_SIZE),ret_len);	// padding as PKCS7
    memcpy(data_bak,data,dataLen);
    
    *out_data=(unsigned char *)malloc(ret_len);	// malloc for encrypted data to return
    unsigned char *pOut = *out_data;
    
    for(unsigned int i = 0; i < ret_len/AES_BLOCK_SIZE; i++)
    {
        unsigned char out[AES_BLOCK_SIZE];
        ::memset(out, 0, AES_BLOCK_SIZE);
        //AES_encrypt((const unsigned char*)(&data_bak[i*AES_BLOCK_SIZE]), out, &aes_key);
        AES_cbc_encrypt(&data_bak[AES_BLOCK_SIZE*i], out, AES_BLOCK_SIZE,&aes_key,initval_hex, AES_ENCRYPT);
        memcpy(&pOut[i*AES_BLOCK_SIZE], out, AES_BLOCK_SIZE);
    }
    free(data_bak);
    
    return ret_len;
}

int xtalkDecodeAES_cbc( unsigned char *password, int passlen, unsigned char *data, unsigned int dataLen, unsigned char **out_data)
{
    unsigned char initval_hex[16]={0x23,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x33};
    AES_KEY aes_key;
    if(AES_set_decrypt_key((const unsigned char*)password, passlen * 8, &aes_key) < 0)
    {
        assert(false);
        return 0;
    }
    if (dataLen % AES_BLOCK_SIZE > 0)
    {
        // must be AES_BLOCK_SIZE's multiplier
        assert(false);
        return 0;
    }
    *out_data=(unsigned char *)malloc(dataLen);	// malloc for encrypted data to return
    unsigned char *pOut = *out_data;
    
    for(unsigned int i = 0; i < dataLen/AES_BLOCK_SIZE; i++)
    {
        unsigned char out[AES_BLOCK_SIZE];
        ::memset(out, 0, AES_BLOCK_SIZE);
        //    AES_cbc_encrypt(&data[AES_BLOCK_SIZE*i], out, &aes_key);
        AES_cbc_encrypt(&data[AES_BLOCK_SIZE*i], out,AES_BLOCK_SIZE,&aes_key,initval_hex, AES_DECRYPT);
        memcpy(&pOut[AES_BLOCK_SIZE*i],out, AES_BLOCK_SIZE);
    }
    return dataLen-pOut[dataLen-1];	// decrease the PKCS padding length
}

#pragma mark - Add ECDH to generate KEY and generic encryption and decryption functions
/*
 privKey: user A 's private key
 pubKey: user B 's public key
 ecdh_key: unsigned char ecdh_key[256];   used to store the ECDH key
 
 return value is the real key length of ecdh_key, normally return 32.  32 bytes means 256bits
 
 if return 0 or -1 ,then failed on creation!!!
 */
int xtalk_getRawECDHkey(char *privKey, char *pubKey, unsigned char *ecdh_key)
{
    char rawPrivKey[256];
    GetRawPrivKey(rawPrivKey,privKey);
    return ecies_getRawECDHkey(rawPrivKey,pubKey,ecdh_key);	// return real length of raw ecdh_key;
}
/**
 Input parameters:
   1. privKey: is the bitmember format private key, derived from CreateNewPrivKey
   2. pubKey: is the public key of the bitmember format, derived from GetPubKeyFromPrivKey
  
   Output parameters:
   Ecdh_key: is the shared key. The caller must define an unsigned char ecdh_key [64] byte array. Used for storage.
  
   return value:
   0 indicates success; -1 or other negative number indicates failure.
 */
int xtalk_getECDHkey(char *privKey, char *pubKey, unsigned char *ecdh_key /* must be unsigned char ecdh_key[64]*/)
{
    char rawPrivKey[256];
    GetRawPrivKey(rawPrivKey,privKey);
    return ecies_getECDHkey(rawPrivKey,pubKey,ecdh_key);	// return 0 is success,  ecdh_key must be unsigned char ecdh_key[64];
}

/**
 Input parameters:
   1. ecdh_key: is shared with its own private key and the other party's public key, from: xtalk_getECDHkey
   2. input: is to be encrypted processing data, is the array.
   3. inLen: is the length of the data to be encrypted, byte units.
  
   Output parameters:
   Encrypted_output: is the pointer to the encrypted array. Note: This is the memory allocated within the function, the caller to use this data, the need to release, with free function
  
   return value:
   The length of the data after encryption, in bytes. If -1 or other negative numbers indicate a failure.
 */

int xtalk_ECDHencrypt(unsigned char *ecdh_key, unsigned char *input, int inLen, unsigned char **encrypted_output)
{
    secure_t *ciphered = NULL;
    
    if (!(ciphered = ecies_encryptECDH(ecdh_key, (unsigned char *)input, inLen)))
    {
        printf("The encryption process failed!\n");
        return -1;
    }
    
    *encrypted_output=(unsigned char *)ciphered;
    return secure_total_length(ciphered);
}

/**
 Input parameters:
   1. ecdh_key: is shared with its own private key and the other party's public key, from: xtalk_getECDHkey
   2. encrypted: is to decrypt the data processing, is the array. From: xtalk_ECDHencrypt * encrypted_output
   3. enLen: is the length of the data to be decrypted, byte units. From: xtalk_ECDHencrypt return value
  
   Output parameters:
   Decrypted_output: is the pointer to the decrypted array. Note: This is the memory allocated within the function, the caller to use this data, the need to release, with free function
  
   return value:
   Decrypted data length, in bytes. If -1 or other negative numbers indicate a failure.
 */

int xtalk_ECDHdecrypt(unsigned char *ecdh_key, unsigned char *encrypted, int enLen, unsigned char **decrypted_output)
{
    secure_t *ciphered = NULL;
    size_t olen;
    unsigned char *original = NULL;
    int i;
    ciphered=(secure_t *)malloc(enLen);
    memcpy((void *)ciphered,encrypted,enLen);
    
    if (!(original = ecies_decryptECDH(ecdh_key, ciphered, &olen)))
    {
        printf("The decryption process failed!\n");
        free(ciphered);
        return -1;
    }
    
    *decrypted_output=original;
    free(ciphered);
    return olen;
}

int GetBtcPrivKeyFromRawPrivKey(char *privKey, char *rawprivKey)
{
    std::vector<unsigned char> privKeyBin = ParseHex(rawprivKey);
    CBitcoinSecret btcSecret;
    CKey pkey;
    pkey.Set(privKeyBin.begin(),privKeyBin.end(),true);
    btcSecret.SetKey(pkey);
    sprintf(privKey,"%s",btcSecret.ToString().c_str());
    return 0;
}

string BinToHex(const string &strBin, bool bIsUpper = false)
{
    string strHex;
    strHex.resize(strBin.size() * 2);
    for (size_t i = 0; i < strBin.size(); i++)
    {
        uint8_t cTemp = strBin[i];
        for (size_t j = 0; j < 2; j++)
        {
            uint8_t cCur = (cTemp & 0x0f);
            if (cCur < 10)
            {
                cCur += '0';
            }
            else
            {
                cCur += ((bIsUpper ? 'A' : 'a') - 10);
            }
            strHex[2 * i + 1 - j] = cCur;
            cTemp >>= 4;
        }
    }
    return strHex;
}


string HexToBin(const string &strHex)
{
    if (strHex.size() % 2 != 0)
        {
            return "";
        }
    string strBin;
    strBin.resize(strHex.size() / 2);
    for (size_t i = 0; i < strBin.size(); i++)
    {
        uint8_t cTemp = 0;
        for (size_t j = 0; j < 2; j++)
        {
                char cCur = strHex[2 * i + j];
                if (cCur >= '0' && cCur <= '9')
                {
                    cTemp = (cTemp << 4) + (cCur - '0');
                }
                else if (cCur >= 'a' && cCur <= 'f')
                {
                    cTemp = (cTemp << 4) + (cCur - 'a' + 10);
                }
                else if (cCur >= 'A' && cCur <= 'F')
                {
                    cTemp = (cTemp << 4) + (cCur - 'A' + 10);
                }
                else
                {
                    return "";
                }
        }
        strBin[i] = cTemp;
    }
    return strBin;
}

// usrID is 36 bytes length     privKey is 32 bytes length
#define XTALK_USRID_LEN		36
#define XTALK_PRIVKEY_LEN	32
std::string xtalkUsrPirvKeyEncrypt(unsigned char *usrID, unsigned char *privKey, char *pwd, int n, int ver)
{
    //  below is the process of E1
    unsigned char h[64];
    unsigned char chk[2];
    unsigned char usrIDAandPrivKey[XTALK_USRID_LEN+XTALK_PRIVKEY_LEN];
    
    // user id 8bytes
    memcpy(usrIDAandPrivKey,usrID,XTALK_USRID_LEN);
    // privkey 32 bytes
    memcpy(usrIDAandPrivKey+XTALK_USRID_LEN,privKey,XTALK_PRIVKEY_LEN);
    
    xtalkSHA512(usrIDAandPrivKey, XTALK_USRID_LEN+XTALK_PRIVKEY_LEN, h);
    
    // copy first 2 bytes to chk
    memcpy(chk,h,2);
    
    // below is the process of E2
    unsigned char salt[8];	// 8*8= 64 bits
    RAND_bytes(salt,8);
    
    // below is the process of E3
    unsigned char key[256/8];
    xtalkPBKDF2_HMAC_SHA512((unsigned char *)pwd, strlen(pwd), salt, 64, key, 256, n);
    
    // below is the process of E4
    unsigned char chkUsrIDPrivKey[2+XTALK_USRID_LEN+XTALK_PRIVKEY_LEN];	// 2+36+32 = 70
    memcpy(chkUsrIDPrivKey,chk,2);
    memcpy(chkUsrIDPrivKey+2,usrID,XTALK_USRID_LEN);
    memcpy(chkUsrIDPrivKey+2+XTALK_USRID_LEN,privKey,XTALK_PRIVKEY_LEN);
    
    AES_KEY aes_key;
    if(AES_set_encrypt_key((const unsigned char*)key, sizeof(key) * 8, &aes_key) < 0)
    {
        assert(false);
        return "error";
    }
    
    unsigned char *secret;
    unsigned char *data_tmp;
    unsigned int ret_len = sizeof(chkUsrIDPrivKey);	// use input data len to get the secret len
    if (sizeof(chkUsrIDPrivKey) % AES_BLOCK_SIZE > 0)
    {
        ret_len +=  AES_BLOCK_SIZE - (sizeof(chkUsrIDPrivKey) % AES_BLOCK_SIZE);
    }
    data_tmp=(unsigned char *)malloc(ret_len);
    secret=(unsigned char *)malloc(ret_len);
    memset(data_tmp,0x00,ret_len);
    memcpy(data_tmp,chkUsrIDPrivKey,sizeof(chkUsrIDPrivKey));	// prepare data for encrypt
    
    for(unsigned int i = 0; i < ret_len/AES_BLOCK_SIZE; i++)
    {
        unsigned char out[AES_BLOCK_SIZE];
        memset(out, 0, AES_BLOCK_SIZE);
        AES_encrypt((const unsigned char*)(&data_tmp[i*AES_BLOCK_SIZE]), out, &aes_key);
        memcpy(&secret[i*AES_BLOCK_SIZE], out, AES_BLOCK_SIZE);
    }
    free(data_tmp);
    // data stored in secret, length is ret_len
    
    // below is the process of E5
    unsigned char *result;
    result=(unsigned char *)malloc(1+8+ret_len);	// 1 byte version + 8 bytes salt + secret
    
    // set v value;
    result[0]=(ver<<5)+n;
    memcpy(result+1,salt,8);
    memcpy(result+9,secret,ret_len);
    free(secret);	// do not forget to free it.
    
    // finally, we return the hex string. easiler for debug and show
    std::string retStr=HexStr(&result[0],&result[1+8+ret_len],false);
    free(result);
    
    return retStr;
}

int xtalkUsrPirvKeyDecrypt(char *encryptedString, char *pwd, int ver, unsigned char *usrID, unsigned char *privKey)
{
    std::vector<unsigned char> encryptedData = ParseHex(encryptedString);
    // below is the process of D1
    unsigned char v[1];
    v[0]=encryptedData[0];
    
    int version=(v[0]>>5)&0x7;	// only get the high 3 bits' value
    if(version!=ver)
        return -1; // version error
    
    // below is the process of D2
    int n=v[0]&0x1f;	// only get the low 5 bits' value
    
    // below is the process of D3
    unsigned char salt[8];
    unsigned char *secret;
    int secretLen=encryptedData.size()-1-8;  // decrease one byte v and 8 bytes salt
    secret=(unsigned char *)malloc(secretLen);
    memcpy(salt,&encryptedData[1],8);
    memcpy(secret,&encryptedData[9],secretLen);
    
    // below is the process of D4
    unsigned char key[256/8];
    xtalkPBKDF2_HMAC_SHA512((unsigned char *)pwd, strlen(pwd), salt, 64, key, 256, n);
    
    // below is the process of D5
    unsigned char *secret_decrypted;
    secret_decrypted=(unsigned char *)malloc(secretLen);
    
    AES_KEY aes_key;
    if(AES_set_decrypt_key(key, sizeof(key) * 8, &aes_key) < 0)
    {
        assert(false);
        return -1;
    }
    
    for(unsigned int i = 0; i < secretLen/AES_BLOCK_SIZE; i++)
    {
        unsigned char out[AES_BLOCK_SIZE];
        ::memset(out, 0, AES_BLOCK_SIZE);
        AES_decrypt(&secret[AES_BLOCK_SIZE*i], out, &aes_key);
        memcpy(&secret_decrypted[AES_BLOCK_SIZE*i],out, AES_BLOCK_SIZE);
    }
    free(secret);
    
    unsigned char chk[2];
    memcpy(chk,secret_decrypted,2);
    memcpy(usrID,secret_decrypted+2,XTALK_USRID_LEN);
    memcpy(privKey,secret_decrypted+2+XTALK_USRID_LEN,XTALK_PRIVKEY_LEN);
    free(secret_decrypted);
    
    // below is the process of D6
    unsigned char h[64];
    unsigned char usrIDAandPrivKey[XTALK_USRID_LEN+XTALK_PRIVKEY_LEN];
    
    // user id 36bytes
    memcpy(usrIDAandPrivKey,usrID,XTALK_USRID_LEN);
    // privkey 32 bytes
    memcpy(usrIDAandPrivKey+XTALK_USRID_LEN,privKey,XTALK_PRIVKEY_LEN);
    
    xtalkSHA512(usrIDAandPrivKey, XTALK_USRID_LEN+XTALK_PRIVKEY_LEN, h);
    
    if(memcmp(chk,h,2)!=0)
        return 0;
    
    return 1;
}

// use hex string to input userID and privKey
std::string xtalkUsrPirvKeyEncrypt_String(char *usrID_BtcAddress, char *privKey_HexString, char *pwd, int n, int ver)
{
    unsigned char usrID[XTALK_USRID_LEN];
    std::vector<unsigned char> privKey = ParseHex(privKey_HexString);
    
    if(strlen(usrID_BtcAddress) >= XTALK_USRID_LEN || privKey.size()!=XTALK_PRIVKEY_LEN)
        return "error userID or privKey length";
    
    memset(usrID,'\0',XTALK_USRID_LEN);
    strcpy((char *)usrID,usrID_BtcAddress);
    
    return xtalkUsrPirvKeyEncrypt(usrID,&privKey[0],pwd,n,ver);
}

int xtalkUsrPirvKeyDecrypt_String(char *encryptedString, char *pwd, int ver, char *usrID_BtcAddress, char *privKey_HexString)
{
    unsigned char usrID[XTALK_USRID_LEN];
    unsigned char privKey[XTALK_PRIVKEY_LEN];
    int ret;
    
    memset(usrID,'\0',XTALK_USRID_LEN);
    ret=xtalkUsrPirvKeyDecrypt(encryptedString,pwd,ver,usrID,privKey);
    
    strcpy(usrID_BtcAddress,(char *)usrID);	
    std::string hexString=HexStr(&privKey[0],&privKey[32],false);
    strcpy(privKey_HexString,hexString.c_str());
    
    return ret;
}
using namespace std;
using namespace boost;
using namespace boost::assign;
using namespace json_spirit;

static const string strSecret1     ("5HxWvvfubhXpYYpS3tJkw6fq9jE9j18THftkZjHHfmFiWtmAbrj");
static const string strSecret2     ("5KC4ejrDjv152FGwP386VD1i2NYc5KkfSMyv1nGy1VGDxGHqVY3");
static const string strSecret1C    ("Kwr371tjA9u2rFSMZjTNun2PXXP3WPZu2afRHTcta6KxEUdm1vEw");
static const string strSecret2C    ("L3Hq7a8FEQwJkW1M2GNKDW28546Vp5miewcCzSqUD9kCAXrJdS3g");
static const CBitcoinAddress addr1 ("1QFqqMUD55ZV3PJEJZtaKCsQmjLT6JkjvJ");
static const CBitcoinAddress addr2 ("1F5y5E5FMc5YzdJtB9hLaUe43GDxEKXENJ");
static const CBitcoinAddress addr1C("1NoJrossxPBKfCHuJXT4HadJrXRE9Fxiqs");
static const CBitcoinAddress addr2C("1CRj2HyM1CXWzHAXLQtiGLyggNT9WQqsDs");

static const string strAddressBad("1HV9Lc3sNHZxwj4Zk6fB38tEmBryq2cBiF");

void tryKeyTest()
{
    CBitcoinSecret bsecret1, bsecret2, bsecret1C, bsecret2C, baddress1;
    if(!bsecret1.SetString (strSecret1))
        printf("Error : bsecret1.SetString (strSecret1)...\n");
    
    if(!bsecret2.SetString (strSecret2))
        printf("Error : bsecret2.SetString (strSecret2)...\n");
    
    if(!bsecret1C.SetString (strSecret1C))
        printf("Error : bsecret1C.SetString (strSecret1C)...\n");
    
    if(!bsecret2C.SetString (strSecret2C))
        printf("Error : bsecret2C.SetString (strSecret2C)...\n");
    
    if(baddress1.SetString(strAddressBad))
        printf("Error : baddress1.SetString(strAddressBad)...\n");
    
    CKey key1  = bsecret1.GetKey();
    if(key1.IsCompressed())
        printf("Error : key1.IsCompressed(), must not be compressed!\n");
    
    CKey key2  = bsecret2.GetKey();
    if(key2.IsCompressed())
        printf("Error : key2.IsCompressed(), must not be compressed!\n");
    
    CKey key1C = bsecret1C.GetKey();
    if(!key1C.IsCompressed())
        printf("Error : key1C.IsCompressed(), must be compressed!\n");
    
    CKey key2C = bsecret2C.GetKey();
    if(!key2C.IsCompressed())
        printf("Error : key2C.IsCompressed(), must be compressed!\n");
    
    CPubKey pubkey1  = key1.GetPubKey();
    CPubKey pubkey2  = key2.GetPubKey();
    CPubKey pubkey1C = key1C.GetPubKey();
    CPubKey pubkey2C = key2C.GetPubKey();
    
    if(!(addr1.Get()  == CTxDestination(pubkey1.GetID())))
        printf("Error : addr1.Get()  == CTxDestination(pubkey1.GetID())\n");
    
    if(!(addr2.Get()  == CTxDestination(pubkey2.GetID())))
        printf("Error : addr2.Get()  == CTxDestination(pubkey2.GetID())\n");
    
    if(!(addr1C.Get() == CTxDestination(pubkey1C.GetID())))
        printf("Error : addr1C.Get() == CTxDestination(pubkey1C.GetID())\n");
    
    if(!(addr2C.Get() == CTxDestination(pubkey2C.GetID())))
        printf("Error : addr2C.Get() == CTxDestination(pubkey2C.GetID())\n");
    
    for (int n=0; n<16; n++)
    {
        string strMsg = strprintf("Very secret message %i: 11", n);
        uint256 hashMsg = Hash(strMsg.begin(), strMsg.end());
        
        // normal signatures
        
        vector<unsigned char> sign1, sign2, sign1C, sign2C;
        
        if(!key1.Sign (hashMsg, sign1))
            printf("Error : key1.Sign (hashMsg, sign1)\n");
        
        if(!key2.Sign (hashMsg, sign2))
            printf("Error : key2.Sign (hashMsg, sign2)\n");
        
        if(!key1C.Sign(hashMsg, sign1C))
            printf("Error : key1C.Sign(hashMsg, sign1C)\n");
        
        if(!key2C.Sign(hashMsg, sign2C))
            printf("Error : key2C.Sign(hashMsg, sign2C)\n");
        
        if(! pubkey1.Verify(hashMsg, sign1))
            printf("Error : pubkey1.Verify(hashMsg, sign1)\n");
        
        if(pubkey1.Verify(hashMsg, sign2))
            printf("Error : pubkey1.Verify(hashMsg, sign2) must be false\n");
        
        if(! pubkey1.Verify(hashMsg, sign1C))
            printf("Error : pubkey1.Verify(hashMsg, sign1C)\n");
        
        if(pubkey1.Verify(hashMsg, sign2C))
            printf("Error : pubkey1.Verify(hashMsg, sign2C) must be false\n");
        
        if(pubkey2.Verify(hashMsg, sign1))
            printf("Error : pubkey2.Verify(hashMsg, sign1) must be false\n");
        
        if(! pubkey2.Verify(hashMsg, sign2))
            printf("Error : pubkey2.Verify(hashMsg, sign2)\n");
        
        if(pubkey2.Verify(hashMsg, sign1C))
            printf("Error: pubkey2.Verify(hashMsg, sign1C) must be false\n");
        
        if(! pubkey2.Verify(hashMsg, sign2C))
            printf("Error : pubkey2.Verify(hashMsg, sign2C)\n");
        
        if(! pubkey1C.Verify(hashMsg, sign1))
            printf("Error : pubkey1C.Verify(hashMsg, sign1)\n");
        
        if(pubkey1C.Verify(hashMsg, sign2))
            printf("Error : pubkey1C.Verify(hashMsg, sign1) must be false\n");
        
        if(! pubkey1C.Verify(hashMsg, sign1C))
            printf("Error : pubkey1C.Verify(hashMsg, sign1C)\n");
        
        if(pubkey1C.Verify(hashMsg, sign2C))
            printf("Error : pubkey1C.Verify(hashMsg, sign2C) must be false\n");
        
        if(pubkey2C.Verify(hashMsg, sign1))
            printf("Error : pubkey2C.Verify(hashMsg, sign1) must be false \n");
        
        if(! pubkey2C.Verify(hashMsg, sign2))
            printf("Error : pubkey2C.Verify(hashMsg, sign2)\n");
        
        if(pubkey2C.Verify(hashMsg, sign1C))
            printf("Error : pubkey2C.Verify(hashMsg, sign1C) must be false\n");
        
        if(! pubkey2C.Verify(hashMsg, sign2C))
            printf("Error : pubkey2C.Verify(hashMsg, sign2C)\n");
        
        // compact signatures (with key recovery)
        
        vector<unsigned char> csign1, csign2, csign1C, csign2C;
        
        if(!key1.SignCompact (hashMsg, csign1))
            printf(" Error : key1.SignCompact (hashMsg, csign1)\n");
        
        if(!key2.SignCompact (hashMsg, csign2))
            printf("Error : key2.SignCompact (hashMsg, csign2)\n");
        
        if(!key1C.SignCompact(hashMsg, csign1C))
            printf("Error : key1C.SignCompact(hashMsg, csign1C)\n");
        
        if(!key2C.SignCompact(hashMsg, csign2C))
            printf("Error : key2C.SignCompact(hashMsg, csign2C)\n");
        
        CPubKey rkey1, rkey2, rkey1C, rkey2C;
        
        if(!rkey1.RecoverCompact (hashMsg, csign1))
            printf("Error : rkey1.RecoverCompact (hashMsg, csign1)\n");
        
        if(!rkey2.RecoverCompact (hashMsg, csign2))
            printf("Error : rkey2.RecoverCompact (hashMsg, csign2)\n");
        
        if(!rkey1C.RecoverCompact(hashMsg, csign1C))
            printf("Error : rkey1C.RecoverCompact(hashMsg, csign1C)\n");
        
        if(!rkey2C.RecoverCompact(hashMsg, csign2C))
            printf("Error : rkey2C.RecoverCompact(hashMsg, csign2C)\n");
        
        if(!(rkey1  == pubkey1))
            printf("Error : rkey1  == pubkey1\n");
        
        if(!(rkey2  == pubkey2))
            printf("Error : rkey2  == pubkey2\n");
        
        if(!(rkey1C == pubkey1C))
            printf("Error : (rkey1C == pubkey1C)\n");
        
        if(!(rkey2C == pubkey2C))
            printf("Error : rkey2C == pubkey2C\n");
    }
}

struct TestDerivation {
    std::string pub;
    std::string prv;
    unsigned int nChild;
};

struct TestVector {
    std::string strHexMaster;
    std::vector<TestDerivation> vDerive;
    
    TestVector(std::string strHexMasterIn) : strHexMaster(strHexMasterIn) {}
    
    TestVector& operator()(std::string pub, std::string prv, unsigned int nChild) {
        vDerive.push_back(TestDerivation());
        TestDerivation &der = vDerive.back();
        der.pub = pub;
        der.prv = prv;
        der.nChild = nChild;
        return *this;
    }
};

TestVector test1 =
TestVector("000102030405060708090a0b0c0d0e0f")
("xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8",
 "xprv9s21ZrQH143K3QTDL4LXw2F7HEK3wJUD2nW2nRk4stbPy6cq3jPPqjiChkVvvNKmPGJxWUtg6LnF5kejMRNNU3TGtRBeJgk33yuGBxrMPHi",
 0x80000000)
("xpub68Gmy5EdvgibQVfPdqkBBCHxA5htiqg55crXYuXoQRKfDBFA1WEjWgP6LHhwBZeNK1VTsfTFUHCdrfp1bgwQ9xv5ski8PX9rL2dZXvgGDnw",
 "xprv9uHRZZhk6KAJC1avXpDAp4MDc3sQKNxDiPvvkX8Br5ngLNv1TxvUxt4cV1rGL5hj6KCesnDYUhd7oWgT11eZG7XnxHrnYeSvkzY7d2bhkJ7",
 1)
("xpub6ASuArnXKPbfEwhqN6e3mwBcDTgzisQN1wXN9BJcM47sSikHjJf3UFHKkNAWbWMiGj7Wf5uMash7SyYq527Hqck2AxYysAA7xmALppuCkwQ",
 "xprv9wTYmMFdV23N2TdNG573QoEsfRrWKQgWeibmLntzniatZvR9BmLnvSxqu53Kw1UmYPxLgboyZQaXwTCg8MSY3H2EU4pWcQDnRnrVA1xe8fs",
 0x80000002)
("xpub6D4BDPcP2GT577Vvch3R8wDkScZWzQzMMUm3PWbmWvVJrZwQY4VUNgqFJPMM3No2dFDFGTsxxpG5uJh7n7epu4trkrX7x7DogT5Uv6fcLW5",
 "xprv9z4pot5VBttmtdRTWfWQmoH1taj2axGVzFqSb8C9xaxKymcFzXBDptWmT7FwuEzG3ryjH4ktypQSAewRiNMjANTtpgP4mLTj34bhnZX7UiM",
 2)
("xpub6FHa3pjLCk84BayeJxFW2SP4XRrFd1JYnxeLeU8EqN3vDfZmbqBqaGJAyiLjTAwm6ZLRQUMv1ZACTj37sR62cfN7fe5JnJ7dh8zL4fiyLHV",
 "xprvA2JDeKCSNNZky6uBCviVfJSKyQ1mDYahRjijr5idH2WwLsEd4Hsb2Tyh8RfQMuPh7f7RtyzTtdrbdqqsunu5Mm3wDvUAKRHSC34sJ7in334",
 1000000000)
("xpub6H1LXWLaKsWFhvm6RVpEL9P4KfRZSW7abD2ttkWP3SSQvnyA8FSVqNTEcYFgJS2UaFcxupHiYkro49S8yGasTvXEYBVPamhGW6cFJodrTHy",
 "xprvA41z7zogVVwxVSgdKUHDy1SKmdb533PjDz7J6N6mV6uS3ze1ai8FHa8kmHScGpWmj4WggLyQjgPie1rFSruoUihUZREPSL39UNdE3BBDu76",
 0);

TestVector test2 =
TestVector("fffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542")
("xpub661MyMwAqRbcFW31YEwpkMuc5THy2PSt5bDMsktWQcFF8syAmRUapSCGu8ED9W6oDMSgv6Zz8idoc4a6mr8BDzTJY47LJhkJ8UB7WEGuduB",
 "xprv9s21ZrQH143K31xYSDQpPDxsXRTUcvj2iNHm5NUtrGiGG5e2DtALGdso3pGz6ssrdK4PFmM8NSpSBHNqPqm55Qn3LqFtT2emdEXVYsCzC2U",
 0)
("xpub69H7F5d8KSRgmmdJg2KhpAK8SR3DjMwAdkxj3ZuxV27CprR9LgpeyGmXUbC6wb7ERfvrnKZjXoUmmDznezpbZb7ap6r1D3tgFxHmwMkQTPH",
 "xprv9vHkqa6EV4sPZHYqZznhT2NPtPCjKuDKGY38FBWLvgaDx45zo9WQRUT3dKYnjwih2yJD9mkrocEZXo1ex8G81dwSM1fwqWpWkeS3v86pgKt",
 0xFFFFFFFF)
("xpub6ASAVgeehLbnwdqV6UKMHVzgqAG8Gr6riv3Fxxpj8ksbH9ebxaEyBLZ85ySDhKiLDBrQSARLq1uNRts8RuJiHjaDMBU4Zn9h8LZNnBC5y4a",
 "xprv9wSp6B7kry3Vj9m1zSnLvN3xH8RdsPP1Mh7fAaR7aRLcQMKTR2vidYEeEg2mUCTAwCd6vnxVrcjfy2kRgVsFawNzmjuHc2YmYRmagcEPdU9",
 1)
("xpub6DF8uhdarytz3FWdA8TvFSvvAh8dP3283MY7p2V4SeE2wyWmG5mg5EwVvmdMVCQcoNJxGoWaU9DCWh89LojfZ537wTfunKau47EL2dhHKon",
 "xprv9zFnWC6h2cLgpmSA46vutJzBcfJ8yaJGg8cX1e5StJh45BBciYTRXSd25UEPVuesF9yog62tGAQtHjXajPPdbRCHuWS6T8XA2ECKADdw4Ef",
 0xFFFFFFFE)
("xpub6ERApfZwUNrhLCkDtcHTcxd75RbzS1ed54G1LkBUHQVHQKqhMkhgbmJbZRkrgZw4koxb5JaHWkY4ALHY2grBGRjaDMzQLcgJvLJuZZvRcEL",
 "xprvA1RpRA33e1JQ7ifknakTFpgNXPmW2YvmhqLQYMmrj4xJXXWYpDPS3xz7iAxn8L39njGVyuoseXzU6rcxFLJ8HFsTjSyQbLYnMpCqE2VbFWc",
 2)
("xpub6FnCn6nSzZAw5Tw7cgR9bi15UV96gLZhjDstkXXxvCLsUXBGXPdSnLFbdpq8p9HmGsApME5hQTZ3emM2rnY5agb9rXpVGyy3bdW6EEgAtqt",
 "xprvA2nrNbFZABcdryreWet9Ea4LvTJcGsqrMzxHx98MMrotbir7yrKCEXw7nadnHM8Dq38EGfSh6dqA9QWTyefMLEcBYJUuekgW4BYPJcr9E7j",
 0);

void RunTest(const TestVector &test)
{
    std::vector<unsigned char> seed = ParseHex(test.strHexMaster);
    CExtKey key;
    CExtPubKey pubkey;
    key.SetMaster(&seed[0], seed.size());
    pubkey = key.Neuter();
    BOOST_FOREACH(const TestDerivation &derive, test.vDerive) {
        unsigned char data[74];
        key.Encode(data);
        pubkey.Encode(data);
        // Test private key
        CBitcoinExtKey b58key; b58key.SetKey(key);
        
        if(b58key.ToString() == derive.prv)
            printf("b58key.ToString() == derive.prv is true\n");
        else printf("b58key.ToString() == derive.prv is false\n");
        
        // Test public key
        CBitcoinExtPubKey b58pubkey;
        b58pubkey.SetKey(pubkey);
        if(b58pubkey.ToString() == derive.pub)
            printf("b58pubkey.ToString() == derive.pub is true\n");
        else printf("b58pubkey.ToString() == derive.pub is false\n");
        
        // Derive new keys
        CExtKey keyNew;
        if(key.Derive(keyNew, derive.nChild))
            printf("key.Derive(keyNew, derive.nChild) is true\n");
        else printf("key.Derive(keyNew, derive.nChild) is false\n");
        
        CExtPubKey pubkeyNew = keyNew.Neuter();
        if (!(derive.nChild & 0x80000000)) {
            // Compare with public derivation
            CExtPubKey pubkeyNew2;
            if(pubkey.Derive(pubkeyNew2, derive.nChild))
                printf("pubkey.Derive(pubkeyNew2, derive.nChild=0x%x) is true\n",derive.nChild);
            else printf("pubkey.Derive(pubkeyNew2, derive.nChild=0x%x) is false\n",derive.nChild);
            
            if(pubkeyNew == pubkeyNew2)
                printf("pubkeyNew == pubkeyNew2\n");
            else printf("pubkeyNew != pubkeyNew2\n");
        }
        key = keyNew;
        pubkey = pubkeyNew;
    }
}

unsigned int EncodeAES( const std::string& password, unsigned char *data, unsigned int dataLen, unsigned char *out_data)
{
    AES_KEY aes_key;
    if(AES_set_encrypt_key((const unsigned char*)password.c_str(), password.length() * 8, &aes_key) < 0)
    {
        assert(false);
        return -1;
    }
    
    unsigned char *data_bak;
    unsigned int ret_len = dataLen;
    if (dataLen % AES_BLOCK_SIZE > 0)
    {
        ret_len +=  AES_BLOCK_SIZE - (dataLen % AES_BLOCK_SIZE);
    }
    data_bak=(unsigned char *)malloc(ret_len);
    memset(data_bak,'\0',ret_len);
    memcpy(data_bak,data,dataLen);
    
    for(unsigned int i = 0; i < ret_len/AES_BLOCK_SIZE; i++)
    {
        unsigned char out[AES_BLOCK_SIZE];
        ::memset(out, 0, AES_BLOCK_SIZE);
        AES_encrypt((const unsigned char*)(&data_bak[i*AES_BLOCK_SIZE]), out, &aes_key);
        memcpy(&out_data[i*AES_BLOCK_SIZE], out, AES_BLOCK_SIZE);
    }
    free(data_bak);
    
    return ret_len;
}

int DecodeAES( const std::string& strPassword, unsigned char *data, unsigned int dataLen, unsigned char *out_data)
{
    AES_KEY aes_key;
    if(AES_set_decrypt_key((const unsigned char*)strPassword.c_str(), strPassword.length() * 8, &aes_key) < 0)
    {
        assert(false);
        return 0;
    }
    
    for(unsigned int i = 0; i < dataLen/AES_BLOCK_SIZE; i++)
    {
        unsigned char out[AES_BLOCK_SIZE];
        ::memset(out, 0, AES_BLOCK_SIZE);
        AES_decrypt(&data[AES_BLOCK_SIZE*i], out, &aes_key);
        memcpy(&out_data[AES_BLOCK_SIZE*i],out, AES_BLOCK_SIZE);
    }
    return dataLen;
}

void GetHash160(char *indata, char *outhash)
{
    unsigned char hash1[32];
    SHA256((unsigned char*)indata, strlen(indata), (unsigned char*)&hash1);
    unsigned char hash2[20];
    RIPEMD160((unsigned char*)&hash1, sizeof(hash1), (unsigned char*)&hash2);
    int ret=0;
    for(int i=0;i<20;i++)
        ret+=sprintf(outhash+ret,"%02x",hash2[i]);
}

// API DEFINED ///////////
int CreateNewPrivKey(char *privKey)
{
    CKey key;
    key.MakeNewKey(true); // set rand bytes. we need add our own MakeNewKey(true, randombytes_data), we need use our own RAND_bytes func to get random bytes.
    CBitcoinSecret btcSecret(key);
//        sprintf(privKey,"%s",btcSecret.begin());
    sprintf(privKey,"%s",btcSecret.ToString().c_str());
    
    return 0;
}

/*
 std::string str1 = "Hello Lily!";
 std::vector<unsigned char> v(str1.begin(), str1.end());
 std::string str2( v.begin(), v.end() );
 */

int GetPubKeyFromPrivKey(char *privKey, char *pubKey)
{
    string privStr(privKey);
    CBitcoinSecret btcSecret;
    if(!btcSecret.SetString (privStr))
    {
        printf("Error : btcSecret.SetString (privStr)...\n");
        return 1;
    }
    CPubKey pubkey  = btcSecret.GetKey().GetPubKey();
    std::vector<unsigned char> vch(pubkey.begin(), pubkey.end());
    std::string pubkeyStr=HexStr(vch);
    
    sprintf(pubKey,"%s",pubkeyStr.c_str());
    
    return 0;
}

int GetScriptPubKeyFromPubKey(char *pubKey, char *ScriptPubKey)
{
    std::string pubkeyStr = pubKey;
    CPubKey pubkey(ParseHex(pubkeyStr));
    CScript pubkey_script;
    
    pubkey_script.SetDestination(pubkey.GetID());
    string prevout_pubkey=HexStr(pubkey_script.begin(), pubkey_script.end(), false);
    sprintf(ScriptPubKey,"%s",prevout_pubkey.c_str());
    
    return 0;
}

int GetBTCAddrFromPubKey(char *pubKey, char *address)
{
    std::string pubkeyStr = pubKey;
    CPubKey pubkey(ParseHex(pubkeyStr));
    CBitcoinAddress btcAddr(pubkey.GetID());
    sprintf(address,"%s",btcAddr.ToString().c_str());
    
    return 0;
}

Value CallRPC(string args);

int createRawTranscation(char *in_param, char **rawtrans_string)
{
    Value r;
    char *ret_str;
    string param=string("createrawtransaction ")+in_param;
    r = CallRPC(param);
    string notsigned = r.get_str();
    ret_str=(char *)malloc(notsigned.size()+1);
    sprintf(ret_str,"%s",notsigned.c_str());
    *rawtrans_string=ret_str;
    return 0;
}

int signRawTranscation(char *in_param, char **signedtrans_ret)
{
    Value r;
    char *ret_str;
    string param=string("signrawtransaction ")+in_param;
    r = CallRPC(param);
    string ret=write_string(Value(r), false);
    ret_str=(char *)malloc(ret.size()+1);
    sprintf(ret_str,"%s",ret.c_str());
    *signedtrans_ret=ret_str;
    return 0;
}

int createMultiSigAddress(char *in_param, char **multiSigAddr_ret)
{
    char *ret_str;
    Value r;
    string param=string("createmultisig ")+in_param;
    r = CallRPC(param);
    string ret=write_string(Value(r), false);
    ret_str=(char *)malloc(ret.size()+1);
    sprintf(ret_str,"%s",ret.c_str());
    *multiSigAddr_ret=ret_str;
    return 0;
}

// Turn on the test mode
void EnableTESTmode()
{
    //    SelectParams(CChainParams::REGTEST);
    SelectParams(CChainParams::TESTNET);
}

void CreateSeed(unsigned int uSound, char *SeedStr)	//get sound from MIC
{
    unsigned char uSeed[66];
    RAND_bytes(uSeed,30);
    memcpy(&uSeed[30],&uSound,2);
    RAND_bytes(uSeed+32,30);
    memcpy(&uSeed[62],(&uSound)+2,2);
    
    string seedString=HexStr(&uSeed[0],&uSeed[64],false);
    sprintf(SeedStr,"%s",seedString.c_str());
}

void CreateSeed(unsigned int uSound, char *SeedStr, int seedVersion)	//get sound from MIC
{
    unsigned char uSeed[33];
    
    if(seedVersion == SEED_VERSION4)	// BIP39  32bytes
    {
        RAND_bytes(uSeed,32);
        string seedString=HexStr(&uSeed[0],&uSeed[32],false);
        sprintf(SeedStr,"%s",seedString.c_str());
    }
    else if(seedVersion == SEED_VERSION3)	// BIP39  16bytes
    {
        RAND_bytes(uSeed,16);
        string seedString=HexStr(&uSeed[0],&uSeed[16],false);
        sprintf(SeedStr,"%s",seedString.c_str());
    }
    else if(seedVersion == SEED_VERSION2)	// 12 words
    {
        RAND_bytes(uSeed,8);
        memcpy(&uSeed[8],&uSound,2);
        RAND_bytes(uSeed+10,8);
        memcpy(&uSeed[16],(&uSound)+2,2);
        
        string seedString=HexStr(&uSeed[0],&uSeed[18],false);
        sprintf(SeedStr,"%s",seedString.c_str());
    }
    else if(seedVersion == SEED_VERSION1)	// 6 words
    {
        RAND_bytes(uSeed,4);
        memcpy(&uSeed[4],&uSound,2);
        RAND_bytes(uSeed+6,2);
        memcpy(&uSeed[7],(&uSound)+2,2);
        
        string seedString=HexStr(&uSeed[0],&uSeed[9],false);
        sprintf(SeedStr,"%s",seedString.c_str());
    }
}




int EncriptData(char *password, char *dataStr, char **pEncriptedDataStr)
{
    char *ret_str;
    unsigned char encodedRet[512];
    string pass=password;
    unsigned int encodedRetLen=EncodeAES(password,(unsigned char *)dataStr,strlen(dataStr),encodedRet);
    
    string retString=HexStr(&encodedRet[0],&encodedRet[encodedRetLen],false);
    ret_str=(char *)malloc(retString.size()+1);
    sprintf(ret_str,"%s",retString.c_str());
    *pEncriptedDataStr=ret_str;
    return 0;
}

int DecriptData(char *password, char *dataStr, char **pDecriptedDataStr)
{
    char *ret_str;
    string pass=password;
    std::vector<unsigned char> dataVetor = ParseHex(dataStr);
    unsigned char *indata;
    indata=(unsigned char *)malloc(dataVetor.size()+1);
    for(int i=0;i<dataVetor.size();i++)
        indata[i]=dataVetor[i];
    
    unsigned char outdata[512];
    DecodeAES(password,indata,dataVetor.size(),outdata);
    free(indata);
    
    string decodedRet=(char *)outdata;
    ret_str=(char *)malloc(decodedRet.size()+1);
    sprintf(ret_str,"%s",decodedRet.c_str());
    *pDecriptedDataStr=ret_str;
    return 0;
}


string getMD5(char* str, int length)
{
    unsigned char sign[16] = {0};
    string ret;
    
    MD5_CTX  md5_ctx;
    MD5_Init(&md5_ctx);
    MD5_Update(&md5_ctx, str, length);
    MD5_Final(sign, &md5_ctx);
    
    char output[33] = {0};
    int j;
    for( j = 0; j < 16; j++ )
    {
        sprintf( output + j * 2, "%02x", sign[j] );
    }
    
    output[32]='\0';
    ret=output;
    return ret;
}

int EncriptWithMD5(char *pass, char *seedStr, char *encriptedSeed)
{
    string aes_pass;
    char privKeyHash160[64];
    GetHash160(seedStr,privKeyHash160);
    
    char privKeyAndHash160[512];
    sprintf(privKeyAndHash160,"%s:MD5:%s",seedStr,privKeyHash160);
    
    aes_pass=getMD5(pass,strlen(pass));
    
    char *encriptPrivKey;
    EncriptData((char *)(aes_pass.c_str()),privKeyAndHash160,&encriptPrivKey);
    string encriptPrivKeyStr=encriptPrivKey;
    free(encriptPrivKey);
    sprintf(encriptedSeed,"%s",encriptPrivKeyStr.c_str());
    return 0;
    
}

int DecriptAndCheckMD5(char *pass, char *encriptedSeed, char *seedStr)
{
    // here , we need 16 bytes password, if user's pass is less than 16 bytes, we expand pass to 16 bytes
    string aes_pass;
    aes_pass=getMD5(pass,strlen(pass));
    
    char privKeyAndHash160[256];
    char *decriptPrivKey;	// Must same as PRIVKEY_DATA
    DecriptData((char *)(aes_pass.c_str()),encriptedSeed,&decriptPrivKey);
    string decriptPrivKeyStr=decriptPrivKey;
    free(decriptPrivKey);
    sprintf(privKeyAndHash160,"%s",decriptPrivKeyStr.c_str());
    
    char privKeyData[256];
    char MD5_hash160[64];
    char *pMD5_begin;
    pMD5_begin=strstr(privKeyAndHash160,":MD5:");
    if(!pMD5_begin)
        return -1;	// ERROR
    
    int privkeyLen=strlen(privKeyAndHash160)-strlen(pMD5_begin);
    memcpy(privKeyData,privKeyAndHash160,privkeyLen);
    privKeyData[privkeyLen]='\0';
    
    pMD5_begin+=5;	// jump over :MD5: , 5 bytes
    
    int MD5_hash160Len=strlen(pMD5_begin);
    if(MD5_hash160Len != 40)	// HASH160 's hex string length must be 40 bytes
        return -1;
    
    memcpy(MD5_hash160,pMD5_begin,MD5_hash160Len);
    MD5_hash160[MD5_hash160Len]='\0';
    
    char privKeyHash160[64];
    GetHash160(privKeyData,privKeyHash160);
    if(strcmp(privKeyHash160,MD5_hash160)==0)
    {
        strcpy(seedStr,privKeyData);
        return 0;
    }
    return -1;	// ERROR
    
}

/*
 struct CExtPubKey {
 unsigned char nDepth;
 unsigned char vchFingerprint[4];
 unsigned int nChild;
 unsigned char vchChainCode[32];
 CPubKey pubkey;
 */
int GetExPubKeyFromSeed(char *SeedStr, char *ExPubKey)
{
    CExtKey Exkey;
    CExtPubKey Expubkey;
    std::vector<unsigned char> seed = ParseHex(SeedStr);
    
    Exkey.SetMaster(&seed[0], seed.size());
    Expubkey=Exkey.Neuter();
    
    unsigned char data[76];
    Expubkey.Encode(data);
    std::vector<unsigned char> vch(&data[0], &data[74]);
    string pubkeyStr=HexStr(vch);
    sprintf(ExPubKey,"%s",pubkeyStr.c_str());
    
    return 0;
}

int GetPrivKeyFromSeed(char *SeedStr, unsigned int N, char *PrivKey)
{
    CExtKey Exkey;
    std::vector<unsigned char> seed = ParseHex(SeedStr);
    Exkey.SetMaster(&seed[0], seed.size());
    
    CExtKey privkeyNew;
    CBitcoinSecret btcSecret;
    Exkey.Derive(privkeyNew, N);
    btcSecret.SetKey(privkeyNew.key);
    sprintf(PrivKey,"%s",btcSecret.ToString().c_str());
    return 0;
}

int GetAddrFromExPubKey(char *ExPubKeyStr, unsigned int N, char *address)
{
    CExtPubKey Expubkey;
    unsigned char data[74];
    std::vector<unsigned char> ExPubKeyRawData = ParseHex(ExPubKeyStr);
    for(int i=0;i<74;i++)
        data[i]=ExPubKeyRawData[i];
    Expubkey.Decode(data);
    
    CExtPubKey pubkeyNew;
    Expubkey.Derive(pubkeyNew, N);
    
    CBitcoinAddress btcAddr(pubkeyNew.pubkey.GetID());
    sprintf(address,"%s",btcAddr.ToString().c_str());
    
    return 0;
}
//

int HmacEncode(const char * algo,
               const char * key, unsigned int key_length,
               const char * input, unsigned int input_length,
               unsigned char * &output, unsigned int &output_length)
{
    const EVP_MD * engine = NULL;
    if(strcasecmp("sha512", algo) == 0) {
        engine = EVP_sha512();
    }
    else if(strcasecmp("sha256", algo) == 0) {
        engine = EVP_sha256();
    }
    else if(strcasecmp("sha1", algo) == 0) {
        engine = EVP_sha1();
    }
    else if(strcasecmp("md5", algo) == 0) {
        engine = EVP_md5();
    }
    else if(strcasecmp("sha224", algo) == 0) {
        engine = EVP_sha224();
    }
    else if(strcasecmp("sha384", algo) == 0) {
        engine = EVP_sha384();
    }
    else if(strcasecmp("sha", algo) == 0) {
        engine = EVP_sha();
    }
    else {
        cout << "Algorithm " << algo << " is not supported by this program!" << endl;
        return -1;
    }
    
    output = (unsigned char*)malloc(EVP_MAX_MD_SIZE);
    
    HMAC_CTX ctx;
    HMAC_CTX_init(&ctx);
    HMAC_Init_ex(&ctx, key, strlen(key), engine, NULL);
    HMAC_Update(&ctx, (unsigned char*)input, strlen(input));        // input is OK; &input is WRONG !!!
    
    HMAC_Final(&ctx, output, &output_length);
    HMAC_CTX_cleanup(&ctx);
    
    return 0;
}

//check address  -1: invalid address  0: valid address
int CheckAddress(char *addr)
{
    CBitcoinAddress address(addr);
    if (!address.IsValid())
    {
        return -1;
    }
    
    return 0;
}


//check privkey  -1: invalid privkey  0: valid privkey
int CheckPrivKey(char *privKey)
{
    string privStr(privKey);
    CBitcoinSecret btcSecret;
    if(!btcSecret.SetString (privStr))
    {
        printf("Error : btcSecret.SetString (privStr)...\n");
        return -1;
    }
    if(btcSecret.IsValid())
        return 0;
    
    return -1;
}


//
int GetPubKeyFromSeedEx(char *SeedStr, char *PubKey, int type1, int type2, int index)
{
    CExtKey Exkey;
    CExtPubKey Expubkey;
    std::vector<unsigned char> seed = ParseHex(SeedStr);
    
    Exkey.SetMaster(&seed[0], seed.size());
    Expubkey=Exkey.Neuter();
    
    CExtPubKey pubkey1;
    Expubkey.Derive(pubkey1, type1);
    
    CExtPubKey pubkey2;
    pubkey1.Derive(pubkey2, type2);
    
    CExtPubKey pubkey3;
    pubkey2.Derive(pubkey3, index);
    
    CPubKey pubkey  = pubkey3.pubkey;
    std::vector<unsigned char> vch(pubkey.begin(), pubkey.end());
    std::string pubkeyStr=HexStr(vch);
    
    sprintf(PubKey,"%s",pubkeyStr.c_str());
    return 0;
}

int GetPrivKeyFromSeedEx(char *SeedStr, char *PrivKey, int type1, int type2, int index)
{
    CExtKey Exkey;
    std::vector<unsigned char> seed = ParseHex(SeedStr);
    Exkey.SetMaster(&seed[0], seed.size());
    
    CExtKey privkeyNew;
    Exkey.Derive(privkeyNew, type1);
    
    CExtKey privkeyNew2;
    privkeyNew.Derive(privkeyNew2, type2);
    
    CExtKey privkeyNew3;
    privkeyNew2.Derive(privkeyNew3, index);
    
    CBitcoinSecret btcSecret;
    btcSecret.SetKey(privkeyNew3.key);
    sprintf(PrivKey,"%s",btcSecret.ToString().c_str());
    
    return 0;
}

int decodeRawTransaction(char *in_param, char **decodetx_ret)
{
    Value r;
    char *ret_str;
    string param=string("decoderawtransaction ")+in_param;
    r = CallRPC(param);
    string ret=write_string(Value(r), false);
    ret_str=(char *)malloc(ret.size()+1);
    sprintf(ret_str,"%s",ret.c_str());
    *decodetx_ret=ret_str;
    return 0;
}

// zip file
int EncodeZipToString(unsigned char *zipData, int len, char **outStr)
{
    std::string output=EncodeBase64(zipData, len);
    *outStr=(char *)malloc(output.size()+1);
    sprintf(*outStr,"%s",output.c_str());
    
    return 0;
}

int DecodeStringToZip(char *outStr, unsigned char **zipData, int* plen)
{
    unsigned char *output;
    bool Invalid;
    std::vector<unsigned char> vch=DecodeBase64(outStr,&Invalid);
    
    if(Invalid)
        return -1;
    
    *zipData=(unsigned char *)malloc(vch.size());
    output=*zipData;
    for(int i=0;i<vch.size();i++)
    {
        output[i]=vch[i];
    }
    *plen=vch.size();
    return 0;
}


//add
int GetPubKeyFromSeedVector(char *SeedStr, char *PubKey, vector<int> index)
{
    CExtKey Exkey;
    CExtPubKey Expubkey;
    std::vector<unsigned char> seed = ParseHex(SeedStr);
    
    Exkey.SetMaster(&seed[0], seed.size());
    Expubkey=Exkey.Neuter();
    
    for(int i=0;i<index.size();i++)
    {
        CExtPubKey pubkey1;
        Expubkey.Derive(pubkey1, index[i]);
        Expubkey=pubkey1;
    }
    
    CPubKey pubkey  = Expubkey.pubkey;
    std::vector<unsigned char> vch(pubkey.begin(), pubkey.end());
    std::string pubkeyStr=HexStr(vch);
    
    sprintf(PubKey,"%s",pubkeyStr.c_str());
    return 0;
}

int GetPrivKeyFromSeedVector(char *SeedStr, char *PrivKey, vector<int> index)
{
    CExtKey Exkey;
    std::vector<unsigned char> seed = ParseHex(SeedStr);
    Exkey.SetMaster(&seed[0], seed.size());
    
    for(int i=0;i<index.size();i++)
    {
        CExtKey privkeyNew;
        Exkey.Derive(privkeyNew, index[i]);
        Exkey=privkeyNew;
    }
    
    CBitcoinSecret btcSecret;
    btcSecret.SetKey(Exkey.key);
    sprintf(PrivKey,"%s",btcSecret.ToString().c_str());
    
    return 0;
}

int GetPubKeyFromSeedEx2(char *SeedStr, char *PubKey, int *pIndex, int num)
{
    CExtKey Exkey;
    CExtPubKey Expubkey;
    std::vector<unsigned char> seed = ParseHex(SeedStr);
    
    Exkey.SetMaster(&seed[0], seed.size());
    Expubkey=Exkey.Neuter();
    
    for(int i=0;i<num;i++)
    {
        CExtPubKey pubkey1;
        Expubkey.Derive(pubkey1, pIndex[i]);
        Expubkey=pubkey1;
    }
    
    CPubKey pubkey  = Expubkey.pubkey;
    std::vector<unsigned char> vch(pubkey.begin(), pubkey.end());
    std::string pubkeyStr=HexStr(vch);
    
    sprintf(PubKey,"%s",pubkeyStr.c_str());
    return 0;
}

int GetPrivKeyFromSeedEx2(char *SeedStr, char *PrivKey, int *pIndex, int num)
{
    CExtKey Exkey;
    std::vector<unsigned char> seed = ParseHex(SeedStr);
    Exkey.SetMaster(&seed[0], seed.size());
    
    for(int i=0;i<num;i++)
    {
        CExtKey privkeyNew;
        Exkey.Derive(privkeyNew, pIndex[i]);
        Exkey=privkeyNew;
    }
    
    CBitcoinSecret btcSecret;
    btcSecret.SetKey(Exkey.key);
    sprintf(PrivKey,"%s",btcSecret.ToString().c_str());
    
    return 0;
}


// add
int GetPrivKeyFromSeedBIP44(const char *SeedStr, char *PrivKey, unsigned int purpose, unsigned int coin, unsigned int account, unsigned int isInternal, unsigned int addrIndex)
{
    CExtKey Exkey;
    std::vector<unsigned char> seed = ParseHex(SeedStr);
    Exkey.SetMaster(&seed[0], seed.size());
    
    CExtKey privkey1;
    purpose |= 0x80000000;
    Exkey.Derive(privkey1, purpose);
    
    CExtKey privkey2;
    coin |= 0x80000000;
    privkey1.Derive(privkey2, coin);
    
    CExtKey privkey3;
    account |= 0x80000000;
    privkey2.Derive(privkey3, account);
    
    CExtKey privkey4;
    privkey3.Derive(privkey4, isInternal);
    
    CExtKey privkey5;
    privkey4.Derive(privkey5, addrIndex);
    
    CBitcoinSecret btcSecret;
    btcSecret.SetKey(privkey5.key);
    sprintf(PrivKey,"%s",btcSecret.ToString().c_str());
    
    return 0;
}

int GetPubKeyFromSeedBIP44(const char *SeedStr, char *PubKey, unsigned int purpose, unsigned int coin, unsigned int account, unsigned int isInternal, unsigned int addrIndex)
{
    CExtPubKey Expubkey;
    CExtKey Exkey;
    std::vector<unsigned char> seed = ParseHex(SeedStr);
    Exkey.SetMaster(&seed[0], seed.size());
    
    CExtKey privkey1;
    purpose |= 0x80000000;
    Exkey.Derive(privkey1, purpose);
    
    CExtKey privkey2;
    coin |= 0x80000000;
    privkey1.Derive(privkey2, coin);
    
    CExtKey privkey3;
    account |= 0x80000000;
    privkey2.Derive(privkey3, account);
    
    Expubkey=privkey3.Neuter();
    CExtPubKey pubkey4;
    Expubkey.Derive(pubkey4, isInternal);
    
    CExtPubKey pubkey5;
    pubkey4.Derive(pubkey5, addrIndex);
    
    CPubKey pubkey  = pubkey5.pubkey;
    std::vector<unsigned char> vch(pubkey.begin(), pubkey.end());
    std::string pubkeyStr=HexStr(vch);
    
    sprintf(PubKey,"%s",pubkeyStr.c_str());
    return 0;
}

int GetAccountMasterPubKeyFromSeedBIP44(const char *SeedStr, char *masterPubKey, unsigned int purpose, unsigned int coin, unsigned int account)
{
    unsigned char code[74];
    CExtPubKey Expubkey;
    CExtKey Exkey;
    std::vector<unsigned char> seed = ParseHex(SeedStr);
    Exkey.SetMaster(&seed[0], seed.size());
    
    CExtKey privkey1;
    purpose |= 0x80000000;
    Exkey.Derive(privkey1, purpose);
    
    CExtKey privkey2;
    coin |= 0x80000000;
    privkey1.Derive(privkey2, coin);
    
    CExtKey privkey3;
    account |= 0x80000000;
    privkey2.Derive(privkey3, account);
    
    Expubkey=privkey3.Neuter();
    Expubkey.Encode(code);
    
    std::string pubkeyStr=HexStr(&code[0],&code[74],false);
    sprintf(masterPubKey,"%s",pubkeyStr.c_str());
    return 0;
}

int GetPubKeyFromAccountMasterPubKeyBIP44(const char *masterPubKey, char *PubKey, unsigned int isInternal, unsigned int addrIndex)
{
    std::vector<unsigned char> master_Pubkey = ParseHex(masterPubKey);
    unsigned char code[74];
    CExtPubKey Expubkey;
    
    if(master_Pubkey.size()!=74)
        return -1;
    
    for(int i=0;i<74;i++)
        code[i]=master_Pubkey[i];
    
    Expubkey.Decode(code);
    
    CExtPubKey pubkey4;
    Expubkey.Derive(pubkey4, isInternal);
    
    CExtPubKey pubkey5;
    pubkey4.Derive(pubkey5, addrIndex);
    
    CPubKey pubkey  = pubkey5.pubkey;
    std::vector<unsigned char> vch(pubkey.begin(), pubkey.end());
    std::string pubkeyStr=HexStr(vch);
    
    sprintf(PubKey,"%s",pubkeyStr.c_str());
    return 0;
}

void GetSeedFromBIP39Words(char *wordsStr, char *pass, char *outSeedstr)
{
    string seedStr;
    uint8_t seed_bytes[64];
    mnemonic_to_seed(wordsStr,pass,seed_bytes, 0);
    seedStr=HexStr(&seed_bytes[0],&seed_bytes[64],false);
    sprintf(outSeedstr,"%s",seedStr.c_str());
}

int GetBIP39WordsFromSeed(char *Seedstr, char *wordsStr)
{
    string wordstring;
    uint8_t seed_bytes[64];
    int i;
    std::vector<unsigned char> seed = ParseHex(Seedstr);
    
    for(i=0;i<seed.size();i++)
        seed_bytes[i]=seed[i];
    
    wordstring=mnemonic_from_data(seed_bytes,seed.size());
    sprintf(wordsStr,"%s",wordstring.c_str());
    
    return 0;
}


//hash256  1000次
void GetHash256Str(char *indata, char *outhashstr)
{

        uint256 hashMsg = Hash((unsigned char *)indata, (unsigned char *)indata+strlen(indata));
        string hashstring=HexStr(hashMsg.begin(), hashMsg.end());
        sprintf(outhashstr,"%s",hashstring.c_str());

}

int SignHash(char *privKey, char *hashHexStr, char *signStr)
{
    
    CBitcoinSecret btcSecret;
    if(!btcSecret.SetString (privKey))
    {
        printf("Error : btcSecret.SetString (privStr)...\n");
        return 1;
    }
    CKey key  = btcSecret.GetKey();
    uint256 hashMsg;
    hashMsg.SetHex(hashHexStr);
    
    // normal signatures
    vector<unsigned char> sign;
    if(!key.Sign (hashMsg, sign))
    {
        printf("Error : key1.Sign (hashMsg, sign1)\n");
        return 2;
    }
    
    string signstring=HexStr(sign.begin(), sign.end());
    sprintf(signStr,"%s",signstring.c_str());
    return 0;
}

int VerifySign(char *pubKey, char *hashHexStr, char *signStr)
{
    uint256 hashMsg;
    hashMsg.SetHex(hashHexStr);
    std::vector<unsigned char> sign = ParseHex(signStr);
    std::string pubkeyStr = pubKey;
    CPubKey pubkey(ParseHex(pubkeyStr));
    
    if(! pubkey.Verify(hashMsg, sign))
    {
        printf("Error : pubkey1.Verify(hashMsg, sign1C)\n");
        return 0;
    }
    return 1;
}


int signMessage(char *in_param, char **signed_output)
{
    Value r;
    char *ret_str;
    string param=string("signmessage ")+in_param;
    r = CallRPC(param);
    string signed_ret = r.get_str();
    ret_str=(char *)malloc(signed_ret.size()+1);
    sprintf(ret_str,"%s",signed_ret.c_str());
    *signed_output=ret_str;
    return 0;
}

int verifyMessage(char *in_param)
{
    Value r;
    char *ret_str;
    string param=string("verifymessage ")+in_param;
    r = CallRPC(param);
    string verify_ret=write_string(Value(r), false);
    if(verify_ret=="true")
        return 1;
    return 0;
}

//
int GetRawPrivKey(char *rawPrivKey, char *privKey)
{
    string privStr(privKey);
    CBitcoinSecret btcSecret;
    if(!btcSecret.SetString (privStr))
    {
        printf("Error : btcSecret.SetString (privStr)...\n");
        return 1;
    }
    CKey pkey  = btcSecret.GetKey();
    std::vector<unsigned char> vch(pkey.begin(), pkey.end());
    std::string pkeyStr=HexStr(vch);
    
    sprintf(rawPrivKey,"%s",pkeyStr.c_str());
//    printf("rawPrivKey is :%s\n",rawPrivKey);
    return 0;
}

#pragma mark - ECC encryption and decryption algorithm
int ECC_encryptEx(char *privKey, char *pubKey, char *input, char **encryptedString)
{
    char rawPrivKey[256];
    secure_t *ciphered = NULL;
    
    GetRawPrivKey(rawPrivKey,privKey);
    
    if (!(ciphered = ecies_encryptEx(rawPrivKey, pubKey, (unsigned char *)input, strlen(input)+1)))
    {
        printf("The encryption process failed!\n");
        return -1;
    }
    
    std::string outputStr=HexStr((unsigned char *)ciphered, (unsigned char *)ciphered+secure_total_length(ciphered), false);
    *encryptedString=(char *)malloc(outputStr.size()+1);
    sprintf(*encryptedString,"%s",outputStr.c_str());
    free(ciphered);
    return 0;
}

int ECC_decryptEx(char *privKey, char *pubKey, char *encrypted, char **outputStr)
{
    char rawPrivKey[256];
    secure_t *ciphered = NULL;
    size_t olen;
    unsigned char *original = NULL;
    int i;
    std::vector<unsigned char> ciphervec = ParseHex(encrypted);
    ciphered=(secure_t *)malloc(ciphervec.size());
    for(i=0;i<ciphervec.size();i++)
        *((unsigned char *)ciphered+i)=ciphervec[i];
    
    GetRawPrivKey(rawPrivKey,privKey);
    
    if (!(original = ecies_decryptEx(rawPrivKey, pubKey, ciphered, &olen)))
    {
        printf("The decryption process failed!\n");
        return -1;
    }
    
    *outputStr=(char *)original;
    free(ciphered);
    return 0;
}

#pragma mark -pbkdf2_hmac_sha512

void xtalkPBKDF2_HMAC_SHA512(unsigned char *pass, int passLen, unsigned char *salt, int saltLen, uint8_t *key, int keyLen, int n)
{
    // calc iteration count 2^n
    uint32_t iter = 1<<n;
    PKCS5_PBKDF2_HMAC((const char*)pass, passLen, salt, saltLen/8, iter, EVP_sha512(), keyLen/8, key);
}

/**
   Extended key function
   Ordinary ecdh
   Random salt
 */
+ (NSData *)getAes256KeyByECDHKeyAndSalt:(NSData *)ecdhKey salt:(NSData *)salt{
    const char *ecdhKey_c = (const char *)ecdhKey.bytes;
    const char *salt_c;
    if(!salt || salt.length != 64){
        char default_salt[64];
        memset(default_salt,0x00,64);
        salt_c = &default_salt[0];
    } else{
        salt_c = (const char *)salt.bytes;
    }
    unsigned char outKey[256/8];
    
    xtalkPBKDF2_HMAC_SHA512((unsigned char*)ecdhKey_c, (int)ecdhKey.length, (unsigned char*)salt_c, 512, outKey, 256, 12);

    NSData *data = [NSData dataWithBytes:outKey length:32];
    
    return  data;
}

#pragma mark - test createPrvkey by unknown length
-(void)testSeedCreateMorePrvkeyPubkey
{
    char seed[128] = "b7bd5cb106212c5494c71e094a05638aa8fd";
    char prikey[128];
    char pubkey[128];
    int aa[] = {1,2,3,4,5,6,7,9};
    int lengh = sizeof(aa)/sizeof(int);
    GetPrivKeyFromSeedEx2(seed, prikey, aa, lengh);
    DDLogInfo(@"prikey --%s",prikey);
    GetPubKeyFromPrivKey(prikey, pubkey);
    DDLogInfo(@"pubkey -- %s",pubkey);
    
    vector<int> ivector(aa,aa+lengh);
    GetPrivKeyFromSeedVector(seed, prikey, ivector);
    DDLogInfo(@"prikey --%s",prikey);
    GetPubKeyFromPrivKey(prikey, pubkey);
    DDLogInfo(@"pubkey -- %s",pubkey);
}


@end
