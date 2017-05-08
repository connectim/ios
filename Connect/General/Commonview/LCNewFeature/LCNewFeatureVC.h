//
//  Created by 刘超 on 15/4/30.
//  Copyright (c) 2015年 Leo. All rights reserved.
//
//  Mail:   mailto:devtip@163.com
//  GitHub: http://github.com/iTofu
//  如有问题或建议请给我发邮件, 或在该项目的 GitHub 主页提 Issue, 谢谢:)
//
//  V 1.1.2

#import <UIKit/UIKit.h>


// screen size
#define LC_NEW_FEATURE_SCREEN_SIZE  [UIScreen mainScreen].bounds.size

@class LCNewFeatureVC;

/**
 *  Complete the block callback after the new feature interface is displayed
 */
typedef void (^LCNewFeatureFinishBlock)();

//typedef void (^LCNewFeaturePageBlock)(NSInteger page);

/**
  *  Status bar style
 */
typedef enum : NSUInteger {
    LCStatusBarStyleBlack,  // black
    LCStatusBarStyleWhite,  // white
    LCStatusBarStyleNone,   // hide
} LCStatusBarStyle;

/**
  *  device id
 */
typedef enum : NSUInteger {
    DeviceModelUnknow,      // unkown device
    DeviceModeliPhone4,     // iPhone 4 / 4s
    DeviceModeliPhone56,    // iPhone 5 / 5s / 6 / 6 p / 6s / 6s p
    DeviceModeliPad,        // iPad
} DeviceModel;


@protocol LCNewFeatureVCDelegate <NSObject>

@optional

/**
 *  Proxy method, callback current page number
 *
 *  @param newFeatureVC Controller
 *  @param page         Current page number
 */
- (void)newFeatureVC:(LCNewFeatureVC *)newFeatureVC page:(NSInteger)page;

@end



@interface LCNewFeatureVC : UIViewController



#pragma mark -  Properties

/**
 *  The color of the current point (paging controller)
 */
@property (nonatomic, strong) UIColor *pointCurrentColor;

/**
 *  Other point (paging controller) color
 */
@property (nonatomic, strong) UIColor *pointOtherColor;

/**
 *  Status bar style, please refer to the `read` section 3 settings
 */
@property (nonatomic, assign) LCStatusBarStyle statusBarStyle;

/**
 *  Whether to display the skip button is not displayed by default
 */
@property (nonatomic, assign) BOOL showSkip;

/**
 *  Click the block to skip the button
 */
@property (nonatomic, copy) LCNewFeatureFinishBlock skipBlock;

/**
 *  delegate
 */
@property (nonatomic, weak) id<LCNewFeatureVCDelegate> delegate;
#pragma mark - funtion Methods

/**
 *  Whether to display the new feature view controller, compared with the version number that
 */
+ (BOOL)shouldShowNewFeature;

/**
 *  Initialize the new feature view controller, class method
 *
 *  @param imageName Image name, please change the original name to the format: `<imageName> _1`,` <imageName> _2` ... such as: `NewFeature_1 @ 2x.png``
 *
 *  @param imageCount photo number
 *
 *  @param showPageControl Whether to display the paging controller
 *
 *  @param enterButton Enter the button on the main interface
 *
 *  @return Initialize the controller instance
 */
+ (instancetype)newFeatureWithImageName:(NSString *)imageName
                             imageCount:(NSInteger)imageCount
                        showPageControl:(BOOL)showPageControl
                            enterButton:(UIButton *)enterButton;

/**
 *  Initialize the new feature view controller, instance method
 *
 *  @param imageName Image name, please change the original name to the format: `<imageName> _1`,` <imageName> _2` ... such as: `NewFeature_1 @ 2x.png`
 *
 *  @param imageCount photo number
 *
 *  @param showPageControl Whether to display the paging controller
 *
 *  @param enterButton Enter the button on the main interface
 *
 *  @return Initialize the controller instance
 */
- (instancetype)initWithImageName:(NSString *)imageName
                       imageCount:(NSInteger)imageCount
                  showPageControl:(BOOL)showPageControl
                      enterButton:(UIButton *)enterButton;

/**
 *  Initialize the new feature view controller, class method
 *
 *  @param imageName Image name, please change the original name to the format: `<imageName> _1`,` <imageName> _2` ... such as: `NewFeature_1 @ 2x.png``
 *
 *  @param imageCount photo number
 *
 *  @param showPageControl Whether to display the paging controller
 *
 *  @param enterButton Enter the button on the main interface
 *
 *  @return Initialize the controller instance
 */
+ (instancetype)newFeatureWithImageName:(NSString *)imageName
                             imageCount:(NSInteger)imageCount
                        showPageControl:(BOOL)showPageControl
                            finishBlock:(LCNewFeatureFinishBlock)finishBlock;

/**
 *  Initialize the new feature view controller, class method
 *
 *  @param imageName Image name, please change the original name to the format: `<imageName> _1`,` <imageName> _2` ... such as: `NewFeature_1 @ 2x.png``
 *
 *  @param imageCount photo number
 *
 *  @param showPageControl Whether to display the paging controller
 *
 *  @param enterButton Enter the button on the main interface
 *
 *  @return Initialize the controller instance
 */
- (instancetype)initWithImageName:(NSString *)imageName
                       imageCount:(NSInteger)imageCount
                  showPageControl:(BOOL)showPageControl
                      finishBlock:(LCNewFeatureFinishBlock)finishBlock;

@end
