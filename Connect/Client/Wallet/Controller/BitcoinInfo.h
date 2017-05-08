//
//  BitcoinInfo.h
//  Connect
//
//  Created by Edwin on 16/7/17.
//  Copyright © 2016年 bitmain. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BitcoinInfo : NSObject

/**
 *  地址
 */
@property(nonatomic, copy) NSString *bitcoinAddress;
/**
 *  二维码
 */
@property(nonatomic, copy) NSString *qrimageUrl;
/**
 *  标签
 */
@property(nonatomic, copy) NSString *mainAddress;
/**
 *  余额
 */
@property(nonatomic, strong) NSString *bitcoinAccout;
@end
