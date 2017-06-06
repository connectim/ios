//
//  LMReceiptViewController.m
//  Connect
//
//  Created by Edwin on 16/7/14.
//  Copyright © 2016年 Connect.  All rights reserved.
//  收款

#import "LMReceiptViewController.h"
#import "BarCodeTool.h"
#import "NSString+Size.h"
#import "UIView+Toast.h"
#import "YYImageCache.h"

@interface LMReceiptViewController () <UITextFieldDelegate>

@property(nonatomic, copy) NSString *userNameAccoutInformation;
@property(nonatomic, strong) UILabel *titleLabel;
/**
 *  输入金额
 */
@property(nonatomic, strong) UITextField *bitTextField;

/**
 *  条形
 */
@property(nonatomic, strong) UIImageView *lineImageView;

@property(nonatomic, strong) UIImageView *imageView;

@property(nonatomic, strong) UIView *backGrounView;

@property(nonatomic, strong) UIButton *setAmountButton;

@property(nonatomic, copy) NSString *payRequestUrl;

@property(nonatomic, strong) UIView *leftView;

@end

@implementation LMReceiptViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setNavigationRight:@"wallet_share_payment"];
    self.title = LMLocalizedString(@"Wallet Receipt", nil);
    // get usermessage
    AccountInfo *ainfo = [[LKUserCenter shareCenter] currentLoginUser];
    self.userNameAccoutInformation = [NSString stringWithFormat:@"bitcoin:%@",ainfo.address];
    self.view.backgroundColor = [UIColor blackColor];
    // qr code
    [self addQRcodeImageView];
    [self.view addSubview:self.errorTipLabel];
}

- (void)doRight:(id)sender {

    NSString *lang = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
    NSString *title = [NSString stringWithFormat:LMLocalizedString(@"Wallet request for payment", nil), [[LKUserCenter shareCenter] currentLoginUser].username, self.bitTextField.text];
    NSString *link = [NSString stringWithFormat:@"%@?address=%@&locale=%@&amount=0", H5PayServerUrl, [[LKUserCenter shareCenter] currentLoginUser].address, lang];
    if (!GJCFStringIsNull(self.bitTextField.text)) {
        title = [NSString stringWithFormat:LMLocalizedString(@"Wallet request for payment BTC", nil), [[LKUserCenter shareCenter] currentLoginUser].username, self.bitTextField.text];
        link = [NSString stringWithFormat:@"%@?address=%@&amount=%@&locale=%@", H5PayServerUrl, [[LKUserCenter shareCenter] currentLoginUser].address, self.bitTextField.text, lang];
    }

    UIImage *avatar = [[YYImageCache sharedCache] getImageForKey:[[LKUserCenter shareCenter] currentLoginUser].avatar];
    if (!avatar) {
        avatar = [UIImage imageNamed:@"default_user_avatar"];
    }
    UIActivityViewController *activeViewController = [[UIActivityViewController alloc] initWithActivityItems:@[title, [NSURL URLWithString:link], avatar] applicationActivities:nil];
    activeViewController.excludedActivityTypes = @[UIActivityTypeAirDrop, UIActivityTypeCopyToPasteboard, UIActivityTypeAddToReadingList];
    [self presentViewController:activeViewController animated:YES completion:nil];
    UIActivityViewControllerCompletionWithItemsHandler myblock = ^(NSString *__nullable activityType, BOOL completed, NSArray *__nullable returnedItems, NSError *__nullable activityError) {
        NSLog(@"%d %@", completed, activityType);
    };
    activeViewController.completionWithItemsHandler = myblock;
}

