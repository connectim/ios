//
//  GJAssetsView.h
//  GJAssetsPickerViewController
//
//  Created by ZYVincent on 14-9-8.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GJCFAsset.h"
#import "GJCFAssetsPickerOverlayView.h"

/* Photo display view */
@interface GJCFAssetsView : UIView

/* Overlay the view on the photo used to compare selected and non-selected states */
@property (nonatomic,strong)GJCFAssetsPickerOverlayView *overlayView;

- (void)setAsset:(GJCFAsset*)asset;

- (void)setOverlayView:(GJCFAssetsPickerOverlayView*)aOverlayView;

@end
