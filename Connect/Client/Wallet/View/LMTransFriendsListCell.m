//
//  LMTransFriendsListCell.m
//  Connect
//
//  Created by Qingxu Kuang on 16/8/24.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMTransFriendsListCell.h"

@implementation LMTransFriendsListCell

- (void)awakeFromNib {
    [super awakeFromNib];

    self.nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.nameLabel.numberOfLines = 1;
}

@end