- (void)addQRcodeImageView {

    UIView *backGrounView = [[UIView alloc] init];
    backGrounView.backgroundColor = [UIColor whiteColor];
    backGrounView.layer.cornerRadius = 5;
    backGrounView.layer.masksToBounds = YES;
    self.backGrounView = backGrounView;
    [self.view addSubview:backGrounView];

    [backGrounView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(AUTO_HEIGHT(60) + 64);
        make.width.equalTo(self.view).multipliedBy(0.8);
        make.height.equalTo(backGrounView.mas_width);
        make.centerX.equalTo(self.view);
    }];


    self.setAmountButton = [[UIButton alloc] init];
    [self.setAmountButton setTitle:LMLocalizedString(@"Wallet Set Amount", nil) forState:UIControlStateNormal];
    [self.setAmountButton setTitle:LMLocalizedString(@"Wallet Clear", nil) forState:UIControlStateSelected];
    self.setAmountButton.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    [self.setAmountButton setTitleColor:LMBasicYellow forState:UIControlStateNormal];
    [self.setAmountButton addTarget:self action:@selector(btnChange:) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:self.setAmountButton];
    [_setAmountButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(backGrounView.mas_bottom).offset(20);
        make.centerX.equalTo(self.view);
    }];


    self.titleLabel = [[UILabel alloc] init];
    NSString *title = [NSString stringWithFormat:LMLocalizedString(@"Wallet Your Bitcoin Address", nil), [[LKUserCenter shareCenter] currentLoginUser].address];
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.text = title;
    self.titleLabel.font = [UIFont boldSystemFontOfSize:FONT_SIZE(25)];
    self.titleLabel.textColor = LMBasicBlack;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.userInteractionEnabled = YES;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAddress)];
    [self.titleLabel addGestureRecognizer:tap];
    [backGrounView addSubview:self.titleLabel];
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(backGrounView).offset(AUTO_HEIGHT(10));
        make.centerX.equalTo(backGrounView);
        make.height.mas_equalTo(AUTO_HEIGHT(AUTO_HEIGHT(200)));
    }];

    self.bitTextField = [[UITextField alloc] init];
    self.bitTextField.delegate = self;
    self.bitTextField.keyboardType = UIKeyboardTypeDecimalPad;
    self.bitTextField.font = [UIFont systemFontOfSize:FONT_SIZE(64)];
    self.bitTextField.textColor = [UIColor blackColor];
    [self.bitTextField addTarget:self action:@selector(textFieldEditingVauleChanged:) forControlEvents:UIControlEventEditingChanged];

    UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, AUTO_WIDTH(40), AUTO_HEIGHT(80))];
    self.leftView = leftView;
    self.leftView.hidden = YES;
    UILabel *label = [[UILabel alloc] init];
    label.text = @"฿";
    label.numberOfLines = 0;
    label.textColor = [UIColor blackColor];
    label.font = [UIFont systemFontOfSize:FONT_SIZE(30)];
    label.textAlignment = NSTextAlignmentCenter;
    label.size = [label.text sizeWithFont:label.font constrainedToWidth:AUTO_WIDTH(40)];
    label.left = 0;
    label.top = 0;
    [leftView addSubview:label];
    self.bitTextField.leftView = leftView;
    self.bitTextField.leftViewMode = UITextFieldViewModeAlways;
    [backGrounView addSubview:self.bitTextField];

    [_bitTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_titleLabel.mas_bottom).offset(AUTO_HEIGHT(10));
        make.width.equalTo(backGrounView.mas_width).multipliedBy(0.7);
        make.height.mas_equalTo(AUTO_HEIGHT(0));
        make.centerX.equalTo(backGrounView);
    }];

    self.lineImageView = [[UIImageView alloc] init];
    self.lineImageView.image = [UIImage imageNamed:@"dotted_line"];
    self.lineImageView.hidden = YES;
    [backGrounView addSubview:self.lineImageView];

    [_lineImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_bitTextField.mas_bottom).offset(AUTO_HEIGHT(20));
        make.centerX.equalTo(backGrounView);
        make.height.mas_equalTo(AUTO_HEIGHT(5));
        make.width.equalTo(backGrounView.mas_width).multipliedBy(0.9);
    }];

    _imageView = [[UIImageView alloc] init];
    _imageView.backgroundColor = [UIColor whiteColor];
    _imageView.image = [BarCodeTool barCodeImageWithString:self.userNameAccoutInformation withSize:400];
    [backGrounView addSubview:_imageView];

    [_imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_lineImageView).offset(AUTO_HEIGHT(10));
        make.bottom.equalTo(backGrounView.mas_bottom).offset(-AUTO_HEIGHT(20));
        make.width.equalTo(_imageView.mas_height);
        make.centerX.equalTo(backGrounView);
    }];

    self.errorTipLabel.height = AUTO_HEIGHT(60);
    [self.view bringSubviewToFront:self.errorTipLabel];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    [self.bitTextField resignFirstResponder];
    return YES;
}

