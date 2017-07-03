//
//  LMIMHelper.m
//  Connect-IM-Encryption
//
//  Created by MoHuilin on 2017/6/13.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "LMIMHelper.h"


#ifdef __cplusplus
#if __cplusplus
extern "C"{
#include "bip39.h"
#include "ecies.h"
#include "pbkdf2.h"
}
#endif
#endif /* __cplusplus */

#include "key.h"
#include "base58.h"
#include <openssl/aes.h>
#include <openssl/rand.h>
#include <boost/algorithm/string.hpp>
#include <boost/assign/list_of.hpp>
#include "json_spirit_reader_template.h"

@implementation LMIMHelper

// Create a new private key
+ (NSString *)creatNewPrivkey {
    char privkey[256];
    CreateNewPrivKey_im(privkey);
    return [NSString stringWithFormat:@"%s", privkey];
}

+ (NSString *)creatNewPrivkeyByRandom:(NSString *)random {
    char myRand[129] = {0};
    char *randomC = (char *) [random UTF8String];
    sprintf(myRand, "%s", randomC);
    char privKey[512];
    GetPrivKeyFromSeedBIP44_im(myRand, privKey, 44, 0, 0, 0, 0);
    return [NSString stringWithFormat:@"%s", privKey];
}

+ (NSString *)getPubkeyByPrikey:(NSString *)prikey {
    char pubkey[256];
    GetPubKeyFromPrivKey_im((char *) [prikey UTF8String], pubkey);
    return [NSString stringWithFormat:@"%s", pubkey];
}


+ (NSString *)getAddressByPubkey:(NSString *)pubkey {
    char myaddress[128];
    char *myPubkey = (char *) [pubkey UTF8String];
    GetBTCAddrFromPubKey_im(myPubkey, myaddress);
    return [NSString stringWithFormat:@"%s", myaddress];
}

+ (NSString *)getAddressByPrivKey:(NSString *)prvkey {
    char *cPrivkey = (char *) [prvkey UTF8String];
    char pubKey[128];
    GetPubKeyFromPrivKey_im(cPrivkey, pubKey);
    char address[128];
    GetBTCAddrFromPubKey_im(pubKey, address);
    return [NSString stringWithFormat:@"%s", address];
}


+ (NSString *)encodeWithPrikey:(NSString *)privkey address:(NSString *)address password:(NSString *)password {
    char usrID_BtcAddress[256];
    char privKey_HexString[65];
    char pass[64];
    int n = 17;
    string bitAddressString = [address UTF8String];
    char *privkeyStr22 = (char *) [privkey UTF8String];
    GetRawPrivKey_im(privKey_HexString, privkeyStr22);

    sprintf(usrID_BtcAddress, bitAddressString.c_str());
    std::string passwordStr = [password UTF8String];
    sprintf(pass, passwordStr.c_str());

    std::string retString = xtalkUsrPirvKeyEncrypt_im_String(usrID_BtcAddress, privKey_HexString, pass, n, 1);

    return [NSString stringWithFormat:@"%s", retString.c_str()];
}

+ (NSDictionary *)decodeEncryptPrikey:(NSString *)encryptPrikey withPassword:(NSString *)password {

    if (!encryptPrikey || !password) {
        return @{@"is_success": @(NO)};
    }
    std::string retString = [encryptPrikey UTF8String];
    char usrID2_BtcAddress[256];
    char privKey2_HexString[65];
    char privKey[52];
    char pass[64];
    string passwordStr = [password UTF8String];
    sprintf(pass, (char *) passwordStr.c_str());
    BOOL isSuccess = NO;
    int ret = xtalkUsrPirvKeyDecrypt_im_String((char *) retString.c_str(), pass, 1, usrID2_BtcAddress, privKey2_HexString);
    if (ret != 1) {
        printf("xtalk decrypted error!\n");
        return nil;
    } else {
        GetBtcPrivKeyFromRawPrivKey_im(privKey, privKey2_HexString);
        printf("%s", privKey);
        isSuccess = YES;
    }
    return @{@"address": [NSString stringWithCString:usrID2_BtcAddress encoding:NSUTF8StringEncoding],
            @"is_success": @(isSuccess),
            @"prikey": [NSString stringWithUTF8String:privKey]};
}

+ (NSData *)createRandom512bits {
    uint8_t randNum[512 / 8];
    xtalkRNG_im(randNum, 512);
    return [NSData dataWithBytes:randNum length:512 / 8];
}

+ (BOOL)CheckPrivKey:(NSString *)privkey {
    char *cPrivkey = (char *) [privkey UTF8String];
    int result = CheckPrivKey_im(cPrivkey);
    return result == 0 ? YES : NO;
}


+ (BOOL)CheckAddress:(NSString *)address {

    // Adapt the btc.com sweep results
    address = [address stringByReplacingOccurrencesOfString:@"bitcoin:" withString:@""];
    if (address.length == 0) {
        return NO;
    }
    char *cAddress = (char *) [address UTF8String];
    int result = CheckAddress_im(cAddress);
    return result == 0 ? YES : NO;
}

