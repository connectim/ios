//
//  ServerCenter.m
//  Connect
//
//  Created by MoHuilin on 16/7/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "ServerCenter.h"
#import "StringTool.h"
#import "KeyHandle.h"
#import "ConnectTool.h"
#import "Protofile.pbobjc.h"

@implementation ServerCenter

@synthesize httpTokenSalt = _httpTokenSalt;

static ServerCenter *center = nil;

+ (ServerCenter *)shareCenter{
    @synchronized(self) {
        if(center == nil) {
            center = [[[self class] alloc] init];
        }
    }
    return center;
}

- (instancetype)init{
    if (self = [super init]) {
    }
    
    return self;
}

+(id)allocWithZone:(NSZone *)zone
{
    @synchronized(self)
    {
        if (center == nil)
        {
            center = [super allocWithZone:zone];
            return center;
        }
    }
    return nil;
}


- (ServerInfo *)getCurrentServer{
    ServerInfo *server = [ServerInfo new];
    server.data.pub_key = ServerPublickey;
    return server;
}

- (NSString *)getCurrentServer_userEcdhkey{
    NSString *ecdhkey = [KeyHandle getECDHkeyUsePrivkey:[[LKUserCenter shareCenter] currentLoginUser].prikey PublicKey:[self getCurrentServer].data.pub_key];
                         

    return ecdhkey;
}


- (NSData *)httpTokenSalt{
    
    if (_httpTokenSalt && _httpTokenSalt.length > 0) {
        return _httpTokenSalt;
    }
    return self.httpTokenResponse.salt;
}

- (GenerateTokenResponse *)httpTokenResponse{
    if (!_httpTokenResponse) {
        NSString *saltHex = GJCFUDFGetValue([[LKUserCenter shareCenter] currentLoginUser].pub_key);
        if (!GJCFStringIsNull(saltHex)) {
            NSData *gcmData = [StringTool hexStringToData:saltHex];
            GcmData *gcm = [GcmData parseFromData:gcmData error:nil];
            NSData *saltData = [ConnectTool decodeGcmDataWithGcmData:gcm publickey:[[LKUserCenter shareCenter] currentLoginUser].pub_key];
            _httpTokenResponse = [GenerateTokenResponse parseFromData:saltData error:nil];
            return _httpTokenResponse;
        }
    }
    return _httpTokenResponse;
}

- (NSTimeInterval)saltDeadTime{
    if (_saltDeadTime == 0) {
        _saltDeadTime = self.httpTokenResponse.expired + [[NSDate date] timeIntervalSince1970];
    }
    return _saltDeadTime;
}

- (void)setHttpTokenSalt:(NSData *)httpTokenSalt{
    if (httpTokenSalt && httpTokenSalt.length > 0) {
        _httpTokenSalt = httpTokenSalt;
    }
}

- (NSData *)defineAad{
    if (_defineAad.length < 16) {
        _defineAad = [InnerAadStringDefine dataUsingEncoding:NSUTF8StringEncoding];
    }
    return _defineAad;
}

@end
