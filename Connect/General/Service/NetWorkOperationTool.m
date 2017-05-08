//
//  NetWorkOperationTool.m
//  Connect
//
//  Created by MoHuilin on 16/7/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "NetWorkOperationTool.h"
#import "AppDelegate.h"
#import "NSString+Hash.h"
#import "KeyHandle.h"
#import "Protofile.pbobjc.h"
#import "NetWorkTool.h"
#import "SingleAFNetworkManager.h"
#import "ConnectTool.h"
#import "StringTool.h"
#import "Protofile.pbobjc.h"
#import "LMBaseSSDBManager.h"


@interface NetWorkOperationTool ()

@property (nonatomic ,copy) NetWorkOperationSuccess success;
@property (nonatomic ,copy) NetWorkOperationFail fail;

@end

@implementation NetWorkOperationTool

+ (AFHTTPSessionManager *)manager {
    return [[SingleAFNetworkManager sharedManager] sharedHTTPSession];
}

+ (void)GETWithUrlString:(NSString *)url complete:(NetWorkOperationSuccess)success fail:(NetWorkOperationFail)fail{
    [NetWorkTool cacheGetRequest:NO shoulCachePost:NO];
    [NetWorkTool getWithUrl:url refreshCache:YES params:nil progress:^(int64_t bytesRead, int64_t totalBytesRead) {
    } success:^(id response) {
        if (success) {
            if ([response isKindOfClass:[NSString class]]) {
                success(response);
            } else if([response isKindOfClass:[NSData class]]){
                NSError *error_ = nil;
                HttpNotSignResponse *hNoRes = [HttpNotSignResponse parseFromData:response error:&error_];
                if (error_) {
                    success(response);
                } else{
                    success(hNoRes);
                }
            }
        }
    } fail:^(NSError *error) {
        DDLogInfo(@"error :%@",error);
        if (fail) {
            fail(error);
        }
    }];
}


+ (void)POSTWithUrlString:(NSString *)url noSignProtoData:(NSData *)protoData complete:(NetWorkOperationSuccess)success fail:(NetWorkOperationFail)fail{
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    
    [request setHTTPBody:protoData];
    [request setHTTPMethod:@"POST"];
    
    //Clears the request that is currently executing
    NSArray *tasks = [[self manager] tasks];
    for (NSURLSessionTask *doingTask in tasks) {
        if ([doingTask.currentRequest.URL.absoluteString isEqualToString:url]) {
            [doingTask cancel];
        }
    }
    NSURLSessionUploadTask *task;
    task = [[self manager]
            uploadTaskWithStreamedRequest:request
            progress:^(NSProgress * _Nonnull uploadProgress) {
            }
            completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                if (error) {
                    DDLogInfo(@"error :%@",error);
                    if (fail) {
                        fail(error);
                    }
                } else{
                    if (success) {
                        success([HttpNotSignResponse parseFromData:responseObject error:nil]);
                    }
                }
            }];
    
    [task resume];
    
}


