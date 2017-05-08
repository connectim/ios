//
//  OuterTransferDetailController.m
//  Connect
//
//  Created by MoHuilin on 2016/11/15.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "OuterTransferDetailController.h"
#import "BarCodeTool.h"
#import "GJGCChatSystemNotiCellStyle.h"
#import "UIImage+Color.h"
#import "WallteNetWorkTool.h"
#import "YYImageCache.h"

@interface OuterTransferDetailController () {
    NSTimer *timer;
    int remainTime;

}
@property(nonatomic, strong) UILabel *countTimeLabel;

@property(nonatomic, strong) UIView *topContentView;
@property(nonatomic, strong) UIView *bottomContentView;

@property(nonatomic, strong) UIButton *statusView;

@end

@implementation OuterTransferDetailController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = LMLocalizedString(@"Wallet Transfer", nil);

}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [timer invalidate];
    timer = nil;
}


- (void)doRight:(id)sender {

    __weak typeof(self) weakSelf = self;

    UIAlertController *actionController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Wallet transferOutVia return", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        [WallteNetWorkTool cancelExternalWithHashid:self.billInfo.hash_p complete:^(NSError *error) {
            [GCDQueue executeInMainQueue:^{
                if (!error) {
                    weakSelf.billInfo.cancelled = YES;
                    [weakSelf loadStatus];
                } else {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Cancel Failed", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                    }];
                }
            }];
        }];

    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:nil];

    [actionController addAction:deleteAction];
    [actionController addAction:cancelAction];
    [self presentViewController:actionController animated:YES completion:nil];

}

- (void)dealloc {
    [timer invalidate];
    timer = nil;
}

- (void)setup {
    UIView *topContentView = [[UIView alloc] init];
    self.topContentView = topContentView;
    topContentView.backgroundColor = GJCFQuickHexColor(@"F0F0F6");
    [self.view addSubview:topContentView];
    [topContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view).offset(64);
        make.height.mas_equalTo(AUTO_HEIGHT(210));
    }];
    UIImageView *headerView = [[UIImageView alloc] init];
    headerView.image = [[YYImageCache sharedCache] getImageForKey:[[LKUserCenter shareCenter] currentLoginUser].avatar];
    headerView.layer.cornerRadius = 6;
    headerView.layer.masksToBounds = YES;
    [topContentView addSubview:headerView];
    [headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(topContentView).offset(AUTO_HEIGHT(25));
        make.bottom.equalTo(topContentView).offset(-AUTO_HEIGHT(25));
        make.width.equalTo(headerView.mas_height);
    }];

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.text = [[LKUserCenter shareCenter] currentLoginUser].username;
    nameLabel.font = [UIFont boldSystemFontOfSize:FONT_SIZE(36)];
    [topContentView addSubview:nameLabel];
    [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(headerView.mas_top).offset(AUTO_HEIGHT(20));
        make.left.equalTo(headerView.mas_right).offset(AUTO_WIDTH(35));
    }];

    UIImageView *redBagIconView = [[UIImageView alloc] init];
    [topContentView addSubview:redBagIconView];
    redBagIconView.image = [UIImage imageNamed:@"chat_bar_trasfer"];
    [redBagIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(nameLabel);
        make.bottom.equalTo(headerView);
        make.size.mas_equalTo(AUTO_SIZE(60, 60));
    }];

    NSString *str = [NSString stringWithFormat:LMLocalizedString(@"Wallet Send bitcoin BTC", nil), [PayTool getBtcStringWithAmount:self.billInfo.amount]];
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:str];
    NSInteger len = LMLocalizedString(@"Wallet Send bitcoin", nil).length;
    [attrStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:FONT_SIZE(24)] range:NSMakeRange(0, len)];
    [attrStr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:FONT_SIZE(30)] range:NSMakeRange(len, str.length - len)];
    UILabel *descLabel = [[UILabel alloc] init];
    descLabel.numberOfLines = 0;
    descLabel.attributedText = attrStr;
    [topContentView addSubview:descLabel];
    [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(redBagIconView);
        make.left.equalTo(redBagIconView.mas_right).offset(AUTO_WIDTH(25));
    }];

    self.statusView = [[UIButton alloc] init];
    [self.statusView setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.statusView.enabled = NO;
    [self.view addSubview:self.statusView];
    [self.statusView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(topContentView.mas_bottom).offset(AUTO_HEIGHT(100));
        make.centerX.equalTo(self.view);
    }];
    [self.statusView setImage:[UIImage imageNamed:@"attention_message"] forState:UIControlStateNormal];

    // Add the controls at the bottom
    [self.view addSubview:self.bottomContentView];
    [_bottomContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.right.equalTo(self.view);
        make.top.equalTo(topContentView.mas_bottom);
    }];

    // Displays the bottom status
    [self loadStatus];
}


- (void)loadStatus {
    if (!self.billInfo.cancelled) {
        if (self.billInfo.expired) {
            self.bottomContentView.hidden = YES;
            self.statusView.hidden = NO;
            self.navigationItem.rightBarButtonItems = nil;
            [self.statusView setTitle:LMLocalizedString(@"Wallet Over time", nil) forState:UIControlStateNormal];
        } else if (self.billInfo.received) {
            self.navigationItem.rightBarButtonItems = nil;
            self.bottomContentView.hidden = YES;
            self.statusView.hidden = NO;
            [self.statusView setImage:[UIImage imageNamed:@"transfer_success"] forState:UIControlStateNormal];
            [self.statusView setTitle:LMLocalizedString(@"Common Completed", nil) forState:UIControlStateNormal];
        } else {
            [self setNavigationRight:@"menu_white"];
            self.bottomContentView.hidden = NO;
            self.statusView.hidden = YES;
        }
    } else {
        self.navigationItem.rightBarButtonItems = nil;
        self.bottomContentView.hidden = YES;
        self.statusView.hidden = NO;
        [self.statusView setTitle:LMLocalizedString(@"Wallet Canceled", nil) forState:UIControlStateNormal];
    }
}

