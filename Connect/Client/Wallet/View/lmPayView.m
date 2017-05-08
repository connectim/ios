//
//  WXPayView.m
//  WXPayView
//
//  Created by apple on 16/1/6.
//  Copyright © 2016年 apple. All rights reserved.


#import "lmPayView.h"

@interface lmPayView ()


@property(weak, nonatomic) IBOutlet UILabel *accoutLabel;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *cardMessageConstraintW;
@property(weak, nonatomic) IBOutlet UILabel *moneyL;
@property(weak, nonatomic) IBOutlet UILabel *titleLabel;

@property(nonatomic, copy) WXPayViewCompletion completion;
@property(nonatomic, copy) NSString *cardMessage;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, assign) CGFloat money;

@property(nonatomic, strong) UIView *cover;

@end

@implementation lmPayView

- (instancetype)initWithMoney:(CGFloat)money title:(NSString *)title transferName:(NSString *)name completion:(WXPayViewCompletion)completion {

    self = [[[NSBundle mainBundle] loadNibNamed:@"lmPayView" owner:nil options:nil] lastObject];

    if (self == nil) {
        return nil;
    }

    _title = title;
    _money = money;
    _cardMessage = name;
    _completion = completion;

    [self setupContents];

    return self;
}

- (void)reloadTitle:(NSString *)title {
    _title = title;
    [self.titleLabel setText:_title];
    [self.inputView beginInput];
    [self reloadInputViews];
    [self layoutIfNeeded];
}

- (void)awakeFromNib {
    self.layer.cornerRadius = 10;

    // Default 6 bits
    self.inputView.places = 6;

    [super awakeFromNib];
}

- (void)setupContents {

    self.moneyL.text = [NSString stringWithFormat:@"￥%.2f", self.money];
    self.titleLabel.text = self.title;
    self.accoutLabel.text = self.cardMessage;
    __weak typeof(self) weakSelf = self;
    self.inputView.WXInputViewDidCompletion = ^(NSString *text) {
        if (weakSelf.completion) {
            weakSelf.completion(text);
        }

        self.endBlock(text);
    };
}

- (void)setPlaces:(NSInteger)places {
    _places = places;
    self.inputView.places = places;
}

- (IBAction)exitButtonClicked {
    if (self.exitBtnClicked) {
        self.exitBtnClicked();
    }
}


- (void)showView {

    UIWindow *window = [[UIApplication sharedApplication].windows lastObject];
    [window addSubview:self.cover];
    [window addSubview:self];

    // Set the WeChat payment interface animation and location
    self.transform = CGAffineTransformMakeScale(0.6, 0.6);
    self.alpha = 0;
    [UIView animateWithDuration:0.25 animations:^{
        self.transform = CGAffineTransformIdentity;
        self.cover.alpha = 1;
        self.alpha = 1;
    }];
    self.center = CGPointMake(window.center.x, (window.frame.size.height - 216) * 0.5);

    // Adapt small screen
    if (window.frame.size.width == 320) {
        self.bounds = CGRectMake(0, 0, self.bounds.size.width * 0.9, self.bounds.size.height);
    }

    // Pop up the keyboard
    [self.inputView beginInput];
}

- (void)hiddenView {

    // Set the micro-payment interface to disappear animation
    [UIView animateWithDuration:0.25 animations:^{
        self.transform = CGAffineTransformMakeScale(0.6, 0.6);
        self.alpha = 0;
        self.cover.alpha = 0;
    }                completion:^(BOOL finished) {
        [self removeFromSuperview];
        [self.cover removeFromSuperview];
    }];

    // Exit the keyboard
    [self.inputView endInput];
}

- (UIView *)cover {
    if (_cover == nil) {
        UIWindow *window = [[UIApplication sharedApplication].windows lastObject];
        _cover = [[UIView alloc] initWithFrame:window.bounds];
        CGFloat rgb = 83 / 255.0;
        _cover.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:0.7];
        _cover.alpha = 0;
    }
    return _cover;
}


@end
