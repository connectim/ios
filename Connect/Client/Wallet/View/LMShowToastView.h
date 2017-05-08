//
//  LMShowToastView.h
//  Connect
//
//  Created by bitmain on 2016/12/10.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD+Loading.h"

@interface LMShowToastView : UIView
@property(weak, nonatomic) IBOutlet UILabel *disPlayLable;
@property(weak, nonatomic) IBOutlet UIImageView *disPlayImageView;


- (void)setUpWithType:(ToastType)type withDisPlayTitle:(NSString *)displayTitle;

@end
