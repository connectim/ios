//
//  NCellTextFieldWithLabel.h
//  HashNest
//
//  Created by MoHuilin on 16/3/21.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseCell.h"

@interface NCellTextFieldWithLabel : BaseCell

@property (copy ,nonatomic) NSString *placeholder;

@property (copy ,nonatomic) NSString *titleName;

@property (copy ,nonatomic) void (^valueChangeBlock)(UITextField *textFiled,NSString *text);

@end
