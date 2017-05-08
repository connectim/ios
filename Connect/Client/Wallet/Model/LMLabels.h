//
//  LMLabels.h
//  Connect
//
//  Created by Edwin on 16/8/31.
//  Copyright © 2016年 Connect.  All rights reserved.
//  标签

#import <Foundation/Foundation.h>
#import "AccountInfo.h"

@interface LMLabels : NSObject
// user tag array
@property(nonatomic, strong) NSMutableArray *info;
// tag
@property(nonatomic, copy) NSString *label;
@end
