//
//  LMConnectStatusView.h
//  Connect
//
//  Created by MoHuilin on 2017/3/13.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger ,LMConnectStatus){
    LMConnectStatusViewDisconnect = 0,
    LMConnectStatusViewUpdatingEcdh,
    LMConnectStatusViewUpdateecdhSuccess,
};

@interface LMConnectStatusView : UIView

- (void)showViewWithStatue:(LMConnectStatus)status;

@end
