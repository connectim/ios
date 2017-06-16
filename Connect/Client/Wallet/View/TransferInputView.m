//
//  TransferInputView.m
//  Connect
//
//  Created by MoHuilin on 16/9/24.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "TransferInputView.h"
#import "BaseViewController.h"
#import "LMDrawView.h"
#import "SetTransferFeePage.h"
#import "StringTool.h"
#import "LMPayCheck.h"
#import "LMChatRedLuckyViewController.h"

#define MAX_STARWORDS_LENGTH 10

@interface TransferInputView () <UITextFieldDelegate>
// Enter the container view
@property(weak, nonatomic) IBOutlet UIView *inputContentView;
// Remark button
@property(weak, nonatomic) IBOutlet UIButton *noteButton;
// The top of the label
@property(weak, nonatomic) IBOutlet UILabel *topTipLabel;
// Exchange rate conversion button
@property(weak, nonatomic) IBOutlet UIButton *rateChangeButton;
@property(weak, nonatomic) IBOutlet UILabel *feeLabel;

@property(weak, nonatomic) IBOutlet LMDrawView *line;
// Stores the length of the inputTextField
@property(copy, nonatomic) NSString *inputTextFieldString;
// Common controls are constrained
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *noteButtonTopConstaton;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *rateButtonTopConstaton;


@property(nonatomic, copy) NSString *code;
@property(nonatomic, copy) NSString *sympol;

@property(nonatomic, copy) NSString *note;

@property(nonatomic, assign) BOOL btcAmount;

@property(nonatomic, strong) NSDecimalNumber *amount;

@end

@implementation TransferInputView

- (UIViewController *)viewController {
    for (UIView *next = [self superview]; next; next = next.superview) {
        UIResponder *nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *) nextResponder;
        }
    }
    return nil;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    if (GJCFSystemiPhone5) {
        self.noteButtonTopConstaton.constant = 1;
        self.rateButtonTopConstaton.constant = 0;
    } else if (GJCFSystemiPhone6) {
        self.noteButtonTopConstaton.constant = 9;
        self.rateButtonTopConstaton.constant = 8;
    } else {
        self.noteButtonTopConstaton.constant = 11;
        self.rateButtonTopConstaton.constant = 10;
    }
}

- (IBAction)addNote:(id)sender {
    
    UIViewController *controller = [self viewController];
    if (!controller) {
        return;
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LMLocalizedString(@"Wallet Note", nil) message:LMLocalizedString(@"Wallet Add note", nil) preferredStyle:UIAlertControllerStyleAlert];
    __weak __typeof(&*self) weakSelf = self;
    UITextField __block *textFieldTem = nil;
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textFieldTem = textField;
        textField.text = [weakSelf.noteButton.titleLabel.text isEqualToString:weakSelf.noteDefaultString] ? @"" : weakSelf.noteButton.titleLabel.text;
        [GCDQueue executeInMainQueue:^{
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFiledEditChanged:)
                                                         name:UITextFieldTextDidChangeNotification object:textField];
        }];
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        [GCDQueue executeInMainQueue:^{
            if (GJCFStringIsNull(textFieldTem.text)) {
                [weakSelf.noteButton setTitle:weakSelf.noteDefaultString forState:UIControlStateNormal];
            } else {
                [weakSelf.noteButton setTitle:textFieldTem.text forState:UIControlStateNormal];
            }
        }];
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [controller presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)exChangeRate:(id)sender {
    if (self.btcAmount) {
        NSString *nameString = nil;
        nameString = [NSString stringWithFormat:@"%f", [[MMAppSetting sharedSetting] getRate] * self.amount.doubleValue];
        nameString = [self limitPoint:nameString withSympol:self.sympol];
        self.inputTextField.text = nameString;

        nameString = [NSString stringWithFormat:@"฿ %0.8f", self.amount.doubleValue];
        nameString = [self limitPoint:nameString withSympol:@"฿"];
        [self.rateChangeButton setTitle:nameString forState:UIControlStateNormal];

        self.typeLabel.text = self.sympol;
        self.topTipLabel.text = [self.topTipLabel.text stringByReplacingOccurrencesOfString:@"BTC" withString:self.code];
        self.btcAmount = NO;
    } else {
        self.typeLabel.text = @"฿";

        NSString *nameString = nil;
        nameString = [NSString stringWithFormat:@"%0.8f", self.amount.doubleValue];
        nameString = [self limitPoint:nameString withSympol:@"฿"];

        self.inputTextField.text = nameString;

        nameString = [NSString stringWithFormat:@"%@ %f", self.sympol, [[MMAppSetting sharedSetting] getRate] * self.amount.doubleValue];
        nameString = [self limitPoint:nameString withSympol:self.sympol];


        [self.rateChangeButton setTitle:nameString forState:UIControlStateNormal];
        self.btcAmount = YES;
        self.topTipLabel.text = [self.topTipLabel.text stringByReplacingOccurrencesOfString:self.code withString:@"BTC"];
    }
}

