//
//  LMBaseViewController.h
//  Connect
//
//  Created by Edwin on 16/7/14.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BitcoinInfo.h"
#import "BaseViewController.h"
#import "PayTool.h"
#import "TransferButton.h"
#import "InputPayPassView.h"
#import "PaySetPage.h"
#import "UIAlertController+Blocks.h"
#import "LMUnspentCheckTool.h"
#import "ConnectButton.h"

typedef void (^baseBitRequestInfoComplete)(BOOL complete, BitcoinInfo *info);

typedef void (^baseRMBRateRequestComplete)(BOOL complete, float rate, NSString *code, NSString *symbol);

typedef void (^baseRequestErrorBlock)(NSError *__autoreleasing error);

typedef void (^bitRatoComplete)(BOOL isSuccess, NSString *rate);

typedef void (^trasferComplete)();


@interface LMBaseViewController : BaseViewController

@property(nonatomic, strong) NSArray *vtsArray; // enter
@property(nonatomic, copy) NSString *rawTransaction; // Original transaction


@property(nonatomic, assign) float rate;

@property(nonatomic, copy) NSString *rateCode; // symbol

@property(nonatomic, strong) AccountInfo *ainfo;

@property(nonatomic, strong) BitcoinInfo *bitInfo;
@property(nonatomic, strong) KQXPasswordInputController *passwordInputVC;
@property(nonatomic, copy) NSString *moneyTypes;
@property(nonatomic, copy) bitRatoComplete complete;

@property(nonatomic, copy) trasferComplete trasferComplete;

@property(nonatomic, assign) long long blance; // Account Balance
@property(nonatomic, copy) NSString *blanceString; // Account balance string, interface display
@property(nonatomic, copy) NSString *code; //
@property(nonatomic, copy) NSString *symbol; //


@property(nonatomic, strong) UILabel *errorTipLabel; // Error message
/**
 *  Unified tool class approach
 */
// In order to change the new table, the button position changes
@property(nonatomic, strong) ConnectButton *comfrimButton;

/**
 *  Currency symbol changes the notification method, you need to call the parent class method
 */
- (void)currencyChange;

/**
 *   hide tabbar
 */
- (void)showTabBar;

/**
 *  display tabbar
 */
- (void)hideTabBar;


/**
 *  creat transfer
 */
- (void)createTranscationWithMoney:(NSDecimalNumber *)money note:(NSString *)note;

/**
 *  Get exchange rate
 */
- (void)showWithLoadingLabelText:(NSString *)text andSelTask:(SEL)sel;

- (void)transferToAddress:(NSString *)address decimalMoney:(NSDecimalNumber *)money tips:(NSString *)tips complete:(void (^)(NSString *hashId, NSError *error))complete;

- (void)paymentToAddress:(NSString *)address decimalMoney:(NSDecimalNumber *)money hashID:(NSString *)hashID complete:(void (^)(NSString *hashId, NSError *error))complete;

- (void)createChatWithHashId:(NSString *)hashId address:(NSString *)address Amount:(NSString *)amount;

/**
 *  External Transfer Method OuterTransferViewController
 */
- (void)checkChangeWithRawTrancationModel:(LMRawTransactionModel *)rawModel billing:(OrdinaryBilling *)billing;

/**
 *  Bit Coin Address Transfer / Single Transfer LMBitAddressViewController
 */
- (void)checkChangeWithRawTrancationModel:(LMRawTransactionModel *)rawModel
                                   amount:(NSDecimalNumber *)amount
                                     note:(NSString *)note;

/**
 *  Red envelope transfer audit. LMChatRedLuckyViewController
 */
- (void)checkChangeWithRawTrancationModel:(LMRawTransactionModel *)rawModel
                              ordinaryRed:(OrdinaryRedPackage *)ordinaryRed
                                     note:(NSString *)note
                                    money:(NSDecimalNumber *)money type:(int)type;

/**
 *  Transfer to friends / LMTransFriendsViewController
 */
- (void)checkChangeWithRawTrancationModel:(LMRawTransactionModel *)rawModel
                                     note:(NSString *)note
                                    money:(NSDecimalNumber *)money;

/**
 *  All the chips
 */
- (void)checkChangeWithRawTrancationModel:(LMRawTransactionModel *)rawModel
                                   amount:(double)amount;

/**
 *  Set the payment result LMSetMoneyResultViewController
 */
- (void)checkChangeWithRawTrancationModel:(LMRawTransactionModel *)rawModel;

/**
 *  Transfer Note LMTransferNotesViewController
 */
- (void)checkChangeWithRawTrancationModel:(LMRawTransactionModel *)rawModel
                             decimalMoney:(NSDecimalNumber *)amount;

/**
 *  The LMUnSetMoneyResultViewController does not pay for the result
 */
- (void)checkChangeWithRawTrancationModel:(LMRawTransactionModel *)rawModel
                             decimalMoney:(NSDecimalNumber *)amount
                                     note:(NSString *)note;


@end
