//
//  NetServiceTool.m
//  URLCallBackDemo
//
//  Created by Edwin on 16/8/15.
//  Copyright © 2016年 EdwinXiang. All rights reserved.
//

#import "NetServiceTool.h"
#import "AFNetworking.h"

@interface NetServiceTool ()

@property (nonatomic, strong) NSURLSessionDataTask *task;
@property (nonatomic, strong) AFHTTPSessionManager *manager;
@end
@implementation NetServiceTool

-(AFHTTPSessionManager *)manager {
    if (!_manager) {
        _manager = [AFHTTPSessionManager manager];
    }
    return _manager;
}

+ (instancetype)shareService
{
    static NetServiceTool *__sharedGenerator = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedGenerator = [[self alloc] init];
    });
    return __sharedGenerator;
}

-(void)aqureResultWithUrl:(NSString *)url withParams:(NSDictionary *)params withCallBack:(ServiceResultCallback)callBack {
    [self configManager:self.manager];
    self.task = [_manager GET:url parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (callBack) {
            callBack(responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error = %@",[error localizedDescription]);
    }];
//    _task 
}

// Configure the request header here
- (void)configManager:(AFHTTPSessionManager *)manager
{
    ///	response data parse
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",@"text/html",nil];
    
    ///	request data parse
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.requestSerializer.timeoutInterval = 30.f;
    
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"accept"];
    [manager.requestSerializer setHTTPShouldHandleCookies:YES];
    
    manager.securityPolicy = [AFSecurityPolicy defaultPolicy];
}

-(void)dealloc {
    [_task cancel];
}
@end
