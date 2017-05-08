//
//  LMGroupVerifyOtherTableViewCell.m
//  Connect
//
//  Created by bitmain on 2016/12/28.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import "LMGroupVerifyOtherTableViewCell.h"


@interface LMGroupVerifyOtherTableViewCell ()

@property(weak, nonatomic) IBOutlet UILabel *nameLable;
@property(weak, nonatomic) IBOutlet UILabel *contentLable;
@property(weak, nonatomic) IBOutlet UIImageView *headImageView;


@end


@implementation LMGroupVerifyOtherTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.contentLable.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
    self.nameLable.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
}

- (void)setModel:(LMOtherModel *)model {
    self.nameLable.text = model.userName;
    self.contentLable.text = model.contentName;
    if (self.contentLable.text.length <= 0) {
        self.contentLable.text = LMLocalizedString(@"Link apply to join group", nil);
    }
    [self.headImageView setPlaceholderImageWithAvatarUrl:model.headImageViewUrl];

}

@end
