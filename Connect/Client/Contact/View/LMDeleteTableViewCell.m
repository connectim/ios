//
//  LMDeleteTableViewCell.m
//  Connect
//
//  Created by bitmain on 2016/12/20.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import "LMDeleteTableViewCell.h"


@interface LMDeleteTableViewCell ()

@property(weak, nonatomic) IBOutlet UIView *bottomView;


@end


@implementation LMDeleteTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.bottomView.layer.cornerRadius = 4;
    self.bottomView.layer.masksToBounds = YES;


}
@end
