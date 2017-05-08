//
//  NCellTextFieldWithLabel.m
//  HashNest
//
//  Created by MoHuilin on 16/3/21.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "NCellTextFieldWithLabel.h"
#import "UIView+Frame.h"

@interface NCellTextFieldWithLabel ()
{
    UIView *line;
}
@property (strong ,nonatomic) UITextField *textFiled;
@property (strong ,nonatomic) UILabel *nameLabel;

@end

@implementation NCellTextFieldWithLabel

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.textFiled = [[UITextField alloc] init];
        
        [self.textFiled addTarget:self action:@selector(textFiledValueChange) forControlEvents:UIControlEventEditingChanged];
        
        _textFiled.borderStyle = UITextBorderStyleNone;
        [self.contentView addSubview:self.textFiled];
        
        self.nameLabel = [[UILabel alloc] init];
        [self.contentView addSubview:self.nameLabel];
        self.nameLabel.textAlignment = NSTextAlignmentRight;
        
        line = [UIView new];
        [self.contentView addSubview:line];
        line.backgroundColor = [UIColor blackColor];
        line.frame = CGRectMake(0, 0, DEVICE_SIZE.width, .5f);
        line.alpha = .2f;
    }
    return self;
}

- (void)textFiledValueChange{
    self.valueChangeBlock?self.valueChangeBlock(self.textFiled,self.textFiled.text):nil;
}



- (void)setTitleName:(NSString *)titleName{
    _titleName = titleName;
    self.nameLabel.text = titleName;
}

- (void)setPlaceholder:(NSString *)placeholder{
    _placeholder = placeholder;
    self.textFiled.placeholder = placeholder;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    line.top = self.height - .5f;
    
    self.textFiled.frame = CGRectMake(100 + 30, 0, self.width - 100 - 30, self.height);
    
    self.nameLabel.frame = CGRectMake(0, 0, 100, self.height);
}

@end