/**
 *  Limit the number of decimal places (button) after clicking the toggle button
 */
- (NSString *)limitPoint:(NSString *)nameString withSympol:(NSString *)sympol {
    if ([nameString containsString:@"."]) {
        NSString *firstString = [[nameString componentsSeparatedByString:@"."] firstObject];
        NSString *lastString = [[nameString componentsSeparatedByString:@"."] lastObject];
        if ([sympol containsString:@"฿"]) {// btc
            if (lastString.length >= 8) {
                return [self displayNumberWichFirstString:firstString withLastString:lastString withCount:8];
            }
        } else if ([sympol containsString:@"$"]) {
            if (lastString.length >= 2) {
                return [self displayNumberWichFirstString:firstString withLastString:lastString withCount:2];
            }
        } else if ([sympol containsString:@"¥"]) {
            if (lastString.length >= 2) {
                return [self displayNumberWichFirstString:firstString withLastString:lastString withCount:2];
            }
        } else {
            if (lastString.length >= 2) {
                return [self displayNumberWichFirstString:firstString withLastString:lastString withCount:2];
            }
        }
    }
    return nameString;
}

/**
 *  The number displayed
 */
- (NSString *)displayNumberWichFirstString:(NSString *)firstString withLastString:(NSString *)lastString withCount:(NSInteger)count {
    if (lastString.length >= count) {
        lastString = [lastString substringToIndex:count];
        firstString = [NSString stringWithFormat:@"%@.%@", firstString, lastString];
        return firstString;
    } else {
        firstString = [NSString stringWithFormat:@"%@.%@", firstString, lastString];
        return firstString;
    }
}

/**
 *  According to different currencies, limit the input of inputTextField
 */
- (void)setInputViewField:(NSString *)sympol {
    if ([sympol containsString:@"¥"]) {
        [self detailLimitPreviousCount:9 withBehindCount:2];
    } else if ([sympol containsString:@"$"]) {
        [self detailLimitPreviousCount:9 withBehindCount:2];
    } else if ([sympol containsString:@"฿"]) {
        [self detailLimitPreviousCount:3 withBehindCount:8];

    } else {
        [self detailLimitPreviousCount:9 withBehindCount:2];
    }
}

/**
 *  limit detail
 */
- (void)detailLimitPreviousCount:(NSInteger)previousCount withBehindCount:(NSInteger)behindCount {
    // The number of decimal places can not be greater than three
    if ([self.inputTextField.text containsString:@"."]) {
        NSString *lastString = [[self.inputTextField.text componentsSeparatedByString:@"."] lastObject];
        NSString *firstString = [[self.inputTextField.text componentsSeparatedByString:@"."] firstObject];
        if (lastString.length >= behindCount) {
            lastString = [lastString substringToIndex:behindCount];
            self.inputTextField.text = [NSString stringWithFormat:@"%@.%@", firstString, lastString];
        }

    }
    if (self.inputTextField.text.length >= previousCount) {
        // First judge whether to add or delete
        if (self.inputTextFieldString.length <= self.inputTextField.text.length) {
            if (![self.inputTextField.text containsString:@"."]) {
                NSMutableString *temString = [[NSMutableString alloc] initWithString:[self.inputTextField.text substringToIndex:previousCount]];
                self.inputTextField.text = [temString stringByAppendingString:@"."];
            }
        }
        self.inputTextFieldString = self.inputTextField.text;
    }
}

