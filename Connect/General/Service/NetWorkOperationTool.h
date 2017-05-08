//
//  NetWorkOperationTool.h
//  Connect
//
//  Created by MoHuilin on 16/7/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

/**
   * Request successful block
   *
   * @param responseObject The data returned by the server
 */
typedef void (^NetWorkOperationSuccess) (id response);

/**
   * Request failed Block
   *
   * @param responseObject error message
 */
typedef void (^NetWorkOperationFail) (NSError *error);

@interface NetWorkOperationTool : NSObject


+ (NSURLSessionUploadTask *)POSTWithUrlString:(NSString *)url postData:(NSData *)postData UploadProgressBlock:(void (^)(NSProgress *uploadProgress))uploadProgressBlock complete:(NetWorkOperationSuccess)success fail:(NetWorkOperationFail)fail;

/**
   * Requires signature and encryption request
   *
   * @param url request url
   * @param postData proto
   * @param success returns a successful callback
   * @param fail returns a failed callback
 */

+ (void)POSTWithUrlString:(NSString *)url postProtoData:(NSData *)postData complete:(NetWorkOperationSuccess)success fail:(NetWorkOperationFail)fail;


+ (void)POSTWithUrlString:(NSString *)url postProtoData:(NSData *)postData NotSignComplete:(NetWorkOperationSuccess)success fail:(NetWorkOperationFail)fail;

+ (void)POSTWithUrlString:(NSString *)url postProtoData:(NSData *)postData pirkey:(NSString *)privkey publickey:(NSString *)publickey complete:(NetWorkOperationSuccess)success fail:(NetWorkOperationFail)fail;

/**
   * There is no need to sign a request that does not require encryption
   *
   * @param url request url
   * @param postData proto
   * @param success returns a successful callback
   * @param fail returns a failed callback
 */

+ (void)POSTWithUrlString:(NSString *)url noSignProtoData:(NSData *)protoData complete:(NetWorkOperationSuccess)success fail:(NetWorkOperationFail)fail;

/**
   * Requires signature without encryption request
   *
   * @param url request url
   * @param postData raw binary
   * @param success returns a successful callback
   * @param fail returns a failed callback
 */
+ (void)POSTWithUrlString:(NSString *)url signNoEncryptPostData:(NSData *)postData complete:(NetWorkOperationSuccess)success fail:(NetWorkOperationFail)fail;

+ (void)POSTWithUrlString:(NSString *)url postNoStrutDataProtoData:(NSData *)postData complete:(NetWorkOperationSuccess)success fail:(NetWorkOperationFail)fail;


+ (void)GETWithUrlString:(NSString *)url complete:(NetWorkOperationSuccess)success fail:(NetWorkOperationFail)fail;


+ (void)POSTWithUrlString:(NSString *)url signNoEncryptPostData:(NSData *)postData withPrivkey:(NSString *)privkey Publickey:(NSString *)publickey complete:(NetWorkOperationSuccess)success fail:(NetWorkOperationFail)fail;

+ (void)POSTWithUrlString:(NSString *)url postData:(NSData *)postData NotSignComplete:(NetWorkOperationSuccess)success fail:(NetWorkOperationFail)fail;


/**
  * get salt
 */
+ (void)getSaltWithComplete:(void (^)(NSData *salt,NSError *error))complete forceUpdate:(BOOL)forceUpdate;
+ (void)checkSaltExpired;

@end
