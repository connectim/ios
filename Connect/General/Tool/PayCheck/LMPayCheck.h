//
//  LMPayCheck.h
//  Connect
//
//  Created by Connect on 2017/4/10.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Protofile.pbobjc.h"
#import "UnSpentInfo.h"
#import "LMBaseViewController.h"
typedef NS_ENUM(NSUInteger,TransferType) {
    TransferTypeCommon        = 1 << 0,
    TransferTypeOuterTransfer = 1 << 1,
    TransferTypeTransFriend   = 1 << 2,
    TransferTypeRedPag        = 1 << 3,
    TransferTypeBitAddress    = 1 << 4,
    TransferTypeChatSingle    = 1 << 5,
    TransferTypezChouTransfer = 1 << 6,
    TransferTypeSetMoney      = 1 << 7,
    TransferTypeNotes         = 1 << 8,
    TransferTypeUnsSetResult  = 1 << 9
};
typedef NS_ENUM(NSUInteger,MoneyType) {
    MoneyTypeCommon =        1 << 0,
    MoneyTypeTransferSmall = 1 << 1,
    MoneyTypeTransferBig =   1 << 2,
    MoneyTypeRedSmall =      1 << 3,
    MoneyTypeRedBig =        1 << 4,
    
};

@interface LMPayCheck : NSObject
/**
 *  New method. Used to make payment judgment
 *
 */
+ (void)payCheck:(OrdinaryBilling *)billing withVc:(LMBaseViewController*)transferViewVc withTransferType:(TransferType)transferType unSpent:(UnspentOrderResponse *)unspent withArray:(NSArray *)toAddresses withMoney:(NSDecimalNumber*)money withNote:(NSString *)note withType:(int)type withRedPackage:(OrdinaryRedPackage *)ordinaryRed withError:(NSError*)error;
/**
 *   Click the relevant button to verify the legitimacy
 *
 */
+ (NSInteger)checkMoneyNumber:(NSDecimalNumber*)number withTransfer:(BOOL)flag;
/**
 *   Turned out the amount of dirty check and alert
 *
 */
+ (void)dirtyAlertWithAddress:(NSArray* )toAddresses withController:(UIViewController*)controller;
@end
