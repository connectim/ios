//
//  HandleUrlManager.m
//  Connect
//
//  Created by MoHuilin on 2016/11/16.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "HandleUrlManager.h"
#import "NSURL+Param.h"
#import "UserDBManager.h"
#import "UserDetailPage.h"
#import "InviteUserPage.h"
#import "NetWorkOperationTool.h"
#import "LMSetMoneyResultViewController.h"
#import "LMUnSetMoneyResultViewController.h"
#import "IMService.h"

@implementation HandleUrlManager

/**
 *
 *  url = [NSURL URLWithString:@"connectim://friend?address=12GMLiboaCBfBHpp71gZyqu4cUacD1eC2Z"];
 *  url = [NSURL URLWithString:@"connectim://pay?address=12GMLiboaCBfBHpp71gZyqu4cUacD1eC2Z&amount=0.4"];
 *  url = [NSURL URLWithString:@"connectim://pay?address=12GMLiboaCBfBHpp71gZyqu4cUacD1eC2Z"];
 *  "connectim://transfer?token="
 *  "connectim://packet?token="
 */
+ (void)handleOpenURL:(NSURL *)url {

    //login user
    if (![[MMAppSetting sharedSetting] haveLoginAddress]) {
        return;
    }

    NSDictionary *parms = [url parameters];
    NSString *urlString = url.absoluteString;

    UIViewController *controller = (UIViewController *) [UIApplication sharedApplication].keyWindow.rootViewController;
    if ([controller isKindOfClass:[UITabBarController class]]) {
        
        UITabBarController *mainTabController = (UITabBarController *) controller;
        UINavigationController *nav = [mainTabController.viewControllers objectAtIndexCheck:mainTabController.selectedIndex];

        [nav popToRootViewControllerAnimated:NO];
        switch ([self getUrlType:urlString]) {
                
            case UrlTypeFriend: {
                
                NSString *address = [parms valueForKey:@"address"];
                if ([KeyHandle checkAddress:address]) {
                    AccountInfo *user = [[UserDBManager sharedManager] getUserByAddress:address];
                    if (!user.stranger) {
                        UserDetailPage *page = [[UserDetailPage alloc] initWithUser:user];
                        page.hidesBottomBarWhenPushed = YES;
                        [nav pushViewController:page animated:YES];
                    } else {
                        if (user) {
                            InviteUserPage *page = [[InviteUserPage alloc] initWithUser:user];
                            page.sourceType = UserSourceTypeTransaction;
                            page.hidesBottomBarWhenPushed = YES;
                            [nav pushViewController:page animated:YES];
                        } else {
                            SearchUser *usrAddInfo = [[SearchUser alloc] init];
                            usrAddInfo.criteria = address;
                            [NetWorkOperationTool POSTWithUrlString:ContactUserSearchUrl postProtoData:usrAddInfo.data complete:^(id response) {
                                NSError *error;
                                HttpResponse *respon = (HttpResponse *) response;
                                if (respon.code == successCode) {
                                    NSData *data = [ConnectTool decodeHttpResponse:respon];
                                    if (data) {
                                        UserInfo *info = [[UserInfo alloc] initWithData:data error:&error];
                                        if (error) {
                                            return;
                                        }
                                        AccountInfo *accoutInfo = [[AccountInfo alloc] init];
                                        accoutInfo.username = info.username;
                                        accoutInfo.avatar = info.avatar;
                                        accoutInfo.pub_key = info.pubKey;
                                        accoutInfo.address = info.address;
                                        [GCDQueue executeInMainQueue:^{
                                            InviteUserPage *page = [[InviteUserPage alloc] initWithUser:accoutInfo];
                                            page.hidesBottomBarWhenPushed = YES;
                                            [nav pushViewController:page animated:YES];
                                        }];
                                        
                                    }
                                } else {
                                    
                                }
                            }                                  fail:^(NSError *error) {
                                
                            }];
                        }
                    }
                }
            }
                break;
            case UrlTypePay: {
                
                NSString *address = [parms valueForKey:@"address"];
                NSDecimalNumber *decimalAmount = nil;
                if ([parms valueForKey:@"amount"]) {
                    decimalAmount = [NSDecimalNumber decimalNumberWithString:[parms valueForKey:@"amount"]];
                }
                
                if (GJCFStringIsNull(address) || ![KeyHandle checkAddress:address]) {
                    return;
                }
                
                if (decimalAmount.doubleValue > 0) {
                    AccountInfo *info = [[UserDBManager sharedManager] getUserByAddress:address];
                    if (info) {
                        LMSetMoneyResultViewController *unsetVc = [[LMSetMoneyResultViewController alloc] init];
                        unsetVc.info = info;
                        unsetVc.trasferAmount = [NSDecimalNumber decimalNumberWithString:decimalAmount.stringValue];
                        unsetVc.hidesBottomBarWhenPushed = YES;
                        [nav pushViewController:unsetVc animated:YES];
                    } else {
                        SearchUser *usrAddInfo = [[SearchUser alloc] init];
                        usrAddInfo.criteria = address;
                        [NetWorkOperationTool POSTWithUrlString:ContactUserSearchUrl postProtoData:usrAddInfo.data complete:^(id response) {
                            NSError *error;
                            HttpResponse *respon = (HttpResponse *) response;
                            NSData *data = [ConnectTool decodeHttpResponse:respon];
                            if (data) {
                                
                                UserInfo *info = [[UserInfo alloc] initWithData:data error:&error];
                                if (error) {
                                    return;
                                }
                                AccountInfo *accoutInfo = [[AccountInfo alloc] init];
                                accoutInfo.username = info.username;
                                accoutInfo.avatar = info.avatar;
                                accoutInfo.pub_key = info.pubKey;
                                accoutInfo.address = info.address;
                                [GCDQueue executeInMainQueue:^{
                                    LMSetMoneyResultViewController *unsetVc = [[LMSetMoneyResultViewController alloc] init];
                                    unsetVc.info = accoutInfo;
                                    unsetVc.trasferAmount = [NSDecimalNumber decimalNumberWithString:decimalAmount.stringValue];
                                    unsetVc.hidesBottomBarWhenPushed = YES;
                                    [nav pushViewController:unsetVc animated:YES];
                                }];
                            } else {
                                return;
                            }
                        }                                  fail:^(NSError *error) {
                        }];
                    }
                } else {
                    AccountInfo *info = [[UserDBManager sharedManager] getUserByAddress:address];
                    if (info) {
                        LMUnSetMoneyResultViewController *unsetVc = [[LMUnSetMoneyResultViewController alloc] init];
                        unsetVc.info = info;
                        unsetVc.hidesBottomBarWhenPushed = YES;
                        [nav pushViewController:unsetVc animated:YES];
                    } else {
                        SearchUser *usrAddInfo = [[SearchUser alloc] init];
                        usrAddInfo.criteria = address;
                        [NetWorkOperationTool POSTWithUrlString:ContactUserSearchUrl postProtoData:usrAddInfo.data complete:^(id response) {
                            NSError *error;
                            HttpResponse *respon = (HttpResponse *) response;
                            if (respon.code != successCode) {
                                return;
                            }
                            NSData *data = [ConnectTool decodeHttpResponse:respon];
                            if (data) {
                                UserInfo *info = [[UserInfo alloc] initWithData:data error:&error];
                                if (error) {
                                    return;
                                }
                                AccountInfo *accoutInfo = [[AccountInfo alloc] init];
                                accoutInfo.username = info.username;
                                accoutInfo.avatar = info.avatar;
                                accoutInfo.pub_key = info.pubKey;
                                accoutInfo.address = info.address;
                                [GCDQueue executeInMainQueue:^{
                                    LMUnSetMoneyResultViewController *unsetVc = [[LMUnSetMoneyResultViewController alloc] init];
                                    unsetVc.info = accoutInfo;
                                    unsetVc.hidesBottomBarWhenPushed = YES;
                                    [nav pushViewController:unsetVc animated:YES];
                                }];
                            }
                        }                                  fail:^(NSError *error) {
                            
                        }];
                    }
                }
            }
                break;
            case UrlTypeTransfer: {
                
                NSString *token = [parms valueForKey:@"token"];
                [GCDQueue executeInMainQueue:^{
                    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
                    window.userInteractionEnabled = NO;
                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:window animated:YES];
                    hud.labelText = LMLocalizedString(@"Receiving", nil);
                }];
                if (!GJCFStringIsNull(token)) {
                    [[IMService instance] reciveMoneyWihtToken:token complete:^(NSError *erro, id data) {
                        
                    }];
                }
            }
                break;
            case UrlTypePacket: {
                
                [GCDQueue executeInMainQueue:^{
                    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
                    window.userInteractionEnabled = NO;
                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:window animated:YES];
                    hud.labelText = LMLocalizedString(@"Receiving", nil);
                }];
                NSString *token = [parms valueForKey:@"token"];
                if (!GJCFStringIsNull(token)) {
                    [[IMService instance] openRedPacketWihtToken:token complete:^(NSError *erro, id data) {
                        
                    }];
                }
            }
                break;
            case UrlTypeGroup: {
                
                NSString *token = [parms valueForKey:@"token"];
                if (!GJCFStringIsNull(token)) {
                    [GCDQueue executeInMainQueue:^{
                        SendNotify(@"HandleGroupTokenNotification", token);
                    }];
                }
            }
                break;
            default:
                break;
        }
    }
}
/* get type*/
+ (NSUInteger)getUrlType:(NSString *)urlString {
    
    if ([urlString containsString:@"friend"]) {
        
        return UrlTypeFriend;
        
    } else if ([urlString containsString:@"pay"]) {
        
        return UrlTypePay;
        
    } else if ([urlString containsString:@"transfer"]) {
        
        return UrlTypeTransfer;
    
    } else if ([urlString containsString:@"packet"]) {
        
        return UrlTypePacket;
        
    } else if ([urlString containsString:@"group"]) {
        
        return UrlTypeGroup;
    }else {
        
        return UrlTypeCommon;
        
    }

}
@end
