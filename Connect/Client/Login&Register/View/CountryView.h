//
//  CountryView.h
//  BitmainLoginLib
//
//  Created by MoHuilin on 16/3/29.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, CountryTableViewStytle) {
    CountryTableViewStytleDefault,
    CountryTableViewStytleInterleave,
};

@interface CountryView : UIView

@property(nonatomic) CountryTableViewStytle tableViewStyle;

/**
 *  set up
 *
 *  @param block select Block，countryInfo dictioary：
    Internal has done a multi-language processing, English country no pinyin, non-English non-Chinese did not do
    "countryName": "安道尔",
    "countryPinyin": "an dao er",
    "phoneCode": "376",
    "countryCode": "AD"
 *
 *  @return
 */
- (instancetype)initCountryViewWithBlock:(void (^)(id countryInfo))block showDissBtn:(BOOL)showDissBtn;

/**
 *  Displays the view of the selected country
 */
- (void)show;
@end
