//
//  HandleUrlManager.h
//  Connect
//
//  Created by MoHuilin on 2016/11/16.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger,UrlType) {
    
   UrlTypeCommon        = 1 << 0,
   UrlTypeFriend        = 1 << 1,
   UrlTypePay           = 1 << 2,
   UrlTypeTransfer      = 1 << 3,
   UrlTypePacket        = 1 << 4,
   UrlTypeGroup         = 1 << 5

};


@interface HandleUrlManager : NSObject

+ (void)handleOpenURL:(NSURL *)url;

@end
