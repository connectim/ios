//
//  LMTableHeaderView.m
//  Connect
//
//  Created by bitmain on 2017/1/10.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMTableHeaderView.h"

@interface LMTableHeaderView ()
@property(weak, nonatomic) IBOutlet UILabel *displayLble;


@end

@implementation LMTableHeaderView
- (void)awakeFromNib {
    [super awakeFromNib];
    self.displayLble.text = LMLocalizedString(@"Chat Create a new chat", nil);
    self.displayLble.font = [UIFont systemFontOfSize:FONT_SIZE(32)];
}

// button click Action
- (IBAction)buttonClick:(id)sender {
    if (self.buttonClickBlock) {
        self.buttonClickBlock();
    }
}
@end
