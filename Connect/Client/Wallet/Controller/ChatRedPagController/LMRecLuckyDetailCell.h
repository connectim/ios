//
//  LMRecLuckyDetailCell.h
//  Connect
//
//  Created by Qingxu Kuang on 16/7/30.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LMRecLuckyDetailCell : UITableViewCell
@property(weak, nonatomic) IBOutlet UIImageView *icon;
@property(weak, nonatomic) IBOutlet UILabel *nameLabel;
@property(weak, nonatomic) IBOutlet UILabel *moneyValueLabel;
@property(weak, nonatomic) IBOutlet UILabel *dateLabel;
@property(weak, nonatomic) IBOutlet UIButton *winerTipView;

@end
