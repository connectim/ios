//
//  SingleAFNetworkManager.m
//  Connect
//
//  Created by MoHuilin on 16/10/11.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "SingleAFNetworkManager.h"
#import "AFNetworking.h"
#import "UIKit+AFNetworking.h"

@interface SingleAFNetworkManager ()


@property (nonatomic ,strong) AFHTTPSessionManager *uploaderManager ;
@property (nonatomic ,strong) AFHTTPSessionManager *manager ;
@property (nonatomic ,strong) AFHTTPSessionManager *downloadManager ;
@property (nonatomic ,strong) AFURLSessionManager *urlsession ;


@end

static SingleAFNetworkManager *manager = nil;
@implementation SingleAFNetworkManager

+ (SingleAFNetworkManager *)sharedManager{
    @synchronized(self) {
        if(manager == nil) {
            manager = [[[self class] alloc] init];
        }
    }
    return manager;
}


+(id)allocWithZone:(NSZone *)zone
{
    @synchronized(self)
    {
        if (manager == nil)
        {
            manager = [super allocWithZone:zone];
            return manager;
        }
    }
    return nil;
}


-(AFHTTPSessionManager *)sharedDownloadURLSession{
    if (self.downloadManager) {
        return self.downloadManager;
    }
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.downloadManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
    return self.downloadManager;
}


-(AFHTTPSessionManager *)sharedHTTPUploaderManager{
    
    if (self.uploaderManager) {
        return self.uploaderManager;
    }
    
    self.uploaderManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    self.uploaderManager.requestSerializer.timeoutInterval = 15;
    self.uploaderManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    NSSet *set = self.uploaderManager.responseSerializer.acceptableContentTypes;
    self.uploaderManager.responseSerializer.acceptableContentTypes = [set setByAddingObject:@"binary/octet-stream"];
    // Set the maximum number of concurrent concurrent, too easy to go wrong
    self.uploaderManager.operationQueue.maxConcurrentOperationCount = 9;
    
    
    //- 999
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    securityPolicy.allowInvalidCertificates = YES;
    [securityPolicy setValidatesDomainName:NO];
    self.uploaderManager.securityPolicy = securityPolicy;
    
    return self.uploaderManager;
}


-(AFHTTPSessionManager *)sharedHTTPSession{
    
    if (self.manager) {
        return self.manager;
    }
    
    self.manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    self.manager.requestSerializer.timeoutInterval = 15;
    self.manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    NSSet *set = self.manager.responseSerializer.acceptableContentTypes;
    self.manager.responseSerializer.acceptableContentTypes = [set setByAddingObject:@"binary/octet-stream"];
    // Set the maximum number of concurrent concurrent, too easy to go wrong
    self.manager.operationQueue.maxConcurrentOperationCount = 10;
    
    //- 999
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    securityPolicy.allowInvalidCertificates = YES;
    [securityPolicy setValidatesDomainName:NO];
    self.manager.securityPolicy = securityPolicy;
    
    return self.manager;

}

-(AFURLSessionManager *)sharedURLSession{
    if (self.urlsession) {
        return self.urlsession;
    }
    self.urlsession = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    return self.urlsession;
}


@end
