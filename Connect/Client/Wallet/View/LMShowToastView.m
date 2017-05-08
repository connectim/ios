//
//  LMShowToastView.m
//  Connect
//
//  Created by bitmain on 2016/12/10.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import "LMShowToastView.h"

@interface LMShowToastView ()

@property(weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewTopContraton;


@end


@implementation LMShowToastView
- (void)awakeFromNib {
    [super awakeFromNib];
    self.disPlayLable.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.disPlayLable.textColor = [UIColor whiteColor];
    self.backgroundColor = [UIColor clearColor];
    self.alpha = 0.9;
    // Spacing settings
    self.imageViewTopContraton.constant = AUTO_WIDTH(65);


}

- (void)setUpWithType:(ToastType)type withDisPlayTitle:(NSString *)displayTitle {
    NSString *imageName = nil;
    if (type == ToastTypeSuccess) {
        imageName = @"success_message";
    } else if (type == ToastTypeFail) {
        imageName = @"error_message";
    } else {
        imageName = @"attention_message";
    }
    self.disPlayImageView.image = [UIImage imageNamed:imageName];

    self.disPlayLable.text = displayTitle;
}

@end