- (void)textFieldEditingVauleChanged:(UITextField *)textField {
    if (textField.text.length > 12) {
        textField.text = [textField.text substringToIndex:12];
    }
    NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:textField.text];
    self.rightBarBtn.enabled = amount.doubleValue > 0;
    if (self.rightBarBtn.enabled) {
        NSString *address = [self.userNameAccoutInformation stringByReplacingOccurrencesOfString:@"bitcoin:" withString:@""];
        NSString *moneyAddress = [NSString stringWithFormat:@"bitcoin:%@?amount=%@", address, self.bitTextField.text];
        self.payRequestUrl = moneyAddress;
        _imageView.image = [BarCodeTool barCodeImageWithString:moneyAddress withSize:400];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.bitTextField resignFirstResponder];
}

#pragma mark --

- (void)btnChange:(UIButton *)btn {
    btn.selected = !btn.selected;
    self.leftView.hidden = !btn.selected;
    if (btn.selected) {
        self.titleLabel.text = LMLocalizedString(@"Wallet Scan to pay me", nil);
        self.lineImageView.hidden = NO;
        [self.bitTextField mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(AUTO_HEIGHT(80));
        }];
        [UIView animateWithDuration:0.1 animations:^{
            [self.view layoutIfNeeded];
        }];
        [self.bitTextField becomeFirstResponder];
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            self.errorTipLabel.alpha = 0;
            self.errorTipLabel.bottom = 64;
        }];
        self.rightBarBtn.enabled = YES;
        self.titleLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Your Bitcoin Address", nil), [[LKUserCenter shareCenter] currentLoginUser].address];
        self.bitTextField.text = nil;
        [self.bitTextField mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(AUTO_HEIGHT(0));
        }];
        [UIView animateWithDuration:0.1 animations:^{
            [self.view layoutIfNeeded];
        }];
        self.lineImageView.hidden = YES;
        _imageView.image = [BarCodeTool barCodeImageWithString:self.userNameAccoutInformation withSize:400];
        [self.bitTextField resignFirstResponder];
    }
}

- (void)tapAddress {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = [[LKUserCenter shareCenter] currentLoginUser].address;
    [self.view makeToast:LMLocalizedString(@"Set Copied", nil) duration:0.8 position:CSToastPositionCenter];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    // Before the logic
    NSString *toBeString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSRange findRange = [toBeString rangeOfString:@"."];
    if (findRange.length != 0) {
        if ([toBeString substringFromIndex:findRange.location].length > 9 && range.length != 1) {
            textField.text = [toBeString substringToIndex:9];
            return NO;
        }
    }
    // You can only enter numbers and decimal points
    if ([string isEqualToString:@""] || string == nil) {
        return YES;
    }
    if (string.length > 0) {
        unichar single = [string characterAtIndex:0];
        if ((single >= '0' && single <= '9') || single == '.') {
            if ((textField.text.length <= 0) && (single == '.')) {
                return NO;
            } else {
                if (textField.text.length >= 11 && (single == '.')) {
                    return NO;
                }
                return YES;
            }
        } else {
            return NO;
        }
    }
    return YES;
}
@end
