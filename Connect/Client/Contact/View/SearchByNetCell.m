//
//  SearchByNetCell.m
//  Connect
//
//  Created by MoHuilin on 16/5/25.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "SearchByNetCell.h"

@interface SearchByNetCell ()
@property (weak, nonatomic) IBOutlet UILabel *searchTextLabel;

@property (weak, nonatomic) IBOutlet UILabel *searchTitleLabel;

@end

@implementation SearchByNetCell

- (void)drawRect:(CGRect)rect {
    
    CGContextRef context =UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    
    CGContextFillRect(context, rect);
    
    // bottom line
    UIColor *lineColor = [UIColor colorWithHex:0xf0f0f6];
    CGContextSetStrokeColorWithColor(context,lineColor.CGColor);
    
    CGFloat height = AUTO_HEIGHT(0.4);
    CGContextStrokeRect(context,CGRectMake(0, rect.size.height-height, rect.size.width,height));
    
}
    
- (void)awakeFromNib{
    [super awakeFromNib];
    self.searchTitleLabel.text = LMLocalizedString(@"Link Through the network search", nil);
}

- (void)setData:(id)data{
    [super setData:data];
    _searchTextLabel.text = data;
}

@end
