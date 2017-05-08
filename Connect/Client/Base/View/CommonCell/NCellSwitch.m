//
//  NCellSwitch.m
//  HashNest
//
//  Created by MoHuilin on 16/3/16.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "NCellSwitch.h"

@interface NCellSwitch ()

@property (strong ,nonnull) UISwitch *customSwitch;

@end

@implementation NCellSwitch

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.customSwitch = [[UISwitch alloc] init];
        
        [self.customSwitch addTarget:self action:@selector(doSwitch:) forControlEvents:UIControlEventValueChanged];
        
        self.accessoryView = self.customSwitch;
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        //自定义的lable的创建
        self.customLable = [UILabel new];
        [self.contentView addSubview:self.customLable];
        self.customLable.font = [UIFont systemFontOfSize:FONT_SIZE(32)];
        self.customLable.textAlignment = NSTextAlignmentLeft;
        [ self.customLable mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(AUTO_WIDTH(30));
            make.centerY.equalTo(self.contentView);
            make.right.mas_equalTo(self.contentView).mas_offset(-10);
        }];
    }
    return self;
}

- (void)setSwitchIsOn:(BOOL)switchIsOn{
    _switchIsOn = switchIsOn;
    [self.customSwitch setOn:switchIsOn animated:YES];
}


- (void)doSwitch:(UISwitch *)sender
{
    self.SwitchValueChangeCallBackBlock?self.SwitchValueChangeCallBackBlock(self.customSwitch.on):nil;
}
@end
