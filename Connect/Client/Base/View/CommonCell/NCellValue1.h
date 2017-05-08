//
//  NCellValue1.h
//  Connect
//
//  Created by MoHuilin on 16/7/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseCell.h"
typedef NS_ENUM(NSUInteger,CellSourceType)
{
    CellSourceTypeCommon = 1 << 0,
    CellSourceTypeAbout  = 1 << 1
};

@interface NCellValue1 : BaseCell


@property (assign, nonatomic) CellSourceType cellSourceType;

@end
