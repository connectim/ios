//
//  LMCollectionEmojiTip.h
//  Connect
//
//  Created by MoHuilin on 2017/1/11.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMCollectionEmotionCell.h"

@interface LMCollectionEmojiTip : UIView

@property(nonatomic) LMCollectionEmojiCell *cell;

+ (instancetype)sharedTip;

- (void)showTipOnCell:(LMCollectionEmojiCell *)cell;

@end


@interface LMCollectionGifTip : UIView

@property(nonatomic) LMCollectionGifCell *cell;

+ (instancetype)sharedTip;

- (void)showTipOnCell:(LMCollectionGifCell *)cell;

@end
