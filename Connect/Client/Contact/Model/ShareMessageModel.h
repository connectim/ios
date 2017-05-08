//
//  ShareMessageModel.h
//  Connect
//
//  Created by MoHuilin on 16/9/26.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ShareMessageModel : NSObject

@property (nonatomic ,copy) NSString *title;
@property (nonatomic ,copy) NSString *desc;
@property (nonatomic ,copy) NSString *url;
@property (nonatomic ,copy) NSString *local;
@property (nonatomic ,copy) NSString *enable;
@property (nonatomic ,copy) NSString *priority;
@property (nonatomic ,copy) NSString *display;
@property (nonatomic ,copy) NSString *created_at;

@end