+ (NSString *)getECDHkeyUsePrivkey:(NSString *)privkey PublicKey:(NSString *)pubkey {

    char *privkeyc = (char *) [privkey UTF8String];
    char *pubkeyc = (char *) [pubkey UTF8String];
    unsigned char ecdh_key[32];
    int len = xtalk_getRawECDHkey_im(privkeyc, pubkeyc, ecdh_key);
    if (len == 32) {
        std::vector<unsigned char> outdata;
        outdata.resize(32);
        for (int i = 0; i < 32; i++)
            outdata[i] = ecdh_key[i];
        std::string str;
        str = BinToHexString_im(outdata);
        str = bytestohexstring_im((char *) ecdh_key, 32);
        NSString *result = [NSString stringWithFormat:@"%s", str.c_str()];
        return result;
    }
    return @"";
}

/**
 Extended key function
   Ordinary ecdh
   Random salt
 */
+ (NSData *)getAes256KeyByECDHKeyAndSalt:(NSData *)ecdhKey salt:(NSData *)salt {
    const char *ecdhKey_c = (const char *) ecdhKey.bytes;
    const char *salt_c;
    if (!salt || salt.length != 64) {
        char default_salt[64];
        memset(default_salt, 0x00, 64);
        salt_c = &default_salt[0];
    } else {
        salt_c = (const char *) salt.bytes;
    }
    unsigned char outKey[256 / 8];
    
    xtalkPBKDF2_HMAC_SHA512_im((unsigned char *) ecdhKey_c, (int) ecdhKey.length, (unsigned char *) salt_c, 512, outKey, 256, 12);
    
    NSData *data = [NSData dataWithBytes:outKey length:32];
    
    return data;
}


#pragma mark -AES

+ (NSDictionary *)xtalkEncodeAES_gcm_im:(NSString *)password data:(NSString *)dataStr aad:(NSString *)aad iv:(NSString *)iv {

    unsigned char *encryptedData;

    //IV
    std::vector<unsigned char> IVByte;
    IVByte = HexStringToBin_im([iv UTF8String]);


    // key
    std::vector<unsigned char> KeyByte;
    KeyByte = HexStringToBin_im([password UTF8String]);


    //aad
    std::vector<unsigned char> aadByte;
    aadByte = HexStringToBin_im([aad UTF8String]);

    std::vector<unsigned char> inDataByte;
    int len;
    unsigned char *indata = (unsigned char *) [dataStr UTF8String];
    string indataStr = (char *) indata;
    len = indataStr.size();
    inDataByte.resize(len);
    for (int i = 0; i < len; i++)
        inDataByte[i] = indata[i];

    // accept tag
    unsigned char tag[16];

    int encryptedLen = xtalkEncodeAES_gcm_im(&inDataByte[0], len, &aadByte[0], aadByte.size(), &KeyByte[0], &IVByte[0], IVByte.size(), &encryptedData, tag);


    std::string tagstring = HexStr(&tag[0], &tag[16]);

    std::string encryptedDatastring = HexStr(&encryptedData[0], &encryptedData[encryptedLen]);

    if (encryptedData)
        free(encryptedData);

    NSDictionary *resultD = @{
            @"encryptedDatastring": [[NSString alloc] initWithUTF8String:encryptedDatastring.c_str()],
            @"tagstring": [[NSString alloc] initWithUTF8String:tagstring.c_str()]
    };

    return resultD;
}

#pragma mark new method

/**
 *  ECDH Shared key generation
 */

+ (NSData *)getECDHkeyWithPrivkey:(NSString *)privkey publicKey:(NSString *)pubkey {
    char *privkeyc = (char *) [privkey UTF8String];
    char *pubkeyc = (char *) [pubkey UTF8String];
    unsigned char ecdh_key[32];
    int len = xtalk_getRawECDHkey_im(privkeyc, pubkeyc, ecdh_key);
    if (len == 32) {
        NSData *ecdhData = [NSData dataWithBytes:(const void *) ecdh_key length:sizeof(unsigned char) * 32];
        return ecdhData;
    }
    return nil;
}


+ (NSDictionary *)xtalkEncodeAES_imWithPassword:(NSData *)password originData:(NSData *)data aad:(NSData *)aad {

    if (!data || data.length <= 0 || !password || password.length <= 0 || !aad || aad.length <= 0) {
        return nil;
    }

    unsigned char *encryptedData;

    NSData *ivData = [self createRandom512bits];
    ivData = [ivData subdataWithRange:NSMakeRange(0, 16)];

    //IV
    unsigned char *ivdata = (unsigned char *) [ivData bytes];

    // key
    unsigned char *keydata = (unsigned char *) [password bytes];

    //aad
    unsigned char *aaddata = (unsigned char *) [aad bytes];

    // perapre indata
    unsigned char *indata = (unsigned char *) [data bytes];

    //接受tag
    unsigned char tag[16];

    int encryptedLen = xtalkEncodeAES_gcm_im(indata, data.length, aaddata, aad.length, keydata, ivdata, ivData.length, &encryptedData, tag);

    if (encryptedLen == -1) {
        return nil;
    }

    NSData *ciphertextData = [NSData dataWithBytes:(const void *) encryptedData length:sizeof(unsigned char) * encryptedLen];
    NSData *tagData = [NSData dataWithBytes:(const void *) tag length:sizeof(unsigned char) * 16];

    NSDictionary *cipTagDict = @{@"ciphertext": ciphertextData,
            @"tag": tagData,
            @"iv": ivData};
    if (encryptedData)
        free(encryptedData);

    return cipTagDict;
}

