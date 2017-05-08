//
//  UnSpentInfo.h
//  Connect
//
//  Created by MoHuilin on 16/8/2.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UnSpentInfo : NSObject

@property(nonatomic, copy) NSString *tx_hash;

@property(nonatomic, assign) double value;

@property(nonatomic, assign) int confirmations;

@property(nonatomic, copy) NSString *scriptpubkey;


@property(nonatomic, assign) int outputN;

@end
