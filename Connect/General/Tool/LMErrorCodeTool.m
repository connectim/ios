//
//  LMErrorCodeTool.m
//  Connect
//
//  Created by bitmain on 2017/1/6.
//  Copyright © 2017年 Connect. All rights reserved.
//


#import "LMErrorCodeTool.h"

#define UnKnownError  @"Link Unknown error"

#define NoTransactionHistory1001        LMLocalizedString(@"Set No transaction history", nil)
#define SaltUnavailable2001             LMLocalizedString(@"ErrorCode salt failure or gcm decryption failed", nil)
#define EcdhCreatFail2002               LMLocalizedString(@"ErrorCode Ecdh generation failed", nil)
#define GcmGenerationFail2003           LMLocalizedString(@"ErrorCode Gcm generation failed", nil)
#define BroadcastFailed2010             LMLocalizedString(@"ErrorCode he broadcast failed", nil)
#define PublishDecodeError2011          LMLocalizedString(@"ErrorCode publish hex decode error", nil)
#define DecodeRawTransactionError2012   LMLocalizedString(@"ErrorCode DecodeRawTransaction error", nil)
#define MsgTxConvert2013                LMLocalizedString(@"ErrorCode msgTx convert error", nil)
#define Dust2014                        LMLocalizedString(@"ErrorCode dust", nil)
#define TxnMempoolConflict2015          LMLocalizedString(@"ErrorCode xn mempool conflict", nil)
#define DoubleFlowers2016               LMLocalizedString(@"ErrorCode Double flowers", nil)
#define UserNameError2100               LMLocalizedString(@"Login UserName Error", nil)
#define UserAvatarIllegal2101           LMLocalizedString(@"Login User avatar is illegal", nil)
#define UsernameExists2102              LMLocalizedString(@"Login username already exists", nil)
#define RequestError2400                LMLocalizedString(@"ErrorCode Request Error", nil)
#define SignatureError2401              LMLocalizedString(@"ErrorCode Signature error", nil)
#define resourceAlready2402             LMLocalizedString(@"ErrorCode The resource already exists", nil)
#define ResourceValidationFailed2403    LMLocalizedString(@"ErrorCode Resource rule validation failed", nil)
#define ResourceNotExist2404            LMLocalizedString(@"ErrorCode The resource is not exist", nil)
#define TimestampNotRange2405           LMLocalizedString(@"ErrorCode timestamp not in the specified range", nil)
#define RsourceExpired2406              LMLocalizedString(@"ErrorCode The resource has expired", nil)
#define FormatInvalid2410               LMLocalizedString(@"ErrorCode The format is invalid", nil)
#define NmuberWrong2411                 LMLocalizedString(@"ErrorCode Phone number is incorrect", nil)
#define TokenNotMatch2412               LMLocalizedString(@"ErrorCode Token does not match", nil)
#define BackupIncomplete2413            LMLocalizedString(@"ErrorCode backup key password hint incomplete", nil)
#define PhoneExists2414                 LMLocalizedString(@"ErrorCode The phone number already exists", nil)
#define CreateError2415                 LMLocalizedString(@"ErrorCode Create error", nil)
#define PublickeyNotMatch2420           LMLocalizedString(@"ErrorCode The public key does not match", nil)
#define ServiceError2500                LMLocalizedString(@"Network Server error", nil)
#define NotProtoBufferData2501          LMLocalizedString(@"ErrorCode Not ProtoBuffer data", nil)
#define NotJsonData2502                 LMLocalizedString(@"ErrorCode Not json data", nil)
#define ErrorUploadingAvatar2460        LMLocalizedString(@"ErrorCode Error uploading avatar", nil)
#define DataTooLarge2461                LMLocalizedString(@"ErrorCode Data is too large", nil)
#define DataError2462                   LMLocalizedString(@"ErrorCode data error", nil)

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
            return SaltUnavailable2001;
        
        }
            break;
        case ErrorCodeType2002:
        {
            return EcdhCreatFail2002;
            
        }
            break;
        case ErrorCodeType2003:
        {
            return GcmGenerationFail2003;
            
        }
            break;
        case ErrorCodeType2010:
        {
            return BroadcastFailed2010;
            
        }
            break;
        case ErrorCodeType2011:
        {
            return PublishDecodeError2011;
            
        }
            break;
        case ErrorCodeType2012:
        {
            return DecodeRawTransactionError2012;
            
        }
            break;
        case ErrorCodeType2013:
        {
            return MsgTxConvert2013;
            
        }
            break;
        case ErrorCodeType2014:
        {
            return Dust2014;
            
        }
            break;
        case ErrorCodeType2015:
        {
            return TxnMempoolConflict2015;
            
        }
            break;
        case ErrorCodeType2016:
        {
            return DoubleFlowers2016;
            
        }
            break;
        case ErrorCodeType2100:
        {
            if ([url isEqualToString:LoginSignUpUrl]) {
               return UserNameError2100;
            }
        }
            break;
        case ErrorCodeType2101:
        {
            if ([url isEqualToString:LoginSignUpUrl]) {
                return UserAvatarIllegal2101;
            }
            
        }
            break;
        case ErrorCodeType2102:
        {
            if ([url isEqualToString:LoginSignUpUrl]) {
                return UsernameExists2102;
            }
        }
            break;
        case ErrorCodeType2400:
        {
            return RequestError2400;
            
        }
            break;
        case ErrorCodeType2401:
        {
            
              return SignatureError2401;
        }
            break;
        case ErrorCodeType2402:
        {
            
              return resourceAlready2402;
        }
            break;
        case ErrorCodeType2403:
        {
            
              return ResourceValidationFailed2403;
        }
        case ErrorCodeType2404:
        {
              return ResourceNotExist2404;
            
        }
            break;
        case ErrorCodeType2405:
        {
              return TimestampNotRange2405;
            
        }
            break;
        case ErrorCodeType2406:
        {
            
              return RsourceExpired2406;
        }
        case ErrorCodeType2410:
        {
            
              return FormatInvalid2410;
        }
            break;
        case ErrorCodeType2411:
        {
            
              return NmuberWrong2411;
        }
            break;
        case ErrorCodeType2412:
        {
            
              return TokenNotMatch2412;
        }
        case ErrorCodeType2413:
        {
              return BackupIncomplete2413;
            
        }
            break;
        case ErrorCodeType2414:
        {
            
              return PhoneExists2414;
        }
            break;
        case ErrorCodeType2415:
        {
            
              return CreateError2415;
        }
        case ErrorCodeType2420:
        {
            
              return PublickeyNotMatch2420;
        }
            break;
        case ErrorCodeType2500:
        {
            
              return ServiceError2500;
        }
            break;
        case ErrorCodeType2501:
        {
            
              return NotProtoBufferData2501;
        }
            break;
        case ErrorCodeType2502:
        {
            
            return NotJsonData2502;
        }
            break;
        case ErrorCodeType2460:
        {
            
              return ErrorUploadingAvatar2460;
        }
            break;
        case ErrorCodeType2461:
        {
            
              return DataTooLarge2461;
        }
            break;
        case ErrorCodeType2462:
        {
              return DataError2462;
            
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
            return SaltUnavailable2001;
            
        }
            break;
        case ErrorCodeType2002:
        {
            return EcdhCreatFail2002;
            
        }
            break;
        case ErrorCodeType2003:
        {
            return GcmGenerationFail2003;
            
        }
            break;
        case ErrorCodeType2010:
        {
            return BroadcastFailed2010;
            
        }
            break;
        case ErrorCodeType2011:
        {
            return PublishDecodeError2011;
            
        }
            break;
        case ErrorCodeType2012:
        {
            return DecodeRawTransactionError2012;
            
        }
            break;
        case ErrorCodeType2013:
        {
            return MsgTxConvert2013;
            
        }
            break;
        case ErrorCodeType2014:
        {
            return Dust2014;
            
        }
            break;
        case ErrorCodeType2015:
        {
            return TxnMempoolConflict2015;
            
        }
            break;
        case ErrorCodeType2016:
        {
            return DoubleFlowers2016;
            
        }
            break;
        case ErrorCodeType2100:
        {
            if ([url isEqualToString:LoginSignUpUrl]) {
                return UserNameError2100;
            }
        }
            break;
        case ErrorCodeType2101:
        {
            if ([url isEqualToString:LoginSignUpUrl]) {
                return UserAvatarIllegal2101;
            }
            
        }
            break;
        case ErrorCodeType2102:
        {
            if ([url isEqualToString:LoginSignUpUrl]) {
                return UsernameExists2102;
            }
        }
            break;
        case ErrorCodeType2400:
        {
            return RequestError2400;
            
        }
            break;
        case ErrorCodeType2401:
        {
            
            return SignatureError2401;
        }
            break;
        case ErrorCodeType2402:
        {
            
            return resourceAlready2402;
        }
            break;
        case ErrorCodeType2403:
        {
            
            return ResourceValidationFailed2403;
        }
        case ErrorCodeType2404:
        {
            return ResourceNotExist2404;
            
        }
            break;
        case ErrorCodeType2405:
        {
            return TimestampNotRange2405;
            
        }
            break;
        case ErrorCodeType2406:
        {
            
            return RsourceExpired2406;
        }
        case ErrorCodeType2410:
        {
            
            return FormatInvalid2410;
        }
            break;
        case ErrorCodeType2411:
        {
            
            return NmuberWrong2411;
        }
            break;
        case ErrorCodeType2412:
        {
            
            return TokenNotMatch2412;
        }
        case ErrorCodeType2413:
        {
            return BackupIncomplete2413;
            
        }
            break;
        case ErrorCodeType2414:
        {
            
            return PhoneExists2414;
        }
            break;
        case ErrorCodeType2415:
        {
            
            return CreateError2415;
        }
        case ErrorCodeType2420:
        {
            
            return PublickeyNotMatch2420;
        }
            break;
        case ErrorCodeType2500:
        {
            
            return ServiceError2500;
        }
            break;
        case ErrorCodeType2501:
        {
            
            return NotProtoBufferData2501;
        }
            break;
        case ErrorCodeType2502:
        {
            
            return NotJsonData2502;
        }
            break;
        case ErrorCodeType2460:
        {
            
            return ErrorUploadingAvatar2460;
        }
            break;
        case ErrorCodeType2461:
        {
            
            return DataTooLarge2461;
        }
            break;
        case ErrorCodeType2462:
        {
            return DataError2462;
            
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
            return NoTransactionHistory1001;
            
        }
            break;
        case ErrorCodeType2001:
        {
            return SaltUnavailable2001;
            
        }
            break;
        case ErrorCodeType2002:
        {
            return EcdhCreatFail2002;
            
        }
            break;
        case ErrorCodeType2003:
        {
            return GcmGenerationFail2003;
            
        }
            break;
        case ErrorCodeType2010:
        {
            return BroadcastFailed2010;
            
        }
            break;
        case ErrorCodeType2011:
        {
            return PublishDecodeError2011;
            
        }
            break;
        case ErrorCodeType2012:
        {
            return DecodeRawTransactionError2012;
            
        }
            break;
        case ErrorCodeType2013:
        {
            return MsgTxConvert2013;
            
        }
            break;
        case ErrorCodeType2014:
        {
            return Dust2014;
            
        }
            break;
        case ErrorCodeType2015:
        {
            return TxnMempoolConflict2015;
            
        }
            break;
        case ErrorCodeType2016:
        {
            return DoubleFlowers2016;
            
        }
            break;
        case ErrorCodeType2100:
        {
            if ([url isEqualToString:LoginSignUpUrl]) {
                return UserNameError2100;
            }
        }
            break;
        case ErrorCodeType2101:
        {
            if ([url isEqualToString:LoginSignUpUrl]) {
                return UserAvatarIllegal2101;
            }
            
        }
            break;
        case ErrorCodeType2102:
        {
            if ([url isEqualToString:LoginSignUpUrl]) {
                return UsernameExists2102;
            }
        }
            break;
        case ErrorCodeType2400:
        {
            return RequestError2400;
            
        }
            break;
        case ErrorCodeType2401:
        {
            
            return SignatureError2401;
        }
            break;
        case ErrorCodeType2402:
        {
            
            return resourceAlready2402;
        }
            break;
        case ErrorCodeType2403:
        {
            
            return ResourceValidationFailed2403;
        }
        case ErrorCodeType2404:
        {
            return ResourceNotExist2404;
            
        }
            break;
        case ErrorCodeType2405:
        {
            return TimestampNotRange2405;
            
        }
            break;
        case ErrorCodeType2406:
        {
            
            return RsourceExpired2406;
        }
        case ErrorCodeType2410:
        {
            
            return FormatInvalid2410;
        }
            break;
        case ErrorCodeType2411:
        {
            
            return NmuberWrong2411;
        }
            break;
        case ErrorCodeType2412:
        {
            
            return TokenNotMatch2412;
        }
        case ErrorCodeType2413:
        {
            return BackupIncomplete2413;
            
        }
            break;
        case ErrorCodeType2414:
        {
            
            return PhoneExists2414;
        }
            break;
        case ErrorCodeType2415:
        {
            
            return CreateError2415;
        }
        case ErrorCodeType2420:
        {
            
            return PublickeyNotMatch2420;
        }
            break;
        case ErrorCodeType2500:
        {
            
            return ServiceError2500;
        }
            break;
        case ErrorCodeType2501:
        {
            
            return NotProtoBufferData2501;
        }
            break;
        case ErrorCodeType2502:
        {
            
            return NotJsonData2502;
        }
            break;
        case ErrorCodeType2460:
        {
            
            return ErrorUploadingAvatar2460;
        }
            break;
        case ErrorCodeType2461:
        {
            
            return DataTooLarge2461;
        }
            break;
        case ErrorCodeType2462:
        {
            return DataError2462;
            
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
            return SaltUnavailable2001;
            
        }
            break;
        case ErrorCodeType2002:
        {
            return EcdhCreatFail2002;
            
        }
            break;
        case ErrorCodeType2003:
        {
            return GcmGenerationFail2003;
            
        }
            break;
        case ErrorCodeType2010:
        {
            return BroadcastFailed2010;
            
        }
            break;
        case ErrorCodeType2011:
        {
            return PublishDecodeError2011;
            
        }
            break;
        case ErrorCodeType2012:
        {
            return DecodeRawTransactionError2012;
            
        }
            break;
        case ErrorCodeType2013:
        {
            return MsgTxConvert2013;
            
        }
            break;
        case ErrorCodeType2014:
        {
            return Dust2014;
            
        }
            break;
        case ErrorCodeType2015:
        {
            return TxnMempoolConflict2015;
            
        }
            break;
        case ErrorCodeType2016:
        {
            return DoubleFlowers2016;
            
        }
            break;
        case ErrorCodeType2100:
        {
            if ([url isEqualToString:LoginSignUpUrl]) {
                return UserNameError2100;
            }
        }
            break;
        case ErrorCodeType2101:
        {
            if ([url isEqualToString:LoginSignUpUrl]) {
                return UserAvatarIllegal2101;
            }
            
        }
            break;
        case ErrorCodeType2102:
        {
            if ([url isEqualToString:LoginSignUpUrl]) {
                return UsernameExists2102;
            }
        }
            break;
        case ErrorCodeType2400:
        {
            return RequestError2400;
            
        }
            break;
        case ErrorCodeType2401:
        {
            
            return SignatureError2401;
        }
            break;
        case ErrorCodeType2402:
        {
            
            return resourceAlready2402;
        }
            break;
        case ErrorCodeType2403:
        {
            
            return ResourceValidationFailed2403;
        }
        case ErrorCodeType2404:
        {
            return ResourceNotExist2404;
            
        }
            break;
        case ErrorCodeType2405:
        {
            return TimestampNotRange2405;
            
        }
            break;
        case ErrorCodeType2406:
        {
            
            return RsourceExpired2406;
        }
        case ErrorCodeType2410:
        {
            
            return FormatInvalid2410;
        }
            break;
        case ErrorCodeType2411:
        {
            
            return NmuberWrong2411;
        }
            break;
        case ErrorCodeType2412:
        {
            
            return TokenNotMatch2412;
        }
        case ErrorCodeType2413:
        {
            return BackupIncomplete2413;
            
        }
            break;
        case ErrorCodeType2414:
        {
            
            return PhoneExists2414;
        }
            break;
        case ErrorCodeType2415:
        {
            
            return CreateError2415;
        }
        case ErrorCodeType2420:
        {
            
            return PublickeyNotMatch2420;
        }
            break;
        case ErrorCodeType2500:
        {
            
            return ServiceError2500;
        }
            break;
        case ErrorCodeType2501:
        {
            
            return NotProtoBufferData2501;
        }
            break;
        case ErrorCodeType2502:
        {
            
            return NotJsonData2502;
        }
            break;
        case ErrorCodeType2460:
        {
            
            return ErrorUploadingAvatar2460;
        }
            break;
        case ErrorCodeType2461:
        {
            
            return DataTooLarge2461;
        }
            break;
        case ErrorCodeType2462:
        {
            return DataError2462;
            
        }
            break;
        default:
            break;
    }
    
    return LMLocalizedString(UnKnownError, nil);
}
@end
