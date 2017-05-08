//
//  TagsView.h
//  Connect
//
//  Created by MoHuilin on 16/5/31.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseView.h"
#import "LMUserDetaiLongPressGestureRecognizer.h"

typedef NS_ENUM(NSInteger ,TagsViewType) {
    TagsViewTypeNone,
    TagsViewTypeEdit,
    TagsViewTypeMutableSelect,
};

@protocol TagsViewDelegate <NSObject>

@optional
- (void)tagsViewSaveNewTag:(NSString *)newTag;

- (void)addTag:(NSString *)tag;

- (void)removeTag:(NSString *)tag;
//移除下边的tag
-(void)removeBottomTag:(NSString*)tag;


@end

@interface TagsView : BaseView

@property (nonatomic ,strong) NSMutableArray *tags;
@property (nonatomic ,strong) NSMutableArray *commomTags;
@property (nonatomic ,weak) id<TagsViewDelegate>delegate;

@property (nonatomic ,assign) TagsViewType type;

/// >刷新
- (void)reloadData;

@end
