//
//  MyAddressQRPage.m
//  Connect
//
//  Created by MoHuilin on 16/7/21.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "MyAddressQRPage.h"
#import "BarCodeTool.h"

#define scanViewWH (DEVICE_SIZE.width - 100)

@interface MyAddressQRPage ()

@property(nonatomic, strong) AccountInfo *user;

@property(nonatomic, strong) UIControl *myCodeView;

@property(nonatomic, strong) UIImageView *codeImageView;
@property(nonatomic, strong) UILabel *IDLabel;


@end

@implementation MyAddressQRPage


- (instancetype)initWithUser:(AccountInfo *)user {
    if (self = [super init]) {
        self.user = user;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = LMLocalizedString(@"Set My QR code", nil);

    self.view.backgroundColor = XCColor(22, 26, 33);


    [self.view addSubview:self.myCodeView];

    CGFloat scaleMargin = 15;
    [_myCodeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(scanViewWH + scaleMargin, scanViewWH + scaleMargin * 3));
        make.top.equalTo(self.view.mas_top).offset(120 - scaleMargin);
        make.centerX.equalTo(self.view);
    }];


}


- (UIControl *)myCodeView {
    if (!_myCodeView) {
        _myCodeView = [[UIControl alloc] init];
        _myCodeView.layer.cornerRadius = 5;
        _myCodeView.layer.masksToBounds = YES;
        _myCodeView.backgroundColor = XCColor(43, 254, 192);

        _codeImageView = [UIImageView new];
        _codeImageView.image = [BarCodeTool barCodeImageWithString:self.user.address withSize:200];
        [_myCodeView addSubview:_codeImageView];
        [_codeImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.equalTo(_myCodeView).offset(AUTO_WIDTH(76));
            make.right.equalTo(_myCodeView).offset(-AUTO_WIDTH(76));
            make.height.equalTo(_codeImageView.mas_width);
        }];

        _IDLabel = [UILabel new];
        _IDLabel.text = [[LKUserCenter shareCenter] currentLoginUser].address;
        _IDLabel.textColor = [UIColor blackColor];
        _IDLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
        [_myCodeView addSubview:_IDLabel];
        [_IDLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_codeImageView.mas_bottom);
            make.centerX.equalTo(_myCodeView);
            make.bottom.equalTo(_myCodeView);
        }];
    }
    return _myCodeView;
}


@end