- (void)sendTransder:(UIButton *)sender {

    __weak typeof(self) weakSelf = self;
    if (!self.billInfo.URL) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Unknown error", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
        }];
        return;
    }

    UIImage *header = [[YYImageCache sharedCache] getImageForKey:[[LKUserCenter shareCenter] currentLoginUser].avatar];
    if (!header) {
        header = [UIImage imageNamed:@"default_user_avatar"];
    }

    NSString *title = [NSString stringWithFormat:LMLocalizedString(@"Wallet Transfer BTC to you by Connect IM", nil), [[LKUserCenter shareCenter] currentLoginUser].username, [PayTool getBtcStringWithAmount:self.billInfo.amount]];
    UIActivityViewController *activeViewController = [[UIActivityViewController alloc] initWithActivityItems:@[title, [NSURL URLWithString:self.billInfo.URL], header] applicationActivities:nil];
    activeViewController.excludedActivityTypes = @[UIActivityTypeAirDrop, UIActivityTypeCopyToPasteboard, UIActivityTypeAddToReadingList];
    [self presentViewController:activeViewController animated:YES completion:nil];
    UIActivityViewControllerCompletionWithItemsHandler myblock = ^(NSString *__nullable activityType, BOOL completed, NSArray *__nullable returnedItems, NSError *__nullable activityError) {
        NSLog(@"%d %@", completed, activityType);
    };
    activeViewController.completionWithItemsHandler = myblock;
}

- (void)timerCount {
    if (remainTime > 0) {
        remainTime--;
        self.countTimeLabel.text = [GJGCChatSystemNotiCellStyle formartDurationTime:remainTime];
    } else {
        [timer invalidate];
        timer = nil;
        self.countTimeLabel.text = LMLocalizedString(@"Over time", nil);
    }
}


- (UIView *)bottomContentView {
    if (!_bottomContentView) {
        _bottomContentView = [[UIView alloc] init];

        //center
        UILabel *centerDescLabel = [[UILabel alloc] init]; 
        centerDescLabel.text = LMLocalizedString(@"Wallet Wallet Out Send Share", nil);
        centerDescLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
        [_bottomContentView addSubview:centerDescLabel];
        [centerDescLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_bottomContentView).offset(AUTO_HEIGHT(65));
            make.centerX.equalTo(_bottomContentView);
        }];

        UIImageView *qrImageVieq = [[UIImageView alloc] init];
        UIImage *qrImage = [BarCodeTool barCodeImageWithString:self.billInfo.URL withSize:AUTO_WIDTH(400)];
        qrImageVieq.image = qrImage;
        [_bottomContentView addSubview:qrImageVieq];
        [qrImageVieq mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(centerDescLabel.mas_bottom).offset(AUTO_HEIGHT(10));
            make.centerX.equalTo(_bottomContentView);
            make.size.mas_equalTo(AUTO_SIZE(400, 400));
        }];

        UILabel *timeTipLabel = [[UILabel alloc] init];
        timeTipLabel.text = LMLocalizedString(@"Wallet The Countdown", nil);
        timeTipLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
        [_bottomContentView addSubview:timeTipLabel];
        [timeTipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(qrImageVieq.mas_bottom).offset(AUTO_HEIGHT(15));
            make.centerX.equalTo(_bottomContentView);
        }];


        UILabel *countTimeLabel = [[UILabel alloc] init];
        self.countTimeLabel = countTimeLabel;
        countTimeLabel.font = [UIFont systemFontOfSize:FONT_SIZE(64)];
        countTimeLabel.textColor = GJCFQuickHexColor(@"00C400");
        [_bottomContentView addSubview:countTimeLabel];
        [countTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(timeTipLabel.mas_bottom);
            make.centerX.equalTo(_bottomContentView);
        }];

        UIButton *comfrimButton = [[UIButton alloc] init];
        [comfrimButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithHexString:@"B3B5BD"]] forState:UIControlStateDisabled];
        [comfrimButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithHexString:@"37C65C"]] forState:UIControlStateNormal];
        comfrimButton.layer.cornerRadius = 3;
        comfrimButton.layer.masksToBounds = YES;
        CGFloat buttonH = AUTO_HEIGHT(100);
        [comfrimButton addTarget:self action:@selector(sendTransder:) forControlEvents:UIControlEventTouchUpInside];
        [comfrimButton setTitle:LMLocalizedString(@"Link Send", nil) forState:UIControlStateNormal];
        [_bottomContentView addSubview:comfrimButton];
        [comfrimButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_bottomContentView).offset(AUTO_WIDTH(25));
            make.right.equalTo(_bottomContentView).offset(-AUTO_WIDTH(25));
            make.bottom.equalTo(_bottomContentView.mas_bottom).offset(-AUTO_HEIGHT(50));
            make.height.mas_equalTo(buttonH);
        }];
        // leave time
        remainTime = (int) self.billInfo.deadline;
        self.countTimeLabel.text = [GJGCChatSystemNotiCellStyle formartDurationTime:remainTime];
        timer = [NSTimer scheduledTimerWithTimeInterval:1.f target:self selector:@selector(timerCount) userInfo:nil repeats:YES];
        [timer fire];
    }
    return _bottomContentView;
}

@end
