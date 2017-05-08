//
//  GJAssetsPickerViewControllerDelegate.h
//  GJAssetsPickerViewController
//
//  Created by ZYVincent on 14-9-8.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import "GJCFAssetsPickerStyle.h"
#import "GJCFAssetsPickerConstans.h"

@class GJCFAssetsPickerViewController;

/* GJAssetsPickerViewController 可响应的一些代理方法 */
@protocol GJCFAssetsPickerViewControllerDelegate <NSObject>

/* It is recommended to enforce these proxy methods to monitor abnormal behavior in order to avoid forgetting to implement the agent, and feel the picture can not continue to click on the selected confusion */
@required

/*
   * Executes when the image selection view reaches the limit of multiple selections
   *
   * @prama limitCount Returns the maximum number of multi-select quantities
 */
- (void)pickerViewController:(GJCFAssetsPickerViewController*)pickerViewController didReachLimitSelectedCount:(NSInteger)limitCount;


/*
 * When the picture selection wants to preview but not selected when the implementation of the picture
 *
 */
- (void)pickerViewControllerRequirePreviewButNoSelectedImage:(GJCFAssetsPickerViewController*)pickerViewController;

/*
 * Executed when the image selection has no access authorization
 *
 */
- (void)pickerViewControllerPhotoLibraryAccessDidNotAuthorized:(GJCFAssetsPickerViewController*)pickerViewController;


@optional

/*
 * Picture selection view need to pickerStyle through the definition of some UI when you can call this agent to achieve, otherwise all call [GJAssetsPickerStyle defaultStyle]
 *
 */
- (GJCFAssetsPickerStyle*)pickerViewShouldUseCustomStyle:(GJCFAssetsPickerViewController*)pickerViewController;

/*
 *  When the picture selection view will disappear when the implementation
 */
- (void)pickerViewControllerWillCancel:(GJCFAssetsPickerViewController*)pickerViewController;

/*
   * When the image selection is completed after the implementation of this proxy method, the selected picture back to the caller
   *
   * @param resultArray Returns the selected image content as an array of GJAsset objects
 */
- (void)pickerViewController:(GJCFAssetsPickerViewController*)pickerViewController didFinishChooseMedia:(NSArray *)resultArray;

/*
   * Execute this method when an image selection error occurs
   *
   * @param errorMsg occurred error message content errorType occurred in the wrong type
 */
- (void)pickerViewController:(GJCFAssetsPickerViewController*)pickerViewController didFaildWithErrorMsg:(NSString*)errorMsg withErrorType:(GJAssetsPickerErrorType)errorType;

@end
