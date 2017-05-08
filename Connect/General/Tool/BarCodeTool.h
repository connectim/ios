//
//  BarCodeTool.h
//  HashNest
//
//  Created by MoHuilin on 16/5/5.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BarCodeTool : NSObject

+ (UIImage *)barCodeImageWithString:(NSString *)string withSize:(CGFloat)size;
+ (UIImage*)imageBlackToTransparent:(UIImage*)image withRed:(CGFloat)red andGreen:(CGFloat)green andBlue:(CGFloat)blue;
@end
