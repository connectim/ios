//
//  GJAsset.h
//  GJAssetsPickerViewController
//
//  Created by ZYVincent on 14-9-8.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <UIKit/UIKit.h>


@interface GJCFAsset : NSObject

@property (nonatomic,strong)ALAsset *containtAsset;

@property (nonatomic,assign)BOOL    selected;

@property (nonatomic,readonly)UIImage *aspectRatioThumbnail;

@property (nonatomic,readonly)UIImage *thumbnail;

@property (nonatomic,readonly)CGSize   imageSize;

@property (nonatomic,readonly)UIImage *fullResolutionImage;

@property (nonatomic,readonly)UIImage *fullScreenImage;

@property (nonatomic,readonly)NSString *fileName;

@property (nonatomic,readonly)CGFloat scale;

@property (nonatomic,readonly)long long size;

@property (nonatomic,readonly)ALAssetOrientation orientation;

@property (nonatomic,readonly)NSDictionary *metaData;

@property (nonatomic,readonly)BOOL isHaveBeenEdit;

@property (nonatomic,readonly)UIImage *editImage;

@property (nonatomic,readonly)NSURL *url;

@property (nonatomic,readonly)NSString *uniqueIdentifier;


- (id)initWithAsset:(ALAsset*)asset;

- (BOOL)isEqual:(GJCFAsset*)asset;


@end
