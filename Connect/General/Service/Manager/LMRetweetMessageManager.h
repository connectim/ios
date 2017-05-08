//
//  LMRetweetMessageManager.h
//  Connect
//
//  Created by MoHuilin on 2017/1/20.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LMRerweetModel;

@interface LMRetweetMessageManager : NSObject

+ (instancetype)sharedManager;

- (void)retweetMessageWithModel:(LMRerweetModel *)retweetModel
                       complete:(void (^)(NSError *error,float progress))complete;


@end
