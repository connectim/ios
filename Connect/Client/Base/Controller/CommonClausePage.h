//
//  CommonClausePage.h
//  HashNest
//
//  Created by MoHuilin on 16/5/5.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseViewController.h"

typedef NS_ENUM(NSInteger, SourceType) {
    SourceTypeOutNetWork = 0,
    SourceTypeHelp = 1,
    SourceTypeFeedBack = 2
};

@interface CommonClausePage : BaseViewController
@property(assign, nonatomic) SourceType sourceType;

- (instancetype)initWithUrl:(NSString *)url;

@end
