//
//  CommonGetPostTool.m
//  Connect
//
//  Created by MoHuilin on 16/6/1.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "CommonGetPostTool.h"
#import "KeyHandle.h"
#import "NSString+DictionaryValue.h"
#import "NSDictionary+JSONString.h"
#import "ConnectTool.h"
#import "AppDelegate.h"

@implementation CommonGetPostTool

+ (AccountInfo *)getLoginAccountInfo{
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    AccountInfo *currentUser = app.currentUser;
    return currentUser;
}

+ (NSDictionary *)signWithDecodeDataDict:(NSDictionary *)dataDict{
    
    NSString *jsonDatastr = [dataDict mj_JSONString];
    // Symmetric key
    NSString *password = [KeyHandle getECDHkeyUsePrivkey:[[LKUserCenter shareCenter] currentLoginUser].prikey PublicKey:[[ServerCenter shareCenter] getCurrentServer].data.pub_key];
    NSString *aad = @"de211d0cd1054a4ce0a34959b056fb11";
    NSString *iv = @"b5826fe574a0574bc4ac9be636830770";
    // Encrypt the string
    NSDictionary *encryptionDict = [AesGCMTool AES_GCMEncodeWithPass:password data:jsonDatastr iv:iv aad:aad];
    NSString *encryptionjsonString = [encryptionDict mj_JSONString];
    encryptionjsonString = [encryptionjsonString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    encryptionjsonString = [encryptionjsonString stringByReplacingOccurrencesOfString:@" " withString:@""];
    //sign 
    NSString *sign = [ConnectTool signWithData:encryptionjsonString];;
    
    NSDictionary *bodyDict = @{@"sign":sign,
                               @"pub_key":[[LKUserCenter shareCenter] currentLoginUser].pub_key,
                               @"data":encryptionDict};

    
    return bodyDict;
}

+ (NSDictionary *)getRequestBodyDictWithDataDict:(NSDictionary *)dataDict{
    NSDictionary *encryptionDict = [CommonGetPostTool signWithDecodeDataDict:dataDict];
    
    NSString *encryptionjsonString = [encryptionDict mj_JSONString];
    encryptionjsonString = [encryptionjsonString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    encryptionjsonString = [encryptionjsonString stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *sign = [ConnectTool signWithData:encryptionjsonString];;
    NSDictionary *bodyDict = @{@"sign":sign,
                               @"pub_key":[[LKUserCenter shareCenter] currentLoginUser].pub_key,
                               @"data":encryptionDict};
    
    return bodyDict;
}


+ (NSString *)getSignPubkeyAndTimestampWithAPI:(NSString *)apiUrl
{
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    NSString *timestampStr = [NSString stringWithFormat:@"%.0f",timeStamp];
    
    NSString *sign = [ConnectTool signWithData:timestampStr];
    
    NSString *url = [NSString stringWithFormat:@"%@?sign=%@&pub_key=%@&timestamp=%@",apiUrl,sign,[[LKUserCenter shareCenter] currentLoginUser].pub_key,timestampStr];
    return url;
}

@end
