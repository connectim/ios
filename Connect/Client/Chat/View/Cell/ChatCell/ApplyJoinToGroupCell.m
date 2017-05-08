//
//  ApplyJoinToGroupCell.m
//  Connect
//
//  Created by MoHuilin on 2016/12/29.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import "ApplyJoinToGroupCell.h"

@interface ApplyJoinToGroupCell ()

@property(nonatomic, strong) GJCFCoreTextContentView *statusLabel;

@end

@implementation ApplyJoinToGroupCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {

        self.statusLabel = [[GJCFCoreTextContentView alloc] init];
        self.statusLabel.width = AUTO_WIDTH(300);
        self.statusLabel.height = AUTO_HEIGHT(33);
        self.statusLabel.contentBaseWidth = self.statusLabel.width;
        self.statusLabel.contentBaseHeight = self.statusLabel.height;
        self.statusLabel.backgroundColor = [UIColor clearColor];
        [self.bubbleBackImageView addSubview:self.statusLabel];

    }
    return self;
}


- (void)setContentModel:(GJGCChatContentBaseModel *)contentModel {
    if (!contentModel) {
        return;
    }
    [super setContentModel:contentModel];

    //
    [self showStatusLabelWithResult:YES];
}


- (void)tapOnSelf {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatCellDidTapOnGroupReviewed:)]) {
        [self.delegate chatCellDidTapOnGroupReviewed:self];
    }
}

- (void)haveNoteThisMessage {
    self.statusLabel.hidden = YES;
}

- (void)showStatusLabelWithResult:(BOOL)refused {
    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) self.contentModel;
    if (GJCFStringIsNull(chatContentModel.statusMessageString.string)) {
        self.statusLabel.hidden = YES;
    } else {
        self.statusLabel.hidden = NO;
        self.statusLabel.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:chatContentModel.statusMessageString forBaseContentSize:self.statusLabel.contentBaseSize];
        self.statusLabel.contentAttributedString = chatContentModel.statusMessageString;

        if (self.isFromSelf) {
            self.statusLabel.left = ImageIconInnerMargin;
        } else {
            self.statusLabel.left = ImageIconInnerMargin + BubbleLeftRight;
        }
        self.statusLabel.bottom = self.bubbleBackImageView.height - BubbleContentBottomMargin;
    }
}

@end
