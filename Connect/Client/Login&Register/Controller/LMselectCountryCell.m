//
//  LMselectCountryCell.m
//  Connect
//
//  Created by bitmain on 2016/12/10.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import "LMselectCountryCell.h"

@implementation LMselectCountryCell

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self creatLable];
    }
    return self;

}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self creatLable];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self creatLable];
    }
    return self;
}

- (void)creatLable {
    if (self.disPlayLable == nil) {
        self.disPlayLable = [[UILabel alloc] initWithFrame:CGRectMake(AUTO_WIDTH(30), AUTO_HEIGHT(70) / 2.0, DEVICE_SIZE.width - AUTO_WIDTH(30) * 2, AUTO_HEIGHT(30))];
        self.disPlayLable.textColor = LMBasicBlack;
        self.disPlayLable.textAlignment = NSTextAlignmentLeft;
        self.disPlayLable.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
        [self.contentView addSubview:self.disPlayLable];
    }
}
@end
