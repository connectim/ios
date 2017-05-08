//
//  GJAssetsPickerPreviewItemViewController.h
//  GJAssetsPickerViewController
//
//  Created by ZYVincent on 14-9-10.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GJCFAsset.h"

@protocol GJCFAssetsPickerPreviewItemViewControllerDataSource <NSObject>

/* The current need to display the picture */
- (GJCFAsset *)assetAtIndex:(NSInteger)index;

@end

@interface GJCFAssetsPickerPreviewItemViewController : UIViewController

@property (nonatomic,weak)id<GJCFAssetsPickerPreviewItemViewControllerDataSource> dataSource;

/* Current index */
@property (nonatomic,assign)NSInteger pageIndex;

+ (instancetype)itemViewForPageIndex:(NSInteger)index;

@end
