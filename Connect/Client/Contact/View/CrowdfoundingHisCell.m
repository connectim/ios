//
//  CrowdfoundingHisCell.m
//  Connect
//
//  Created by MoHuilin on 2016/11/2.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "CrowdfoundingHisCell.h"
#import "Protofile.pbobjc.h"
#import "StitchingImage.h"

#define borderSpen AUTO_WIDTH(15)

@interface CrowdfoundingHisCell ()
@property(weak, nonatomic) IBOutlet UIImageView *AvatarView;
@property(weak, nonatomic) IBOutlet UILabel *groupInfoLabel;
@property(weak, nonatomic) IBOutlet UILabel *timeLabel;
@property(weak, nonatomic) IBOutlet UILabel *noteLabel;
@property(weak, nonatomic) IBOutlet UILabel *amountLabel;
@property(weak, nonatomic) IBOutlet UILabel *statusLabel;


@property(nonatomic, strong) UIImageView *canvasView;

@end

@implementation CrowdfoundingHisCell

- (void)awakeFromNib {
    [super awakeFromNib];

    self.layer.cornerRadius = 7;
    self.layer.borderWidth = 0.7;
    self.layer.borderColor = GJCFQuickHexColor(@"efeff4").CGColor;
    self.layer.masksToBounds = YES;
    self.backgroundColor = [UIColor colorWithHexString:@"ffffff"];
    self.contentView.backgroundColor = [UIColor colorWithHexString:@"ffffff"];


    self.timeLabel.font = [UIFont systemFontOfSize:FONT_SIZE(25)];
    self.groupInfoLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.noteLabel.font = [UIFont systemFontOfSize:FONT_SIZE(25)];
    self.statusLabel.font = [UIFont systemFontOfSize:FONT_SIZE(25)];
    self.amountLabel.font = [UIFont boldSystemFontOfSize:FONT_SIZE(34)];

    self.noteLabel.textColor = [UIColor grayColor];
    self.timeLabel.textColor = [UIColor grayColor];
    self.statusLabel.textColor = [UIColor grayColor];


    [self.AvatarView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.AvatarView.mas_height);
    }];
    // refresh
    [self layoutIfNeeded];
}

/**
 *   set frame
 */
- (void)setFrame:(CGRect)frame {
    frame.origin.y += borderSpen;
    frame.origin.x = borderSpen;
    frame.size.width -= 2 * borderSpen;
    frame.size.height -= borderSpen;
    [super setFrame:frame];
}


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {

    }
    return self;
}

