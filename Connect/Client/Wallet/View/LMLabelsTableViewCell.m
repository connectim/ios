//
//  LMLabelsTableViewCell.m
//  Connect
//
//  Created by Edwin on 16/8/31.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMLabelsTableViewCell.h"

#define LabelsTag 1000

@interface LMLabelsTableViewCell ()


@property(weak, nonatomic) IBOutlet UILabel *label;
@property(nonatomic, strong) IBOutletCollection(UILabel) NSArray *usernameLabels;

@end

@implementation LMLabelsTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.selectBtn.layer.cornerRadius = CGRectGetWidth(self.selectBtn.frame) / 2;
    self.selectBtn.layer.masksToBounds = YES;
    [self.selectBtn setBackgroundImage:[UIImage imageNamed:@"unselect"] forState:UIControlStateNormal];
    [self.selectBtn setBackgroundImage:[UIImage imageNamed:@"selected"] forState:UIControlStateSelected];
}

- (void)setLabels:(LMLabels *)labels {
    if (labels) {
        self.label.text = labels.label;
        if (self.usernameLabels.count > labels.info.count) {
            for (int i = 0; i < labels.info.count; i++) {
                UILabel *label = self.usernameLabels[i];
                AccountInfo *info = labels.info[i];
                label.text = info.username;
            }
        } else {
            for (int i = 0; i < self.usernameLabels.count; i++) {
                UILabel *label = self.usernameLabels[i];
                AccountInfo *info = labels.info[i];
                label.text = info.username;
                label.lineBreakMode = NSLineBreakByTruncatingTail;
            }
        }

    }

}

- (IBAction)selectBtnClick:(id)sender {
    if (sender == self.selectBtn) {
        [self.delegate LMLabelsTableViewCell:self SelectedBtnClick:sender];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
