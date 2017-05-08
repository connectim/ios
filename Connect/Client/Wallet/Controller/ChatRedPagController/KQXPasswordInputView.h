//
//  KQXPasswordInputView.h
//  KQXPasswordInputViewDemo
//
//  Created by Qingxu Kuang on 16/7/31.
//  Copyright © 2016年 Asahi Kuang. All rights reserved.
//

#import <UIKit/UIKit.h>

//=============== KQXPasswordInputView======================//
typedef enum KQXPasswordInputViewStyle : NSInteger {
    KQXPasswordInputViewStyleWithFunctionButton = 0,    // There is an operation button
    KQXPasswordInputViewStyleWithoutFunctionButton      // No operation button
} kqxInputViewStyle;

typedef void (^fillPasswordComplete)(NSString *password);

@interface KQXPasswordInputView : UIView

@property(nonatomic, copy) fillPasswordComplete fillCompleteBlock;

/** @brief Singleton constructs the password input box.
 *  @param frame: View size。
 *  @param title: title.。
 *  @param description: Subtitle description。
 *  @param style: Password input box style。
 *  @return Return to the password input box instance object。
 */
+ (instancetype)sharedPasswordInputViewWithFrame:(CGRect)frame tittle:(NSString *)title description:(NSString *)description style:(kqxInputViewStyle)style;

/** @brief Pop-up password input box view。
 */
- (void)showPasswordInputView;

/** @brief Put the password input box view。
 */
- (void)dismissPasswordInputView;

/** @brief Change the input box style。
 *  @param style:
 *  @see KQXPsswordInputViewStyle
 */
- (void)changeStyle:(kqxInputViewStyle)style;

/** @brief update title。
 *  @param title: title。
 *  @param description: text。
 **/
- (void)updateTitle:(NSString *)title description:(NSString *)descriptionString;

/** @brief update title。
 *  @param title: title。
 *  @param description: description。
 *  @param moneyString:moneyString。
 **/
- (void)updateTitle:(NSString *)title description:(NSString *)descriptionString moneyValueString:(NSString *)moneyString;

/** @brief error
 *  @param errorString errorString
 */
- (void)showErrorTip:(NSString *)errorString;

/**
 *  @brief display view。
 *  @param successString successString
 */
- (void)showSuccessTip:(NSString *)successString;

/** @brief context。
 */
- (void)clearContents;

@end
