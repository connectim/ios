//
//  LMLabels.h
//  Connect
//
//  Created by Edwin on 16/8/31.
//  Copyright © 2016年 bitmain. All rights reserved.
//  标签

#import <Foundation/Foundation.h>
#import "AccountInfo.h"

@interface LMLabels : NSObject
/**
 *  用户标签数组
 */
@property(nonatomic, strong) NSMutableArray *info;
/**
 *  标签
 */
@property(nonatomic, copy) NSString *label;
@end
