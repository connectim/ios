//
//  SyscContactCell.m
//  Connect
//
//  Created by MoHuilin on 16/7/29.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "SyscContactCell.h"

@interface SyscContactCell ()
@property(weak, nonatomic) IBOutlet UILabel *titleLabel;
@property(weak, nonatomic) IBOutlet UIImageView *imageLabel;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *tilleLableLeftConstraton;

@end

@implementation SyscContactCell


- (void)awakeFromNib {
    [super awakeFromNib];

    [self setup];
    self.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(32)];
    self.tilleLableLeftConstraton.constant = AUTO_WIDTH(20);
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setup];

    }

    return self;
}

- (void)setup {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(syscContact)];

    self.imageLabel.userInteractionEnabled = YES;
    [self.imageLabel addGestureRecognizer:tap];

}

- (void)syscContact {
    CABasicAnimation *rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat:M_PI * 2.0];
    rotationAnimation.duration = 0.5;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = MAXFLOAT;
    [self.imageLabel.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];

    [GCDQueue executeInBackgroundPriorityGlobalQueue:^{
        if (self.SyscContactBlock) {
            int long long comleteTime = self.SyscContactBlock();
            [GCDQueue executeInMainQueue:^{
                [self.imageLabel.layer removeAllAnimations];
                if (comleteTime > 0) {
                    NSDate *date = [NSDate dateWithTimeIntervalSince1970:comleteTime];
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];

                    // Zzz that time zone, zzz can be deleted, so that the date characters will not return the time zone information +0000.

                    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];

                    NSString *destDateString = [dateFormatter stringFromDate:date];

                    self.titleLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Set Updated time", nil), destDateString];

                }
            }];
        }
    }];
}

- (void)setData:(id)data {
    [super setData:data];

    CellItem *item = (CellItem *) data;

    _imageLabel.image = [UIImage imageNamed:item.icon];
    NSTimeInterval lastTime = [[MMAppSetting sharedSetting] getLastSyncContactTime];
    if (lastTime) {
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:lastTime];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];

        // Zzz that time zone, zzz can be deleted, so that the date characters will not return the time zone information +0000.

        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];

        NSString *destDateString = [dateFormatter stringFromDate:date];

        self.titleLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Set Updated time", nil), destDateString];
    } else {
        self.titleLabel.text = LMLocalizedString(@"Set Not synchronized", nil);
    }
}

- (void)dealloc {
    [self.imageLabel.layer removeAllAnimations];
}

@end