+ (NSData *)get16_32RandData {
    NSData *randomData = [self createRandom512bits];
    int loc = arc4random() % 32;
    int len = arc4random() % 16 + 16;
    randomData = [randomData subdataWithRange:NSMakeRange(loc, len)];
    return randomData;
}


+ (NSDictionary *)xtalkEncodeAES_gcm_im:(NSString *)password withNSdata:(NSData *)data aad:(NSString *)aad iv:(NSString *)iv {

    if (!data) {
        return nil;
    }
    if (!password) {
        return nil;
    }


    unsigned char *encryptedData;
    unsigned char *decryptedData;

    //IV
    std::vector<unsigned char> IVByte;
    IVByte = HexStringToBin_im([iv UTF8String]);


    // key
    std::vector<unsigned char> KeyByte;
    KeyByte = HexStringToBin_im([password UTF8String]);


    //aad
    std::vector<unsigned char> aadByte;
    aadByte = HexStringToBin_im([aad UTF8String]);



    // perapre indata
    int indatalen = data.length;
    Byte *indata = (Byte *) [data bytes];

    unsigned char tag[16];

    int encryptedLen = xtalkEncodeAES_gcm_im(indata, indatalen, &aadByte[0], aadByte.size(), &KeyByte[0], &IVByte[0], IVByte.size(), &encryptedData, tag);
    if (encryptedLen == -1) {
        return nil;
    }

    std::string tagstring = HexStr(&tag[0], &tag[16]);

    std::string encryptedDatastring = HexStr(&encryptedData[0], &encryptedData[encryptedLen]);

    if (encryptedData)
        free(encryptedData);

    NSDictionary *resultD = @{
            @"encryptedDatastring": [[NSString alloc] initWithUTF8String:encryptedDatastring.c_str()],
            @"tagstring": [[NSString alloc] initWithUTF8String:tagstring.c_str()]
    };


    return resultD;
}


+ (NSData *)xtalkDecodeAES_GCMWithPassword:(NSString *)password data:(NSString *)dataStr aad:(NSString *)aad iv:(NSString *)iv tag:(NSString *)tagin {
    unsigned char *decryptedData;


    std::vector<unsigned char> IVByte;
    IVByte = HexStringToBin_im([iv UTF8String]);

    // key
    std::vector<unsigned char> KeyByte;
    KeyByte = HexStringToBin_im([password UTF8String]);

    //aad
    std::vector<unsigned char> aadByte;
    aadByte = HexStringToBin_im([aad UTF8String]);

    // perapre indata
    string indataStr = [dataStr UTF8String];

    std::vector<unsigned char> inDataByte;
    inDataByte = HexStringToBin_im(indataStr);


    std::vector<unsigned char> tagByte;
    tagByte = HexStringToBin_im([tagin UTF8String]);


    int decryptedLen = xtalkDecodeAES_gcm_im(&inDataByte[0], inDataByte.size(), &aadByte[0], aadByte.size(), &tagByte[0], &KeyByte[0], &IVByte[0], IVByte.size(), &decryptedData);


    NSData *result = nil;

    if (decryptedLen < 0) {
        return result;
    }
    std::vector<unsigned char> resultData;
    resultData.resize(decryptedLen);
    for (int i = 0; i < decryptedLen; i++) {
        resultData[i] = decryptedData[i];
    }

    if (decryptedLen > 0) {
        result = [[NSData alloc] initWithBytes:&resultData[0] length:decryptedLen];
    } else {
        std::string error = xtalk_getErrInfo_im();
        printf("Error: %s\n", error.c_str());
    }

    if (decryptedData)
        free(decryptedData);

    return result;
}


+ (NSData *)xtalkDecodeAES_GCMDataWithPassword:(NSData *)password data:(NSData *)data aad:(NSData *)aad iv:(NSData *)iv tag:(NSData *)tag {

    unsigned char *decryptedData;


    unsigned char *IVByte = (unsigned char *) [iv bytes];

    unsigned char *KeyByte = (unsigned char *) [password bytes];

    unsigned char *inDataByte = (unsigned char *) [data bytes];

    unsigned char *aadByte = (unsigned char *) [aad bytes];

    unsigned char *tagByte = (unsigned char *) [tag bytes];


    int decryptedLen = xtalkDecodeAES_gcm_im(inDataByte, data.length, aadByte, aad.length, tagByte, KeyByte, IVByte, iv.length, &decryptedData);

    NSData *result = nil;

    if (decryptedLen > 0) {
        result = [[NSData alloc] initWithBytes:&decryptedData[0] length:decryptedLen];
    } else {
        std::string error = xtalk_getErrInfo_im();
        printf("Error: %s\n", error.c_str());
    }

    if (decryptedData)
        free(decryptedData);

    return result;
}


