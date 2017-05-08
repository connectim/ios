//
//  TextFieldViewButtomCell.m
//  Connect
//
//  Created by MoHuilin on 2016/12/13.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import "TextFieldViewButtomCell.h"

@interface TextFieldViewButtomCell ()<UITextFieldDelegate>





@end

@implementation TextFieldViewButtomCell


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.textFiled = [[UITextField alloc] init];
        self.textFiled.delegate = self;
        [self.textFiled addTarget:self action:@selector(textFiledValueChange) forControlEvents:UIControlEventEditingChanged];
        
        _textFiled.borderStyle = UITextBorderStyleNone;
        
        _textFiled.clearButtonMode = UITextFieldViewModeWhileEditing;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [self.contentView addSubview:self.textFiled];
        
        [_textFiled mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self.contentView);
            make.left.equalTo(self.contentView).offset(AUTO_WIDTH(30));
        }];
        
        UIView *line = [UIView new];
        line.backgroundColor = [UIColor blackColor];
        line.alpha = 0.3;
        [self.contentView addSubview:line];
        
        [line mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.textFiled.mas_right);
            make.width.mas_equalTo(0.5);
            make.height.equalTo(self.textFiled.mas_height).multipliedBy(0.7);
            make.centerY.equalTo(self.contentView);
        }];
        
        self.actonButton = [[UIButton alloc] init];
        [self.actonButton setTitleColor:LMBasicBlue forState:UIControlStateNormal];
        [self.actonButton setTitleColor:LMBasicDarkGray forState:UIControlStateDisabled];
        self.actonButton.enabled = NO;
        [self.actonButton addTarget:self action:@selector(buttonTap) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.actonButton];
        
        [_actonButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.right.equalTo(self.contentView);
            make.width.mas_equalTo(AUTO_WIDTH(140));
            make.left.equalTo(line.mas_right);
        }];
        
    }
    return self;
}

- (void)buttonTap{
    if (self.ButtonTapBlock) {
        self.ButtonTapBlock();
    }
}

- (void)textFiledValueChange{
    if (self.sourceType == SourceTypeSet) {
        NSString* temStr = self.textFiled.text;
        if ([self.textFiled.text containsString:@"฿"]) {
           temStr = [temStr stringByReplacingOccurrencesOfString:@"฿" withString:@""];
        }
        self.actonButton.enabled = [temStr doubleValue] > 0;
    }
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

- (void)setButtonTitle:(NSString *)title{
    [self.actonButton setTitle:title forState:UIControlStateNormal];
}
#pragma mark - delegate 
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (self.sourceType == SourceTypeSet) {
        if ([string isEqualToString:@""]) {
            return YES;
        }
        if ([textField.text containsString:@"."]) {
            if ([[textField.text componentsSeparatedByString:@"."] lastObject].length >=8) {
                return NO;
            }
        }
    }
    return YES;
}

@end
