//
//  TopImageBottomTitleButton.m
//  Connect
//
//  Created by MoHuilin on 16/5/26.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "TopImageBottomTitleButton.h"
#import "NSString+Size.h"

@implementation TopImageBottomTitleButton

-(void)layoutSubviews {
    [super layoutSubviews];
    //image
    CGFloat y = (self.height - self.imageView.height - self.titleLabel.height) / 2;
    self.imageView.frame = CGRectMake(truncf((self.width - self.imageView.width) / 2), y, self.imageView.width, self.imageView.height);
    
    //title
    self.titleLabel.numberOfLines = 1;
    CGSize titleSize = [self.titleLabel.text sizeWithFont:self.titleLabel.font constrainedToHeight:self.titleLabel.height];
    CGFloat titleW = titleSize.width;
    if (titleW > self.width * 0.9) {
        titleW = self.width * 0.9;
    }
    self.titleLabel.frame = CGRectMake(truncf((self.width - titleW) / 2), self.imageView.bottom, titleW, titleSize.height);
}

@end
