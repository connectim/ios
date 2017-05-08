//
//  GJAssetsPickerScrollView.h
//  GJAssetsPickerViewController
//
//  Created by ZYVincent on 14-9-8.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GJCFAssetsPickerPreviewItemViewController.h"

/* Supports zoomed UIScrollView */
@interface GJCFAssetsPickerScrollView : UIScrollView<UIScrollViewDelegate>

/* Used to display the current picture */
@property (nonatomic,strong)UIImageView *contentImageView;

/* Image data source*/
@property (nonatomic,weak)id<GJCFAssetsPickerPreviewItemViewControllerDataSource> dataSource;

/* Current index */
@property (nonatomic,assign)NSInteger index;

@end
