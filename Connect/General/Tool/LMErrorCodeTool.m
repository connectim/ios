//
//  LMErrorCodeTool.m
//  Connect
//
//  Created by bitmain on 2017/1/6.
//  Copyright © 2017年 Connect. All rights reserved.
//


#import "LMErrorCodeTool.h"

#define UnKnownError  @"Link Unknown error"

#define NO_TRANSATION_HISTORY_1001        LMLocalizedString(@"Set No transaction history", nil)
#define SALT_UNAVAILABLE_2001             LMLocalizedString(@"ErrorCode salt failure or gcm decryption failed", nil)
#define ECDH_CREAT_FAILURE_2002           LMLocalizedString(@"ErrorCode Ecdh generation failed", nil)
#define GCM_GENERATION_FAIL_2003          LMLocalizedString(@"ErrorCode Gcm generation failed", nil)
#define BROAD_FAILED_2010                 LMLocalizedString(@"ErrorCode he broadcast failed", nil)
#define PUBLIC_DECODE_ERROR_2011          LMLocalizedString(@"ErrorCode publish hex decode error", nil)
#define DECODE_TRANS_ERROR_2012           LMLocalizedString(@"ErrorCode DecodeRawTransaction error", nil)
#define MSG_TX_ERROR_2013                 LMLocalizedString(@"ErrorCode msgTx convert error", nil)
#define DUST_2014                         LMLocalizedString(@"ErrorCode dust", nil)
#define TXN_CONFLICT_2015                 LMLocalizedString(@"ErrorCode xn mempool conflict", nil)
#define DOUBLE_FLOWER_2016                LMLocalizedString(@"ErrorCode Double flowers", nil)
#define USERNAME_ERROR_2100               LMLocalizedString(@"Login UserName Error", nil)
#define USERAVATAR_ILLEGAL_2101           LMLocalizedString(@"Login User avatar is illegal", nil)
#define USERNAME_EXISTS_2102              LMLocalizedString(@"Login username already exists", nil)
#define REQUEST_ERROR_2400                LMLocalizedString(@"ErrorCode Request Error", nil)
#define SIGN_ERROR_2401                   LMLocalizedString(@"ErrorCode Signature error", nil)
#define RESOURCE_AlREADY_2402             LMLocalizedString(@"ErrorCode The resource already exists", nil)
#define RESOURCE_VAIL_FAILED_2403         LMLocalizedString(@"ErrorCode Resource rule validation failed", nil)
#define RESOURCE_Not_Exists_2404          LMLocalizedString(@"ErrorCode The resource is not exist", nil)
#define TIMES_NOT_RANGE_2405              LMLocalizedString(@"ErrorCode timestamp not in the specified range", nil)
#define RESOURCE_EXPIRED_2406             LMLocalizedString(@"ErrorCode The resource has expired", nil)
#define FORMAT_INVAILED_2410              LMLocalizedString(@"ErrorCode The format is invalid", nil)
#define NUMBER_WRONG_2411                 LMLocalizedString(@"ErrorCode Phone number is incorrect", nil)
#define TOKEN_NOT_MATCH_2412              LMLocalizedString(@"ErrorCode Token does not match", nil)
#define BACKUP_INCOMPLETE_2413            LMLocalizedString(@"ErrorCode backup key password hint incomplete", nil)
#define PHONE_EXISTS_2414                 LMLocalizedString(@"ErrorCode The phone number already exists", nil)
#define CREATE_ERROR_2415                 LMLocalizedString(@"ErrorCode Create error", nil)
#define PUBLICKEY_NOTMATCH_2420           LMLocalizedString(@"ErrorCode The public key does not match", nil)
#define SERVICE_ERROR_2500                LMLocalizedString(@"Network Server error", nil)
#define NOT_PROBUF_DATA_2501              LMLocalizedString(@"ErrorCode Not ProtoBuffer data", nil)
#define NOT_JSON_DATA_2502                LMLocalizedString(@"ErrorCode Not json data", nil)
#define ERROR_UPLOADING_AVATAR_2460       LMLocalizedString(@"ErrorCode Error uploading avatar", nil)
#define DATA_TOO_LARGE_2461               LMLocalizedString(@"ErrorCode Data is too large", nil)
#define DATA_ERROR_2462                   LMLocalizedString(@"ErrorCode data error", nil)
#define TRANSSATION_ERROR_2616            LMLocalizedString(@"ErrorCode Transaction information is incorrect", nil)
#define VERSION_REPEAT_2618               LMLocalizedString(@"ErrorCode Version information is repeated", nil)
#define DUST_MESSAGE_2664                 LMLocalizedString(@"ErrorCode dust", nil)
#define DUST_MESSAGE_2665                 LMLocalizedString(@"ErrorCode dust", nil)
#define FEE_LOW_2666                      LMLocalizedString(@"ErrorCode The fee is too low", nil)

