//
//  HWPopTool.h
//  HWPopTool
//
//  Created by HenryCheng on 16/1/11.
//  Copyright © 2016年 www.igancao.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
/**
 *  Close the position of the button
 */
typedef NS_ENUM(NSInteger, ButtonPositionType) {
    /**
     *  nothing
     */
    ButtonPositionTypeNone = 0,
    /**
     *  left
     */
    ButtonPositionTypeLeft = 1 << 0,
    /**
     *  right
     */
    ButtonPositionTypeRight = 2 << 0
};
/**
 *  Mask the background color
 */
typedef NS_ENUM(NSInteger, ShadeBackgroundType) {
    /**
     *  Gradient color
     */
    ShadeBackgroundTypeGradient = 0,
    /**
     *  Fixed color
     */
    ShadeBackgroundTypeSolid = 1 << 0
};

typedef void(^completeBlock)(void);

@interface LMQRcodePopView : NSObject

@property (strong, nonatomic) UIColor *popBackgroudColor;
@property (assign, nonatomic) BOOL tapOutsideToDismiss;
@property (assign, nonatomic) ButtonPositionType closeButtonType;
@property (assign, nonatomic) ShadeBackgroundType shadeBackgroundType;

/**
 *  Create an instance
 *
 *  @return CHWPopTool
 */
+ (LMQRcodePopView *)sharedInstance;
/**
 *  Pop up the view to be displayed
 *
 *  @param presentView show View
 *  @param animated    Whether it is animated
 */
- (void)showWithPresentView:(UIView *)presentView animated:(BOOL)animated;
/**
 *  Close the pop-up view
 *
 *  @param complete complete block
 */
- (void)closeWithBlcok:(void(^)())complete;

@end

