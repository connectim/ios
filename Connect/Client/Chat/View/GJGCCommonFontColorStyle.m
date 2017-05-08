//
//  GJGCCommonColorStyle.m
//  Connect
//
//  Created by KivenLin on 14-11-3.
//  Copyright (c) 2014年 ConnectSoft. All rights reserved.
//

@implementation GJGCCommonFontColorStyle

+ (UIFont *)navigationBarTitleViewFont {
    return [UIFont boldSystemFontOfSize:18];
}

+ (UIFont *)detailBigTitleFont {
    return [UIFont systemFontOfSize:16];
}

+ (UIColor *)detailBigTitleColor {
    return GJCFQuickRGBColor(38, 38, 38);
}

+ (UIFont *)listTitleAndDetailTextFont {
    return [UIFont systemFontOfSize:14];
}

+ (UIColor *)listTitleAndDetailTextColor {
    return [GJGCCommonFontColorStyle detailBigTitleColor];
}

+ (UIFont *)baseAndTitleAssociateTextFont {
    return [UIFont systemFontOfSize:12];
}

+ (UIColor *)baseAndTitleAssociateTextColor {
    return GJCFQuickRGBColor(153, 153, 153);
}

+ (UIColor *)mainThemeColor {
    return GJCFQuickRGBColorAlpha(240, 240, 246, 60);
}

+ (UIColor *)audioTimeTextColor {
    return GJCFQuickHexColor(@"0DA835");
}

@end
