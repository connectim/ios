//
//  TextFieldRoundCell.h
//  Connect
//
//  Created by MoHuilin on 16/7/28.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseCell.h"

typedef NS_ENUM(NSUInteger, SourceType) {

    SourceTypeCommon = 1 << 0,
    SourceTypeSetChnagePass = 1 << 1
};


@interface TextFieldRoundCell : BaseCell

@property(copy, nonatomic) void (^TextValueChangeBlock)(UITextField *textFiled, NSString *text);

@property(nonatomic, copy) NSString *placeholder;

@property(nonatomic, copy) NSString *text;

@property(nonatomic, strong) UITextField *textField;
// Protected head characters can not be deleted
@property(nonatomic, strong) NSString *keepString;
// Type, according to this limit input length
@property(nonatomic, assign) int type;
// sourcetype
@property(nonatomic, assign) NSUInteger sourceType;


@end
