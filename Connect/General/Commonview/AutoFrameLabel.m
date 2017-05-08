//
//  AutoFrameLabel.m
//  Connect
//
//  Created by Edwin on 16/8/15.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "AutoFrameLabel.h"

@implementation AutoFrameLabel

-(instancetype)creatLabelWithContentStr:(NSString *)str withFontOfSize:(CGFloat)fontsize {
    if (self == [super init]) {
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectZero];
        [label setNumberOfLines:0];
        UIFont *font = [UIFont systemFontOfSize:fontsize];
        CGSize size = CGSizeMake(VSIZE.width, MAXFLOAT);
        CGSize labelsize = [str sizeWithFont:font constrainedToSize:size lineBreakMode:UILineBreakModeWordWrap];
        label.frame = CGRectMake(0.0, 0.0, labelsize.width, labelsize.height );
        label.backgroundColor = [UIColor purpleColor];
        label.textColor = [UIColor blackColor];
        label.text = str;
    }
    return self;
}
@end
