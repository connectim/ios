//
//  GJAssetsPreviewController.h
//  GJAssetsPickerViewController
//
//  Created by ZYVincent on 14-9-8.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GJCFAsset.h"
#import "GJCFAssetsPickerStyle.h"

@class GJCFAssetsPreviewController;

@protocol GJCFAssetsPreviewControllerDelegate <NSObject>


- (GJCFAssetsPickerStyle*)previewControllerShouldCustomStyle:(GJCFAssetsPreviewController*)previewController;


- (void)previewController:(GJCFAssetsPreviewController*)previewController didUpdateAssetSelectedState:(GJCFAsset*)asset;

@end

@interface GJCFAssetsPreviewController : UIPageViewController

@property (nonatomic,weak)id<GJCFAssetsPreviewControllerDelegate> previewDelegate;

/* Start browsing location */
@property (nonatomic,assign)NSInteger pageIndex;

/* Photo data source */
@property (nonatomic,strong)NSMutableArray *assets;

/* Bottom custom toolbar */
@property (nonatomic,strong)UIImageView    *customBottomToolBar;

/* When not under preview mode, you can use this title to override the index header below the preview mode */
@property (nonatomic,strong)NSString *importantTitle;

/* Multi-pattern selection mode below the maximum number of selected */
@property (nonatomic,assign)NSInteger mutilSelectLimitCount;

- (instancetype)initWithAssets:(NSArray*)sAsstes;

@end
