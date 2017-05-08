//
//  MBProgressHUD+Loading.h
//  Connect
//
//  Created by MoHuilin on 16/8/31.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <MBProgressHUD/MBProgressHUD.h>

typedef NS_ENUM(NSInteger,ToastType) {
  ToastTypeSuccess = 0,
  ToastTypeFail = 1 << 0,
  ToastTypeCommon = 2 <<0
};

@interface MBProgressHUD (Loading)

/**
   * Displays an error message
   *
   * @param message content
   *
   * @return directly returns an MBProgressHUD that needs to be closed manually
 */
+ (MBProgressHUD *)showMessage:(NSString *)message;

+ (MBProgressHUD *)showTransferLoadingViewtoView:(UIView *)view;
/**
 *
 *  @return directly returns an MBProgressHUD that needs to be closed manually
    @param toastType The type of displa
 *  
 *  
 */
+ (MBProgressHUD *)showToastwithText:(NSString*)text withType:(ToastType)toastType showInView:(UIView *)view complete:(void(^)())complete;

/**
 *  Show loading information (loading ...)
 *
 *  @param view
 *
 *  @return
 */
+ (MBProgressHUD *)showLoadingMessageToView:(UIView *)view;

/**
   * Show some information
   *
   * @param message content
   * @param view A view of the information that needs to be displayed
   *
   * @return directly returns an MBProgressHUD that needs to be closed manually
 */
+ (MBProgressHUD *)showMessage:(NSString *)message toView:(UIView *)view;
/**
 *  Manually closedMBProgressHUD
 */
+ (void)hideHUD;
/**
 *  Manually close MBProgressHUD
 *
 *  @param view    Displays the view of MBProgressHUD
 */
+ (void)hideHUDForView:(UIView *)view;

@end
