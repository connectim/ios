//
//  LMHandleScanResultManager.m
//  Connect
//
//  Created by MoHuilin on 2016/12/21.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import "LMHandleScanResultManager.h"
#import "NetWorkOperationTool.h"
#import "UserDBManager.h"
#import "LMBitAddressViewController.h"
#import "NSURL+Param.h"
#import "HandleUrlManager.h"
#import "UserDetailPage.h"
#import "InviteUserPage.h"
#import "MainWalletPage.h"
#import "LMApplyJoinToGroupViewController.h"
#import "LMChatSingleTransferViewController.h"
#import "CommonClausePage.h"
#import "StringTool.h"

#define BIT_COIN_STR @"bitcoin:"
#define AMOUNT_TIP  @"?amount"

@interface LMHandleScanResultManager ()

@property(nonatomic, strong) UIViewController *controller;
@property(nonatomic, copy) NSString *resultContent;
@property(nonatomic, strong) NSDecimalNumber *money;

@end

@implementation LMHandleScanResultManager

CREATE_SHARED_MANAGER(LMHandleScanResultManager)

- (void)handleScanResult:(NSString *)resultStr controller:(UIViewController *)controller {
    self.controller = controller;
    if ([self isHttpNetWork:resultStr]) {
        
        [self handleHttpUrl:resultStr];
        
    } else {
        if ([resultStr hasPrefix:@"group:"]) {
            
            [self appleyToGroupWithStr:resultStr];
            
        } else {
            
            [self search:resultStr];
        }
    }
}
- (void)loadWeb:(NSString *)resultStr {
    
    CommonClausePage *page = [[CommonClausePage alloc] initWithUrl:resultStr];
    page.hidesBottomBarWhenPushed = YES;
    [self.controller.navigationController pushViewController:page animated:YES];
    
}

