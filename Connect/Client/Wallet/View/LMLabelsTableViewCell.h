//
//  LMLabelsTableViewCell.h
//  Connect
//
//  Created by Edwin on 16/8/31.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMLabels.h"

@class LMLabelsTableViewCell;

@protocol LMLabelsTableViewCellDelegate <NSObject>

- (void)LMLabelsTableViewCell:(LMLabelsTableViewCell *)cell SelectedBtnClick:(UIButton *)btn;
@end

@interface LMLabelsTableViewCell : UITableViewCell
@property(nonatomic, strong) id <LMLabelsTableViewCellDelegate> delegate;
@property(weak, nonatomic) IBOutlet UIButton *selectBtn;

- (void)setLabels:(LMLabels *)labels;
@end
