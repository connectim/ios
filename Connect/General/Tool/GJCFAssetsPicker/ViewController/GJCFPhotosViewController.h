//
//  GJPhotosViewController.h
//  GJAssetsPickerViewController
//
//  Created by ZYVincent on 14-9-8.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GJCFAssetsPickerCell.h"
#import "GJCFAlbums.h"

@class GJCFPhotosViewController;
@class GJCFAssetsPickerStyle;

@protocol GJCFPhotosViewControllerDelegate <NSObject>

@optional

/* Photo selection view requires a custom style */
- (GJCFAssetsPickerStyle*)photoViewControllerShouldUseCustomStyle:(GJCFPhotosViewController*)photoViewController;

/* Photo has been enumerated when the implementation will be completed */
- (void)photoViewController:(GJCFPhotosViewController*)photoViewController didFinishEnumrateAssets:(NSArray *)assets forAlbums:(GJCFAlbums*)destAlbums;

@end

@interface GJCFPhotosViewController : UIViewController<UITableViewDelegate,UITableViewDataSource,GJCFAssetsPickerCellDelegate>

@property (nonatomic,weak)id<GJCFPhotosViewControllerDelegate> delegate;

/* Photo list */
@property (nonatomic,strong)UITableView *assetsTable;

/* Photo data source */
@property (nonatomic,strong)NSMutableArray *assetsArray;

/* The maximum number of multiple choices */
@property (nonatomic,assign)NSInteger mutilSelectLimitCount;

/* How many columns each row has */
@property (nonatomic,assign)NSInteger colums;

/* The interval between two rows of each row */
@property (nonatomic,assign)CGFloat    columSpace;

/* Real album data source */
@property (nonatomic,strong)GJCFAlbums * albums;

/*
   * Used to pass the outer layer has been selected Assets, used to load the new Assets selection list, the direct form of selected state, has been achieved
   * However, the current demand and efficiency issues are limited and the call is temporarily invalid
 */
@property (nonatomic,strong)NSArray *shouldInitSelectedStateAssetArray;

@end
