//
//  UITextView+ExtensionRange.h
//  Connect
//
//  Created by MoHuilin on 2017/3/10.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITextView (ExtensionRange)

- (NSRange) selectedRange;
- (void) setSelectedRange:(NSRange) range;

@end
