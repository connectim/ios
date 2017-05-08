//
//  BitcoinInfo.h
//  Connect
//
//  Created by Edwin on 16/7/17.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BitcoinInfo : NSObject

// address
@property(nonatomic, copy) NSString *bitcoinAddress;
// qr
@property(nonatomic, copy) NSString *qrimageUrl;
// tag
@property(nonatomic, copy) NSString *mainAddress;
// blance
@property(nonatomic, strong) NSString *bitcoinAccout;
@end
