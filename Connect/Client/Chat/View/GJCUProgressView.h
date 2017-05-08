//
//  GJGCProgressView.h
//  Connect
//
//  Created by KivenLin on 15/7/1.
//  Copyright (c) 2015年 Connect. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GJCUProgressView : UIView

@property (nonatomic,strong)UIColor *tintColor;

@property (nonatomic,assign)CGFloat progress;

- (void)dismiss;

@end
