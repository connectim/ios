//
//  LMVerifyTableHeadView.m
//  Connect
//
//  Created by bitmain on 2017/2/27.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMVerifyTableHeadView.h"

@interface LMVerifyTableHeadView ()

@property(weak, nonatomic) IBOutlet UIView *bottomLine;

@end

@implementation LMVerifyTableHeadView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = LMBasicBackgroudGray;

    self.groupSummaryLable.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.groupMemberLable.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
    self.groupNameLable.font = [UIFont systemFontOfSize:FONT_SIZE(28)];

    self.groupMemberLable.textColor = LMBasicLableColor;
    self.groupSummaryLable.textColor = LMBasicLableColor;
    self.bottomLine.backgroundColor = LMBasicMiddleGray;

}
@end
