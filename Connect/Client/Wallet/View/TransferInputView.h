//
//  TransferInputView.h
//  Connect
//
//  Created by MoHuilin on 16/9/24.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMNumberTextField.h"

typedef void (^TransferInputResultBlock)(NSDecimalNumber *btcMoney, NSString *note);

typedef void (^TransferInputValueChangeBlock)(NSString *text, NSDecimalNumber *btcMoney);

typedef void (^TransferInputValueLagelBlock)(BOOL lagel);

@interface TransferInputView : UIView
// The result of the block
@property(nonatomic, copy) TransferInputResultBlock resultBlock;
// Notice of change
@property(nonatomic, copy) TransferInputValueChangeBlock valueChangeBlock;

@property(nonatomic, copy) TransferInputValueLagelBlock lagelBlock;
// Top of the prompt text
@property(nonatomic, copy) NSString *topTipString;
// Default note text
@property(nonatomic, copy) NSString *noteDefaultString;
// Enter the default amount of the box
@property(nonatomic, copy) NSString *defaultAmountString;

// Whether to hide fee default no
@property(nonatomic, assign) BOOL isHidenFee;
// The top of the label
@property(weak, nonatomic) IBOutlet UILabel *typeLabel;
// inputTextField
@property(weak, nonatomic) IBOutlet LMNumberTextField *inputTextField;

// call block
- (void)executeBlock;

- (void)reloadWithRate:(float)rate;

- (void)hidenKeyBoard;

@end