+ (NSURLSessionUploadTask *)POSTWithUrlString:(NSString *)url postData:(NSData *)postData UploadProgressBlock:(void (^)(NSProgress *uploadProgress))uploadProgressBlock complete:(NetWorkOperationSuccess)success fail:(NetWorkOperationFail)fail{
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    [request setHTTPBody:postData];
    [request setHTTPMethod:@"POST"];
    NSURLSessionUploadTask *task;
    task = [[[SingleAFNetworkManager sharedManager] sharedHTTPUploaderManager]
            uploadTaskWithStreamedRequest:request
            progress:uploadProgressBlock
            completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                NSData *data = (NSData *)responseObject;
                if ([data isKindOfClass:[NSData class]]) {
                    if (error || data.length <= 0) {
                        if (fail) {
                            fail(error);
                        }
                    } else{
                        if (success) {
                            HttpServerResponse *hResponse = [HttpServerResponse parseFromData:responseObject error:nil];
                            HttpResponse *hr = [[HttpResponse alloc] init];
                            hr.code = hResponse.code;
                            hr.message = hResponse.message;
                            hr.body = [IMResponse parseFromData:hResponse.body error:nil];
                            if (hr.code == 2001) {
                                [self getSaltWithComplete:^(NSData *salt, NSError *error1) {
                                    if (error1) {
                                        if (fail) {
                                            fail(error1);
                                        }
                                    } else{
                                        if (fail) {
                                            fail([NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
                                        }
                                    }
                                } forceUpdate:YES];
                                if (fail) {
                                    fail([NSError errorWithDomain:hr.message code:hr.code userInfo:nil]);
                                }
                            } else{
                                success(hr);
                            }
                        }
                    }

                } else if ([responseObject isKindOfClass:[NSString class]]){
                    success(responseObject);
                }
            }];
    
    [task resume];
    
    return task;
}


+ (void)POSTWithUrlString:(NSString *)url postData:(NSData *)postData complete:(NetWorkOperationSuccess)success fail:(NetWorkOperationFail)fail{
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    
    [request setHTTPBody:postData];
    [request setHTTPMethod:@"POST"];
    
    //Clears the request that is currently executing
    NSArray *tasks = [[self manager] tasks];
    for (NSURLSessionTask *doingTask in tasks) {
        if ([doingTask.currentRequest.URL.absoluteString isEqualToString:url]) {
            [doingTask cancel];
        }
    }
    NSURLSessionUploadTask *task;
    task = [[self manager]
                       uploadTaskWithStreamedRequest:request
                       progress:nil
                       completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                           if (error) {
                               DDLogInfo(@"error :%@",error);
                               if (fail) {
                                   fail(error);
                               }
                           } else{
                               HttpServerResponse *hResponse = [HttpServerResponse parseFromData:responseObject error:nil];
                               if (hResponse.code == 2001) { //Salt has expired
                                   [self getSaltWithComplete:^(NSData *salt, NSError *error1) {
                                       if (error1) {
                                           if (fail) {
                                               fail(error1);
                                           }
                                       } else{
                                           if (fail) {
                                               fail([NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
                                           }
                                       }
                                   } forceUpdate:YES];
                               } else{
                                   if (success) {
                                       HttpResponse *hr = [[HttpResponse alloc] init];
                                       hr.code = hResponse.code;
                                       hr.message = hResponse.message;
                                       hr.body = [IMResponse parseFromData:hResponse.body error:nil];
                                       success(hr);
                                   }
                               }
                           }
                       }];
    
    [task resume];

}

+ (void)POSTWithUrlString:(NSString *)url postData:(NSData *)postData NotSignComplete:(NetWorkOperationSuccess)success fail:(NetWorkOperationFail)fail{
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    
    [request setHTTPBody:postData];
    [request setHTTPMethod:@"POST"];
    
    
    NSURLSessionUploadTask *task;
    task = [[self manager]
            uploadTaskWithStreamedRequest:request
            progress:nil
            completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                if (error) {
                    DDLogInfo(@"error :%@",error);
                    if (fail) {
                        fail(error);
                    }
                } else{
                    if (success) {
                        [GCDQueue executeInMainQueue:^{
                            success([HttpNotSignResponse parseFromData:responseObject error:nil]);
                        }];
                    }
                }
            }];
    [task resume];
}


+ (void)POSTWithUrlString:(NSString *)url postData:(NSData *)postData complete:(NetWorkOperationSuccess)success fail:(NetWorkOperationFail)fail needSign:(BOOL)needSign neesDecode:(BOOL)decode{
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    
    [request setHTTPBody:postData];
    [request setHTTPMethod:@"POST"];
    
    
    NSURLSessionUploadTask *task;
    task = [[self manager]
            uploadTaskWithStreamedRequest:request
            progress:^(NSProgress * _Nonnull uploadProgress) {
            }
            completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                if (error) {
                    DDLogInfo(@"error :%@",error);
                    if (fail) {
                        fail(error);
                    }
                } else{
                    if (success) {
                        HttpServerResponse *hResponse = [HttpServerResponse parseFromData:responseObject error:nil];

                        HttpResponse *hr = [[HttpResponse alloc] init];
                        hr.code = hResponse.code;
                        hr.message = hResponse.message;
                        hr.body = [IMResponse parseFromData:hResponse.body error:nil];
                        success(hr);

                    }
                }
            }];
    
    [task resume];
    
}

