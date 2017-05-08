//
//  LMPayCheck.m
//  Connect
//
//  Created by Connect on 2017/4/10.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMPayCheck.h"
#import "LMUnspentCheckTool.h"
#import "NSObject+CurrentViewController.h"
#import "OuterTransferViewController.h"
#import "LMBitAddressViewController.h"
#import "LMChatRedLuckyViewController.h"
#import "LMTransFriendsViewController.h"
#import "LMChatSingleTransferViewController.h"
#import "LMGroupZChouTransViewController.h"
#import "LMSetMoneyResultViewController.h"
#import "LMTransferNotesViewController.h"
#import "LMUnSetMoneyResultViewController.h"


@implementation LMPayCheck
// New method. Used to make payment judgment
+ (void)payCheck:(OrdinaryBilling *)billing withVc:(LMBaseViewController*)transferViewVc withTransferType:(TransferType)transferType unSpent:(UnspentOrderResponse *)unspent withArray:(NSArray *)toAddresses withMoney:(NSDecimalNumber*)money withNote:(NSString *)note withType:(int)type withRedPackage:(OrdinaryRedPackage *)ordinaryRed withError:(NSError*)error
{
       if (error) {
        [GCDQueue executeInMainQueue:^{
            transferViewVc.comfrimButton.enabled = YES;
            [MBProgressHUD showToastwithText:[LMErrorCodeTool showToastErrorType:ToastErrorTypeWallet withErrorCode:error.code withUrl:nil] withType:ToastTypeFail showInView:transferViewVc.view complete:nil];
            return ;
        }];
    } else {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:transferViewVc.view];
            transferViewVc.comfrimButton.enabled = YES;
        }];
        
        
        LMRawTransactionModel *rawModel = [LMRawTransactionModel new];
        rawModel.unspent = unspent;
        rawModel.toAddresses = toAddresses;
        
        // check packet
        BOOL packge = [LMUnspentCheckTool checkPackgeWithRawTrancation:rawModel];
        if (!packge) {
            transferViewVc.comfrimButton.enabled = YES;
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Too much transaction can not generated", nil) withType:ToastTypeFail showInView:transferViewVc.view complete:nil];
            }];
            return;
        }
        
        // Balance check
        BOOL blanceCheck = [LMUnspentCheckTool checkBlanceEnoughWithRawTrancation:rawModel];
        if (!blanceCheck) {
            transferViewVc.comfrimButton.enabled = YES;
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Insufficient balance", nil) withType:ToastTypeFail showInView:transferViewVc.view complete:nil];
            }];
            return;
        }
        
        // Turned out the amount of dirty check
        BOOL amountDust = [LMUnspentCheckTool checkToAddressAmountDustWithToAddresses:toAddresses];
        if (amountDust) {
            transferViewVc.comfrimButton.enabled = YES;
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Amount is too small", nil) withType:ToastTypeFail showInView:transferViewVc.view complete:nil];
            }];
            return;
        }
        
        // Charge check
        rawModel = [LMUnspentCheckTool checkFeeWithRawTrancation:rawModel toAddresses:toAddresses];
        
        switch (rawModel.unspentErrorType) {
            case UnspentErrorTypeAutoFeeTooLarge: // Greater than the automatic calculation of the fee
            {
                NSString *tips = [NSString stringWithFormat:LMLocalizedString(@"Wallet Auto fees is greater than the maximum set maximum and continue", nil),
                                  [PayTool getBtcStringWithAmount:rawModel.autoFee]];
                [UIAlertController showAlertInViewController:transferViewVc withTitle:LMLocalizedString(@"Set tip title", nil) message:tips cancelButtonTitle:LMLocalizedString(@"Common Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:@[LMLocalizedString(@"Common OK", nil)] tapBlock:^(UIAlertController *_Nonnull controller, UIAlertAction *_Nonnull action, NSInteger buttonIndex) {
                    switch (buttonIndex) {
                        case 0: {
                            transferViewVc.comfrimButton.enabled = YES;
                        }
                            break;
                        case 2: //click button
                        {
                            rawModel.unspent.fee = [[MMAppSetting sharedSetting] getMaxTranferFee]; // set max
                            // blance check
                            BOOL balance = [LMUnspentCheckTool checkBlanceEnoughithRawTrancation:rawModel];
                            if (!balance) {
                                transferViewVc.comfrimButton.enabled = YES;
                                [GCDQueue executeInMainQueue:^{
                                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Insufficient balance", nil) withType:ToastTypeFail showInView:transferViewVc.view complete:nil];
                                }];
                            } else {
                                
                                switch (transferType) {
                                        // Check for change
                                    case TransferTypeOuterTransfer:  // External transfer
                                    {
                                        [transferViewVc checkChangeWithRawTrancationModel:rawModel billing:billing];
                                    }
                                        break;
                                    case TransferTypeBitAddress:    // Bitcoin address transfer
                                    {
                                        [transferViewVc checkChangeWithRawTrancationModel:rawModel amount:money note:note];
                                    }
                                        break;
                                    case TransferTypeRedPag:        // Red envelope address transfer LMChatRedLuckyViewController
                                    {
                                        [transferViewVc checkChangeWithRawTrancationModel:rawModel ordinaryRed:ordinaryRed note:note money:money type:type];
                                    }
                                       break;
                                    case TransferTypeTransFriend:     // transfer to friends
                                    {
                                        [transferViewVc checkChangeWithRawTrancationModel:rawModel note:note money:money];
                                    }
                                        break;
                                    case TransferTypeChatSingle:       // single transfer
                                    {
                                        [transferViewVc checkChangeWithRawTrancationModel:rawModel amount:money note:note];
                                    }
                                        break;
                                    case TransferTypezChouTransfer:   // crowd transfer
                                    {
                                       
                                       [transferViewVc checkChangeWithRawTrancationModel:rawModel amount: [money doubleValue]];
                                    }
                                        break;
                                    case TransferTypeSetMoney:          // set result
                                    {
                                        [transferViewVc checkChangeWithRawTrancationModel:rawModel];
                                    }
                                        break;
                                    case TransferTypeNotes:             // transfer note
                                    {
                                        [transferViewVc checkChangeWithRawTrancationModel:rawModel decimalMoney:money];
                                    }
                                        break;
                                    case TransferTypeUnsSetResult:      // no set result
                                    {
                                        [transferViewVc checkChangeWithRawTrancationModel:rawModel decimalMoney:money note:note];
                                    }
                                        break;

                                        
                                    default:
                                        break;
                                }
                                
                            }
                        }
                            break;
                        default:
                            break;
                    }
                }];
            }
                break;
            case UnspentErrorTypeSmallFee:// Set the fee is too small
            {
                [UIAlertController showAlertInViewController:transferViewVc withTitle:LMLocalizedString(@"Set tip title", nil) message:LMLocalizedString(@"Wallet Transaction fee too low Continue", nil) cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@[LMLocalizedString(@"Common Cancel", nil), LMLocalizedString(@"Common OK", nil)] tapBlock:^(UIAlertController *_Nonnull controller, UIAlertAction *_Nonnull action, NSInteger buttonIndex) {
                    switch (buttonIndex) {
                        case 2: {
                            transferViewVc.comfrimButton.enabled = YES;
                        }
                            break;
                        case 3: {
                            BOOL balance = [LMUnspentCheckTool checkBlanceEnoughithRawTrancation:rawModel];
                            if (!balance) {
                                transferViewVc.comfrimButton.enabled = YES;
                                [GCDQueue executeInMainQueue:^{
                                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Insufficient balance", nil) withType:ToastTypeFail showInView:transferViewVc.view complete:nil];
                                }];
                            } else {
                                switch (transferType) {
                                         // Check for change
                                    case TransferTypeOuterTransfer:  // External transfer
                                    {
                                        [transferViewVc checkChangeWithRawTrancationModel:rawModel billing:billing];
                                    }
                                        break;
                                    case TransferTypeBitAddress:   // Bitcoin address transfer
                                    {
                                        [transferViewVc checkChangeWithRawTrancationModel:rawModel amount:money note:note];
                                    }
                                        break;
                                    case TransferTypeRedPag:        // Red envelope address transfer LMChatRedLuckyViewController
                                    {
                                        [transferViewVc checkChangeWithRawTrancationModel:rawModel ordinaryRed:ordinaryRed note:note money:money type:type];
                                    }
                                        break;
                                    case TransferTypeTransFriend:    // Transfer to friends
                                    {
                                        [transferViewVc checkChangeWithRawTrancationModel:rawModel note:note money:money];
                                    }
                                        break;
                                    case TransferTypeChatSingle:    // Single transfer
                                    {
                                        [transferViewVc checkChangeWithRawTrancationModel:rawModel amount:money note:note];
                                    }
                                        break;
                                    case TransferTypezChouTransfer:  // All funds transfer
                                    {
                                        [transferViewVc checkChangeWithRawTrancationModel:rawModel amount: [money doubleValue]];
                                    }
                                        break;
                                    case TransferTypeSetMoney:       // Set the payment result
                                    {
                                        [transferViewVc checkChangeWithRawTrancationModel:rawModel];
                                    }
                                        break;
                                    case TransferTypeNotes:           // Transfer notes
                                    {
                                        [transferViewVc checkChangeWithRawTrancationModel:rawModel decimalMoney:money];
                                    }
                                        break;
                                    case TransferTypeUnsSetResult:     // No payment results are set
                                    {
                                        [transferViewVc checkChangeWithRawTrancationModel:rawModel decimalMoney:money note:note];
                                    }
                                        break;
                                        
                                        
                                    default:
                                        break;
                                }
                                
                            }
                        }
                            break;
                        default:
                            break;
                    }
                }];
            }
                break;
            case UnspentErrorTypeNoError:// no problem
            {
                switch (transferType) {
                        // Check for change
                    case TransferTypeOuterTransfer:  // out transfer
                    {
                        [transferViewVc checkChangeWithRawTrancationModel:rawModel billing:billing];
                    }
                        break;
                    case TransferTypeBitAddress:    // btc address
                    {
                        [transferViewVc checkChangeWithRawTrancationModel:rawModel amount:money note:note];
                    }
                        break;
                    case TransferTypeRedPag:        // red pack transfer LMChatRedLuckyViewController
                    {
                        [transferViewVc checkChangeWithRawTrancationModel:rawModel ordinaryRed:ordinaryRed note:note money:money type:type];
                    }
                        break;
                    case TransferTypeTransFriend:   // Transfer to friends
                    {
                        [transferViewVc checkChangeWithRawTrancationModel:rawModel note:note money:money];
                    }
                        break;
                    case TransferTypeChatSingle:    // Single transfer
                    {
                        [transferViewVc checkChangeWithRawTrancationModel:rawModel amount:money note:note];
                    }
                        break;
                    case TransferTypezChouTransfer:   // All funds transfer
                    {
                        [transferViewVc checkChangeWithRawTrancationModel:rawModel amount:[money doubleValue]];
                    }
                        break;
                    case TransferTypeSetMoney:       // Set the payment result
                    {
                        [transferViewVc checkChangeWithRawTrancationModel:rawModel];
                    }
                        break;
                    case TransferTypeNotes:           // Transfer notes
                    {
                        [transferViewVc checkChangeWithRawTrancationModel:rawModel decimalMoney:money];
                    }
                        break;
                    case TransferTypeUnsSetResult:     // No payment results are set
                    {
                        [transferViewVc checkChangeWithRawTrancationModel:rawModel decimalMoney:money note:note];
                    }
                        break;
                        
                    default:
                        break;
                }
            }
                break;
                
            default:
                break;
        }
    }

}
/**
 *   Click the relevant button to verify the legitimacy
 *
 */
+(NSInteger)checkMoneyNumber:(NSDecimalNumber*)number withTransfer:(BOOL)flag
{
    // All the ratio of the conversion rate by bit currency
    if (flag) {  // transfer
        if (number.doubleValue > MAX_TRANSFER_AMOUNT) {
            return MoneyTypeTransferBig;
        }
        if (number.doubleValue < MIN_TRANSFER_AMOUNT) {
            return MoneyTypeTransferSmall;
        }
        
    }else         // red pack
    {
        if (number.doubleValue > MAX_REDBAG_AMOUNT) {
            return MoneyTypeRedBig;
        }
        if (number.doubleValue < MAX_REDMIN_AMOUNT) {
            return MoneyTypeRedSmall;
        }
    }
    return MoneyTypeCommon;;
}
@end
