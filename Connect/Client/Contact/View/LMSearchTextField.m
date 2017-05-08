//
//  LMSearchTextField.m
//  Connect
//
//  Created by Connect on 2017/3/24.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMSearchTextField.h"

@implementation LMSearchTextField

 //placeholder position
- (CGRect)textRectForBounds:(CGRect)bounds {
    
    CGRect tem = [super textRectForBounds:bounds];
    tem.origin.x += 15;
    return tem;
}

// text position
- (CGRect)editingRectForBounds:(CGRect)bounds {
    CGRect tem = [super textRectForBounds:bounds];
    tem.origin.x += 0;
    return tem;
}

- (void)disPLayPlaceHolder:(NSString *)name {
    NSMutableAttributedString *placeholder = [[NSMutableAttributedString alloc] initWithString:name];
    [placeholder addAttribute:NSForegroundColorAttributeName
                        value:GJCFQuickHexColor(@"B3B5BC")
                        range:NSMakeRange(0, name.length)];
    [placeholder addAttribute:NSFontAttributeName
                        value:[UIFont systemFontOfSize:FONT_SIZE(28)]
                        range:NSMakeRange(0, name.length)];
    self.attributedPlaceholder = placeholder;
    self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    
}

// set placeholder center
- (void)setVerPlaceHolderWithName:(NSString *)poaceHolderName {
    NSMutableParagraphStyle *style = [self.defaultTextAttributes[NSParagraphStyleAttributeName] mutableCopy];
    
    style.minimumLineHeight = self.font.lineHeight - (self.font.lineHeight - [UIFont systemFontOfSize:FONT_SIZE(28)].lineHeight) / 2.0;
    
    self.attributedPlaceholder = [[NSAttributedString alloc] initWithString:poaceHolderName
                                  
                                                                 attributes:@{
                                                                              NSForegroundColorAttributeName: GJCFQuickHexColor(@"B3B5BC"),
                                                                              
                                                                              NSFontAttributeName: [UIFont systemFontOfSize:FONT_SIZE(28)],
                                                                              
                                                                              NSParagraphStyleAttributeName: style
                                                                              
                                                                              }
                                  
                                  ];
    
}
- (CGRect)leftViewRectForBounds:(CGRect)bounds{
    CGRect leftBounds = CGRectMake(bounds.origin.x + 11, 8.5, 13, 13);
    return leftBounds;
}
@end