+ (NSString *)xtalkDecodeAES_GCM:(NSString *)password data:(NSString *)dataStr aad:(NSString *)aad iv:(NSString *)iv tag:(NSString *)tagin {
    unsigned char *decryptedData;


    std::vector<unsigned char> IVByte;
    IVByte = HexStringToBin_im([iv UTF8String]);

    // key
    std::vector<unsigned char> KeyByte;
    KeyByte = HexStringToBin_im([password UTF8String]);

    //aad
    std::vector<unsigned char> aadByte;
    aadByte = HexStringToBin_im([aad UTF8String]);

    // perapre indata
    string indataStr = [dataStr UTF8String];
    std::vector<unsigned char> inDataByte;
    inDataByte = HexStringToBin_im(indataStr);


    std::vector<unsigned char> tagByte;
    tagByte = HexStringToBin_im([tagin UTF8String]);


    int decryptedLen = xtalkDecodeAES_gcm_im(&inDataByte[0], inDataByte.size(), &aadByte[0], aadByte.size(), &tagByte[0], &KeyByte[0], &IVByte[0], IVByte.size(), &decryptedData);


    NSString *result = @"";

    if (decryptedLen < 0) {
        return result;
    }
    std::vector<unsigned char> resultData;
    resultData.resize(decryptedLen);
    for (int i = 0; i < decryptedLen; i++) {
        resultData[i] = decryptedData[i];
    }

    if (decryptedLen > 0) {
        result = [[NSString alloc] initWithBytes:&resultData[0] length:decryptedLen encoding:NSUTF8StringEncoding];
    } else {
        std::string error = xtalk_getErrInfo_im();
        printf("Error: %s\n", error.c_str());
    }

    if (decryptedData)
        free(decryptedData);

    return result;
}

#pragma mark - sign math

+ (NSString *)signHashWithPrivkey:(NSString *)privkey data:(NSString *)data {
    if (!privkey || !data) {
        return nil;
    }
    char *privkey_ = (char *) [privkey UTF8String];
    char *hashstr = (char *) [data UTF8String];
    char signStr[256];
    int result = SignHash_im(privkey_, hashstr, signStr);
    if (result == 0) {
        return [NSString stringWithUTF8String:signStr];
    }
    return nil;
}

+ (BOOL)verifyWithPublicKey:(NSString *)publicKey originData:(NSString *)data signData:(NSString *)signData {
    if (!publicKey || !signData) {
        return NO;
    }
    char *publicKey_ = (char *) [publicKey UTF8String];
    char *signData_ = (char *) [signData UTF8String];
    char *hashstr_ = (char *) [data UTF8String];
    int result = VerifySign_im(publicKey_, hashstr_, signData_);
    if (result == 1) {
        return YES;
    }
    return NO;
}

string bytestohexstring_im(char *bytes, int bytelength) {
    string str("");
    string str2("0123456789abcdef");
    for (int i = 0; i < bytelength; i++) {
        int b;
        b = 0x0f & (bytes[i] >> 4);
        char s1 = str2.at(b);
        str.append(1, str2.at(b));
        b = 0x0f & bytes[i];
        str.append(1, str2.at(b));
        char s2 = str2.at(b);
    }
    return str;
}

std::string BinToHexString_im(std::vector<unsigned char> data) {
    return HexStr(data);
}

std::vector<unsigned char> HexStringToBin_im(std::string str) {
    return ParseHex(str);
}

/**
 *  IOS side through openssl get the specified bit length random number
 */
void RNG_openssl_im(unsigned char *buf, int bits) {
    RAND_bytes(buf, bits / 8);
}

/**
 *  The IOS side obtains a random number of the specified bit length through the ios system call
 */
void RNG_ios_im(unsigned char *buf, int bits) {
    SecRandomCopyBytes(kSecRandomDefault, bits / 8, buf);
}

/**
 *  XOR two data blocks of the same bit length, writing the result to another data block
 */
void XORbits_im(const void *buf1, const void *buf2, int bits, void *res) {
    for (int i = 0; i < bits / 8; ++i) {
        ((uint8_t *) res)[i] = ((uint8_t *) buf1)[i] ^ ((uint8_t *) buf2)[i];
    }
}

/**
 *  The APP side generates a random number of cryptographic security
 */
void xtalkRNG_im(void *buf, int bits) {
    // get randnum by openssl
    uint8_t fromOpenssl[bits / 8];
    RNG_openssl_im(fromOpenssl, bits);
    // get randnum by ios
    uint8_t fromIOS[bits / 8];
    RNG_ios_im(fromIOS, bits);
    // mix(xor) two randnum into buf
    XORbits_im(fromOpenssl, fromIOS, bits, buf);
}


char *ossl_err_as_string_im(void) {
    BIO *bio = BIO_new(BIO_s_mem());
    ERR_print_errors(bio);
    char *buf = NULL;
    size_t len = BIO_get_mem_data (bio, &buf);
    char *ret = (char *) calloc(1, 1 + len);
    if (ret)
        memcpy(ret, buf, len);
    BIO_free(bio);
    return ret;
}