+ (void)POSTWithUrlString:(NSString *)url postProtoData:(NSData *)postData pirkey:(NSString *)privkey publickey:(NSString *)publickey complete:(NetWorkOperationSuccess)success fail:(NetWorkOperationFail)fail{
    NSData *ecdhkey = [KeyHandle getECDHkeyWithPrivkey:privkey publicKey:[[ServerCenter shareCenter] getCurrentServer].data.pub_key];
    
    NSData *salt = salt = [ConnectTool get64ZeroData];
    ecdhkey = [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdhkey salt:salt];
    if (!postData) {
        postData = [ConnectTool get16_32RandData];
    }
    GcmData *gcmData = [ConnectTool createGcmDataWithEcdhkey:ecdhkey data:[ConnectTool createStructDataWithData:postData] aad:[ServerCenter shareCenter].defineAad];
    IMRequest *imRequest = [ConnectTool createRequestWithData:gcmData privkey:privkey publickKey:publickey];
    [self POSTWithUrlString:url postData:imRequest.data complete:success fail:fail];
}


+ (void)POSTWithUrlString:(NSString *)url postProtoData:(NSData *)postData NotSignComplete:(NetWorkOperationSuccess)success fail:(NetWorkOperationFail)fail{
    NSData *ecdhkey = [KeyHandle getECDHkeyWithPrivkey:[[LKUserCenter shareCenter] currentLoginUser].prikey publicKey:[[ServerCenter shareCenter] getCurrentServer].data.pub_key];
    ecdhkey = [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdhkey salt:[ServerCenter shareCenter].httpTokenSalt];
    if (!postData) {
        postData = [ConnectTool get16_32RandData];
    }
    IMRequest *imRequest = [ConnectTool createRequestWithEcdhKey:ecdhkey data:postData aad:[ServerCenter shareCenter].defineAad];
    [self POSTWithUrlString:url postData:imRequest.data NotSignComplete:success fail:fail];
}

+ (void)POSTWithUrlString:(NSString *)url postProtoData:(NSData *)postData complete:(NetWorkOperationSuccess)success fail:(NetWorkOperationFail)fail{

    NSData *ecdhkey = [KeyHandle getECDHkeyWithPrivkey:[[LKUserCenter shareCenter] currentLoginUser].prikey publicKey:[[ServerCenter shareCenter] getCurrentServer].data.pub_key];
    ecdhkey = [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdhkey salt:[ServerCenter shareCenter].httpTokenSalt];
    
    if (!postData) {
        postData = [ConnectTool get16_32RandData];
    }
    IMRequest *imRequest = [ConnectTool createRequestWithEcdhKey:ecdhkey data:postData aad:[ServerCenter shareCenter].defineAad];
    
    [self POSTWithUrlString:url postData:imRequest.data complete:success fail:fail];
}

+ (void)POSTWithUrlString:(NSString *)url postNoStrutDataProtoData:(NSData *)postData complete:(NetWorkOperationSuccess)success fail:(NetWorkOperationFail)fail{
    
    NSData *ecdhkey = [KeyHandle getECDHkeyWithPrivkey:[[LKUserCenter shareCenter] currentLoginUser].prikey publicKey:[[ServerCenter shareCenter] getCurrentServer].data.pub_key];
    ecdhkey = [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdhkey salt:[ServerCenter shareCenter].httpTokenSalt];
    if (!postData) {
        postData = [ConnectTool get16_32RandData];
    }
    IMRequest *imRequest = [ConnectTool createRequestWithEcdhKey:ecdhkey data:postData aad:[ServerCenter shareCenter].defineAad];
    
    [self POSTWithUrlString:url postData:imRequest.data complete:success fail:fail];
}



