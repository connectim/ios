//
//  GJGCChatBaseCell.h
//  Connect
//
//  Created by KivenLin on 14-11-3.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GJGCChatContentBaseModel.h"
#import "GJGCChatBaseCellDelegate.h"

#define BOTTOM_CELL_MARGIN (GJCFSystemiPhone5?AUTO_HEIGHT(80):AUTO_HEIGHT(40))

@interface GJGCChatBaseCell : UITableViewCell

@property(nonatomic, weak) id <GJGCChatBaseCellDelegate> delegate;

@property(nonatomic, assign) CGFloat cellMargin;

@property(nonatomic, assign) CGSize contentSize;

- (void)setContentModel:(GJGCChatContentBaseModel *)contentModel;

- (CGFloat)heightForContentModel:(GJGCChatContentBaseModel *)contentModel; //Deprecated

+ (CGFloat)cellHeightForContentModel:(GJGCChatContentBaseModel *)contentModel;

- (void)pause;

- (void)resume;


- (void)willDisplayCell;

- (void)didEndDisplayingCell;

- (void)willBeginScrolling;

- (void)didEndScrolling;

@end