std::string xtalk_getErrInfo_im() {
    char *perror = ossl_err_as_string_im();
    std::string err = perror;
    free(perror);
    return err;
}


int xtalkEncodeAES_gcm_im(unsigned char *plaintext, int plaintext_len, unsigned char *aad,
        int aad_len, unsigned char *key, unsigned char *iv, int ivlen,
        unsigned char **cipherret, unsigned char *tag) {
    EVP_CIPHER_CTX *ctx;

    int len;
    unsigned char *ciphertext;
    int ciphertext_len;

    unsigned char initval_hex[16] = {0x23, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x33};

    if ((!iv) || ivlen <= 0) {
        iv = initval_hex;
        ivlen = 16;
    }

    *cipherret = (unsigned char *) malloc(plaintext_len);
    ciphertext = *cipherret;

    /* Create and initialise the context */
    if (!(ctx = EVP_CIPHER_CTX_new())) {
        printf("EVP_CIPHER_CTX_new error!\n");
        free(ciphertext);
        *cipherret = NULL;
        return -1;
    }

    /* Initialise the encryption operation. */
    if (1 != EVP_EncryptInit_ex(ctx, EVP_aes_256_gcm(), NULL, NULL, NULL)) {
        printf("EVP_EncryptInit_ex error!\n");
        free(ciphertext);
        *cipherret = NULL;
        return -1;
    }

    /* Set IV length if default 12 bytes (96 bits) is not appropriate */
    if (1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, ivlen, NULL)) {
        printf("EVP_CIPHER_CTX_ctrl error!\n");
        free(ciphertext);
        *cipherret = NULL;
        return -1;
    }

    /* Initialise key and IV */
    if (1 != EVP_EncryptInit_ex(ctx, NULL, NULL, key, iv)) {
        printf("EVP_EncryptInit_ex error!\n");
        free(ciphertext);
        *cipherret = NULL;
        return -1;
    }

    /* Provide any AAD data. This can be called zero or more times as
     * required
     */
    if (1 != EVP_EncryptUpdate(ctx, NULL, &len, aad, aad_len)) {
        printf("EVP_EncryptUpdate error!\n");
        free(ciphertext);
        *cipherret = NULL;
        return -1;
    }

    /* Provide the message to be encrypted, and obtain the encrypted output.
     * EVP_EncryptUpdate can be called multiple times if necessary
     */
    if (1 != EVP_EncryptUpdate(ctx, ciphertext, &len, plaintext, plaintext_len)) {
        printf("EVP_EncryptUpdate error!\n");
        free(ciphertext);
        *cipherret = NULL;
        return -1;
    }
    ciphertext_len = len;

    /* Finalise the encryption. Normally ciphertext bytes may be written at
     * this stage, but this does not occur in GCM mode
     */
    if (1 != EVP_EncryptFinal_ex(ctx, ciphertext + len, &len)) {
        printf("EVP_EncryptFinal_ex error!\n");
        free(ciphertext);
        *cipherret = NULL;
        return -1;
    }
    ciphertext_len += len;

    /* Get the tag */
    if (1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_GET_TAG, 16, tag)) {
        printf("EVP_CIPHER_CTX_ctrl error!\n");
        free(ciphertext);
        *cipherret = NULL;
        return -1;
    }

    /* Clean up */
    EVP_CIPHER_CTX_free(ctx);

    return ciphertext_len;
}

int xtalkDecodeAES_gcm_im(unsigned char *ciphertext, int ciphertext_len, unsigned char *aad,
        int aad_len, unsigned char *tag, unsigned char *key, unsigned char *iv, int ivlen,
        unsigned char **plainret) {
    EVP_CIPHER_CTX *ctx;
    int len;
    unsigned char *plaintext;
    int plaintext_len;
    int ret;

    unsigned char initval_hex[16] = {0x23, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x33};

    if ((!iv) || ivlen <= 0) {
        iv = initval_hex;
        ivlen = 16;
    }

    *plainret = (unsigned char *) malloc(ciphertext_len);
    plaintext = *plainret;

    /* Create and initialise the context */
    if (!(ctx = EVP_CIPHER_CTX_new())) {
        printf("EVP_CIPHER_CTX_new error!\n");
        free(plaintext);
        *plainret = NULL;
        return -1;
    }

    /* Initialise the decryption operation. */
    if (!EVP_DecryptInit_ex(ctx, EVP_aes_256_gcm(), NULL, NULL, NULL)) {
        printf("EVP_DecryptInit_ex error!\n");
        free(plaintext);
        *plainret = NULL;
        return -1;
    }

    /* Set IV length. Not necessary if this is 12 bytes (96 bits) */
    if (!EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, ivlen, NULL)) {
        printf("EVP_CIPHER_CTX_ctrl error!\n");
        free(plaintext);
        *plainret = NULL;
        return -1;
    }

    /* Initialise key and IV */
    if (!EVP_DecryptInit_ex(ctx, NULL, NULL, key, iv)) {
        printf("EVP_DecryptInit_ex error!\n");
        free(plaintext);
        *plainret = NULL;
        return -1;
    }

    /* Provide any AAD data. This can be called zero or more times as
     * required
     */
    if (!EVP_DecryptUpdate(ctx, NULL, &len, aad, aad_len)) {
        printf("EVP_DecryptUpdate error!\n");
        free(plaintext);
        *plainret = NULL;
        return -1;
    }

    /* Provide the message to be decrypted, and obtain the plaintext output.
     * EVP_DecryptUpdate can be called multiple times if necessary
     */
    if (!EVP_DecryptUpdate(ctx, plaintext, &len, ciphertext, ciphertext_len)) {
        printf("EVP_DecryptUpdate error!\n");
        free(plaintext);
        *plainret = NULL;
        return -1;
    }
    plaintext_len = len;

    /* Set expected tag value. Works in OpenSSL 1.0.1d and later */
    if (!EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, 16, tag)) {
        printf("EVP_CIPHER_CTX_ctrl error!\n");
        free(plaintext);
        *plainret = NULL;
        return -1;
    }

    /* Finalise the decryption. A positive return value indicates success,
     * anything else is a failure - the plaintext is not trustworthy.
     */
    ret = EVP_DecryptFinal_ex(ctx, plaintext + len, &len);

    /* Clean up */
    EVP_CIPHER_CTX_free(ctx);

    if (ret > 0) {
        /* Success */
        plaintext_len += len;
        return plaintext_len;
    } else {
        /* Verify failed */
        printf("GCM Verify failed!\n");
        free(plaintext);
        *plainret = NULL;
        return -1;
    }
}

