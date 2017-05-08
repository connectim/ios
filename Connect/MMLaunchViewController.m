//
//  MMLaunchViewController.m
//  Connect
//
//  Created by MoHuilin on 2016/11/3.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "MMLaunchViewController.h"
#import "YYImageCache.h"

@interface MMLaunchViewController ()

@property(nonatomic, strong) UIImageView *adImageView;
@property(nonatomic, strong) UIButton *hideButton;

@property(nonatomic, assign) int timeCount;

@end

@implementation MMLaunchViewController


- (void)viewDidLoad {
    [super viewDidLoad];

    self.duration = LANUCH_DURATION;
    self.animationDuration = 0.5;

    UIImageView *imgView = [[UIImageView alloc] initWithFrame:[UIApplication sharedApplication].keyWindow.bounds];
    imgView.image = [UIImage imageNamed:@"default_lanuch"];

    NSArray *lanuchImages = [GJCFUDFGetValue(@"lanuchImages") mj_JSONObject];
    if (lanuchImages.count) {
        int index = arc4random() % lanuchImages.count + 0; //[0,lanuchImages.count)

        NSString *urlStr = [lanuchImages objectAtIndexCheck:index];

        UIImage *img = [[YYImageCache sharedCache] getImageForKey:urlStr];
        if (img) {
            imgView.image = img;
        }
    }
    [self.view addSubview:imgView];
    [self.view sendSubviewToBack:imgView];

    BOOL showAd = NO;
    if (showAd) {
        [self.view addSubview:self.adImageView];
        [_adImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(self.view);
            make.height.equalTo(self.view).multipliedBy(0.8);
        }];
        [self.view addSubview:self.hideButton];
        [_hideButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view).offset(AUTO_HEIGHT(20));
            make.right.equalTo(self.view).offset(-AUTO_HEIGHT(20));
        }];
        NSTimer *myTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:myTimer forMode:NSDefaultRunLoopMode];
    } else {
        [GCDQueue executeInMainQueue:^{
            [self hidenAd];
        }             afterDelaySecs:self.duration];
    }
}

- (void)timerFired:(NSTimer *)timer {
    self.timeCount++;
    [self.hideButton setTitle:[NSString stringWithFormat:@"hiden%d", (int) self.duration - self.timeCount] forState:UIControlStateNormal];
    if (self.timeCount >= self.duration) {
        [self hidenAd];
        [timer invalidate];
        timer = nil;
    }
}

- (void)dealloc {

}

- (void)hidenAd {
    [UIView animateWithDuration:self.animationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.view.alpha = 0.0f;
        self.view.layer.transform = CATransform3DScale(CATransform3DIdentity, 1.5f, 1.5f, 1.0f);
    }                completion:^(BOOL finished) {
        if (self.hidenAdByUserBlock) {
            self.hidenAdByUserBlock();
        }
    }];
}

- (UIImageView *)adImageView {
    if (!_adImageView) {
        _adImageView = [[UIImageView alloc] init];
        _adImageView.image = [UIImage imageNamed:@"luckpacket_record"];
    }
    return _adImageView;
}

- (UIButton *)hideButton {
    if (!_hideButton) {
        _hideButton = [[UIButton alloc] init];
        _hideButton.layer.borderColor = [UIColor grayColor].CGColor;
        _hideButton.layer.borderWidth = 1;
        [_hideButton setTitle:LMLocalizedString(@"hiden", nil) forState:UIControlStateNormal];
        [_hideButton addTarget:self action:@selector(hidenAd) forControlEvents:UIControlEventTouchUpInside];
    }
    return _hideButton;
}

@end
