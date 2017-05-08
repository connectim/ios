//
//  NCellTextField.m
//  Connect
//
//  Created by MoHuilin on 16/7/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "NCellTextField.h"

@interface NCellTextField ()

@property (strong ,nonatomic) UITextField *textFiled;

@end

@implementation NCellTextField


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.textFiled = [[UITextField alloc] init];
        
        [self.textFiled addTarget:self action:@selector(textFiledValueChange) forControlEvents:UIControlEventEditingChanged];
        
        _textFiled.borderStyle = UITextBorderStyleNone;
        [self.contentView addSubview:self.textFiled];
        
        _textFiled.clearButtonMode = UITextFieldViewModeWhileEditing;
        
        _textFiled.top = 0;
        _textFiled.left = 15;
        _textFiled.width = DEVICE_SIZE.width - 30;
        _textFiled.height = 55;
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)textFiledValueChange{
    self.TextValueChangeBlock?self.TextValueChangeBlock(self.textFiled,self.textFiled.text):nil;
}


- (void)setPlaceholder:(NSString *)placeholder{
    _placeholder = placeholder;
    self.textFiled.placeholder = placeholder;
}

- (void)setText:(NSString *)text{
    _text = text;
    
    _textFiled.text = text;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
//    _textFiled.height = self.height;
}

@end