int xtalk_getRawECDHkey_im(char *privKey, char *pubKey, unsigned char *ecdh_key) {
    char rawPrivKey[256];
    GetRawPrivKey_im(rawPrivKey, privKey);
    return ecies_getRawECDHkey(rawPrivKey, pubKey, ecdh_key);    // return real length of raw ecdh_key;
}

int GetBtcPrivKeyFromRawPrivKey_im(char *privKey, char *rawprivKey) {
    std::vector<unsigned char> privKeyBin = ParseHex(rawprivKey);
    CBitcoinSecret btcSecret;
    CKey pkey;
    pkey.Set(privKeyBin.begin(), privKeyBin.end(), true);
    btcSecret.SetKey(pkey);
    sprintf(privKey, "%s", btcSecret.ToString().c_str());
    return 0;
}

std::string xtalkUsrPirvKeyEncrypt_im(unsigned char *usrID, unsigned char *privKey, char *pwd, int n, int ver) {
    //  below is the process of E1
    unsigned char h[64];
    unsigned char chk[2];
    unsigned char usrIDAandPrivKey[XTALK_USRID_LEN + XTALK_PRIVKEY_LEN];

    // user id 8bytes
    memcpy(usrIDAandPrivKey, usrID, XTALK_USRID_LEN);
    // privkey 32 bytes
    memcpy(usrIDAandPrivKey + XTALK_USRID_LEN, privKey, XTALK_PRIVKEY_LEN);

    xtalkSHA512(usrIDAandPrivKey, XTALK_USRID_LEN + XTALK_PRIVKEY_LEN, h);

    // copy first 2 bytes to chk
    memcpy(chk, h, 2);

    // below is the process of E2
    unsigned char salt[8];    // 8*8= 64 bits
    RAND_bytes(salt, 8);

    // below is the process of E3
    unsigned char key[256 / 8];
    xtalkPBKDF2_HMAC_SHA512_im((unsigned char *) pwd, strlen(pwd), salt, 64, key, 256, n);

    // below is the process of E4
    unsigned char chkUsrIDPrivKey[2 + XTALK_USRID_LEN + XTALK_PRIVKEY_LEN];    // 2+36+32 = 70
    memcpy(chkUsrIDPrivKey, chk, 2);
    memcpy(chkUsrIDPrivKey + 2, usrID, XTALK_USRID_LEN);
    memcpy(chkUsrIDPrivKey + 2 + XTALK_USRID_LEN, privKey, XTALK_PRIVKEY_LEN);

    AES_KEY aes_key;
    if (AES_set_encrypt_key((const unsigned char *) key, sizeof(key) * 8, &aes_key) < 0) {
        assert(false);
        return "error";
    }

    unsigned char *secret;
    unsigned char *data_tmp;
    unsigned int ret_len = sizeof(chkUsrIDPrivKey);    // use input data len to get the secret len
    if (sizeof(chkUsrIDPrivKey) % AES_BLOCK_SIZE > 0) {
        ret_len += AES_BLOCK_SIZE - (sizeof(chkUsrIDPrivKey) % AES_BLOCK_SIZE);
    }
    data_tmp = (unsigned char *) malloc(ret_len);
    secret = (unsigned char *) malloc(ret_len);
    memset(data_tmp, 0x00, ret_len);
    memcpy(data_tmp, chkUsrIDPrivKey, sizeof(chkUsrIDPrivKey));    // prepare data for encrypt

    for (unsigned int i = 0; i < ret_len / AES_BLOCK_SIZE; i++) {
        unsigned char out[AES_BLOCK_SIZE];
        memset(out, 0, AES_BLOCK_SIZE);
        AES_encrypt((const unsigned char *) (&data_tmp[i * AES_BLOCK_SIZE]), out, &aes_key);
        memcpy(&secret[i * AES_BLOCK_SIZE], out, AES_BLOCK_SIZE);
    }
    free(data_tmp);
    // data stored in secret, length is ret_len

    // below is the process of E5
    unsigned char *result;
    result = (unsigned char *) malloc(1 + 8 + ret_len);    // 1 byte version + 8 bytes salt + secret

    // set v value;
    result[0] = (ver << 5) + n;
    memcpy(result + 1, salt, 8);
    memcpy(result + 9, secret, ret_len);
    free(secret);    // do not forget to free it.

    // finally, we return the hex string. easiler for debug and show
    std::string retStr = HexStr(&result[0], &result[1 + 8 + ret_len], false);
    free(result);

    return retStr;
}

