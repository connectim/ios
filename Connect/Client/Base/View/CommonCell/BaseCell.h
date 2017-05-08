//
//  BaseCell.h
//  Connect
//
//  Created by MoHuilin on 16/5/12.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CellItem.h"

@interface BaseCell : UITableViewCell

@property (strong ,nonatomic) id data;

@property (nonatomic ,assign) CGFloat height;

@end
