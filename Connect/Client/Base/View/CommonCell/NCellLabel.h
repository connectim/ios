//
//  NCellLabel.h
//  HashNest
//
//  Created by MoHuilin on 16/3/16.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseCell.h"

@interface NCellLabel : BaseCell

@property (nonatomic, strong) UIColor *titleColor;

@property (nonatomic) NSTextAlignment textAlignment;

@property (nonatomic ,strong) UILabel *titleLabel;

@end
