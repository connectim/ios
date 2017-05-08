//
//  GJAssetsPickerOverlayView.h
//  GJAssetsPickerViewController
//
//  Created by ZYVincent on 14-9-8.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import <UIKit/UIKit.h>


/*
 * If there is a function to view the big picture mode, the inherited implementation of the GJCFAssetsPickerOverlayView must be implemented by calling the three protocol methods, telling GJCFAssetsPickerCell to respond
 */
@class GJCFAssetsPickerOverlayView;
@protocol GJCFAssetsPickerOverlayViewDelegate <NSObject>

- (void)pickerOverlayView:(GJCFAssetsPickerOverlayView*)overlayView responseToChangeSelectedState:(BOOL)state;

- (void)pickerOverlayViewResponseToShowBigImage:(GJCFAssetsPickerOverlayView *)overlayView;

- (BOOL)pickerOverlayViewCanChangeToSelectedState:(GJCFAssetsPickerOverlayView*)overlayView;

@end
/*
   * If there is a need for persistent properties, then the subclass of this inheritance needs to implement the NSCoding protocol, otherwise it can not be properly stored
   *
   * Normally, the properties of this view do not need to be persistent, so there is no need to implement the NSCoding protocol
 */
@interface GJCFAssetsPickerOverlayView : UIView<NSCoding>

@property (nonatomic,weak)id<GJCFAssetsPickerOverlayViewDelegate> delegate;

/* Marked view is selected */
@property (nonatomic,assign)BOOL selected;

/* Whether the mark is selected */
@property (nonatomic,strong)UIImageView *selectIconImgView;

/*
 * Whether to allow a large view mode, if set to YES, then need to provide, to provide the selected mark of the touch range
 */
@property (nonatomic,assign)BOOL enableChooseToSeeBigImageAction;

/*
 * When the view mode is turned on, this touch response range is used to mark the touch in the selected effect view, the default is to select the size of the view mark
 */
@property (nonatomic,assign)CGRect frameToShowSelectedWhileBigImageActionEnabled;

/* Use the system default style tag view */
+ (GJCFAssetsPickerOverlayView*)defaultOverlayView;

/*
 * Rewrite these two methods to achieve other selected results, the default use of hidden and display the way to show the selected state
 */

/*
 * Called when the photo is selected
 */
- (void)switchSelectState;

/*
 * Call when the photo is not selected
 */
- (void)switchNormalState;

@end
