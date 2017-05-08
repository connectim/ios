//
//  RedPacketHistoryCell.m
//  Connect
//
//  Created by MoHuilin on 2016/11/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "RedPacketHistoryCell.h"
#import "Protofile.pbobjc.h"

@interface RedPacketHistoryCell ()
@property(weak, nonatomic) IBOutlet UILabel *typeName;
@property(weak, nonatomic) IBOutlet UILabel *createAtLabel;
@property(weak, nonatomic) IBOutlet UILabel *amountLabel;
@property(weak, nonatomic) IBOutlet UILabel *statusLabel;

@end

@implementation RedPacketHistoryCell

- (void)awakeFromNib {
    [super awakeFromNib];

    self.backgroundColor = GJCFQuickHexColor(@"FFFAF7");
    self.typeName.font = [UIFont boldSystemFontOfSize:FONT_SIZE(30)];
    self.amountLabel.font = [UIFont boldSystemFontOfSize:FONT_SIZE(30)];

    self.createAtLabel.font = [UIFont boldSystemFontOfSize:FONT_SIZE(25)];
    self.statusLabel.font = [UIFont boldSystemFontOfSize:FONT_SIZE(25)];
    self.createAtLabel.textColor = GJCFQuickHexColor(@"B8B4B0");
    self.statusLabel.textColor = GJCFQuickHexColor(@"B8B4B0");
}

- (void)setData:(id)data {
    [super setData:data];

    RedPackage *redPackge = (RedPackage *) data;

    if (redPackge.typ == 1) { // out packet
        self.typeName.text = LMLocalizedString(@"Wallet Sent via link", nil);
    } else {
        if (redPackge.category == 0) { // single
            self.typeName.text = LMLocalizedString(@"Wallet Sent to friend", nil);
        } else { // group packet
            self.typeName.text = LMLocalizedString(@"Wallet Sent to group", nil);
        }
    }

    // time detail
    NSTimeInterval second = redPackge.createdAt;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:second];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"MM-dd HH:mm";
    NSString *res = [formatter stringFromDate:date];
    self.createAtLabel.text = res;

    // money
    self.amountLabel.text = [NSString stringWithFormat:@"%@ ฿", [PayTool getBtcStringWithAmount:redPackge.money]];

    // status 
    if (redPackge.remainSize == 0) {
        self.statusLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Opened", nil), redPackge.size, redPackge.size];
    } else if (redPackge.expired) {
        self.statusLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Chat Expired", nil), redPackge.size - redPackge.remainSize, redPackge.size];
    } else {
        self.statusLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Opened", nil), redPackge.size - redPackge.remainSize, redPackge.size];
    }
}
@end