- (NSString *)code {
    return [_code uppercaseString];
}

- (void)setTopTipString:(NSString *)topTipString {
    _topTipString = topTipString;
    if (![topTipString containsString:@"BTC"] && ![topTipString containsString:@"btc"]) {
        self.topTipLabel.text = [NSString stringWithFormat:@"%@(BTC)", topTipString];
    } else {
        self.topTipLabel.text = topTipString;
    }
}

- (void)setNoteDefaultString:(NSString *)noteDefaultString {
    _noteDefaultString = noteDefaultString;
    [self.noteButton setTitle:noteDefaultString forState:UIControlStateNormal];
}

- (void)setDefaultAmountString:(NSString *)defaultAmountString {
    if (defaultAmountString.doubleValue > 0) {
        _defaultAmountString = defaultAmountString;
        self.amount = [NSDecimalNumber decimalNumberWithString:defaultAmountString];
        NSString *amountString = [self limitPoint:defaultAmountString withSympol:@"฿"];
        self.inputTextField.text = amountString;

        
        NSString *reteAmountString = [NSString stringWithFormat:@"%@ %f", self.sympol, [[MMAppSetting sharedSetting] getRate] * defaultAmountString.doubleValue];
        reteAmountString = [self limitPoint:reteAmountString withSympol:self.sympol];
        [self.rateChangeButton setTitle:reteAmountString forState:UIControlStateNormal];
    }
}

- (void)hidenKeyBoard {
    [self.inputTextField resignFirstResponder];
}

- (instancetype)init {
    if (self = [super init]) {
        self = [[NSBundle mainBundle] loadNibNamed:@"TransferInputView" owner:nil options:nil].firstObject;
        [self setup];
    }
    return self;
}

- (void)dealloc {
    RemoveNofify;
}

- (void)textFiledEditChanged:(NSNotification *)obj {
     
    UITextField *textField = (UITextField *) obj.object;
    NSString *toBeString = textField.text;
    NSString *lang = [textField.textInputMode primaryLanguage];
    if ([lang isEqualToString:@"zh-Hans"])// Simplified Chinese input
    {
        // Get the highlight section
        UITextRange *selectedRange = [textField markedTextRange];
        UITextPosition *position = [textField positionFromPosition:selectedRange.start offset:0];
        // If there is no highlighted word, the number of words that have been entered is counted and restricted
        if (!position) {
            if (toBeString.length > MAX_STARWORDS_LENGTH) {
                textField.text = [toBeString substringToIndex:MAX_STARWORDS_LENGTH];
            }
        }
    }
        // Chinese input method other than the statistical restrictions can be directly, regardless of other language situation
    else {
        if (toBeString.length > MAX_STARWORDS_LENGTH) {
            NSRange rangeIndex = [toBeString rangeOfComposedCharacterSequenceAtIndex:MAX_STARWORDS_LENGTH];
            if (rangeIndex.length == 1) {
                textField.text = [toBeString substringToIndex:MAX_STARWORDS_LENGTH];
            } else {
                NSRange rangeRange = [toBeString rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, MAX_STARWORDS_LENGTH)];
                textField.text = [toBeString substringWithRange:rangeRange];
            }
        }
    }
}

