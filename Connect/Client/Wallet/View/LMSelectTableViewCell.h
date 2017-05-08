//
//  LMSelectTableViewCell.h
//  Connect
//
//  Created by Edwin on 16/7/19.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AccountInfo.h"
#import "BEMCheckBox.h"


@interface LMSelectTableViewCell : UITableViewCell
- (void)setAccoutInfo:(AccountInfo *)info;

@property(weak, nonatomic) IBOutlet BEMCheckBox *checkBox;

@end
