//
//  GJGCChatFriendTimeCell.m
//  Connect
//
//  Created by KivenLin on 14-12-26.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJGCChatFriendTimeCell.h"

@interface GJGCChatFriendTimeCell ()

@property(nonatomic, strong) GJCFCoreTextContentView *timeLabel;

@property(nonatomic, strong) UIView *myContentView;

@end

@implementation GJGCChatFriendTimeCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {


        self.myContentView = [[UIView alloc] init];
        self.myContentView.backgroundColor = LMBasicBackGroudDarkGray;
        self.myContentView.layer.cornerRadius = 3;
        self.myContentView.layer.masksToBounds = YES;
        self.myContentView.top = 5;
        self.myContentView.width = AUTO_WIDTH(255);
        self.myContentView.gjcf_top = 0;
        self.myContentView.gjcf_height = AUTO_HEIGHT(40);
        self.myContentView.gjcf_centerX = GJCFSystemScreenWidth / 2;


        [self.contentView addSubview:self.myContentView];


        self.cellMargin = 7.f;
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        self.timeLabel = [[GJCFCoreTextContentView alloc] init];
        self.timeLabel.gjcf_centerX = GJCFSystemScreenWidth / 2;
        self.timeLabel.gjcf_width = GJCFSystemScreenWidth;
        self.timeLabel.gjcf_height = AUTO_HEIGHT(40);
        self.timeLabel.contentBaseWidth = self.timeLabel.gjcf_width;
        self.timeLabel.contentBaseHeight = self.timeLabel.gjcf_height;

        [self.contentView addSubview:self.timeLabel];

    }

    return self;
}

- (void)setContentModel:(GJGCChatContentBaseModel *)contentModel {
    if (!contentModel || !contentModel.timeString) {
        return;
    }

    self.timeLabel.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:contentModel.timeString forBaseContentSize:self.timeLabel.contentBaseSize];

    self.timeLabel.contentAttributedString = contentModel.timeString;

    if (self.timeLabel.width > self.myContentView.width) {
        self.myContentView.width = self.timeLabel.width + self.cellMargin * 2;
        self.myContentView.gjcf_centerX = GJCFSystemScreenWidth / 2;
    }

    self.timeLabel.gjcf_centerX = GJCFSystemScreenWidth / 2;
    self.timeLabel.centerY = self.myContentView.centerY;

}

- (CGFloat)heightForContentModel:(GJGCChatContentBaseModel *)contentModel {
    return self.timeLabel.gjcf_bottom + self.cellMargin;
}

+ (CGFloat)cellHeightForContentModel:(GJGCChatContentBaseModel *)contentModel {
    return AUTO_HEIGHT(40) + BOTTOM_CELL_MARGIN;
}

@end