+ (void)POSTWithUrlString:(NSString *)url postProtoData:(NSData *)postData withPrivkey:(NSString *)privkey complete:(NetWorkOperationSuccess)success fail:(NetWorkOperationFail)fail{
    
    NSData *ecdhkey = [KeyHandle getECDHkeyWithPrivkey:privkey publicKey:[[ServerCenter shareCenter] getCurrentServer].data.pub_key];
    NSData *salt = nil;
    if ([privkey isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].prikey]) {
        salt = [ServerCenter shareCenter].httpTokenSalt;
    }
    ecdhkey = [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdhkey salt:salt];
    if (!postData) {
        postData = [ConnectTool get16_32RandData];
    }
    GcmData *gcmData = [ConnectTool createGcmDataWithEcdhkey:ecdhkey data:[ConnectTool createStructDataWithData:postData] aad:[ServerCenter shareCenter].defineAad];
    IMRequest *imRequest = [ConnectTool createRequestWithData:gcmData privkey:privkey publickKey:[KeyHandle createPubkeyByPrikey:privkey]];
    
    [self POSTWithUrlString:url postData:imRequest.data complete:success fail:fail];
}



+ (void)POSTWithUrlString:(NSString *)url signNoEncryptPostData:(NSData *)postData complete:(NetWorkOperationSuccess)success fail:(NetWorkOperationFail)fail{
    
    postData = postData?postData:[ConnectTool get16_32RandData];
    NSString *sign = [ConnectTool signWithData:postData];

    RequestNotEncrypt *noEncryptRequest = [[RequestNotEncrypt alloc] init];
    noEncryptRequest.body = postData;
    noEncryptRequest.sign = sign;
    noEncryptRequest.pubKey = [[LKUserCenter shareCenter] currentLoginUser].pub_key;
    
    [self POSTWithUrlString:url postData:noEncryptRequest.data complete:success fail:fail];
}


+ (void)POSTWithUrlString:(NSString *)url signNoEncryptPostData:(NSData *)postData withPrivkey:(NSString *)privkey Publickey:(NSString *)publickey complete:(NetWorkOperationSuccess)success fail:(NetWorkOperationFail)fail{
    
    postData = postData?postData:[ConnectTool get16_32RandData];
    NSString *sign = [ConnectTool signWithData:postData Privkey:privkey];
    
    RequestNotEncrypt *noEncryptRequest = [[RequestNotEncrypt alloc] init];
    noEncryptRequest.body = postData;
    noEncryptRequest.sign = sign;
    noEncryptRequest.pubKey = publickey;
    
    [self POSTWithUrlString:url postData:noEncryptRequest.data complete:success fail:fail];
}


// Call this method to get new salt
+ (void)getSaltWithComplete:(void (^)(NSData *salt,NSError *error))complete
                forceUpdate:(BOOL)forceUpdate{
    if (forceUpdate) {
        GenerateToken *token = [GenerateToken new];
        token.salt = [KeyHandle createRandom512bits];
        [self getServerToken:token complete:complete];
    } else{
        GenerateToken *token = [GenerateToken new];
        token.salt = [KeyHandle createRandom512bits];
        [self getServerToken:token complete:complete];
        return;
        
        //Decrypted
        NSString *saltHex = GJCFUDFGetValue([[LKUserCenter shareCenter] currentLoginUser].pub_key);
        if (GJCFStringIsNull(saltHex)) {
            GenerateToken *token = [GenerateToken new];
            token.salt = [KeyHandle createRandom512bits];
            [self getServerToken:token complete:complete];
        } else{
            NSData *data = [ConnectTool decodeGcmDataWithGcmData:[GcmData parseFromData:[StringTool hexStringToData:saltHex] error:nil] publickey:[[LKUserCenter shareCenter] currentLoginUser].pub_key];
            GenerateTokenResponse *resPonse = [GenerateTokenResponse parseFromData:data error:nil];
            // timeout
            if (resPonse.expired < [[NSDate date] timeIntervalSince1970] + 400) {
                GenerateToken *token = [GenerateToken new];
                token.salt = [KeyHandle createRandom512bits];
                [self getServerToken:token complete:complete];
            } else{
                [ServerCenter shareCenter].httpTokenSalt = resPonse.salt;
            }
        }
    }
}