int xtalkUsrPirvKeyDecrypt_im(char *encryptedString, char *pwd, int ver, unsigned char *usrID, unsigned char *privKey) {
    std::vector<unsigned char> encryptedData = ParseHex(encryptedString);
    // below is the process of D1
    unsigned char v[1];
    v[0] = encryptedData[0];

    int version = (v[0] >> 5) & 0x7;    // only get the high 3 bits' value
    if (version != ver)
        return -1; // version error

    // below is the process of D2
    int n = v[0] & 0x1f;    // only get the low 5 bits' value

    // below is the process of D3
    unsigned char salt[8];
    unsigned char *secret;
    int secretLen = encryptedData.size() - 1 - 8;  // decrease one byte v and 8 bytes salt
    secret = (unsigned char *) malloc(secretLen);
    memcpy(salt, &encryptedData[1], 8);
    memcpy(secret, &encryptedData[9], secretLen);

    // below is the process of D4
    unsigned char key[256 / 8];
    xtalkPBKDF2_HMAC_SHA512_im((unsigned char *) pwd, strlen(pwd), salt, 64, key, 256, n);

    // below is the process of D5
    unsigned char *secret_decrypted;
    secret_decrypted = (unsigned char *) malloc(secretLen);

    AES_KEY aes_key;
    if (AES_set_decrypt_key(key, sizeof(key) * 8, &aes_key) < 0) {
        assert(false);
        return -1;
    }

    for (unsigned int i = 0; i < secretLen / AES_BLOCK_SIZE; i++) {
        unsigned char out[AES_BLOCK_SIZE];
        ::memset(out, 0, AES_BLOCK_SIZE);
        AES_decrypt(&secret[AES_BLOCK_SIZE * i], out, &aes_key);
        memcpy(&secret_decrypted[AES_BLOCK_SIZE * i], out, AES_BLOCK_SIZE);
    }
    free(secret);

    unsigned char chk[2];
    memcpy(chk, secret_decrypted, 2);
    memcpy(usrID, secret_decrypted + 2, XTALK_USRID_LEN);
    memcpy(privKey, secret_decrypted + 2 + XTALK_USRID_LEN, XTALK_PRIVKEY_LEN);
    free(secret_decrypted);

    // below is the process of D6
    unsigned char h[64];
    unsigned char usrIDAandPrivKey[XTALK_USRID_LEN + XTALK_PRIVKEY_LEN];

    // user id 36bytes
    memcpy(usrIDAandPrivKey, usrID, XTALK_USRID_LEN);
    // privkey 32 bytes
    memcpy(usrIDAandPrivKey + XTALK_USRID_LEN, privKey, XTALK_PRIVKEY_LEN);

    xtalkSHA512(usrIDAandPrivKey, XTALK_USRID_LEN + XTALK_PRIVKEY_LEN, h);

    if (memcmp(chk, h, 2) != 0)
        return 0;

    return 1;
}

// use hex string to input userID and privKey
std::string xtalkUsrPirvKeyEncrypt_im_String(char *usrID_BtcAddress, char *privKey_HexString, char *pwd, int n, int ver) {
    unsigned char usrID[XTALK_USRID_LEN];
    std::vector<unsigned char> privKey = ParseHex(privKey_HexString);

    if (strlen(usrID_BtcAddress) >= XTALK_USRID_LEN || privKey.size() != XTALK_PRIVKEY_LEN)
        return "error userID or privKey length";

    memset(usrID, '\0', XTALK_USRID_LEN);
    strcpy((char *) usrID, usrID_BtcAddress);

    return xtalkUsrPirvKeyEncrypt_im(usrID, &privKey[0], pwd, n, ver);
}

int xtalkUsrPirvKeyDecrypt_im_String(char *encryptedString, char *pwd, int ver, char *usrID_BtcAddress, char *privKey_HexString) {
    unsigned char usrID[XTALK_USRID_LEN];
    unsigned char privKey[XTALK_PRIVKEY_LEN];
    int ret;

    memset(usrID, '\0', XTALK_USRID_LEN);
    ret = xtalkUsrPirvKeyDecrypt_im(encryptedString, pwd, ver, usrID, privKey);

    strcpy(usrID_BtcAddress, (char *) usrID);
    std::string hexString = HexStr(&privKey[0], &privKey[32], false);
    strcpy(privKey_HexString, hexString.c_str());

    return ret;
}

