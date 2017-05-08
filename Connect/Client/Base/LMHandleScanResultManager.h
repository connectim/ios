//
//  LMHandleScanResultManager.h
//  Connect
//
//  Created by MoHuilin on 2016/12/21.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMHandleScanResultManager : NSObject

+ (instancetype)sharedManager;


- (void)handleScanResult:(NSString *)resultStr controller:(UIViewController *)controller;

@end
