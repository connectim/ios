//
//  NCellSwitch.h
//  HashNest
//
//  Created by MoHuilin on 16/3/16.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseCell.h"

@interface NCellSwitch : BaseCell

@property (nonatomic) BOOL switchIsOn;

@property(strong,nonatomic) UILabel* customLable;

@property (copy ,nonatomic) void (^SwitchValueChangeCallBackBlock)(BOOL on);

@end