using namespace std;
using namespace boost;
using namespace boost::assign;
using namespace json_spirit;


// API DEFINED ///////////
int CreateNewPrivKey_im(char *privKey) {
    CKey key;
    key.MakeNewKey(true); // set rand bytes. we need add our own MakeNewKey(true, randombytes_data), we need use our own RAND_bytes func to get random bytes.
    CBitcoinSecret btcSecret(key);
    //        sprintf(privKey,"%s",btcSecret.begin());
    sprintf(privKey, "%s", btcSecret.ToString().c_str());

    return 0;
}

/*
 std::string str1 = "Hello Lily!";
 std::vector<unsigned char> v(str1.begin(), str1.end());
 std::string str2( v.begin(), v.end() );
 */

int GetPubKeyFromPrivKey_im(char *privKey, char *pubKey) {
    string privStr(privKey);
    CBitcoinSecret btcSecret;
    if (!btcSecret.SetString(privStr)) {
        printf("Error : btcSecret.SetString (privStr)...\n");
        return 1;
    }
    CPubKey pubkey = btcSecret.GetKey().GetPubKey();
    std::vector<unsigned char> vch(pubkey.begin(), pubkey.end());
    std::string pubkeyStr = HexStr(vch);

    sprintf(pubKey, "%s", pubkeyStr.c_str());

    return 0;
}

int GetBTCAddrFromPubKey_im(char *pubKey, char *address) {
    std::string pubkeyStr = pubKey;
    CPubKey pubkey(ParseHex(pubkeyStr));
    CBitcoinAddress btcAddr(pubkey.GetID());
    sprintf(address, "%s", btcAddr.ToString().c_str());

    return 0;
}

//check address  -1: invalid address  0: valid address
int CheckAddress_im(char *addr) {
    CBitcoinAddress address(addr);
    if (!address.IsValid()) {
        return -1;
    }

    return 0;
}


//check privkey  -1: invalid privkey  0: valid privkey
int CheckPrivKey_im(char *privKey) {
    string privStr(privKey);
    CBitcoinSecret btcSecret;
    if (!btcSecret.SetString(privStr)) {
        printf("Error : btcSecret.SetString (privStr)...\n");
        return -1;
    }
    if (btcSecret.IsValid())
        return 0;

    return -1;
}


// add
int GetPrivKeyFromSeedBIP44_im(const char *SeedStr, char *PrivKey, unsigned int purpose, unsigned int coin, unsigned int account, unsigned int isInternal, unsigned int addrIndex) {
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
    sprintf(PrivKey, "%s", btcSecret.ToString().c_str());

    return 0;
}


int SignHash_im(char *privKey, char *hashHexStr, char *signStr) {
    CBitcoinSecret btcSecret;
    if (!btcSecret.SetString(privKey)) {
        printf("Error : btcSecret.SetString (privStr)...\n");
        return 1;
    }
    CKey key = btcSecret.GetKey();
    uint256 hashMsg;
    hashMsg.SetHex(hashHexStr);

    // normal signatures
    vector<unsigned char> sign;
    if (!key.Sign(hashMsg, sign)) {
        printf("Error : key1.Sign (hashMsg, sign1)\n");
        return 2;
    }

    string signstring = HexStr(sign.begin(), sign.end());
    sprintf(signStr, "%s", signstring.c_str());
    return 0;
}

int VerifySign_im(char *pubKey, char *hashHexStr, char *signStr) {
    uint256 hashMsg;
    hashMsg.SetHex(hashHexStr);
    std::vector<unsigned char> sign = ParseHex(signStr);
    std::string pubkeyStr = pubKey;
    CPubKey pubkey(ParseHex(pubkeyStr));

    if (!pubkey.Verify(hashMsg, sign)) {
        printf("Error : pubkey1.Verify(hashMsg, sign1C)\n");
        return 0;
    }
    return 1;
}


int GetRawPrivKey_im(char *rawPrivKey, char *privKey) {
    string privStr(privKey);
    CBitcoinSecret btcSecret;
    if (!btcSecret.SetString(privStr)) {
        printf("Error : btcSecret.SetString (privStr)...\n");
        return 1;
    }
    CKey pkey = btcSecret.GetKey();
    std::vector<unsigned char> vch(pkey.begin(), pkey.end());
    std::string pkeyStr = HexStr(vch);

    sprintf(rawPrivKey, "%s", pkeyStr.c_str());
    //    printf("rawPrivKey is :%s\n",rawPrivKey);
    return 0;
}

#pragma mark -pbkdf2_hmac_sha512

void xtalkPBKDF2_HMAC_SHA512_im(unsigned char *pass, int passLen, unsigned char *salt, int saltLen, uint8_t *key, int keyLen, int n) {
    // calc iteration count 2^n
    uint32_t iter = 1 << n;
    PKCS5_PBKDF2_HMAC((const char *) pass, passLen, salt, saltLen / 8, iter, EVP_sha512(), keyLen / 8, key);
}

@end
