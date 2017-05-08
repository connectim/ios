//
//  TextFieldRoundCell.m
//  Connect
//
//  Created by MoHuilin on 16/7/28.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "TextFieldRoundCell.h"

@interface TextFieldRoundCell () <UITextFieldDelegate>


@end

@implementation TextFieldRoundCell


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {

        UITextField *textField = [[UITextField alloc] init];
        self.textField = textField;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        [self.contentView addSubview:textField];
        textField.borderStyle = UITextBorderStyleRoundedRect;
        textField.frame = AUTO_RECT(25, 2, 700, 0);
        [self.textField addTarget:self action:@selector(textFiledValueChange) forControlEvents:UIControlEventEditingChanged];
        self.textField.delegate = self;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.keepString = @"";

        self.selectionStyle = UITableViewCellSelectionStyleNone;

    }
    return self;
}

- (void)dealloc {
    RemoveNofify;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    self.textField.height = self.height;
}

- (void)textFiledValueChange {

    int length = [self convertToInt:self.textField.text];

    if (length < [self convertToInt:self.keepString]) {
        self.textField.text = self.keepString;
    }


    self.TextValueChangeBlock ? self.TextValueChangeBlock(self.textField, self.textField.text) : nil;
}

/**
 *   Judge the length of the string of mixed Chinese and English
 */
- (int)convertToInt:(NSString *)strtemp {
    int strlength = 0;
    for (int i = 0; i < [strtemp length]; i++) {
        int a = [strtemp characterAtIndex:i];
        if (a > 0x4e00 && a < 0x9fff) {
            strlength += 2;
        }
    }
    return strlength;
}


- (void)setPlaceholder:(NSString *)placeholder {
    _placeholder = placeholder;
    self.textField.placeholder = placeholder;
}

- (void)setText:(NSString *)text {
    _text = text;

    _textField.text = text;
}

// can not chinese
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (self.sourceType == SourceTypeSetChnagePass && self.type == 2) {
        if ([string isEqualToString:@""] || string.length <= 0) {
            return YES;
        } else {
            return [RegexKit isNotChinsesWithUrl:string];
        }
    }
    return YES;
}
@end
