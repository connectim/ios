//
//  NCellImageValue1.m
//  Connect
//
//  Created by MoHuilin on 16/7/21.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "NCellImageValue1.h"
#import "CellItem.h"

@interface NCellImageValue1 ()
@property (weak, nonatomic) IBOutlet UILabel *customTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *customSubTitleLabel;

@property (weak, nonatomic) IBOutlet UIImageView *CustomIconImageView;

@end

@implementation NCellImageValue1

- (void)awakeFromNib{
    [super awakeFromNib];
    
    _CustomIconImageView.contentMode = UIViewContentModeCenter;
    _customSubTitleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
}

- (void)setData:(id)data{
    [super setData:data];
    
    CellItem *item = (CellItem *)data;
    
    _customTitleLabel.text = item.title;
    
    _customSubTitleLabel.text = item.subTitle;
    
    _CustomIconImageView.image = [UIImage imageNamed:item.icon];
}

@end
