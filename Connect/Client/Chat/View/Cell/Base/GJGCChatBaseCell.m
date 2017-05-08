//
//  GJGCChatBaseCell.m
//  Connect
//
//  Created by KivenLin on 14-11-3.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJGCChatBaseCell.h"

@implementation GJGCChatBaseCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = [UIColor clearColor];
        self.cellMargin = BOTTOM_CELL_MARGIN;
    }
    return self;
}

- (void)dealloc {
    [GJCFNotificationCenter removeObserver:self];
}

- (void)setContentModel:(GJGCChatContentBaseModel *)contentModel {
}

- (CGFloat)heightForContentModel:(GJGCChatContentBaseModel *)contentModel {
    return 0.f;
}

+ (CGFloat)cellHeightForContentModel:(GJGCChatContentBaseModel *)contentModel {
    return 0;
}

- (void)pause {

}

- (void)resume {

}

- (void)willDisplayCell {

}

- (void)didEndDisplayingCell {

}

- (void)willBeginScrolling {

}

- (void)didEndScrolling {

}


@end
