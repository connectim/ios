//
//  KQXPasswordInputTipView.m
//  Connect
//
//  Created by Qingxu Kuang on 16/8/22.
//  Copyright © 2016年 Connect.  All rights reserved.
//

@interface KQXPasswordInputTipView ()

@property(weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property(weak, nonatomic) IBOutlet UILabel *tipLabel;


@property(nonatomic, assign) tipViewStyle style;    // Show style
@end

@implementation KQXPasswordInputTipView
#pragma mark - initial methods

- (instancetype)initWithFrame:(CGRect)frame {
    [NSException raise:@"请使用sharedTipViewWithFrame:style:构造方法。" format:@"！！！"];
    self = [super initWithFrame:frame];
    return nil;
}

- (instancetype)initWithFramePrivate:(CGRect)frame {
    self = [[NSBundle mainBundle] loadNibNamed:@"KQXPasswordInputTipView" owner:nil options:nil].firstObject;
    if (self) {
        [self setFrame:frame];
    }
    return self;
}

+ (instancetype)sharedTipViewWithFrame:(CGRect)frame {
    static KQXPasswordInputTipView *tipView = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tipView = [[self alloc] initWithFramePrivate:frame];
    });
    return tipView;
}

#pragma mark --

#pragma mark - methods

- (void)showTipViewWithStyle:(tipViewStyle)style tip:(NSString *)tipString {
    [_tipLabel setText:tipString];
    _style = style;
    [self configuration];
    [self animationForTipView];
    UIWindow *key = [UIApplication sharedApplication].keyWindow;
    [key addSubview:self];
}

- (void)configuration {
    NSString *imageName = _style == KQXPasswordInputTipViewStyleRight ? @"success_message" : @"attention_message";
    UIImage *image = [UIImage imageNamed:imageName];
    [_iconImageView setImage:image];
}

- (void)animationForTipView {
    [UIView animateWithDuration:0.3 animations:^{
        [self setTransform:CGAffineTransformMakeTranslation(0.f, CGRectGetHeight(self.frame))];
    }                completion:^(BOOL finished) {
        if (finished) {
            [self dismiss];
        }
    }];
}

- (void)dismiss {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (3.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

        [UIView animateWithDuration:0.3 animations:^{
            [self setTransform:CGAffineTransformMakeTranslation(0.f, 0.f)];
        }                completion:^(BOOL finished) {

        }];
    });
}

#pragma mark --
@end