@implementation LMErrorCodeTool

+(NSString*)showToastErrorType:(ToastErrorType)toastErrorType withErrorCode:(ErrorCodeType)errorCodeType withUrl:(NSString*)url
{
   
    switch (toastErrorType) {
        case ToastErrorTypeLoginOrReg:    //Registered login type
        {
            return [self showLoginOrRegErrorStringWithCode:errorCodeType withUrl:url];
        
        }
            break;
        case ToastErrorTypeContact: //Contact type
        {
            
            return [self showContactErrorStringWithCode:errorCodeType withUrl:url];
        }
            break;
        case ToastErrorTypeWallet:  //Wallet type
        {
            return [self showWalletErrorStringWithCode:errorCodeType withUrl:url];
            
        }
            break;
        case ToastErrorTypeSet:     //Set the type
        {
            
            return [self showSetErrorStringWithCode:errorCodeType withUrl:url];
        }
            break;
        default:
            break;
    }
    return LMLocalizedString(UnKnownError, nil);
}
#pragma mark  -  Registered login type error message display
+(NSString*)showLoginOrRegErrorStringWithCode:(ErrorCodeType)errorCodeType withUrl:(NSString*)url
{
    switch (errorCodeType) {
        case ErrorCodeType2001:
        {
            return SALT_UNAVAILABLE_2001;
        
        }
            break;
        case ErrorCodeType2002:
        {
            return ECDH_CREAT_FAILURE_2002;
            
        }
            break;
        case ErrorCodeType2003:
        {
            return GCM_GENERATION_FAIL_2003;
            
        }
            break;
        case ErrorCodeType2010:
        {
            return BROAD_FAILED_2010;
            
        }
            break;
        case ErrorCodeType2011:
        {
            return PUBLIC_DECODE_ERROR_2011;
            
        }
            break;
        case ErrorCodeType2012:
        {
            return DECODE_TRANS_ERROR_2012;
            
        }
            break;
        case ErrorCodeType2013:
        {
            return MSG_TX_ERROR_2013;
            
        }
            break;
        case ErrorCodeType2014:
        {
            return DUST_2014;
            
        }
            break;
        case ErrorCodeType2015:
        {
            return TXN_CONFLICT_2015;
            
        }
            break;
        case ErrorCodeType2016:
        {
            return DOUBLE_FLOWER_2016;
            
        }
            break;
        case ErrorCodeType2100:
        {
            if ([url isEqualToString:LoginSignUpUrl]) {
               return USERNAME_ERROR_2100;
            }
        }
            break;
        case ErrorCodeType2101:
        {
            if ([url isEqualToString:LoginSignUpUrl]) {
                return USERAVATAR_ILLEGAL_2101;
            }
            
        }
            break;
        case ErrorCodeType2102:
        {
            if ([url isEqualToString:LoginSignUpUrl]) {
                return USERNAME_EXISTS_2102;
            }
        }
            break;
        case ErrorCodeType2400:
        {
            return REQUEST_ERROR_2400;
            
        }
            break;
        case ErrorCodeType2401:
        {
            
              return SIGN_ERROR_2401;
        }
            break;
        case ErrorCodeType2402:
        {
            
              return RESOURCE_AlREADY_2402;
        }
            break;
        case ErrorCodeType2403:
        {
            
              return RESOURCE_VAIL_FAILED_2403;
        }
        case ErrorCodeType2404:
        {
              return RESOURCE_Not_Exists_2404;
            
        }
            break;
        case ErrorCodeType2405:
        {
              return TIMES_NOT_RANGE_2405;
            
        }
            break;
        case ErrorCodeType2406:
        {
            
              return RESOURCE_EXPIRED_2406;
        }
        case ErrorCodeType2410:
        {
            
              return FORMAT_INVAILED_2410;
        }
            break;
        case ErrorCodeType2411:
        {
            
              return NUMBER_WRONG_2411;
        }
            break;
        case ErrorCodeType2412:
        {
            
              return TOKEN_NOT_MATCH_2412;
        }
        case ErrorCodeType2413:
        {
              return BACKUP_INCOMPLETE_2413;
            
        }
            break;
        case ErrorCodeType2414:
        {
            
              return PHONE_EXISTS_2414;
        }
            break;
        case ErrorCodeType2415:
        {
            
              return CREATE_ERROR_2415;
        }
        case ErrorCodeType2420:
        {
            
              return PUBLICKEY_NOTMATCH_2420;
        }
            break;
        case ErrorCodeType2500:
        {
            
              return SERVICE_ERROR_2500;
        }
            break;
        case ErrorCodeType2501:
        {
            
              return NOT_PROBUF_DATA_2501;
        }
            break;
        case ErrorCodeType2502:
        {
            
            return NOT_JSON_DATA_2502;
        }
            break;
        case ErrorCodeType2460:
        {
            
              return ERROR_UPLOADING_AVATAR_2460;
        }
            break;
        case ErrorCodeType2461:
        {
            
              return DATA_TOO_LARGE_2461;
        }
            break;
        case ErrorCodeType2462:
        {
              return DATA_ERROR_2462;
            
        }
            break;
        default:
            break;
    }
    
     return LMLocalizedString(UnKnownError, nil);
}
#pragma mark  -  Contact type error message display
+(NSString*)showContactErrorStringWithCode:(ErrorCodeType)errorCodeType withUrl:(NSString*)url
{
            
    switch (errorCodeType) {
        case ErrorCodeType2001:
        {
            return SALT_UNAVAILABLE_2001;
            
        }
            break;
        case ErrorCodeType2002:
        {
            return ECDH_CREAT_FAILURE_2002;
            
        }
            break;
        case ErrorCodeType2003:
        {
            return GCM_GENERATION_FAIL_2003;
            
        }
            break;
        case ErrorCodeType2010:
        {
            return BROAD_FAILED_2010;
            
        }
            break;
        case ErrorCodeType2011:
        {
            return PUBLIC_DECODE_ERROR_2011;
            
        }
            break;
        case ErrorCodeType2012:
        {
            return DECODE_TRANS_ERROR_2012;
            
        }
            break;
        case ErrorCodeType2013:
        {
            return MSG_TX_ERROR_2013;
            
        }
            break;
        case ErrorCodeType2014:
        {
            return DUST_2014;
            
        }
            break;
        case ErrorCodeType2015:
        {
            return TXN_CONFLICT_2015;
            
        }
            break;
        case ErrorCodeType2016:
        {
            return DOUBLE_FLOWER_2016;
            
        }
            break;
        case ErrorCodeType2100:
        {
            if ([url isEqualToString:LoginSignUpUrl]) {
                return USERNAME_ERROR_2100;
            }
        }
            break;
        case ErrorCodeType2101:
        {
            if ([url isEqualToString:LoginSignUpUrl]) {
                return USERAVATAR_ILLEGAL_2101;
            }
            
        }
            break;
        case ErrorCodeType2102:
        {
            if ([url isEqualToString:LoginSignUpUrl]) {
                return USERNAME_EXISTS_2102;
            }
        }
            break;
        case ErrorCodeType2400:
        {
            return REQUEST_ERROR_2400;
            
        }
            break;
        case ErrorCodeType2401:
        {
            
            return SIGN_ERROR_2401;
        }
            break;
        case ErrorCodeType2402:
        {
            
            return RESOURCE_AlREADY_2402;
        }
            break;
        case ErrorCodeType2403:
        {
            
            return RESOURCE_VAIL_FAILED_2403;
        }
        case ErrorCodeType2404:
        {
            return RESOURCE_Not_Exists_2404;
            
        }
            break;
        case ErrorCodeType2405:
        {
            return TIMES_NOT_RANGE_2405;
            
        }
            break;
        case ErrorCodeType2406:
        {
            
            return RESOURCE_EXPIRED_2406;
        }
        case ErrorCodeType2410:
        {
            
            return FORMAT_INVAILED_2410;
        }
            break;
        case ErrorCodeType2411:
        {
            
            return NUMBER_WRONG_2411;
        }
            break;
        case ErrorCodeType2412:
        {
            
            return TOKEN_NOT_MATCH_2412;
        }
        case ErrorCodeType2413:
        {
            return BACKUP_INCOMPLETE_2413;
            
        }
            break;
        case ErrorCodeType2414:
        {
            
            return PHONE_EXISTS_2414;
        }
            break;
        case ErrorCodeType2415:
        {
            
            return CREATE_ERROR_2415;
        }
        case ErrorCodeType2420:
        {
            
            return PUBLICKEY_NOTMATCH_2420;
        }
            break;
        case ErrorCodeType2500:
        {
            
            return SERVICE_ERROR_2500;
        }
            break;
        case ErrorCodeType2501:
        {
            
            return NOT_PROBUF_DATA_2501;
        }
            break;
        case ErrorCodeType2502:
        {
            
            return NOT_JSON_DATA_2502;
        }
            break;
        case ErrorCodeType2460:
        {
            
            return ERROR_UPLOADING_AVATAR_2460;
        }
            break;
        case ErrorCodeType2461:
        {
            
            return DATA_TOO_LARGE_2461;
        }
            break;
        case ErrorCodeType2462:
        {
            return DATA_ERROR_2462;
            
        }
            break;
        default:
            break;
    }
    
    return LMLocalizedString(UnKnownError, nil);

}

