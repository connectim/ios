//
//  GJAssetsPickerConstans.m
//  GJAssetsPickerViewController
//
//  Created by ZYVincent on 14-9-8.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import "GJCFAssetsPickerConstans.h"

NSString * const kGJAssetsPickerPhotoControllerDidReachLimitCountNoti = @"kGJAssetsPickerPhotoControllerDidReachLimitCountNoti";

NSString * const kGJAssetsPickerNeedCancelNoti = @"kGJAssetsPickerNeedCancelNoti";

NSString * const kGJAssetsPickerDidFinishChooseMediaNoti = @"kGJAssetsPickerDidFinishChooseMediaNoti";

NSString * const kGJAssetsPickerPreviewItemControllerDidTapNoti = @"kGJAssetsPickerPreviewItemControllerDidTapNoti";

NSString * const kGJAssetsPickerRequirePreviewButNoSelectPhotoTipNoti = @"kGJAssetsPickerRequirePreviewButNoSelectPhotoTipNoti";

NSString * const kGJAssetsPickerComeAcrossAnErrorNoti = @"kGJAssetsPickerComeAcrossAnErrorNoti";

NSString * const kGJAssetsPickerErrorDomain = @"GJAssetsPicker.domain.error";

@implementation GJCFAssetsPickerConstans

/*
   * Create a singleton photo access library that is used to ensure that the use of this Libarary enumeration in the ALAsset access is always valid
   * This will not take up a lot of memory, ALAssetsLibrary will create two more objects
   * One is ALAssetPrivate: 48 bytes, one is ALAssetPrivateLibrary: 48 bytes
   * ALAssetsLibrary: 16 bytes
   * So this single case exists and will not affect App performance
 */
+ (ALAssetsLibrary *)shareAssetsLibrary
{
    static ALAssetsLibrary *GJStaticAssetsLibrary = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        GJStaticAssetsLibrary = [[ALAssetsLibrary alloc]init];
        
    });
    return GJStaticAssetsLibrary;
}

+ (BOOL)isIOS7
{
    return [[[UIDevice currentDevice]systemVersion] floatValue] >= 7.0;
}

+ (UIImage*)imageForColor:(UIColor *)aColor withSize:(CGSize)aSize
{
    CGRect rect = CGRectMake(0, 0, aSize.width, aSize.height);
    
    UIGraphicsBeginImageContext(rect.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, aColor.CGColor);
    
    CGContextFillRect(context, rect);
    
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

+ (void)postNoti:(NSString *)noti
{
    [GJCFAssetsPickerConstans postNoti:noti withObject:nil];
}

+ (void)postNoti:(NSString *)noti withObject:(NSObject *)obj
{
    [GJCFAssetsPickerConstans postNoti:noti withObject:obj withUserInfo:nil];
}

+ (void)postNoti:(NSString *)noti withObject:(NSObject *)obj withUserInfo:(NSDictionary *)userInfo
{
    [[NSNotificationCenter defaultCenter]postNotificationName:noti object:obj userInfo:userInfo];
}

@end