- (void)setData:(id)data {
    [super setData:data];

    if ([data isKindOfClass:[ExternalBillingInfo class]]) {
        ExternalBillingInfo *billInfo = (ExternalBillingInfo *) data;
        self.noteLabel.text = GJCFStringIsNull(billInfo.tips) ? nil : [NSString stringWithFormat:LMLocalizedString(@"Link Note", nil), billInfo.tips];
        self.groupInfoLabel.text = @"name";;
        self.timeLabel.textColor = LMBasicBlack;
        self.timeLabel.font = [UIFont boldSystemFontOfSize:FONT_SIZE(34)];
        self.timeLabel.text = [NSString stringWithFormat:@"%@ ฿", [PayTool getBtcStringWithAmount:billInfo.amount]];
        if (billInfo.cancelled) {
            self.statusLabel.text = LMLocalizedString(@"Wallet Canceled", nil);
            self.statusLabel.textColor = LMBasicLableColor;
            // set head
            NSString *userNameUrl = [LKUserCenter shareCenter].currentLoginUser.avatar;
            [self setMyselfImageViewWithString:userNameUrl];
            // set nickName
            NSString *nickName = [LKUserCenter shareCenter].currentLoginUser.username;
            [self setNickNameWithString:nickName withReceived:NO];

        } else if (billInfo.expired) {
            self.statusLabel.text = LMLocalizedString(@"Network Timeout", nil);
            self.statusLabel.textColor = LMBasicLableColor;
            // set head
            NSString *userNameUrl = [LKUserCenter shareCenter].currentLoginUser.avatar;
            [self setMyselfImageViewWithString:userNameUrl];
            // set nickName
            NSString *nickName = [LKUserCenter shareCenter].currentLoginUser.username;
            [self setNickNameWithString:nickName withReceived:NO];
        } else if (billInfo.received) {
            self.statusLabel.text = LMLocalizedString(@"Wallet Received", nil);
            self.statusLabel.textColor = LMBasicSuccessLableColor;
           // set head
            NSString *userNameUrl = billInfo.receiverInfo.avatar;
            [self setMyselfImageViewWithString:userNameUrl];
            // set nickName
            NSString *nickName = billInfo.receiverInfo.username;
            [self setNickNameWithString:nickName withReceived:YES];
        } else {
            self.statusLabel.text = LMLocalizedString(@"Wallet Unconfirmed", nil);
            self.statusLabel.textColor = LMBasicLableColor;
           // set head
            NSString *userNameUrl = [LKUserCenter shareCenter].currentLoginUser.avatar;
            [self setMyselfImageViewWithString:userNameUrl];
            // set nickName
            NSString *nickName = [LKUserCenter shareCenter].currentLoginUser.username;
            [self setNickNameWithString:nickName withReceived:NO];
        }
        // time hand
        NSTimeInterval second = billInfo.createdAt;
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:second];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"MM-dd HH:mm";
        NSString *res = [formatter stringFromDate:date];
        // exchange lable
        self.amountLabel.text = res;
        self.amountLabel.font = [UIFont systemFontOfSize:FONT_SIZE(25)];
        self.amountLabel.textColor = [UIColor grayColor];

    } else if ([data isKindOfClass:[Crowdfunding class]]) {
        Crowdfunding *crowdfunding = (Crowdfunding *) data;
        NSMutableArray *temA = [NSMutableArray array];
        for (CrowdfundingRecord *record in crowdfunding.records.listArray) {
            UIImageView *imageView = [[UIImageView alloc] init];
            [imageView setPlaceholderImageWithAvatarUrl:record.user.avatar];
            if (temA.count >= 9) {
                break;
            }
            [temA objectAddObject:imageView];
        }
        if (crowdfunding.records.listArray.count > 0) {
            UIImageView *canvasView = [[UIImageView alloc] init];
            self.canvasView = canvasView;
            canvasView.frame = self.AvatarView.bounds;
            canvasView.backgroundColor = [GJGCCommonFontColorStyle mainThemeColor];
            UIImageView *coverImage = [[StitchingImage alloc] stitchingOnImageView:canvasView withImageViews:temA marginValue:2.f];
            [self.AvatarView addSubview:coverImage];
        } else {
            // Remove all subspaces
            [[self.canvasView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
            self.AvatarView.image = [UIImage imageNamed:@"default_user_avatar"];
        }
        self.noteLabel.text = GJCFStringIsNull(crowdfunding.tips) ? nil : [NSString stringWithFormat:LMLocalizedString(@"Link Note", nil), crowdfunding.tips];
        self.groupInfoLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Common In", nil), crowdfunding.groupName];
        self.amountLabel.text = [NSString stringWithFormat:@"%@ ฿", [PayTool getBtcStringWithAmount:crowdfunding.total]];
        if (crowdfunding.status) {
            self.statusLabel.text = LMLocalizedString(@"Common Completed", nil);
            self.statusLabel.textColor = [UIColor greenColor];
        } else {
            self.statusLabel.text = LMLocalizedString(@"Chat Crowd founding in progress", nil);
            self.statusLabel.textColor = [UIColor grayColor];
        }
        // time handle
        NSTimeInterval second = crowdfunding.createdAt;
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:second];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"MM-dd HH:mm";
        NSString *res = [formatter stringFromDate:date];
        self.timeLabel.text = res;
    }
}

/**
 *  display header
 */
- (void)setMyselfImageViewWithString:(NSString *)userNameUrl {
    [self.AvatarView setPlaceholderImageWithAvatarUrl:userNameUrl];
}

/**
 * set nickName
 */
- (void)setNickNameWithString:(NSString *)nickName withReceived:(BOOL)isReceived {
    NSString *apedendString = nil;
    if (isReceived) {
        apedendString = LMLocalizedString(@"Wallet Received", nil);
    } else {
        apedendString = LMLocalizedString(@"Wallet Sent", nil);
    }
    nickName = [NSString stringWithFormat:@"%@ %@", nickName, apedendString];
    self.groupInfoLabel.text = nickName;

}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.canvasView.frame = self.AvatarView.bounds;
}

@end
