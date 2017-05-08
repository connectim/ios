//
//  PaddingTextField.m
//  Connect
//
//  Created by MoHuilin on 16/8/4.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "PaddingTextField.h"

@implementation PaddingTextField

// placeholder position
- (CGRect)textRectForBounds:(CGRect)bounds {

    CGRect tem = [super textRectForBounds:bounds];
    tem.origin.x += 10;
    return tem;
}

// text position
- (CGRect)editingRectForBounds:(CGRect)bounds {
    CGRect tem = [super textRectForBounds:bounds];
    tem.origin.x += 10;
    return tem;
}

- (void)disPLayPlaceHolder:(NSString *)name {
    NSMutableAttributedString *placeholder = [[NSMutableAttributedString alloc] initWithString:name];
    [placeholder addAttribute:NSForegroundColorAttributeName
                        value:LMBasicMiddleGray
                        range:NSMakeRange(0, name.length)];
    [placeholder addAttribute:NSFontAttributeName
                        value:[UIFont systemFontOfSize:FONT_SIZE(28)]
                        range:NSMakeRange(0, name.length)];
    self.attributedPlaceholder = placeholder;
    self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;

}

// Set the placeholder to display
- (void)setVerPlaceHolderWithName:(NSString *)poaceHolderName {
    NSMutableParagraphStyle *style = [self.defaultTextAttributes[NSParagraphStyleAttributeName] mutableCopy];

    style.minimumLineHeight = self.font.lineHeight - (self.font.lineHeight - [UIFont systemFontOfSize:FONT_SIZE(28)].lineHeight) / 2.0;

    self.attributedPlaceholder = [[NSAttributedString alloc] initWithString:poaceHolderName

                                                                 attributes:@{
                                                                         NSForegroundColorAttributeName: LMBasicMiddleGray,

                                                                         NSFontAttributeName: [UIFont systemFontOfSize:FONT_SIZE(28)],

                                                                         NSParagraphStyleAttributeName: style

                                                                 }

    ];

}

- (CGRect)leftViewRectForBounds:(CGRect)bounds {
    CGRect leftBounds = CGRectMake(bounds.origin.x + 15, 8.5, 13, 13);
    return leftBounds;
}

@end
