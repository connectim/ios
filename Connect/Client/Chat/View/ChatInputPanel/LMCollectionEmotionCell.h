//
//  LMCollectionEmotionCell.h
//  Connect
//
//  Created by MoHuilin on 2017/1/10.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GJGCChatInputExpandEmojiPanelMenuBarDataSource.h"

#define EMOJI_IMAGE_SIZE 30

@protocol LMEmotionTipDelegate <NSObject>

- (void)didMoveIn;

- (void)didMoveOut;

@end

@interface LMCollectionEmojiCell : UICollectionViewCell <LMEmotionTipDelegate>

@property(nonatomic) LMEmotionModel *emotionModel;

@property(nonatomic) BOOL isDelete;

- (void)setContent:(LMEmotionModel *)model;

- (CGPoint)tipFloatPoint;

@end


//////////////////////////////////


@interface LMCollectionGifCell : UICollectionViewCell <LMEmotionTipDelegate>

@property(nonatomic) LMEmotionModel *emotionModel;

- (void)setContent:(LMEmotionModel *)model;

@end
