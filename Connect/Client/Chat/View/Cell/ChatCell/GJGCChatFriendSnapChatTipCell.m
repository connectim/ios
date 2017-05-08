//
//  GJGCChatFriendSnapChatTipCell.m
//  Connect
//
//  Created by MoHuilin on 16/7/11.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "GJGCChatFriendSnapChatTipCell.h"

@interface GJGCChatFriendSnapChatTipCell ()

@property(nonatomic, strong) GJCFCoreTextContentView *snapChatMessageLabel;

@property(nonatomic, strong) UIView *subContentView;

@end

@implementation GJGCChatFriendSnapChatTipCell


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {

        self.subContentView = [[UIView alloc] init];
        self.subContentView.backgroundColor = LMBasicBackGroudDarkGray;
        self.subContentView.layer.cornerRadius = 3;
        self.subContentView.layer.masksToBounds = YES;
        [self.contentView addSubview:self.subContentView];
        self.subContentView.gjcf_width = AUTO_WIDTH(500);
        self.subContentView.gjcf_height = AUTO_HEIGHT(500);
        self.subContentView.gjcf_centerX = GJCFSystemScreenWidth / 2;

        self.selectionStyle = UITableViewCellSelectionStyleNone;

        self.snapChatMessageLabel = [[GJCFCoreTextContentView alloc] init];
        self.snapChatMessageLabel.gjcf_width = self.subContentView.gjcf_width;
        self.snapChatMessageLabel.gjcf_height = self.subContentView.gjcf_height;
        self.snapChatMessageLabel.contentBaseWidth = self.subContentView.gjcf_width;
        self.snapChatMessageLabel.contentBaseHeight = self.snapChatMessageLabel.gjcf_height;
        self.snapChatMessageLabel.backgroundColor = [UIColor clearColor];

        [self.subContentView addSubview:self.snapChatMessageLabel];
    }

    return self;
}

- (void)setContentModel:(GJGCChatContentBaseModel *)contentModel {
    if (!contentModel || !contentModel.snapChatTipString) {
        return;
    }

    CGSize size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:contentModel.snapChatTipString forBaseContentSize:self.snapChatMessageLabel.contentBaseSize];
    self.snapChatMessageLabel.size = size;
    self.subContentView.gjcf_width = size.width + self.cellMargin * 2;
    self.subContentView.gjcf_centerX = GJCFSystemScreenWidth / 2;
    self.subContentView.height = size.height + self.cellMargin / 2;

    self.snapChatMessageLabel.centerX = self.subContentView.width / 2;
    self.snapChatMessageLabel.centerY = self.subContentView.height / 2;
    self.snapChatMessageLabel.contentAttributedString = contentModel.snapChatTipString;
}

- (CGFloat)heightForContentModel:(GJGCChatContentBaseModel *)contentModel {
    return self.subContentView.gjcf_bottom + self.cellMargin;
}

+ (CGFloat)cellHeightForContentModel:(GJGCChatContentBaseModel *)contentModel {

    CGSize contentSize = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:contentModel.snapChatTipString forBaseContentSize:CGSizeMake(AUTO_WIDTH(500), AUTO_WIDTH(500))];
    return contentSize.height + BOTTOM_CELL_MARGIN / 2 + BOTTOM_CELL_MARGIN;
}

@end
