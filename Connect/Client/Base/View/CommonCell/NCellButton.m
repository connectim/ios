//
//  NCellButton.m
//  Connect
//
//  Created by MoHuilin on 16/7/21.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "NCellButton.h"

@interface NCellButton ()

@property (nonatomic ,strong) UIButton *button;

@end

@implementation NCellButton

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.button = [[UIButton alloc] init];
        
        [self.button setTitle:@"Logout" forState:UIControlStateNormal];
        [self.button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        [self.button setBackgroundColor:[UIColor blackColor]];
        self.button.layer.cornerRadius = 5;
        self.button.layer.masksToBounds = YES;
        
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        
        self.button.left = 15;
        self.button.width = DEVICE_SIZE.width - 30;
        self.button.top = 0;
        self.button.height = AUTO_HEIGHT(100);
        
        self.button.userInteractionEnabled = NO;
        
        [self.contentView addSubview:self.button];
        
        self.separatorInset = UIEdgeInsetsMake(0.f, DEVICE_SIZE.width, 0.f, 0.f);
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
    }
    
    return self;
}

- (void)setData:(id)data{
    [super setData:data];
    
    
    CellItem *item = (CellItem *)data;
    
    [self.button setTitle:item.title forState:UIControlStateNormal];
    
    [self.button setBackgroundColor:item.buttonBackgroudColor];
}

@end