- (void)setup {

    // set attribute
    self.inputContentView.layer.cornerRadius = 6;
    self.inputContentView.layer.masksToBounds = YES;
    self.inputContentView.layer.borderColor = [UIColor grayColor].CGColor;
    self.inputContentView.layer.borderWidth = 0.3;

    self.topTipLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.topTipLabel.textColor = LMBasicDarkGray;
    self.feeLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.typeLabel.font = [UIFont boldSystemFontOfSize:FONT_SIZE(36)];
    [self.noteButton setTitleColor:LMBasicRateBtnTitleColor forState:UIControlStateNormal];
    self.noteButton.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.noteDefaultString = LMLocalizedString(@"Wallet Add note", nil); //Defaults
    [self.noteButton setTitle:self.noteDefaultString forState:UIControlStateNormal];

    // Set a fee

    if ([[MMAppSetting sharedSetting] canAutoCalculateTransactionFee]) {
        self.feeLabel.text = LMLocalizedString(@"Wallet Auto Calculate Miner Fee", nil);
    } else {
        self.feeLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Fee BTC", nil), [[MMAppSetting sharedSetting] getTranferFee] * pow(10, -8)];
    }

    self.feeLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeFee)];
    [self.feeLabel addGestureRecognizer:tap];

    self.rateChangeButton.backgroundColor = LMBasicRateBtnColor;
    self.rateChangeButton.layer.cornerRadius = 3;
    self.rateChangeButton.layer.masksToBounds = YES;
    self.rateChangeButton.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(36)];

    self.rateChangeButton.contentEdgeInsets = UIEdgeInsetsMake(AUTO_HEIGHT(5), AUTO_HEIGHT(15), AUTO_HEIGHT(5), AUTO_HEIGHT(15));

    NSString *curency = [[MMAppSetting sharedSetting] getcurrency];
    NSArray *temA = [curency componentsSeparatedByString:@"/"];
    if (temA.count == 2) {
        self.code = [temA firstObject];
        self.sympol = [temA lastObject];
    }
    NSString *nameString = nil;
    nameString = [NSString stringWithFormat:@"%@ %f", self.sympol, [[MMAppSetting sharedSetting] getRate] * MIN_TRANSFER_AMOUNT];
    nameString = [self limitPoint:nameString withSympol:self.sympol];

    [self.rateChangeButton setTitle:nameString forState:UIControlStateNormal];
    [self.inputTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.typeLabel.mas_right).offset(10);
        make.top.equalTo(self.typeLabel);
        make.right.equalTo(self.inputContentView).offset(-10);
        make.height.mas_equalTo(AUTO_HEIGHT(100));
    }];
    self.inputTextField.text = [NSString stringWithFormat:@"%.8lf", MIN_TRANSFER_AMOUNT];
    self.inputTextField.delegate = self;
    self.amount = [[NSDecimalNumber alloc] initWithDouble:MIN_TRANSFER_AMOUNT];
    self.btcAmount = YES;
    self.inputTextField.keyboardType = UIKeyboardTypeDecimalPad;
    self.inputTextField.tintColor = [UIColor blackColor];
    [self.inputTextField becomeFirstResponder];
    self.inputTextField.font = [UIFont systemFontOfSize:FONT_SIZE(72)];
    [self.inputTextField addTarget:self action:@selector(TextFieldEditValueChanged:) forControlEvents:UIControlEventEditingChanged];
    self.backgroundColor = [UIColor clearColor];
    [self layoutIfNeeded];
}

/**
 *   Refresh freelable
 */
- (void)changeFeeLable {
    self.feeLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Fee BTC", nil), [[MMAppSetting sharedSetting] getTranferFee] * pow(10, -8)];
}

- (void)changeFee {

    __weak __typeof(&*self) weakSelf = self;
    SetTransferFeePage *page = [[SetTransferFeePage alloc] initWithChangeBlock:^(BOOL result, long long displayValue) {
        if (result) {
            weakSelf.feeLabel.text = LMLocalizedString(@"Wallet Auto Calculate Miner Fee", nil);
        } else {
            weakSelf.feeLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Fee BTC", nil), [[MMAppSetting sharedSetting] getTranferFee] * pow(10, -8)];
        }
    }];
    [[self viewController].navigationController pushViewController:page animated:YES];
}

