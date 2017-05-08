//
//  NCellTextField.h
//  Connect
//
//  Created by MoHuilin on 16/7/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseCell.h"

@interface NCellTextField : BaseCell


@property (copy ,nonatomic) void (^TextValueChangeBlock)(UITextField *textFiled,NSString *text);

@property (nonatomic ,copy) NSString *placeholder;

@property (nonatomic ,copy) NSString *text;

@end
