//
//  LMReciptNotesViewController.m
//  Connect
//
//  Created by Edwin on 16/8/10.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMReciptNotesViewController.h"
#import "CommonClausePage.h"
#import "NSString+Size.h"

typedef NS_ENUM(NSInteger, LMTransactionStatusType) {
    TransactionStatusTypeUnconfirmed = 1,
    TransactionStatusTypeConfirmed,

};

@interface LMReciptNotesViewController ()
@property(nonatomic, strong) UIImageView *sendImageView;
@property(nonatomic, strong) UIImageView *receiveImageView;
@property(nonatomic, strong) UIImageView *categoryImageView;
@property(nonatomic, strong) UILabel *sendUsernameLabel;
@property(nonatomic, strong) UILabel *receiveUsernameLabel;
@property(nonatomic, strong) UILabel *reciptReasonLabel;
@property(nonatomic, strong) UILabel *bitNumLabel;

@property(nonatomic, strong) UILabel *noPayLabel;
@property(nonatomic, strong) UIButton *payStatusViewButton;

@property(nonatomic, strong) UILabel *notesTitle;
@property(nonatomic, strong) UILabel *notesContentLabel;
@property(nonatomic, strong) UILabel *timeLabel;
@property(nonatomic, strong) UILabel *checkLabel;
@property(nonatomic, strong) UIButton *payStatusBtn;

@property(nonatomic, assign) LMTransactionStatusType transactonStatusType;

@property(nonatomic, strong) AccountInfo *sender;
@property(nonatomic, strong) AccountInfo *receive;

@end

@implementation LMReciptNotesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LMLocalizedString(@"Wallet Detail", nil);

    NSLog(@"bill === %@", _bill);

    if ([_bill.receiver isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
        self.receive = [[LKUserCenter shareCenter] currentLoginUser];
        self.sender = self.user;
    } else {
        self.sender = [[LKUserCenter shareCenter] currentLoginUser];
        self.receive = self.user;
    }

    [self displayTransferInfo];
    [self payStatusInformation];
}

- (void)displayTransferInfo {
    self.sendImageView = [[UIImageView alloc] initWithFrame:CGRectMake(DEVICE_SIZE.width / 2 - AUTO_WIDTH(232), AUTO_HEIGHT(34) + 64, AUTO_WIDTH(100), AUTO_WIDTH(100))];
    [self.sendImageView setPlaceholderImageWithAvatarUrl:self.sender.avatar];
    self.sendImageView.layer.cornerRadius = 5;
    self.sendImageView.layer.masksToBounds = YES;

    [self.view addSubview:self.sendImageView];

    self.sendUsernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.sendImageView.frame) + AUTO_HEIGHT(10), DEVICE_SIZE.width - AUTO_WIDTH(200), AUTO_HEIGHT(40))];
    self.sendUsernameLabel.centerX = self.sendImageView.centerX;
    self.sendUsernameLabel.textAlignment = NSTextAlignmentCenter;
    self.sendUsernameLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.sendUsernameLabel.textColor = [UIColor blackColor];
    [self.view addSubview:self.sendUsernameLabel];

    if (self.PayStatus) {
        self.sendUsernameLabel.text = self.sender.username;
        self.categoryImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, AUTO_WIDTH(100), AUTO_HEIGHT(37))];
        self.categoryImageView.centerX = DEVICE_SIZE.width / 2;
        self.categoryImageView.centerY = self.sendImageView.centerY;
        [self.categoryImageView setImage:[UIImage imageNamed:@"transfer_to"]];
        [self.view addSubview:self.categoryImageView];

        self.receiveImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.categoryImageView.left + AUTO_WIDTH(170), AUTO_HEIGHT(34) + 64, AUTO_WIDTH(100), AUTO_WIDTH(100))];
        [self.receiveImageView setPlaceholderImageWithAvatarUrl:self.receive.avatar];
        self.receiveImageView.layer.cornerRadius = 5;
        self.receiveImageView.layer.masksToBounds = YES;
        [self.view addSubview:self.receiveImageView];

        self.receiveUsernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.receiveImageView.frame) + AUTO_HEIGHT(10), AUTO_WIDTH(200), AUTO_HEIGHT(40))];
        self.receiveUsernameLabel.centerX = self.receiveImageView.centerX;
        self.receiveUsernameLabel.text = self.receive.username;

        self.receiveUsernameLabel.textAlignment = NSTextAlignmentCenter;
        self.receiveUsernameLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
        self.receiveUsernameLabel.textColor = [UIColor blackColor];
        [self.view addSubview:self.receiveUsernameLabel];
    } else {
        self.sendImageView.centerX = DEVICE_SIZE.width / 2;
        self.sendUsernameLabel.centerX = DEVICE_SIZE.width / 2;
        self.sendUsernameLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet has requested to payment", nil), self.sender.username];
    }


    self.reciptReasonLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.sendUsernameLabel.frame) + AUTO_HEIGHT(26), VSIZE.width - AUTO_WIDTH(200), AUTO_HEIGHT(40))];
    self.reciptReasonLabel.centerX = DEVICE_SIZE.width / 2;
    self.reciptReasonLabel.numberOfLines = 0;
    self.reciptReasonLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.reciptReasonLabel.text = GJCFStringIsNull(self.bill.tips) ? nil : [NSString stringWithFormat:LMLocalizedString(@"Link Note", nil), self.bill.tips];
    self.reciptReasonLabel.textAlignment = NSTextAlignmentCenter;
    self.reciptReasonLabel.textColor = [UIColor colorWithHexString:@"767A82"];
    [self.view addSubview:self.reciptReasonLabel];
    self.bitNumLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.reciptReasonLabel.frame) + AUTO_HEIGHT(21), VSIZE.width - AUTO_WIDTH(300), AUTO_HEIGHT(80))];
    self.bitNumLabel.centerX = DEVICE_SIZE.width / 2;
    self.bitNumLabel.text = [NSString stringWithFormat:@"฿%@", [PayTool getBtcStringWithAmount:self.bill.amount]];
    self.bitNumLabel.font = [UIFont systemFontOfSize:FONT_SIZE(64)];
    self.bitNumLabel.textAlignment = NSTextAlignmentCenter;
    self.bitNumLabel.textColor = [UIColor colorWithHexString:@"161A21"];
    [self.view addSubview:self.bitNumLabel];
}

