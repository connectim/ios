//
//  PopActionSheet.h
//  Connect
//
//  Created by MoHuilin on 16/7/27.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PopActionSheet : UIView


@property (nonatomic, copy) void (^Click)(NSInteger clickIndex);

- (instancetype)initWithFrame:(CGRect)frame titleArr:(NSArray *)titleArr;
- (instancetype)initWithFrame:(CGRect)frame titleArr:(NSArray *)titleArr destructive:(NSString *)title;
- (void)hiddenSheet;


@end
