//
//  GJAlbums.h
//  GJAssetsPickerViewController
//
//  Created by ZYVincent on 14-9-10.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <UIKit/UIKit.h>

/* Album object */
@interface GJCFAlbums : NSObject

/* The actual album data object */
@property (nonatomic,strong)ALAssetsGroup *assetsGroup;

/* The actual photo object in the album GJAsset array, used to enter the album after the first time, do not have to enumerate statistics again */
@property (nonatomic,strong)NSMutableArray *assetsArray;

/* The album used to filter the type */
@property (nonatomic,strong)ALAssetsFilter *filter;

/* Album name */
@property (nonatomic,readonly)NSString  *name;

/* The number of pictures in this album */
@property (nonatomic,readonly)NSInteger totalCount;

/* Thumbnails of albums */
@property (nonatomic,readonly)UIImage *posterImage;

- (id)initWithAssetsGroup:(ALAssetsGroup *)aGroup;

- (BOOL)isEqual:(GJCFAlbums*)aAlbums;

@end
