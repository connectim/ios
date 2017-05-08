//
//  GJAssetsPickerViewController.h
//  GJAssetsPickerViewController
//
//  Created by ZYVincent on 14-9-8.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GJCFAssetsPickerViewControllerDelegate.h"
#import "GJCFAsset.h"
#import "GJCFAssetsPickerConstans.h"

/* Request to add ALAssetsLibrary.framework */
@interface GJCFAssetsPickerViewController : UINavigationController
@property (nonatomic,weak)id<GJCFAssetsPickerViewControllerDelegate> pickerDelegate;

/*
   * Used to pass the outer layer has been selected Assets, used to load the new Assets selection list, the direct form of selected state, has been achieved
   * However, the current demand and efficiency issues are limited and the call is temporarily invalid
 */
@property (nonatomic,strong)NSArray *shouldInitSelectedStateAssetArray;

/*
 * Image Select the maximum number of times the multi-selection status is allowed
 */
@property (nonatomic,assign)NSInteger mutilSelectLimitCount;

/*
 *  Immediately disappear image selector
 */
- (void)dismissPickerViewController;

/*
 *  Register a custom photo selection details class
 */
- (void)registPhotoViewControllerClass:(Class)aPhotoViewControllerClass;

/*
 *  Register a custom album
 */
- (void)registAlbumsCustomCellClass:(Class)aAlbumsCustomCellClass;

/*
 *  Register a custom album Cell, set a custom height
 */
- (void)registAlbumsCustomCellClass:(Class)aAlbumsCustomCellClass withCellHeight:(CGFloat)cellHeight;

/*
 * Set the style directly
 */
- (void)setCustomStyle:(GJCFAssetsPickerStyle*)aCustomStyle;

/*
 *  Set the custom style that has been stored
 */
- (void)setCustomStyleByKey:(NSString*)aExistCustomStyleKey;

@end
