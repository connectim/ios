//
//  LMTableHeaderView.h
//  Connect
//
//  Created by bitmain on 2017/1/10.
//  Copyright © 2017年 Connect. All rights reserved.
//

typedef void (^ButtonClickBlock)();

#import <UIKit/UIKit.h>

@interface LMTableHeaderView : UIView

@property(strong, nonatomic) ButtonClickBlock buttonClickBlock;


@end
