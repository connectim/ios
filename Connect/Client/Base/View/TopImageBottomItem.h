//
//  TopImageBottomItem.h
//  Connect
//
//  Created by MoHuilin on 16/8/24.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TopImageBottomItem : UIControl

+ (instancetype)itemWihtIcon:(NSString *)icon title:(NSString *)title;

@property (nonatomic ,assign) CGFloat margin;

@property (nonatomic ,strong) UILabel *titleLabel;

@end
