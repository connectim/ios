//
//  NSObject+Swing.h
//  Connect
//
//  Created by MoHuilin on 2017/6/1.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Swing)

+ (BOOL)gl_swizzleMethod:(SEL)origSel withMethod:(SEL)altSel;
+ (BOOL)gl_swizzleClassMethod:(SEL)origSel withMethod:(SEL)altSel;

@end
