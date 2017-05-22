//
//  GestureSetPage.h
//  Connect
//
//  Created by MoHuilin on 16/7/30.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseViewController.h"

typedef NS_ENUM(NSInteger, GestureActionType) {
    GestureActionTypeSet = 0,
    GestureActionTypeCancel,
    GestureActionTypeChange,
};

@interface GestureSetPage : BaseViewController
@property(assign, nonatomic) BOOL isChangeGesture;

- (instancetype)initWithAction:(GestureActionType)actionType;

- (instancetype)initWithAction:(GestureActionType)actionType complete:(void (^)(BOOL result))complete;

@end
