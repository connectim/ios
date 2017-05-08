//
//  LMRedLuckyShowView.m
//  Connect
//
//  Created by Qingxu Kuang on 16/7/30.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMRedLuckyShowView.h"
#import "YYAnimatedImageView.h"
#import "YYFrameImage.h"

#define ANNIMATION_DURATION 1.6

@interface LMRedLuckyShowView ()

@property(weak, nonatomic) IBOutlet YYAnimatedImageView *gifImageView;

@property(weak, nonatomic) IBOutlet UIButton *closeButton;
@property(weak, nonatomic) IBOutlet UILabel *titleLabel;
@property(weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property(weak, nonatomic) IBOutlet UIButton *detailButton;


@property(weak, nonatomic) IBOutlet NSLayoutConstraint *widthConstraint;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *heightConstraint;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraint;

// path
@property(strong, nonatomic) NSBundle *imageBundle;

@end

@implementation LMRedLuckyShowView


#define ANIMATION_DURATION 2.f

#pragma mark - lazy loading

- (NSBundle *)imageBundle {
    if (!_imageBundle) {
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"LMRedLuckyAnimationImages" ofType:@"bundle"];
        _imageBundle = [NSBundle bundleWithPath:bundlePath];
    }
    return _imageBundle;
}


#pragma mark - initial methods

- (instancetype)initWithFrame:(CGRect)frame redLuckyGifImages:(NSArray<UIImage *> *)images {
    self = [[NSBundle mainBundle] loadNibNamed:@"LMRedLuckyShowView" owner:nil options:nil].firstObject;
    if (self) {
        [self setFrame:frame];
        if (images && images.count) {
            [self setUpElementsWithGifImages:images endImage:[UIImage imageWithContentsOfFile:[self.imageBundle pathForResource:@"mb34" ofType:@"png"]]];
        }
        [self makeResultTitleLabelsTransformWithScaleX:0.f Y:0.f];
        [self makeDetailButtonTransformWithTranspotationY:CGRectGetHeight(self.frame) / 2];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.titleLabel.text = LMLocalizedString(@"Wallet Congratulations", nil);
    self.subtitleLabel.text = LMLocalizedString(@"Wallet You got a Lucky Packet", nil);
    [self.detailButton setTitle:LMLocalizedString(@"Wallet Detail", nil) forState:UIControlStateNormal];
}

#pragma mark --

#pragma mark - methods

- (void)makeResultTitleLabelsTransformWithScaleX:(CGFloat)x Y:(CGFloat)y {
    [self.titleLabel setTransform:CGAffineTransformMakeScale(x, y)];
    [self.subtitleLabel setTransform:CGAffineTransformMakeScale(x, y)];
}

- (void)makeDetailButtonTransformWithScaleX:(CGFloat)x {
    [self.detailButton setTransform:CGAffineTransformMakeScale(x, 1.f)];
}

- (void)makeDetailButtonTransformWithTranspotationY:(CGFloat)y {
    [self.detailButton setTransform:CGAffineTransformMakeTranslation(0.f, y)];
}

- (void)setUpElementsWithGifImages:(NSArray<UIImage *> *)images endImage:(UIImage *)endImage {
    [_gifImageView setImage:endImage];
    [_gifImageView setContentMode:UIViewContentModeScaleAspectFit];
    [_gifImageView setAnimationImages:images];
    [_gifImageView setAnimationDuration:ANIMATION_DURATION];
    [_gifImageView setAnimationRepeatCount:1];
    [_gifImageView startAnimating];
}

- (void)showRedLuckyViewIsGetARedLucky:(BOOL)getARedLucky {
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    [keyWindow addSubview:self];

    getARedLucky ? [self showResultWithGetARedLucky] : [self showResultWithoutGetARedLucky];

}

- (void)changeConstraintsForDispointImage {
    _widthConstraint.constant = 148.f;
    _heightConstraint.constant = 148.f;
    _topConstraint.constant = CGRectGetHeight(self.frame) / 2 - 74.f;
}

- (void)updateInfoWithTitle:(NSString *)title subtitle:(NSString *)subtitle {
    [self.titleLabel setText:title];
    [self.subtitleLabel setText:subtitle];
}

- (void)showResultWithGetARedLucky {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (ANIMATION_DURATION / 2.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updateInfoWithTitle:LMLocalizedString(@"Wallet Congratulations", nil) subtitle:LMLocalizedString(@"Wallet You got a Lucky Packet", nil)];

        [UIView animateWithDuration:0.3f animations:^{
            [self makeResultTitleLabelsTransformWithScaleX:1.f Y:1.f];
            [self makeDetailButtonTransformWithTranspotationY:0.f];
        }                completion:^(BOOL finished) {

        }];
    });
    NSMutableArray *mbs = @[].mutableCopy;
    // Show results
    NSString *namePrefix;
    for (int i = 0; i < 35; i++) {
        namePrefix = [NSString stringWithFormat:@"mb%d", i];
        NSString *path = [self.imageBundle pathForResource:namePrefix ofType:@"png"];
        [mbs objectAddObject:path];
    }
    UIImage *image = [[YYFrameImage alloc] initWithImagePaths:mbs oneFrameDuration:ANNIMATION_DURATION / mbs.count loopCount:1];
    // Play the animation
    self.gifImageView.image = image;
}

