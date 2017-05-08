//
//  CustomActionSheetView.h
//  Connect
//
//  Created by MoHuilin on 16/9/5.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomActionSheetView : UIView

@property(nonatomic, copy) void (^ItemClick)(int snapTime);
@property(nonatomic, assign) int initTime;

@end