- (BOOL)isHttpNetWork:(NSString *)resultStr {
    
    NSString *pattern = [StringTool regHttp];
    NSRegularExpression *regException = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *resultArray = [regException matchesInString:resultStr options:NSMatchingReportCompletion range:NSMakeRange(0, resultStr.length)];
    if (resultArray.count > 0) {
        
        return YES;
        
    }
    return NO;
}
- (void)handleHttpUrl:(NSString *)resultStr {
    /*
     "connectim://transfer?token="
     "connectim://packet?token="
     */
        NSURL* url = [NSURL URLWithString:resultStr];
        NSDictionary *parameters = [url parameters];
        NSString *token = [parameters valueForKey:@"token"];
    
        if (!GJCFStringIsNull(token) && [self needHttp:resultStr]) {
            if ([resultStr containsString:@"transfer?"]) {
                
                NSString *urlString = [NSString stringWithFormat:@"connectim://transfer?token=%@", token];
                [HandleUrlManager handleOpenURL:[NSURL URLWithString:urlString]];
                return;
                
            } else if ([resultStr containsString:@"packet?"]) {
                
                NSString *urlString = [NSString stringWithFormat:@"connectim://packet?token=%@", token];
                [HandleUrlManager handleOpenURL:[NSURL URLWithString:urlString]];
                return;
                
            } else if ([resultStr containsString:@"group?"]) {
                
                NSString *urlString = [NSString stringWithFormat:@"connectim://group?token=%@", token];
                [HandleUrlManager handleOpenURL:[NSURL URLWithString:urlString]];
                return;
                
            }
        }
    
       [self loadWeb:resultStr];
}
- (BOOL)needHttp:(NSString *)resultStr {
    NSString *pattern = [NSString stringWithFormat:@"(http|https)://.*\\.connect\\.im/share/%@/(packet|transfer|group)\\?token=.+",APIVersion];
    NSRegularExpression *regException = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionDotMatchesLineSeparators error:nil];
    NSArray *resultArray = [regException matchesInString:resultStr options:NSMatchingReportCompletion range:NSMakeRange(0, resultStr.length)];
    if (resultArray.count > 0) {
        
        return YES;
        
    }
    return NO;
}
- (void)handWalletWithKeyWord:(NSString *)resultStr{
    
    if ([resultStr containsString:AMOUNT_TIP]) {
        
        NSString *parm = [resultStr substringFromIndex:[resultStr rangeOfString:@"?"].location + 1];
        NSString *key = [parm componentsSeparatedByString:@"="].firstObject;
        NSString *amount = [parm substringFromIndex:(key.length + 1)];
        NSString *address = [resultStr substringWithRange:NSMakeRange([resultStr rangeOfString:@":"].location + 1, [resultStr rangeOfString:@"?"].location - [resultStr rangeOfString:@":"].location - 1)];
        self.resultContent = address;
        self.money = [NSDecimalNumber decimalNumberWithString:amount];
        
    } else {
        
        self.resultContent = [resultStr stringByReplacingOccurrencesOfString:BIT_COIN_STR withString:@""];
        self.money = 0;
        
    }

    if (![KeyHandle checkAddress:self.resultContent]) {
        
        [MBProgressHUD hideHUDForView:self.controller.view];
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LMLocalizedString(@"Wallet Result is not a bitcoin address", nil) message:LMLocalizedString(@"Login Please check that your input is correct", nil) preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *unBoundAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
            
        }];
        [alertController addAction:unBoundAction];
        [self.controller presentViewController:alertController animated:YES completion:nil];
        
    } else {

        [self getUserInfoWithStr:self.resultContent IsContainBtc:YES];
    }

}
- (void)getUserInfoWithStr:(NSString *)address IsContainBtc:(BOOL)isContainBtc {
    
    AccountInfo *info = [[UserDBManager sharedManager] getUserByAddress:address];
    if (info) { // isfriend
        if (isContainBtc) {
            
            [self userTransferWith:info];
            
        }else {
            
            UserDetailPage *page = [[UserDetailPage alloc] initWithUser:info];
            page.hidesBottomBarWhenPushed = YES;
            [self.controller.navigationController pushViewController:page animated:YES];
            
        }
        return;
    }
    // weather is regiseter
    [GCDQueue executeInMainQueue:^{
       [MBProgressHUD showLoadingMessageToView:self.controller.view];
    }];
    SearchUser *usrAddInfo = [[SearchUser alloc] init];
    usrAddInfo.criteria = address;
    [NetWorkOperationTool POSTWithUrlString:ContactUserSearchUrl postProtoData:usrAddInfo.data complete:^(id response) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:self.controller.view];
        }];
        NSError *error;
        HttpResponse *respon = (HttpResponse *) response;
        if (respon.code == 2404) {
            
            [self bitAddress:address];
            
        }else if (respon.code != successCode) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Set Query failed", nil) withType:ToastTypeFail showInView:self.controller.view complete:nil];
            }];
            return;
            
        } else if (respon.code == successCode) {
            
            NSData *data = [ConnectTool decodeHttpResponse:respon];
            if (data) {
                
                UserInfo *info = [[UserInfo alloc] initWithData:data error:&error];
                [self strangerWithInfo:info isContainBtc:isContainBtc];
                
        }else {
            
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:[LMErrorCodeTool showToastErrorType:ToastErrorTypeContact withErrorCode:respon.code withUrl:ContactUserSearchUrl] withType:ToastTypeFail showInView:self.controller.view complete:^{
                    
                }];
            }];
            
            }
        }
    }   fail:^(NSError *error) {
        
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Server Error", nil) withType:ToastTypeFail showInView:self.controller.view complete:^{
                
            }];
        }];
        
    }];
}
- (void)strangerWithInfo:(UserInfo *)info isContainBtc:(BOOL)isContainBtc{
    
    AccountInfo *accoutInfo = [[AccountInfo alloc] init];
    accoutInfo.username = info.username;
    accoutInfo.avatar = info.avatar;
    accoutInfo.pub_key = info.pubKey;
    accoutInfo.address = info.address;
    accoutInfo.stranger = YES;
    
    if (isContainBtc) {
        
        [self userTransferWith:accoutInfo];
        
    }else { //stranger ui
        
        InviteUserPage *page = [[InviteUserPage alloc] initWithUser:accoutInfo];
        page.sourceType = UserSourceTypeQrcode;
        page.hidesBottomBarWhenPushed = YES;
        [self.controller.navigationController pushViewController:page animated:YES];
        
    }

}
- (void)bitAddress:(NSString *)address {
    
    LMBitAddressViewController *page = [[LMBitAddressViewController alloc] init];
    page.address = address;
    if (self.money.doubleValue > 0) {
        page.amountString = self.money.stringValue;
    }
    page.hidesBottomBarWhenPushed = YES;
    [self.controller.navigationController pushViewController:page animated:YES];
    return;


}
- (void)userTransferWith:(AccountInfo *)info {
    
    LMChatSingleTransferViewController *singleVc = [[LMChatSingleTransferViewController alloc] init];
    if (self.money.doubleValue > 0) {
        
        singleVc.trasferAmount = self.money;
        
    }
    singleVc.info = info;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:singleVc];
    [self.controller presentViewController:nav animated:YES completion:nil];
    
}
- (void)search:(NSString *)resultStr {
    
   // Whether it is included bitcoin:
    if ([resultStr hasPrefix:BIT_COIN_STR]) {
        
        [self handWalletWithKeyWord:resultStr];
        
    }else {
        if (![KeyHandle checkAddress:resultStr]) {
            
            [MBProgressHUD hideHUDForView:self.controller.view];
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LMLocalizedString(@"Wallet Result is not a bitcoin address", nil) message:LMLocalizedString(@"Login Please check that your input is correct", nil) preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *unBoundAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
                
            }];
            [alertController addAction:unBoundAction];
            [self.controller presentViewController:alertController animated:YES completion:nil];
            
        } else {
            
            [self getUserInfoWithStr:resultStr IsContainBtc:NO];
            
        }
    }
}
- (void)appleyToGroupWithStr:(NSString *)resultStr {
    
    NSArray *array = [[resultStr stringByReplacingOccurrencesOfString:@"group:" withString:@""] componentsSeparatedByString:@"/"];
    if (array.count == 4) {
        
        LMApplyJoinToGroupViewController *page = [[LMApplyJoinToGroupViewController alloc]
                                                  initWithGroupIdentifier:[array objectAtIndex:0] hashP:resultStr];
        page.hidesBottomBarWhenPushed = YES;
        [self.controller.navigationController pushViewController:page animated:YES];
        
    }else {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Login The qrCode can not be identified", nil) withType:ToastTypeFail showInView:self.controller.view complete:nil];
        }];
    }

}

@end
