//
//  UINavigationBar+Awesome.h
//  LTNavigationBar
//
//  Created by ltebean on 15-2-15.
//  Copyright (c) 2015 ltebean. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UINavigationBar (Awesome)
- (void)lt_setBackgroundColor:(UIColor *)backgroundColor;
- (void)lt_setElementsAlpha:(CGFloat)alpha;
- (void)lt_setTranslationY:(CGFloat)translationY;
- (void)lt_reset;


/**
 * Hide 1px hairline of the nav bar
 */
- (void)hideBottomHairline;

/**
 * Show 1px hairline of the nav bar
 */
- (void)showBottomHairline;

/**
 * Makes the navigation bar background transparent.
 */
- (void)makeTransparent;

/**
 * Restores the default navigation bar appeareance
 **/
- (void)makeDefault;
@end