- (void)TextFieldEditValueChanged:(UITextField *)textField {
    [self setInputViewField:self.typeLabel.text];
    self.amount = [NSDecimalNumber decimalNumberWithString:textField.text];
    if (textField.text.length <= 0) {
        self.amount = [NSDecimalNumber decimalNumberWithString:@"0"];
    }
    if (self.btcAmount) {
        NSString *nameString = nil;
        nameString = [NSString stringWithFormat:@"%@ %f", self.sympol, [[MMAppSetting sharedSetting] getRate] * self.amount.doubleValue];
        nameString = [self limitPoint:nameString withSympol:self.sympol];
        // refresh
        [self.rateChangeButton setTitle:nameString forState:UIControlStateNormal];
    } else {
        self.amount = [self.amount decimalNumberByDividingBy:[[NSDecimalNumber alloc] initWithDouble:[[MMAppSetting sharedSetting] getRate]]];

        NSString *nameString = nil;
        nameString = [NSString stringWithFormat:@"฿ %0.8f", self.amount.floatValue];
        nameString = [self limitPoint:nameString withSympol:@"฿"];
        [self.rateChangeButton setTitle:nameString forState:UIControlStateNormal];
    }

    // call back
    if (self.valueChangeBlock) {
        self.valueChangeBlock(self.inputTextField.text, self.amount);
    }
    if (self.amount.doubleValue == MAX_REDMIN_AMOUNT) { // Red envelopes amount
        if (self.amount.doubleValue<MAX_REDMIN_AMOUNT || self.amount.doubleValue>MAX_REDBAG_AMOUNT) {
            if (self.lagelBlock) {
                self.lagelBlock(NO);
            }
        } else {
            if (self.lagelBlock) {
                self.lagelBlock(YES);
            }
        }
    } else {
        if (self.amount.doubleValue<MIN_TRANSFER_AMOUNT || self.amount.doubleValue>MAX_TRANSFER_AMOUNT) {
            if (self.lagelBlock) {
                self.lagelBlock(NO);
            }
        } else {
            if (self.lagelBlock) {
                self.lagelBlock(YES);
            }
        }
    }
}


- (void)setIsHidenFee:(BOOL)isHidenFee {
    
    _isHidenFee = isHidenFee;
    self.feeLabel.hidden = isHidenFee;
    [self setNeedsLayout];
    
}

- (void)executeBlock {
    __weak typeof(self) weakSelf = self;
    if (self.resultBlock) {
        if ([[self viewController] isKindOfClass:[LMChatRedLuckyViewController class]]) {
            if ([LMPayCheck checkMoneyNumber:self.amount withTransfer:NO] == MoneyTypeRedSmall) {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Amount is too small", nil) withType:ToastTypeCommon showInView:[weakSelf viewController].view complete:nil];
                }];
                return;
            }
            if ([LMPayCheck checkMoneyNumber:self.amount withTransfer:NO] == MoneyTypeRedBig) {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Too much", nil) withType:ToastTypeCommon showInView:[weakSelf viewController].view complete:nil];
                }];
                return;
            }

        } else {
            if ([LMPayCheck checkMoneyNumber:self.amount withTransfer:YES] == MoneyTypeTransferSmall) {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Amount is too small", nil) withType:ToastTypeCommon showInView:[weakSelf viewController].view complete:nil];
                }];
                return;
            }
            if ([LMPayCheck checkMoneyNumber:self.amount withTransfer:YES] == MoneyTypeTransferBig) {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Too much", nil) withType:ToastTypeCommon showInView:[weakSelf viewController].view complete:nil];
                }];
                return;
            }
        }
        self.resultBlock(self.amount, [self.noteButton.titleLabel.text isEqualToString:self.noteDefaultString] ? nil : self.noteButton.titleLabel.text);
    }
}

- (void)reloadWithRate:(float)rate {

    NSString *nameString = nil;
    nameString = [NSString stringWithFormat:@"%@ %f", self.sympol, [self.amount decimalNumberByMultiplyingBy:[[NSDecimalNumber alloc] initWithFloat:rate]].doubleValue];
    nameString = [self limitPoint:nameString withSympol:self.sympol];
    [self.rateChangeButton setTitle:nameString forState:UIControlStateNormal];

    [self setNeedsLayout];
}


