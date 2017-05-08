//
//  GJAssetsPickerAlbumsCell.h
//  GJAssetsPickerViewController
//
//  Created by ZYVincent on 14-9-10.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GJCFAlbums.h"

/*
 * The custom album Cell must inherit the Cell
 */
@interface GJCFAssetsPickerAlbumsCell : UITableViewCell

/*
 *  Set the height of a line
 */
@property (nonatomic,assign)CGFloat cellHeight;

/*
 *  Customize cell overload This method comes from the definition of content, otherwise it calls the system
 */
- (void)setAlbums:(GJCFAlbums*)aAlbums;

@end
