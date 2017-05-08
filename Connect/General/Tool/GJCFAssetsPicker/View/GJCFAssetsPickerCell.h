//
//  GJAssetsPickerCell.h
//  GJAssetsPickerViewController
//
//  Created by ZYVincent on 14-9-8.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GJCFAssetsView.h"

@class GJCFAssetsPickerCell;

@protocol GJCFAssetsPickerCellDelegate <NSObject>

/* Called when a photo marker status in a location in the cell changes  */
- (void)assetsPickerCell:(GJCFAssetsPickerCell*)assetsPickerCell didChangeStateAtIndex:(NSInteger)index withState:(BOOL)isSelected;

/* Determines whether a photo in a location in the cell can be selected */
- (BOOL)assetsPickerCell:(GJCFAssetsPickerCell *)assetsPickerCell shouldChangeToSelectedStateAtIndex:(NSInteger)index;

/* Decided to start from a picture of the Cell into the big picture mode */
- (void)assetsPickerCell:(GJCFAssetsPickerCell *)assetsPickerCell shouldBeginBigImageShowAtIndex:(NSInteger)index;

@end

/* GJPhotosController View the cell rows */
@interface GJCFAssetsPickerCell : UITableViewCell<GJCFAssetsPickerOverlayViewDelegate>

/* How many columns are there */
@property (nonatomic,assign)NSInteger colums;

/* The distance between the two columns */
@property (nonatomic,assign)CGFloat   columSpace;

/* deleagte */
@property (nonatomic,weak)id<GJCFAssetsPickerCellDelegate> delegate;

/* A view of the tagged state */
@property (nonatomic,strong)Class overlayViewClass;

/* Whether to open the big picture browsing mode */
@property (nonatomic,assign)BOOL enableBigImageShowAction;

- (void)setAssets:(NSArray*)assets;

@end