#pragma mark  -  Wallet type error message display
+(NSString*)showWalletErrorStringWithCode:(ErrorCodeType)errorCodeType withUrl:(NSString*)url
{
    
    switch (errorCodeType) {
        case ErrorCodeType1001:
        {
            return NO_TRANSATION_HISTORY_1001;
            
        }
            break;
        case ErrorCodeType2001:
        {
            return SALT_UNAVAILABLE_2001;
            
        }
            break;
        case ErrorCodeType2002:
        {
            return ECDH_CREAT_FAILURE_2002;
            
        }
            break;
        case ErrorCodeType2003:
        {
            return GCM_GENERATION_FAIL_2003;
            
        }
            break;
        case ErrorCodeType2010:
        {
            return BROAD_FAILED_2010;
            
        }
            break;
        case ErrorCodeType2011:
        {
            return PUBLIC_DECODE_ERROR_2011;
            
        }
            break;
        case ErrorCodeType2012:
        {
            return DECODE_TRANS_ERROR_2012;
            
        }
            break;
        case ErrorCodeType2013:
        {
            return MSG_TX_ERROR_2013;
            
        }
            break;
        case ErrorCodeType2014:
        {
            return DUST_2014;
            
        }
            break;
        case ErrorCodeType2015:
        {
            return TXN_CONFLICT_2015;
            
        }
            break;
        case ErrorCodeType2016:
        {
            return DOUBLE_FLOWER_2016;
            
        }
            break;
        case ErrorCodeType2100:
        {
            if ([url isEqualToString:LoginSignUpUrl]) {
                return USERNAME_ERROR_2100;
            }
        }
            break;
        case ErrorCodeType2101:
        {
            if ([url isEqualToString:LoginSignUpUrl]) {
                return USERAVATAR_ILLEGAL_2101;
            }
            
        }
            break;
        case ErrorCodeType2102:
        {
            if ([url isEqualToString:LoginSignUpUrl]) {
                return USERNAME_EXISTS_2102;
            }
        }
            break;
        case ErrorCodeType2400:
        {
            return REQUEST_ERROR_2400;
            
        }
            break;
        case ErrorCodeType2401:
        {
            
            return SIGN_ERROR_2401;
        }
            break;
        case ErrorCodeType2402:
        {
            
            return RESOURCE_AlREADY_2402;
        }
            break;
        case ErrorCodeType2403:
        {
            
            return RESOURCE_VAIL_FAILED_2403;
        }
        case ErrorCodeType2404:
        {
            return RESOURCE_Not_Exists_2404;
            
        }
            break;
        case ErrorCodeType2405:
        {
            return TIMES_NOT_RANGE_2405;
            
        }
            break;
        case ErrorCodeType2406:
        {
            
            return RESOURCE_EXPIRED_2406;
        }
        case ErrorCodeType2410:
        {
            
            return FORMAT_INVAILED_2410;
        }
            break;
        case ErrorCodeType2411:
        {
            
            return NUMBER_WRONG_2411;
        }
            break;
        case ErrorCodeType2412:
        {
            
            return TOKEN_NOT_MATCH_2412;
        }
        case ErrorCodeType2413:
        {
            return BACKUP_INCOMPLETE_2413;
            
        }
            break;
        case ErrorCodeType2414:
        {
            
            return PHONE_EXISTS_2414;
        }
            break;
        case ErrorCodeType2415:
        {
            
            return CREATE_ERROR_2415;
        }
        case ErrorCodeType2420:
        {
            
            return PUBLICKEY_NOTMATCH_2420;
        }
            break;
        case ErrorCodeType2500:
        {
            
            return SERVICE_ERROR_2500;
        }
            break;
        case ErrorCodeType2501:
        {
            
            return NOT_PROBUF_DATA_2501;
        }
            break;
        case ErrorCodeType2502:
        {
            
            return NOT_JSON_DATA_2502;
        }
            break;
        case ErrorCodeType2460:
        {
            
            return ERROR_UPLOADING_AVATAR_2460;
        }
            break;
        case ErrorCodeType2461:
        {
            
            return DATA_TOO_LARGE_2461;
        }
            break;
        case ErrorCodeType2462:
        {
            return DATA_ERROR_2462;
            
        }
            break;
        case ErrorCodeType2616:
        {
            return TRANSSATION_ERROR_2616;
            
        }
            break;
        case ErrorCodeType2618:
        {
            return VERSION_REPEAT_2618;
            
        }
            break;
        case ErrorCodeType2664:
        case ErrorCodeType2665:
        {
            return DUST_MESSAGE_2665;
            
        }
            break;
        case ErrorCodeType2666:
        {
            return FEE_LOW_2666;
            
        }
            break;
        default:
            break;
    }
    
    return LMLocalizedString(UnKnownError, nil);
}
#pragma mark  -  Set type error message display
+(NSString*)showSetErrorStringWithCode:(ErrorCodeType)errorCodeType withUrl:(NSString*)url
{
    switch (errorCodeType) {
        case ErrorCodeType2001:
        {
            return SALT_UNAVAILABLE_2001;
            
        }
            break;
        case ErrorCodeType2002:
        {
            return ECDH_CREAT_FAILURE_2002;
            
        }
            break;
        case ErrorCodeType2003:
        {
            return GCM_GENERATION_FAIL_2003;
            
        }
            break;
        case ErrorCodeType2010:
        {
            return BROAD_FAILED_2010;
            
        }
            break;
        case ErrorCodeType2011:
        {
            return PUBLIC_DECODE_ERROR_2011;
            
        }
            break;
        case ErrorCodeType2012:
        {
            return DECODE_TRANS_ERROR_2012;
            
        }
            break;
        case ErrorCodeType2013:
        {
            return MSG_TX_ERROR_2013;
            
        }
            break;
        case ErrorCodeType2014:
        {
            return DUST_2014;
            
        }
            break;
        case ErrorCodeType2015:
        {
            return TXN_CONFLICT_2015;
            
        }
            break;
        case ErrorCodeType2016:
        {
            return DOUBLE_FLOWER_2016;
            
        }
            break;
        case ErrorCodeType2100:
        {
            if ([url isEqualToString:LoginSignUpUrl]) {
                return USERNAME_ERROR_2100;
            }
        }
            break;
        case ErrorCodeType2101:
        {
            if ([url isEqualToString:LoginSignUpUrl]) {
                return USERAVATAR_ILLEGAL_2101;
            }
            
        }
            break;
        case ErrorCodeType2102:
        {
            if ([url isEqualToString:LoginSignUpUrl]) {
                return USERNAME_EXISTS_2102;
            }
        }
            break;
        case ErrorCodeType2400:
        {
            return REQUEST_ERROR_2400;
            
        }
            break;
        case ErrorCodeType2401:
        {
            
            return SIGN_ERROR_2401;
        }
            break;
        case ErrorCodeType2402:
        {
            
            return RESOURCE_AlREADY_2402;
        }
            break;
        case ErrorCodeType2403:
        {
            
            return RESOURCE_VAIL_FAILED_2403;
        }
        case ErrorCodeType2404:
        {
            return RESOURCE_Not_Exists_2404;
            
        }
            break;
        case ErrorCodeType2405:
        {
            return TIMES_NOT_RANGE_2405;
            
        }
            break;
        case ErrorCodeType2406:
        {
            
            return RESOURCE_EXPIRED_2406;
        }
        case ErrorCodeType2410:
        {
            
            return FORMAT_INVAILED_2410;
        }
            break;
        case ErrorCodeType2411:
        {
            
            return NUMBER_WRONG_2411;
        }
            break;
        case ErrorCodeType2412:
        {
            
            return TOKEN_NOT_MATCH_2412;
        }
        case ErrorCodeType2413:
        {
            return BACKUP_INCOMPLETE_2413;
            
        }
            break;
        case ErrorCodeType2414:
        {
            
            return PHONE_EXISTS_2414;
        }
            break;
        case ErrorCodeType2415:
        {
            
            return CREATE_ERROR_2415;
        }
        case ErrorCodeType2420:
        {
            
            return PUBLICKEY_NOTMATCH_2420;
        }
            break;
        case ErrorCodeType2500:
        {
            
            return SERVICE_ERROR_2500;
        }
            break;
        case ErrorCodeType2501:
        {
            
            return NOT_PROBUF_DATA_2501;
        }
            break;
        case ErrorCodeType2502:
        {
            
            return NOT_JSON_DATA_2502;
        }
            break;
        case ErrorCodeType2460:
        {
            
            return ERROR_UPLOADING_AVATAR_2460;
        }
            break;
        case ErrorCodeType2461:
        {
            
            return DATA_TOO_LARGE_2461;
        }
            break;
        case ErrorCodeType2462:
        {
            return DATA_ERROR_2462;
            
        }
            break;
        default:
            break;
    }
    
    return LMLocalizedString(UnKnownError, nil);
}
@end