+ (void)getServerToken:(GenerateToken *)token complete:(void (^)(NSData *salt,NSError *error))complete{
    NSData *ecdhkey = [KeyHandle getECDHkeyWithPrivkey:[[LKUserCenter shareCenter] currentLoginUser].prikey publicKey:[[ServerCenter shareCenter] getCurrentServer].data.pub_key];
    ecdhkey = [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdhkey salt:[ConnectTool get64ZeroData]];
    IMRequest *imRequest = [ConnectTool createRequestWithEcdhKey:ecdhkey data:token.data aad:[ServerCenter shareCenter].defineAad];
    [self POSTWithUrlString:getRandomSaltUrl postData:imRequest.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code == successCode) {
            NSData *data = [ConnectTool decodeHttpResponseWithEmptySalt:hResponse];
            // The server returns how long it has expired
            GenerateTokenResponse *serverToken = [GenerateTokenResponse parseFromData:data error:nil];
            
            // Set expiration time
            [ServerCenter shareCenter].saltDeadTime = serverToken.expired + [[NSDate date] timeIntervalSince1970];
            
            // Negotiate salt
            NSData *randomSalt = [StringTool DataXOR1:token.salt DataXOR2:serverToken.salt];
            serverToken.salt = randomSalt;
            if (serverToken.salt.length == 64 && serverToken.expired >=0){
                // Encryption salt
                GcmData *gcmData = [ConnectTool createGcmWithData:serverToken.data publickey:[[LKUserCenter shareCenter] currentLoginUser].pub_key];
                NSString *saltHex = [StringTool hexStringFromData:gcmData.data];
                GJCFUDFCache([[LKUserCenter shareCenter] currentLoginUser].pub_key,saltHex);
                // Save to singleton
                [ServerCenter shareCenter].httpTokenSalt = serverToken.salt;
                [ServerCenter shareCenter].httpTokenResponse = serverToken;
                if (complete) {
                    complete(serverToken.salt,nil);
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(nil,error);
        }
    }];
}



+ (void)checkSaltExpired{
    NSData *ecdhkey = [KeyHandle getECDHkeyWithPrivkey:[[LKUserCenter shareCenter] currentLoginUser].prikey publicKey:[[ServerCenter shareCenter] getCurrentServer].data.pub_key];
    ecdhkey = [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdhkey salt:[ServerCenter shareCenter].httpTokenSalt];
    IMRequest *imRequest = [ConnectTool createRequestWithEcdhKey:ecdhkey data:nil aad:[ServerCenter shareCenter].defineAad];
    [self POSTWithUrlString:checkSaltExpiredUrl postData:imRequest.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code == successCode) {
            NSData *data = [ConnectTool decodeHttpResponse:hResponse];
            GenerateTokenResponse *serverToken = [GenerateTokenResponse parseFromData:data error:nil];
            // Set expiration time
            [ServerCenter shareCenter].saltDeadTime = serverToken.expired + [[NSDate date] timeIntervalSince1970];
            if (serverToken.expired < 400) { // Regain salt
                GenerateToken *token = [GenerateToken new];
                token.salt = [KeyHandle createRandom512bits];
                [self getServerToken:token complete:nil];
            }
        }
    } fail:^(NSError *error) {
        
    }];
}


@end
