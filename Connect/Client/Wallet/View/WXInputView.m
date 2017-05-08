//
//  InputView.m
//  WXPayView
//
//  Created by apple on 16/1/6.
//  Copyright © 2016年 apple. All rights reserved.
//  密码输入框视图

#import "WXInputView.h"

// The size of the center symbol dot
CGFloat const kWXInputViewSymbolWH = 8;

@interface WXInputView ()

// The dot in the middle of all the lattices
@property(nonatomic, strong) NSMutableArray *symbolArr;

@property(nonatomic, strong) UITextField *textField;

@end

@implementation WXInputView

#pragma mark - 视图创建方法

// Code Create an input box view
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addNotification];
    }


    return self;
}

// Xib load the input box view
- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self == nil) {
        return nil;
    }

    [self addNotification];

    return self;
}

- (void)addNotification {
    // Callback keyboard Enter the notification of changes in content
    [[NSNotificationCenter defaultCenter] addObserverForName:UITextFieldTextDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {

        NSUInteger length = _textField.text.length;

        if (length == self.places && self.WXInputViewDidCompletion) {
            self.WXInputViewDidCompletion(_textField.text);
        }

        if (length > self.places) {
            _textField.text = [_textField.text substringToIndex:self.places];
        }

        [_symbolArr enumerateObjectsUsingBlock:^(CAShapeLayer *symbol, NSUInteger idx, BOOL *stop) {

            symbol.hidden = idx < length ? NO : YES;
        }];
    }];
}

- (void)setPlaces:(NSInteger)places {
    _places = places;

    if (places > 0) {
        [self setupContents:places];
    }
}

#pragma mark - View internal layout related

- (void)setupContents:(NSInteger)pages {

    self.layer.borderWidth = 1;
    self.layer.borderColor = [UIColor lightGrayColor].CGColor;

    // Create a split line
    for (int i = 0; i < pages - 1; i++) {
        UIView *line = [[UIView alloc] init];
        line.backgroundColor = [UIColor grayColor];
        [self addSubview:line];
    }

    // Create a central origin
    for (int i = 0; i < pages; i++) {
        CAShapeLayer *symbol = [CAShapeLayer layer];
        symbol.fillColor = [UIColor blackColor].CGColor;
        UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, kWXInputViewSymbolWH, kWXInputViewSymbolWH)];
        symbol.path = path.CGPath;
        symbol.hidden = YES;
        [self.layer addSublayer:symbol];
        [self.symbolArr objectAddObject:symbol];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat lineX = 0;
    CGFloat lineY = 0;
    CGFloat lineW = 1;
    CGFloat lineH = self.frame.size.height;
    CGFloat margin = kWXInputViewSymbolWH * 0.5;

    CGFloat w = self.frame.size.width / self.places;

    for (int i = 0; i < self.places - 1; i++) {
        UIView *line = self.subviews[i];
        lineX = w * (i + 1);
        line.frame = CGRectMake(lineX, lineY, lineW, lineH);
    }

    for (int i = 0; i < self.symbolArr.count; i++) {
        CAShapeLayer *circle = self.symbolArr[i];
        circle.position = CGPointMake(w * (0.5 + i) - margin, self.frame.size.height * 0.5 - margin);
    }
}

#pragma mark - Common method

- (void)beginInput {
    if (_textField == nil) {
        _textField = [[UITextField alloc] init];
        _textField.keyboardType = UIKeyboardTypeDecimalPad;
        _textField.hidden = YES;
        if (GJCFStringIsNull([[MMAppSetting sharedSetting] getPayPass])) {
            [_textField addTarget:self action:@selector(textFieldDidValueChanged) forControlEvents:UIControlEventEditingChanged];
        }
        [self addSubview:_textField];
    }

    [self.textField becomeFirstResponder];
}


- (void)textFieldDidValueChanged {
    if (_textField.text.length == 6) {
        NSLog(@"%@", _textField.text);

        self.WXInputViewDidCompletion(_textField.text);
        [_textField setText:nil];
    }
}


- (void)endInput {
    [self.textField resignFirstResponder];
}

- (void)clearPassword {
    [self.textField setText:nil];
}

#pragma mark - lazy

- (NSMutableArray *)symbolArr {
    if (_symbolArr == nil) {
        _symbolArr = [NSMutableArray array];
    }
    return _symbolArr;
}


+ (instancetype)inputView {
    return [[self alloc] init];
}

#pragma mark - View destroyed

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
