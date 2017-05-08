//
//  UserCommonInfoSetCell.h
//  Connect
//
//  Created by MoHuilin on 16/7/21.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseCell.h"

@interface UserCommonInfoSetCell : BaseCell

@property(copy, nonatomic) void (^TextValueChangeBlock)(NSString *text);

@end