- (void)showResultWithoutGetARedLucky {
    [self changeConstraintsForDispointImage];
    [UIView animateWithDuration:0.3f animations:^{
        [self makeDetailButtonTransformWithTranspotationY:0.f];
        [self makeResultTitleLabelsTransformWithScaleX:1.f Y:1.f];
    }                completion:^(BOOL finished) {

    }];
    [self updateInfoWithTitle:LMLocalizedString(@"Wallet Unfortunately", nil) subtitle:LMLocalizedString(@"Wallet Good luck next time", nil)];
    // Show results
    NSMutableArray *dispoints = @[].mutableCopy;
    NSString *namePrefix;
    for (int i = 0; i < 67; i++) {
        namePrefix = [NSString stringWithFormat:@"dispoint%d@2x", i];
        NSString *path = [self.imageBundle pathForResource:namePrefix ofType:@"png"];
        [dispoints objectAddObject:path];
    }
    UIImage *image = [[YYFrameImage alloc] initWithImagePaths:dispoints oneFrameDuration:ANNIMATION_DURATION / dispoints.count loopCount:1];
    // Play the animation
    self.gifImageView.image = image;
}

- (void)dismissRedLuckyView {
    // Remove the agent
    self.delegate = nil;
    [_gifImageView stopAnimating];
    if (![_gifImageView isAnimating]) {
        [self removeFromSuperview];
        [self deallocImagesForFree];
    }
}

- (void)deallocImagesForFree {
    if (![_gifImageView isAnimating]) {
        [_gifImageView performSelector:@selector(setAnimationImages:) withObject:nil afterDelay:0.f];
    }
}

// Filter gestures
- (CGFloat)min_x {
    return CGRectGetMinX(_gifImageView.frame);
}

- (CGFloat)min_y {
    return CGRectGetMinY(_gifImageView.frame);
}

- (CGFloat)max_x {
    return CGRectGetMaxX(_gifImageView.frame);
}

- (CGFloat)max_y {
    return CGRectGetMaxY(_gifImageView.frame);
}

#pragma mark --

#pragma mark - selectors

- (IBAction)closeRedLuckyView:(UIButton *)sender {
    [self dismissRedLuckyView];
}

- (IBAction)goRedLuckyDetail:(UIButton *)sender {
    if (self.delegate &&
            [self.delegate respondsToSelector:@selector(redLuckyShowView:goRedLuckyDetailWithSender:)]) {
        [self.delegate redLuckyShowView:self goRedLuckyDetailWithSender:sender];
    }
}

#pragma mark --

@end
