//
//  LMTableViewCell.m
//  Connect
//
//  Created by Edwin on 16/7/16.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMTableViewCell.h"
#import "StitchingImage.h"

#define borderSpen AUTO_WIDTH(15)

@interface LMTableViewCell ()

@property(weak, nonatomic) IBOutlet UIImageView *iconImageView;

@property(weak, nonatomic) IBOutlet UILabel *nameLabel;

@property(weak, nonatomic) IBOutlet UILabel *timeLabel;

@property(weak, nonatomic) IBOutlet UILabel *bitMoneyLabel;

@property(weak, nonatomic) IBOutlet UILabel *sureLabel;
@end

@implementation LMTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.layer.cornerRadius = 7;
    self.layer.borderWidth = 0.7;
    self.layer.borderColor = GJCFQuickHexColor(@"efeff4").CGColor;
    self.layer.masksToBounds = YES;
    self.backgroundColor = [UIColor colorWithHexString:@"ffffff"];
    self.contentView.backgroundColor = [UIColor colorWithHexString:@"ffffff"];
    self.iconImageView.layer.cornerRadius = 5;
    self.iconImageView.layer.masksToBounds = YES;
    self.timeLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.bitMoneyLabel.font = [UIFont systemFontOfSize:FONT_SIZE(36)];
    self.nameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    self.nameLabel.textColor = [UIColor blackColor];
    self.nameLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
}

/**
 *  Intercept frame settings
 */
- (void)setFrame:(CGRect)frame {
    frame.origin.y += borderSpen;
    frame.origin.x = borderSpen;
    frame.size.width -= 2 * borderSpen;
    frame.size.height -= borderSpen;
    [super setFrame:frame];
}


- (void)setUserInfo:(LMUserInfo *)model {
    if (model) {
        switch (model.txType) {
            case 1: // Ordinary transfer receipt
            case 2: // All the chips
            {
                if (model.imageUrls.count > 1) {
                    UIImageView *canvasView = [[UIImageView alloc] init];
                    canvasView.frame = self.iconImageView.bounds;
                    canvasView.backgroundColor = [GJGCCommonFontColorStyle mainThemeColor];
                    NSMutableArray *temA = [NSMutableArray array];
                    for (NSString *avatarUrl in model.imageUrls) {
                        UIImageView *imageView = [[UIImageView alloc] init];
                        [imageView setPlaceholderImageWithAvatarUrl:avatarUrl];
                        if (temA.count >= 9) {
                            break;
                        }
                        [temA objectAddObject:imageView];
                    }
                    UIImageView *coverImage = [[StitchingImage alloc] stitchingOnImageView:canvasView withImageViews:temA marginValue:2.f];
                    [self.iconImageView addSubview:coverImage];
                } else {
                    [self.iconImageView setPlaceholderImageWithAvatarUrl:model.imageUrl];
                }
                [self.iconImageView setPlaceholderImageWithAvatarUrl:model.imageUrl];
            }
                break;
            case 3:
            case 4:
            case 5: {
                self.iconImageView.image = [UIImage imageNamed:@"luckpacket_record"];
            }
                break;
            case 7: // System red envelopes
            {
                self.iconImageView.image = [UIImage imageNamed:@"luckpacket_record"];
            }
                break;
            case 6: {
                self.iconImageView.image = [UIImage imageNamed:@"bitcoin_luckybag"];
            }
                break;
            default:
                [self.iconImageView setPlaceholderImageWithAvatarUrl:model.imageUrl];
                break;
        }
        if (model.txType == 7) {
            self.nameLabel.text = LMLocalizedString(@"Wallet From Connect team", nil);
        } else {
            self.nameLabel.text = model.userName;
        }
        self.sureLabel.text = model.confirmation ? LMLocalizedString(@"Wallet Confirmed", nil) : LMLocalizedString(@"Wallet Unconfirmed", nil);

        if (model.confirmation) {
            self.sureLabel.textColor = [UIColor colorWithWhite:0.702 alpha:1.000];
        } else {
            self.sureLabel.textColor = [UIColor redColor];
        }

        // Time processing
        NSTimeInterval second = model.createdAt.longLongValue;
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:second];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"MM-dd HH:mm";
        NSString *res = [formatter stringFromDate:date];
        self.timeLabel.text = res;

        // Judgment positive or negative confirmation or not confirmed
        if (model.balance > 0) {
            NSString *attrString = [NSString stringWithFormat:@"+%@ ฿", [PayTool getBtcStringWithAmount:model.balance]];
            // Rich text text highlighted
            NSMutableAttributedString *AttributedStr = [[NSMutableAttributedString alloc] initWithString:attrString];
            [AttributedStr addAttribute:NSForegroundColorAttributeName

                                  value:[UIColor blackColor]

                                  range:NSMakeRange(attrString.length - 1, 1)];

            UIFont *font = [UIFont boldSystemFontOfSize:FONT_SIZE(36)];
            [AttributedStr addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, attrString.length)];

            [AttributedStr addAttribute:NSForegroundColorAttributeName value:GJCFQuickHexColor(@"00C400") range:NSMakeRange(0, attrString.length - 1)];

            self.bitMoneyLabel.attributedText = AttributedStr;
        } else {
            NSString *attrString = [NSString stringWithFormat:@"%@ ฿", [PayTool getBtcStringWithAmount:model.balance]];
            // Rich text text highlighted
            NSMutableAttributedString *AttributedStr = [[NSMutableAttributedString alloc] initWithString:attrString];
            [AttributedStr addAttribute:NSForegroundColorAttributeName

                                  value:[UIColor blackColor]

                                  range:NSMakeRange(attrString.length - 1, 1)];
            UIFont *font = [UIFont boldSystemFontOfSize:FONT_SIZE(36)];
            [AttributedStr addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, attrString.length)];

            [AttributedStr addAttribute:NSForegroundColorAttributeName value:GJCFQuickHexColor(@"FF6C5A") range:NSMakeRange(0, attrString.length - 1)];

            self.bitMoneyLabel.attributedText = AttributedStr;
        }
    }
}

@end
