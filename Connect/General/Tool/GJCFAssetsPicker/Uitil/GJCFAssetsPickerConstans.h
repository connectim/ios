//
//  GJAssetsPickerConstans.h
//  GJAssetsPickerViewController
//
//  Created by ZYVincent on 14-9-8.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "GJCFAssetsPickerStyle.h"
#import "UIButton+GJCFAssetsPickerStyle.h"
#import "UILabel+GJCFAssetsPickerStyle.h"

/* The picture selection reaches the limit number of notifications */
extern NSString * const kGJAssetsPickerPhotoControllerDidReachLimitCountNoti;

/* Image selection view need to exit notification */
extern NSString * const kGJAssetsPickerNeedCancelNoti;

/* Image selection view has completed image selection notification */
extern NSString * const kGJAssetsPickerDidFinishChooseMediaNoti;

/* Image Preview Details View Click event notification */
extern NSString * const kGJAssetsPickerPreviewItemControllerDidTapNoti;

/* Picture preview but no notification that image has been selected */
extern NSString * const kGJAssetsPickerRequirePreviewButNoSelectPhotoTipNoti;

/* Image selection view error occurred */
extern NSString * const kGJAssetsPickerComeAcrossAnErrorNoti;

/* Image Selector Custom Domain for Error */
extern NSString * const kGJAssetsPickerErrorDomain;

/* Image Select the wrong type */
typedef enum {
    
    /* Album access is not authorized */
    GJAssetsPickerErrorTypePhotoLibarayNotAuthorize,
    
    /**
     *  Photo album selected 0 photos
     */
    GJAssetsPickerErrorTypePhotoLibarayChooseZeroCountPhoto,
    
}GJAssetsPickerErrorType;

@interface GJCFAssetsPickerConstans : NSObject

/* Global use of the photo access library */
+ (ALAssetsLibrary *)shareAssetsLibrary;

/* Create a picture based on color */
+ (UIImage *)imageForColor:(UIColor*)aColor withSize:(CGSize)aSize;

/* Whether the current system version is iOS7 */
+ (BOOL)isIOS7;

/* Send a notification */
+ (void)postNoti:(NSString*)noti;

/* Send a notification with an object */
+ (void)postNoti:(NSString*)noti withObject:(NSObject*)obj;

/* Send a notification with object and userInfo */
+ (void)postNoti:(NSString*)noti withObject:(NSObject*)obj withUserInfo:(NSDictionary*)userInfo;


@end
