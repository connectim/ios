//
//  ServerInfo.h
//  Connect
//
//  Created by MoHuilin on 16/5/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseInfo.h"

@interface DataInfo : NSObject

@property (nonatomic ,copy) NSString *ip;
@property (nonatomic ,copy) NSString *port;
@property (nonatomic ,copy) NSString *pub_key;
@property (nonatomic ,strong) NSNumber *state;

@end


@interface ServerInfo : BaseInfo

@property (nonatomic ,copy) NSString *sign;
@property (nonatomic ,strong) DataInfo *data;

@end
