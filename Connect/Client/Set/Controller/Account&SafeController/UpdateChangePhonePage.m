//
//  UpdateChangePhonePage.m
//  Connect
//
//  Created by MoHuilin on 16/7/29.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "UpdateChangePhonePage.h"
#import "ConnectLabel.h"
#import "ConnectButton.h"
#import "CountryView.h"

#import "ChangePhoneVertifyPage.h"
#import "SelectCountryView.h"
#import "SelectCountryViewController.h"
#import "BottomLineTextField.h"

@interface UpdateChangePhonePage ()

@property(nonatomic, strong) UIButton *selectCountryBtn;

@property(strong, nonatomic) UILabel *enterLable;
@property(nonatomic, strong) SelectCountryView *selectCountryInfo;
@property(nonatomic, strong) BottomLineTextField *phoneField;
@property(nonatomic, strong) ConnectButton *nextBtn;

@property(nonatomic, strong) ConnectLabel *tipLabel;

@property(nonatomic, strong) NSString *scanCodeString;

@property(nonatomic, assign) int countryCode;

@property(nonatomic, copy) NSString *coutryLocalCode;

@end

@implementation UpdateChangePhonePage

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LMLocalizedString(@"Set Change Mobile", nil);
    self.view.backgroundColor = LMBasicBackgroudGray;
    [self addNewCloseBarItem];
}

- (void)doRight:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"top_background"] forBarMetrics:UIBarMetricsDefault];
}

- (void)addNotifications {


    __weak __typeof(&*self) weakSelf = self;
    [NSNotificationCenter.defaultCenter addObserverForName:UIKeyboardWillShowNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        CGFloat duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
        CGRect keyboardFrame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        [UIView animateWithDuration:duration animations:^{
            weakSelf.nextBtn.top = DEVICE_SIZE.height - CGRectGetHeight(keyboardFrame) - weakSelf.nextBtn.height;
        }];

        if (weakSelf.tipLabel.bottom > weakSelf.nextBtn.top) {
            weakSelf.view.top = -(weakSelf.tipLabel.bottom - weakSelf.nextBtn.top);

            weakSelf.nextBtn.top += (weakSelf.tipLabel.bottom - weakSelf.nextBtn.top);
        }

    }];

    [NSNotificationCenter.defaultCenter addObserverForName:UIKeyboardWillHideNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        CGFloat duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
        [UIView animateWithDuration:duration animations:^{
            weakSelf.nextBtn.top = [UIScreen height] - weakSelf.nextBtn.height;
            weakSelf.view.top = 0;
        }];
    }];

}


#pragma mark - set up

- (void)setup {
    // Enter the creation of the phone number label
    UILabel *titleLabel = [UILabel new];
    titleLabel.text = LMLocalizedString(@"Set Enter New Mobile Number", nil);
    titleLabel.font = [UIFont systemFontOfSize:20];
    titleLabel.textColor = LMBasicBlack;
    [self.view addSubview:titleLabel];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(AUTO_HEIGHT(210));
        make.centerX.equalTo(self.view);
    }];
    self.enterLable = titleLabel;

    // get current country code
    self.coutryLocalCode = [RegexKit countryCode];
    self.countryCode = [[RegexKit phoneCode] intValue];

    // select country
    NSNumber *countryPhoneCode = [RegexKit phoneCode];
    self.countryCode = [countryPhoneCode intValue];
    NSString *disPlayName = [[NSLocale currentLocale] displayNameForKey:NSLocaleCountryCode value:self.coutryLocalCode];

    SelectCountryView *selectCountryInfo = [SelectCountryView viewWithCountryName:disPlayName countryCode:countryPhoneCode.intValue];
    self.selectCountryInfo = selectCountryInfo;
    [self.view addSubview:selectCountryInfo];
    [self.selectCountryInfo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.enterLable.mas_bottom).offset(AUTO_HEIGHT(100));
        make.width.mas_equalTo(AUTO_WIDTH(660));
        make.height.mas_equalTo(AUTO_HEIGHT(110));
        make.centerX.equalTo(self.view);
    }];
    [selectCountryInfo addTarget:self action:@selector(updateCountryInfo) forControlEvents:UIControlEventTouchUpInside];

    self.phoneField = [[BottomLineTextField alloc] init];
    _phoneField.keyboardType = UIKeyboardTypeNumberPad;
    [_phoneField addTarget:self action:@selector(textValueChange) forControlEvents:UIControlEventEditingChanged];
    _phoneField.placeholder = LMLocalizedString(@"Set Your Phone", nil);
    _phoneField.font = [UIFont systemFontOfSize:FONT_SIZE(48)];
    [self.view addSubview:_phoneField];
    [self.phoneField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.selectCountryInfo.mas_left);
        make.right.equalTo(self.selectCountryInfo.mas_right);
        make.top.equalTo(self.selectCountryInfo.mas_bottom);
        make.height.equalTo(self.selectCountryInfo.mas_height);
    }];
    // next button creat
    self.nextBtn = [[ConnectButton alloc] initWithNormalTitle:LMLocalizedString(@"Login Next", nil) disableTitle:nil];
    [self.view addSubview:_nextBtn];
    _nextBtn.enabled = NO;
    [_nextBtn addTarget:self action:@selector(nextBtnClick) forControlEvents:UIControlEventTouchUpInside];
    _nextBtn.bottom = self.view.bottom - AUTO_HEIGHT(477);
    _nextBtn.centerX = self.view.centerX;

    UILabel *decLable = [[UILabel alloc] init];
    NSString *tipString = LMLocalizedString(@"Set you can login mobile number link one account", nil);
    NSMutableAttributedString *tipAttrString = [[NSMutableAttributedString alloc] initWithString:tipString];
    [tipAttrString addAttribute:NSFontAttributeName
                          value:[UIFont systemFontOfSize:FONT_SIZE(24)]
                          range:NSMakeRange(0, tipString.length)];
    decLable.attributedText = [tipAttrString copy];
    [self.view addSubview:decLable];
    decLable.numberOfLines = 0;
    decLable.textAlignment = NSTextAlignmentCenter;
    [decLable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.nextBtn.mas_left);
        make.right.equalTo(self.nextBtn.mas_right);
        make.top.equalTo(self.nextBtn.mas_bottom).offset(AUTO_HEIGHT(70));
        make.height.mas_equalTo(AUTO_HEIGHT(100));
    }];


}

// click country
- (void)updateCountryInfo {
    SelectCountryViewController *page = [[SelectCountryViewController alloc] initWithCallBackBlock:^(id countryInfo) {
        self.countryCode = [countryInfo[@"phoneCode"] intValue];
        self.coutryLocalCode = [countryInfo valueForKey:@"countryCode"];
        [self.selectCountryInfo updateCountryInfoWithCountryName:[countryInfo valueForKey:@"countryName"] countryCode:self.countryCode];
        [GCDQueue executeInMainQueue:^{
            [self textValueChange];
        }];
    }];
    page.isSetSelectCountry = YES;
    [self.navigationController pushViewController:page animated:YES];
}

#pragma mark - event
- (void)nextBtnClick {
    ChangePhoneVertifyPage *page = [[ChangePhoneVertifyPage alloc] initWithCountryCode:self.countryCode phone:self.phoneField.text];
    [self.navigationController pushViewController:page animated:YES];
}

- (void)textValueChange {
    self.nextBtn.enabled = [RegexKit vilidatePhoneNum:self.phoneField.text region:self.coutryLocalCode];
}

#pragma mark - hide keyboard

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

@end
