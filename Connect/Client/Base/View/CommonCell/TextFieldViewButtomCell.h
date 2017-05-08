//
//  TextFieldViewButtomCell.h
//  Connect
//
//  Created by MoHuilin on 2016/12/13.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import "BaseCell.h"
typedef NS_ENUM(NSUInteger,SourceType){
     SourceTypeCommon = 1 << 0,
     SourceTypeSet =    1 << 1
};
@interface TextFieldViewButtomCell : BaseCell


@property (copy ,nonatomic) void (^TextValueChangeBlock)(UITextField *textFiled,NSString *text);

@property (copy ,nonatomic) void (^ButtonTapBlock)();

@property (nonatomic ,copy) NSString *placeholder;

@property (nonatomic ,copy) NSString *text;

- (void)setButtonTitle:(NSString *)title;

@property (strong ,nonatomic) UIButton *actonButton;
@property (strong ,nonatomic) UITextField *textFiled;

@property (assign, nonatomic) SourceType sourceType;


@end
