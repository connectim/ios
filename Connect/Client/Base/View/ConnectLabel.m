//
//  ConnectLabel.m
//  Connect
//
//  Created by MoHuilin on 16/5/12.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "ConnectLabel.h"

@implementation ConnectLabel

- (instancetype)initWithText:(NSString *)text{
    if (self = [super init]) {
        self.text = text;
    }
    
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        self.font = [UIFont systemFontOfSize:18];
        self.numberOfLines = 0;
        self.textColor = [UIColor blackColor];
    }
    
    return self;
}

@end
