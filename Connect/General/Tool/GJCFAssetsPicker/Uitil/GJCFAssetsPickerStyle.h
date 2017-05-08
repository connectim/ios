//
//  GJAssetsPickerStyle.h
//  GJAssetsPickerViewController
//
//  Created by ZYVincent on 14-9-8.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GJCFAssetsPickerOverlayView.h"
#import "GJCFAssetsPickerCommonStyleDescription.h"

/* Set some persistent and efficient style to use the storage Key */
#define kGJAssetsPickerStylePersistUDF @"kGJAssetsPickerStylePersistUDF"

/*
 *  Through the inheritance of this object to achieve their own UI custom
 */
@interface GJCFAssetsPickerStyle : NSObject<NSCoding>

/*
 * System preview button style
 */
@property (nonatomic,readonly)GJCFAssetsPickerCommonStyleDescription *sysPreviewBtnDes;

/*
 * The system completes the button style
 */
@property (nonatomic,readonly)GJCFAssetsPickerCommonStyleDescription *sysFinishDoneBtDes;

/*
 * The system exits the button style
 */
@property (nonatomic,readonly)GJCFAssetsPickerCommonStyleDescription *sysCancelBtnDes;

/*
 * The system returns the button style
 */
@property (nonatomic,readonly)GJCFAssetsPickerCommonStyleDescription *sysBackBtnDes;

/*
 * The system selects the album's navigationBar style
 */
@property (nonatomic,readonly)GJCFAssetsPickerCommonStyleDescription *sysAlbumsNavigationBarDes;

/*
 * The system selects the navigationBar style of the photo
 */
@property (nonatomic,readonly)GJCFAssetsPickerCommonStyleDescription *sysPhotoNavigationBarDes;

/*
 * The system previews the NavigationBar style of the photo
 */
@property (nonatomic,readonly)GJCFAssetsPickerCommonStyleDescription *sysPreviewNavigationBarDes;

/*
 * The system previews the style of the bottom of the photo view
 */
@property (nonatomic,readonly)GJCFAssetsPickerCommonStyleDescription *sysPreviewBottomToolBarDes;

/*
 * System preview photo changes the style of the button in the photo state
 */
@property (nonatomic,readonly)GJCFAssetsPickerCommonStyleDescription *sysPreviewChangeSelectStateBtnDes;

/*
 * System Photos Select the bottom toolbar style
 */
@property (nonatomic,readonly)GJCFAssetsPickerCommonStyleDescription *sysPhotoBottomToolBarDes;

/*
 * When you select a list, how many columns you need to show will affect the size of the overlayView
 */
@property (nonatomic,readonly)NSInteger numberOfColums;

/*
 * Whether to open the big view mode, the default open
 */
@property (nonatomic,readonly)BOOL enableBigImageShowAction;

/*
 * Picture Select the interval between two photos
 */
@property (nonatomic,readonly)CGFloat   columSpace;

/*
 * A view that overlays a single photo, used to change the selected and unselected, and the size of a single image must be inherited or GJCFAssetsPickerOverlayView
 */
@property (nonatomic,readonly)Class sysOverlayViewClass;

/**
 * In the big picture details mode can be automatically selected, the default can be automatically selected
 */
@property (nonatomic,readonly)BOOL enableAutoChooseInDetail;

/* System default style */
+ (GJCFAssetsPickerStyle*)defaultStyle;

/* Add a custom style */
+ (void)appendCustomStyle:(GJCFAssetsPickerStyle*)aCustomStyle forKey:(NSString *)customStyleKey;

/* According to the key to get the set style */
+ (GJCFAssetsPickerStyle*)styleByKey:(NSString *)customStyleKey;

/* Delete the set style according to key */
+ (void)removeCustomStyleByKey:(NSString *)customStyleKey;

/* Get all the keys that have been styled */
+ (NSArray *)existCustomStyleKeys;

/* Clear all configured styles */
+ (void)clearAllCustomStyles;

/* Get all the styles you've set */
+ (NSMutableDictionary *)persistStyleDict;

/* Take the system default image */
+ (UIImage *)bundleImage:(NSString*)imageName;

@end
