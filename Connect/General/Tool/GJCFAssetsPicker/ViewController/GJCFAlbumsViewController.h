//
//  GJAlbumsViewController.h
//  GJAssetsPickerViewController
//
//  Created by ZYVincent on 14-9-8.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "GJCFAssetsPickerStyle.h"

@class GJCFAlbumsViewController;

@protocol GJCFAlbumsViewControllerDelegate <NSObject>

@optional

/* Album view requires a custom style */
- (GJCFAssetsPickerStyle*)albumsViewControllerShouldUseCustomStyle:(GJCFAlbumsViewController*)albumsViewController;

@end

@interface GJCFAlbumsViewController : UIViewController

@property (nonatomic,weak)id<GJCFAlbumsViewControllerDelegate> delegate;

/* The album uses the filter settings */
@property (nonatomic,strong)ALAssetsFilter *assetsFilter;

/* The maximum number of multiple choices */
@property (nonatomic,assign)NSUInteger mutilSelectLimitCount;

/* Picture selection list, how many columns each row has */
@property (nonatomic,assign)NSUInteger photoControllerColums;

/*
   * Used to pass the outer layer has been selected Assets, used to load the new Assets selection list, the direct form of selected state, has been achieved
   * However, the current demand and efficiency issues are limited and the call is temporarily invalid
 */
@property (nonatomic,strong)NSArray *shouldInitSelectedStateAssetArray;

/*
 *  Push the default album
 */
- (void)pushDefaultAlbums;

/*
 *  Register a custom album detail class
 */
- (void)registPhotoViewControllerClass:(Class)aPhotoViewControllerClass;

/*
 *  Register a custom album Cell, without a custom height
 */
- (void)registAlbumsCustomCellClass:(Class)aAlbumsCustomCellClass;

/*
 *  Register a custom album Cell, set a custom height
 */
- (void)registAlbumsCustomCellClass:(Class)aAlbumsCustomCellClass withCellHeight:(CGFloat)cellHeight;

@end