#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

    // The input legitimacy check can only be a numeric decimal point.
    if ([StringTool checkString:string] == NO) {
        return NO;
    }
    // Limit the total length of the amount
    if (textField == self.inputTextField) {
        if (textField.text.length >= 11) {
            self.inputTextField.text = [textField.text substringToIndex:11];
        }
    }
    // You can not enter a decimal point again
    if ([string containsString:@"."] && [textField.text containsString:@"."]) {
        return NO;
    }
    // So that the first one can not be a decimal point
    if ([string containsString:@"."] && textField.text.length <= 0) {
        return NO;
    }
    // Digital precision
    if (![string isEqualToString:@""] && [[textField.text componentsSeparatedByString:@"."] lastObject].length == 8) {
        return NO;
    }
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    // Enter the amount of control
    NSDecimalNumber *deAmount = [NSDecimalNumber decimalNumberWithString:textField.text];
    double amount = [deAmount doubleValue];
    if (self.amount.doubleValue == MAX_REDMIN_AMOUNT) {
        if (amount < MAX_REDMIN_AMOUNT) {
            textField.text = [NSString stringWithFormat:@"%f", MAX_REDMIN_AMOUNT];
            BaseViewController *controller = (BaseViewController *) [self viewController];
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:[NSString stringWithFormat:LMLocalizedString(@"Wallet Amount must be greater than", nil), MAX_REDMIN_AMOUNT] withType:ToastTypeCommon showInView:controller.view complete:nil];
            }];


        } else if (amount > MAX_REDBAG_AMOUNT) {
            textField.text = [NSString stringWithFormat:@"%f", MAX_REDBAG_AMOUNT];
            BaseViewController *controller = (BaseViewController *) [self viewController];
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:[NSString stringWithFormat:LMLocalizedString(@"Wallet Amount must be less than", nil), MAX_REDBAG_AMOUNT] withType:ToastTypeCommon showInView:controller.view complete:nil];
            }];
        }
    } else {
        if (amount < MIN_TRANSFER_AMOUNT) {
            textField.text = [NSString stringWithFormat:@"%f", MIN_TRANSFER_AMOUNT];
            BaseViewController *controller = (BaseViewController *) [self viewController];
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:[NSString stringWithFormat:LMLocalizedString(@"Wallet Amount must be greater than", nil), MIN_TRANSFER_AMOUNT] withType:ToastTypeCommon showInView:controller.view complete:nil];
            }];
        } else if (amount > MAX_TRANSFER_AMOUNT) {

        }
    }
    // The amount of reset is issued
    [self TextFieldEditValueChanged:textField];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

/**
 * lineView: Need to draw a dotted view
 **/
- (void)drawDashLine:(UIView *)lineView lineLength:(int)lineLength lineSpacing:(int)lineSpacing lineColor:(UIColor *)lineColor {
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    [shapeLayer setBounds:lineView.bounds];
    [shapeLayer setPosition:CGPointMake((DEVICE_SIZE.width) / 2.0, CGRectGetHeight(lineView.frame))];
    [shapeLayer setFillColor:[UIColor clearColor].CGColor];
    [shapeLayer setStrokeColor:lineColor.CGColor];
    [shapeLayer setLineWidth:CGRectGetHeight(lineView.frame)];
    [shapeLayer setLineJoin:kCALineJoinRound];
    [shapeLayer setLineDashPattern:[NSArray arrayWithObjects:[NSNumber numberWithInt:lineLength], [NSNumber numberWithInt:lineSpacing], nil]];
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, 10, 0);
    CGPathAddLineToPoint(path, NULL, DEVICE_SIZE.width - AUTO_WIDTH(120), 0);
    [shapeLayer setPath:path];
    CGPathRelease(path);
    [lineView.layer addSublayer:shapeLayer];
}
@end
