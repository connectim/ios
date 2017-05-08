//
//  SingleAFNetworkManager.h
//  Connect
//
//  Created by MoHuilin on 16/10/11.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

@interface SingleAFNetworkManager : NSObject

+ (SingleAFNetworkManager *)sharedManager;


-(AFURLSessionManager *)sharedURLSession;

-(AFHTTPSessionManager *)sharedHTTPUploaderManager;

/**
     dlownload manager
 */
-(AFHTTPSessionManager *)sharedDownloadURLSession;

-(AFHTTPSessionManager *)sharedHTTPSession;

@end
