//
//  LMPurseTableViewCell.h
//  Connect
//
//  Created by Edwin on 16/7/17.
//  Copyright © 2016年 Connect.  All rights reserved.
//

//#import <UIKit/UIKit.h>
#import "XWTableViewCell.h"
#import "BitcoinInfo.h"

@class LMPurseTableViewCell;

@protocol LMPurseTableViewDelegate <NSObject>

/**
 *  Two-dimensional code click gestures
 */
- (void)LMPurseTableViewCell:(LMPurseTableViewCell *)cell qrcodeImageTap:(UITapGestureRecognizer *)tap;

/**
 *  Tag click gestures
 */
- (void)LMPurseTableViewCell:(LMPurseTableViewCell *)cell listTap:(UITapGestureRecognizer *)tap;

@end

@interface LMPurseTableViewCell : XWTableViewCell
@property(nonatomic, strong) id <LMPurseTableViewDelegate> delegates;

- (void)setBitCoinInfo:(BitcoinInfo *)info;
@end
