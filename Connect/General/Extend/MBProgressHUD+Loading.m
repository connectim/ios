//
//  MBProgressHUD+Loading.m
//  Connect
//
//  Created by MoHuilin on 16/8/31.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "MBProgressHUD+Loading.h"
#import "PayHudView.h"
#import "LMShowToastView.h"

@implementation MBProgressHUD (Loading)

/**
   * Display information
   *
   * @param message content
   *
   * @return directly returns an MBProgressHUD that needs to be closed manually
 */
+ (MBProgressHUD *)showMessage:(NSString *)message
{
    return [self showMessage:message toView:nil];
}


+ (MBProgressHUD *)showTransferLoadingViewtoView:(UIView *)view{
    
    // hide
    if ([MBProgressHUD allHUDsForView:view].count) {
        [MBProgressHUD hideAllHUDsForView:view animated:NO];
    }
    
    PayHudView *cus = [[[NSBundle mainBundle]loadNibNamed:@"PayHudView" owner:self options:nil]objectAtIndexCheck:0];
    cus.size = CGSizeMake(AUTO_WIDTH(260),AUTO_WIDTH(260));
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.mode = MBProgressHUDModeCustomView;
    hud.customView = cus;
    // Looks a bit nicer if we make it square.
    hud.square = YES;               
    hud.margin = 0;
    [hud hide:YES afterDelay:10.f];
    return hud;
}

/**
   *
   * @return directly returns an MBProgressHUD that needs to be closed manually
   * @param toastType The type of display
   * @text display the text
 */
+ (MBProgressHUD *)showToastwithText:(NSString*)text withType:(ToastType)toastType showInView:(UIView *)view complete:(void(^)())complete
{
    if (view == nil) view = [[UIApplication sharedApplication].windows lastObject];
    if (!view) {
        return nil;
    }
    // hide
    if ([MBProgressHUD allHUDsForView:view].count) {
        [MBProgressHUD hideAllHUDsForView:view animated:NO];
    }
    
    LMShowToastView *cus = [[[NSBundle mainBundle]loadNibNamed:@"LMShowToastView" owner:self options:nil]objectAtIndexCheck:0];
    cus.size = CGSizeMake(DEVICE_SIZE.width * 0.64, DEVICE_SIZE.height * 0.2);
    [cus setUpWithType:toastType withDisPlayTitle:text];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.mode = MBProgressHUDModeCustomView;
    hud.customView = cus;
    hud.square = NO;
    hud.margin = 0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (complete) {
            complete();
        }
        [self hideHUDForView:view];
    });
    return hud;
}

/**
   * Show some information
   *
   * @param message content
   * @param view A view of the information that needs to be displayed
   *
   * @return directly returns an MBProgressHUD that needs to be closed manually
 */
+ (MBProgressHUD *)showMessage:(NSString *)message toView:(UIView *)view {
    view.userInteractionEnabled = NO;
    if (view == nil) view = [[UIApplication sharedApplication].windows lastObject];
    
    
    if (!view) {
        return nil;
    }

    // hide
    if ([MBProgressHUD allHUDsForView:view].count) {
        [MBProgressHUD hideAllHUDsForView:view animated:NO];
    }
    
    // Quickly display a prompt message
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    
    hud.labelText = message;
    // Hide when removed from the parent control
    hud.removeFromSuperViewOnHide = YES;
    // YES on behalf of the need for mask effect
    hud.dimBackground = NO;
    return hud;
}

+ (MBProgressHUD *)showLoadingMessageToView:(UIView *)view{
    return [self showMessage:LMLocalizedString(@"Common Loading", nil) toView:view];
}

/**
 *  Manually close MBProgressHUD
 */
+ (void)hideHUD
{
    [self hideHUDForView:nil];
}

/**
 *  Manually close MBProgressHUD
 *
 *  @param viewManually close MBProgressHUD
 */
+ (void)hideHUDForView:(UIView *)view
{
    view.userInteractionEnabled = YES;
    if (view == nil) view = [[UIApplication sharedApplication].windows lastObject];
    [self hideHUDForView:view animated:YES];
}

@end