- (void)payStatusInformation {
    if (self.PayStatus == YES) {

        self.payStatusViewButton = [[UIButton alloc] init];
        self.payStatusViewButton.enabled = NO;
        [self.payStatusViewButton setImage:[UIImage imageNamed:@"transfer_success"] forState:UIControlStateNormal];
        [self.payStatusViewButton setTitle:LMLocalizedString(@"Wallet Payment Successful", nil) forState:UIControlStateNormal];
        self.payStatusViewButton.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(36)];
        [self.payStatusViewButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.view addSubview:self.payStatusViewButton];

        CGSize statusBtnSize = [self.payStatusViewButton.titleLabel.text sizeWithFont:self.payStatusViewButton.titleLabel.font constrainedToHeight:AUTO_HEIGHT(100)];

        self.payStatusViewButton.size = CGSizeMake(statusBtnSize.width + AUTO_HEIGHT(55), AUTO_HEIGHT(55));
        self.payStatusViewButton.top = self.bitNumLabel.bottom + AUTO_HEIGHT(80);
        self.payStatusViewButton.centerX = self.view.centerX;

        UIView *backView = [UIView new];
        [self.view addSubview:backView];
        backView.backgroundColor = [UIColor whiteColor];
        backView.layer.cornerRadius = 8;
        backView.layer.borderWidth = 0.5;
        backView.layer.borderColor = GJCFQuickHexColor(@"b3b5bd").CGColor;


        self.notesTitle = [[UILabel alloc] initWithFrame:CGRectMake(AUTO_WIDTH(55), CGRectGetMaxY(self.payStatusViewButton.frame) + AUTO_HEIGHT(92), AUTO_WIDTH(240), AUTO_HEIGHT(40))];
        self.notesTitle.textAlignment = NSTextAlignmentLeft;
        self.notesTitle.text = LMLocalizedString(@"Wallet Transcation", nil);
        self.notesTitle.textColor = [UIColor colorWithHexString:@"161A21"];
        self.notesTitle.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
        [self.view addSubview:self.notesTitle];

        backView.top = self.payStatusViewButton.bottom + AUTO_HEIGHT(50);
        CGFloat maginToView = 10;
        backView.width = DEVICE_SIZE.width - maginToView * 2;
        backView.left = maginToView;

        self.notesContentLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.notesTitle.frame), CGRectGetMaxY(self.notesTitle.frame) + AUTO_HEIGHT(12), VSIZE.width - AUTO_WIDTH(110), AUTO_HEIGHT(70))];
        self.notesContentLabel.numberOfLines = 0;
        self.notesContentLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
        self.notesContentLabel.text = self.bill.txid;
        self.notesContentLabel.textAlignment = NSTextAlignmentLeft;
        self.notesContentLabel.textColor = [UIColor colorWithHexString:@"161A21"];
        self.notesContentLabel.userInteractionEnabled = YES;
        [self.view addSubview:self.notesContentLabel];


        UIButton *notesBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        notesBtn.frame = CGRectMake(CGRectGetMinX(self.notesTitle.frame), CGRectGetMaxY(self.notesTitle.frame) + AUTO_HEIGHT(12), VSIZE.width - AUTO_WIDTH(110), AUTO_HEIGHT(70));
        notesBtn.userInteractionEnabled = YES;
        notesBtn.backgroundColor = [UIColor clearColor];
        [notesBtn addTarget:self action:@selector(noteBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:notesBtn];

        self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.notesTitle.frame), CGRectGetMaxY(self.notesContentLabel.frame) + AUTO_HEIGHT(22), VSIZE.width - AUTO_WIDTH(244), AUTO_HEIGHT(30))];
        self.timeLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
        self.timeLabel.textAlignment = NSTextAlignmentLeft;
        self.timeLabel.textColor = [UIColor colorWithHexString:@"858998"];

        NSDate *date = [NSDate dateWithTimeIntervalSince1970:self.bill.createdAt];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm";
        NSString *res = [formatter stringFromDate:date];
        self.timeLabel.text = res;
        [self.view addSubview:self.timeLabel];

        self.checkLabel = [[UILabel alloc] initWithFrame:CGRectMake(AUTO_WIDTH(537), CGRectGetMaxY(self.timeLabel.frame) + AUTO_HEIGHT(5), AUTO_WIDTH(158), AUTO_HEIGHT(67))];
        self.checkLabel.font = [UIFont systemFontOfSize:FONT_SIZE(32)];
        self.checkLabel.textAlignment = NSTextAlignmentCenter;
        self.checkLabel.backgroundColor = [UIColor colorWithHexString:@"FF6C5A"];
        self.checkLabel.layer.cornerRadius = 5;
        self.checkLabel.layer.masksToBounds = YES;
        self.checkLabel.textColor = [UIColor whiteColor];
        if (self.bill.status == TransactionStatusTypeConfirmed) {
            self.checkLabel.text = LMLocalizedString(@"Wallet Confirmed", nil);
            self.checkLabel.backgroundColor = [UIColor colorWithHexString:@"37C65C"];
        } else {
            self.checkLabel.text = LMLocalizedString(@"Wallet Unconfirmed", nil);
        }
        CGSize size = [self.checkLabel.text sizeWithFont:self.checkLabel.font constrainedToHeight:AUTO_HEIGHT(67)];
        self.checkLabel.left -= size.width + 20 - self.checkLabel.width;
        self.checkLabel.width = size.width + 20;
        [self.view addSubview:self.checkLabel];

        backView.height = self.checkLabel.bottom + 10 - backView.top;

    } else {
        self.payStatusBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.payStatusBtn.frame = CGRectMake(AUTO_WIDTH(30), AUTO_HEIGHT(959), VSIZE.width - AUTO_WIDTH(60), AUTO_HEIGHT(100));
        [self.payStatusBtn setTitle:LMLocalizedString(@"Wallet Waitting for pay", nil) forState:UIControlStateNormal];
        self.payStatusBtn.backgroundColor = [UIColor colorWithHexString:@"FF6C5A"];
        self.payStatusBtn.titleLabel.textColor = [UIColor whiteColor];
        self.payStatusBtn.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(36)];
        self.payStatusBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.payStatusBtn.layer.cornerRadius = 3;
        self.payStatusBtn.layer.masksToBounds = YES;
        [self.view addSubview:self.payStatusBtn];
    }
}

- (void)noteBtnClick:(UIButton *)pan {
    NSString *url = [NSString stringWithFormat:@"%@%@", txDetailBaseUrl, self.notesContentLabel.text];
    CommonClausePage *page = [[CommonClausePage alloc] initWithUrl:url];
    [self.navigationController pushViewController:page animated:YES];
}
@end
