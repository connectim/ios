//
//  LMTableViewCell.h
//  Connect
//
//  Created by Edwin on 16/7/16.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMUserInfo.h"

@interface LMTableViewCell : UITableViewCell

- (void)setUserInfo:(LMUserInfo *)model;
@end
