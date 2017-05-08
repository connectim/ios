//
//  UIView+ScreenShot.h
//  Connect
//
//  Created by MoHuilin on 16/7/27.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (ScreenShot)

- (UIImage *)screenShot;

- (UIImage *)screenShotWithFrame:(CGRect)frame;



/**
   * @brief view screenshot
   *
   * @return screenshots
 */
- (UIImage *)screenshotOther;

/**
 *  @author Jakey
 *
 * @brief screenshot All views in a view include rotation scaling effects
 *
 * @param aView a view
 * @param limitWidth limits the maximum width of the zoom to the default pass 0
 *
 * @return screenshots
 */
- (UIImage *)screenshot:(CGFloat)maxWidth;


@end
