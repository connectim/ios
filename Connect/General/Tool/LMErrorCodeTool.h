//
//  LMErrorCodeTool.h
//  Connect
//
//  Created by bitmain on 2017/1/6.
//  Copyright © 2017年 Connect. All rights reserved.
//



typedef NS_ENUM(NSUInteger,ToastErrorType)
{
  ToastErrorTypeLoginOrReg      = 1 << 1,
  ToastErrorTypeContact         = 1 << 2,
  ToastErrorTypeWallet          = 1 << 3,
  ToastErrorTypeSet             = 1 << 4,
};
typedef NS_ENUM(NSInteger,ErrorCodeType)
{
    ErrorCodeType1001    =  -1001,
    ErrorCodeType2001    =  2001,
    ErrorCodeType2002    =  2002,
    ErrorCodeType2003    =  2003,
    ErrorCodeType2010    =  2010,
    ErrorCodeType2011    =  2011,
    ErrorCodeType2012    =  2012,
    ErrorCodeType2013    =  2013,
    ErrorCodeType2014    =  2014,
    ErrorCodeType2015    =  2015,
    ErrorCodeType2016    =  2016,
    ErrorCodeType2100    =  2100,
    ErrorCodeType2101    =  2101,
    ErrorCodeType2102    =  2102,
    ErrorCodeType2400    =  2400,
    ErrorCodeType2401    =  2401,
    ErrorCodeType2402    =  2402,
    ErrorCodeType2403    =  2403,
    ErrorCodeType2404    =  2404,
    ErrorCodeType2405    =  2405,
    ErrorCodeType2406    =  2406,
    ErrorCodeType2410    =  2410,
    ErrorCodeType2411    =  2411,
    ErrorCodeType2412    =  2412,
    ErrorCodeType2413    =  2413,
    ErrorCodeType2414    =  2414,
    ErrorCodeType2415    =  2415,
    ErrorCodeType2420    =  2420,
    ErrorCodeType2500    =  2500,
    ErrorCodeType2501    =  2501,
    ErrorCodeType2502    =  2502,
    ErrorCodeType2460    =  2460,
    ErrorCodeType2461    =  2461,
    ErrorCodeType2462    =  2462,
    ErrorCodeType2616    =  2616,
    ErrorCodeType2618    =  2618,
    ErrorCodeType2664    =  2664,
    ErrorCodeType2665    =  2665,
    ErrorCodeType2666    =  2666
    
};
#import <Foundation/Foundation.h>
@interface LMErrorCodeTool : NSObject

/**

 Returns the error message to be displayed according to the large type and error code
 
*/
+(NSString*)showToastErrorType:(ToastErrorType)toastErrorType withErrorCode:(ErrorCodeType)errorCodeType withUrl:(NSString*)url;

@end






