//
//  GJAssetsPickerCommonStyleDescription.h
//  GJAssetsPickerViewController
//
//  Created by ZYVincent on 14-9-10.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface GJCFAssetsPickerCommonStyleDescription : NSObject<NSCoding>

/* Whether it is hidden*/
@property (nonatomic,assign)BOOL    hidden;

/* Normal picture */
@property (nonatomic,strong)UIImage *normalStateImage;

/* High light picture */
@property (nonatomic,strong)UIImage *highlightStateImage;

/* Select the image */
@property (nonatomic,strong)UIImage *selectedStateImage;

/* Normal title */
@property (nonatomic,strong)NSString *normalStateTitle;

/* Select the title */
@property (nonatomic,strong)NSString *selectedStateTitle;

/* Normal text color */
@property (nonatomic,strong)UIColor  *normalStateTextColor;

/* High glossy text color */
@property (nonatomic,strong)UIColor  *highlightStateTextColor;

/* Select the text color */
@property (nonatomic,strong)UIColor  *selectedStateTextColor;

/* Background picture */
@property (nonatomic,strong)UIImage  *backgroundImage;

/* background color  */
@property (nonatomic,strong)UIColor  *backgroundColor;

/* font */
@property (nonatomic,strong)UIFont   *font;

/* title */
@property (nonatomic,strong)NSString *title;

/* title color */
@property (nonatomic,strong)UIColor  *titleColor;

/* transparency */
@property (nonatomic,assign)CGFloat   alpha;

/* size */
@property (nonatomic,assign)CGSize    frameSize;

/* Upper left corner position */
@property (nonatomic,assign)CGPoint   originPoint;

@end
