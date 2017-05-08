//
//  PassInputFieldView.m
//  Connect
//
//  Created by MoHuilin on 2016/11/10.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "PassInputFieldView.h"


@interface PassInputFieldView ()
// Save the password string
@property(strong, nonatomic) NSMutableString *textStore;

@end

@implementation PassInputFieldView

static NSString *const MONEYNUMBERS = @"0123456789";

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.textStore = [NSMutableString string];
        self.squareWidth = AUTO_HEIGHT(80);
        self.passWordNum = 4;
        self.pointRadius = 6;
        self.rectColor = [UIColor colorWithRed:200 / 255.0 green:202 / 255.0 blue:210 / 255.0 alpha:1.0];
        self.pointColor = [UIColor colorWithRed:72 / 255.0 green:81 / 255.0 blue:107 / 255.0 alpha:1.0];
        [self becomeFirstResponder];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.textStore = [NSMutableString string];
        self.squareWidth = AUTO_HEIGHT(80);
        self.passWordNum = 4;
        self.pointRadius = 6;
        self.rectColor = [UIColor colorWithRed:200 / 255.0 green:202 / 255.0 blue:210 / 255.0 alpha:1.0];
        self.pointColor = [UIColor colorWithRed:72 / 255.0 green:81 / 255.0 blue:107 / 255.0 alpha:1.0];
        [self becomeFirstResponder];
    }

    return self;
}

/**
 *  Set the side length of the square
 */
- (void)setSquareWidth:(CGFloat)squareWidth {
    _squareWidth = squareWidth;
    [self setNeedsDisplay];
}

/**
 *  Set the type of keyboard
 */
- (UIKeyboardType)keyboardType {
    return UIKeyboardTypeNumberPad;
}

- (BOOL)isSecureTextEntry {
    return YES;
}

/**
 *  Set the number of bits in the password
 */
- (void)setPassWordNum:(NSUInteger)passWordNum {
    _passWordNum = passWordNum;
    [self setNeedsDisplay];
}

- (BOOL)becomeFirstResponder {
    if ([self.delegate respondsToSelector:@selector(passWordBeginInput:)]) {
        [self.delegate passWordBeginInput:self];
    }
    return [super becomeFirstResponder];
}

/**
 *  Whether it can be the first respondent
 */
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (![self isFirstResponder]) {
        [self becomeFirstResponder];
    }
}

#pragma mark - UIKeyInput

/**
 *  Whether the text object used for the display has any text
 */
- (BOOL)hasText {
    return self.textStore.length > 0;
}

/**
 * Insert text
 */
- (void)insertText:(NSString *)text {
    if (self.textStore.length < self.passWordNum) {
        //To determine whether the number
        NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:MONEYNUMBERS] invertedSet];
        NSString *filtered = [[text componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
        BOOL basicTest = [text isEqualToString:filtered];
        if (basicTest) {
            [self.textStore appendString:text];
            if ([self.delegate respondsToSelector:@selector(passWordDidChange:)]) {
                [self.delegate passWordDidChange:self];
            }
            if (self.textStore.length == self.passWordNum) {

                if ([self.delegate respondsToSelector:@selector(passWordCompleteInput:)]) {
                    [self.delegate passWordCompleteInput:self];
                }
            }
            [self setNeedsDisplay];
        }
    }
}

/**
 *  Delete the text
 */
- (void)deleteBackward {
    if (self.textStore.length > 0) {
        [self.textStore deleteCharactersInRange:NSMakeRange(self.textStore.length - 1, 1)];
        if ([self.delegate respondsToSelector:@selector(passWordDidChange:)]) {
            [self.delegate passWordDidChange:self];
        }
    }
    [self setNeedsDisplay];
}

- (void)clearAll {
    self.textStore = [NSMutableString string];
    [self setNeedsDisplay];
}

// Only override drawRect: if you perform custom drawing.
- (void)drawRect:(CGRect)rect {
    CGFloat height = rect.size.height;
    CGFloat width = rect.size.width;
    CGFloat x = (width - self.squareWidth * self.passWordNum) / 2.0;
    CGFloat y = (height - self.squareWidth) / 2.0;
    // Get the current drawing context
    CGContextRef context = UIGraphicsGetCurrentContext();
    // Draw the frame
    CGContextAddRect(context, CGRectMake(x, y, self.squareWidth * self.passWordNum, self.squareWidth));
    CGContextSetLineWidth(context, 3);
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextDrawPath(context, kCGPathFillStroke);

    // Painted black circle
    for (int i = 1; i <= self.passWordNum; i++) {
        CGContextAddArc(context, x + i * self.squareWidth - self.squareWidth / 2.0, y + self.squareWidth / 2, self.pointRadius, 0, M_PI * 2, YES);
        CGContextSetFillColorWithColor(context, self.rectColor.CGColor);
        CGContextDrawPath(context, kCGPathFill);
    }
    // Draw black spots
    for (int i = 1; i <= self.textStore.length; i++) {
        CGContextAddArc(context, x + i * self.squareWidth - self.squareWidth / 2.0, y + self.squareWidth / 2, self.pointRadius, 0, M_PI * 2, YES);
        CGContextSetFillColorWithColor(context, self.pointColor.CGColor);
        CGContextDrawPath(context, kCGPathFill);
    }
}


@end
