//
//  BaseSwipeCell.m
//  Connect
//
//  Created by MoHuilin on 16/5/23.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseSwipeCell.h"

@implementation BaseSwipeCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.layoutMargins = UIEdgeInsetsZero;
    self.separatorInset = UIEdgeInsetsZero;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.layoutMargins = UIEdgeInsetsZero;
        self.separatorInset = UIEdgeInsetsZero;
    }
    return self;
}



@end
