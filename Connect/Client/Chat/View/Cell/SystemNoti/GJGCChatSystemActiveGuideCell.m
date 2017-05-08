//
//  GJGCChatSystemActiveGuideCell.m
//  Connect
//
//  Created by KivenLin on 14-11-10.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJGCChatSystemActiveGuideCell.h"
#import "GJGCChatSystemNotiModel.h"

@interface GJGCChatSystemActiveGuideCell ()

@property(nonatomic, strong) UIView *line;
@property(nonatomic, strong) UIView *indicatorContentView;
@property(nonatomic, strong) GJCFCoreTextContentView *detailDesc;

@end

@implementation GJGCChatSystemActiveGuideCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {


        self.indicatorContentView = [[UIView alloc] init];
        [self.stateContentView addSubview:self.indicatorContentView];
        self.indicatorContentView.left = 0;
        self.indicatorContentView.gjcf_width = self.stateContentView.gjcf_width;
        self.indicatorContentView.top = self.contentLabel.bottom;
        self.indicatorContentView.height = AUTO_WIDTH(60);

        self.line = [[UIView alloc] init];
        [self.indicatorContentView addSubview:self.line];
        self.line.height = 1;
        self.line.backgroundColor = [UIColor grayColor];
        self.line.alpha = 0.2;
        self.line.left = self.contentInnerMargin;
        self.line.gjcf_width = self.stateContentView.gjcf_width - 2 * self.contentBordMargin;
        self.line.top = 0;

        self.detailDesc = [[GJCFCoreTextContentView alloc] init];
        self.detailDesc.gjcf_top = 0;
        self.detailDesc.gjcf_left = self.contentBordMargin;
        self.detailDesc.contentBaseWidth = self.indicatorContentView.gjcf_width - 2 * self.contentBordMargin;
        self.detailDesc.contentBaseHeight = 30;
        self.detailDesc.backgroundColor = [UIColor clearColor];
        [self.indicatorContentView addSubview:self.detailDesc];

        self.accessoryIndicator = [[UIImageView alloc] init];
        self.accessoryIndicator.gjcf_width = AUTO_WIDTH(18);
        self.accessoryIndicator.gjcf_height = AUTO_WIDTH(28);
        self.accessoryIndicator.image = GJCFQuickImage(@"set_grey_right_arrow");
        self.accessoryIndicator.gjcf_right = self.indicatorContentView.gjcf_width - self.contentInnerMargin;
        self.accessoryIndicator.centerY = self.indicatorContentView.height / 2;
        [self.indicatorContentView addSubview:self.accessoryIndicator];

    }
    return self;
}

- (void)setContentModel:(GJGCChatContentBaseModel *)contentModel {
    if (!contentModel) {
        return;
    }

    [super setContentModel:contentModel];

    GJGCChatSystemNotiModel *notiModel = (GJGCChatSystemNotiModel *) contentModel;

    self.titleLabel.contentAttributedString = notiModel.systemNotiTitle;
    self.titleLabel.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:notiModel.systemNotiTitle forBaseContentSize:self.titleLabel.contentBaseSize];

    self.timeLabel.contentAttributedString = notiModel.timeString;
    self.timeLabel.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:notiModel.timeString forBaseContentSize:self.timeLabel.contentBaseSize];
    self.timeLabel.gjcf_top = self.titleLabel.bottom + self.contentBordMargin;
    self.timeLabel.left = self.contentInnerMargin;

    self.activeImageView.gjcf_top = self.timeLabel.gjcf_bottom + self.contentInnerMargin;
    notiModel.systemActiveImageUrl = notiModel.systemActiveImageUrl;
    if (GJCFStringIsNull(notiModel.systemActiveImageUrl)) {
        self.activeImageView.height = 0;
    } else {
        self.activeImageView.height = self.activeImageView.width * 0.6;
        [self.activeImageView setOriginImageWithAvatarUrl:notiModel.systemActiveImageUrl placeholder:@"image_message_placeholder"];
    }

    self.contentLabel.gjcf_top = self.activeImageView.gjcf_bottom + self.contentInnerMargin;
    self.contentLabel.contentAttributedString = notiModel.systemOperationTip;
    self.contentLabel.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:notiModel.systemOperationTip forBaseContentSize:self.contentLabel.contentBaseSize];

    if (self.contentLabel.height > kMaxContentHeight) {
        self.contentLabel.height = kMaxContentHeight;
    }
    self.indicatorContentView.top = self.contentInnerMargin + self.contentLabel.bottom;


    self.detailDesc.contentAttributedString = notiModel.systemGuideButtonTitle;
    self.detailDesc.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:notiModel.systemGuideButtonTitle forBaseContentSize:self.detailDesc.contentBaseSize];
    self.detailDesc.centerY = self.indicatorContentView.height / 2;

    self.stateContentView.gjcf_height = self.indicatorContentView.gjcf_bottom;

}

- (void)tapCell {
    if ([self.delegate respondsToSelector:@selector(systemNotiBaseCellDidTapOnPublicMessage:)]) {
        [self.delegate systemNotiBaseCellDidTapOnPublicMessage:self];
    }
}

+ (CGFloat)cellHeightForContentModel:(GJGCChatContentBaseModel *)contentModel {
    GJGCChatSystemNotiModel *notiModel = (GJGCChatSystemNotiModel *) contentModel;

    CGSize titleSize = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:notiModel.systemNotiTitle forBaseContentSize:CGSizeMake(AUTO_WIDTH(500), AUTO_WIDTH(30))];

    CGSize timeSize = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:notiModel.timeString forBaseContentSize:CGSizeMake(AUTO_WIDTH(500), AUTO_WIDTH(30))];

    CGFloat imageHeight = 0;
    if (!GJCFStringIsNull(notiModel.systemActiveImageUrl)) {
        imageHeight = 0.6 * (GJCFSystemScreenWidth - 2 * 13);
    }


    CGSize contentSize = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:notiModel.systemOperationTip forBaseContentSize:CGSizeMake(AUTO_WIDTH(500), AUTO_WIDTH(30))];

    if (contentSize.height > kMaxContentHeight) {
        contentSize.height = kMaxContentHeight;
    }


    CGSize detailSize = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:notiModel.systemGuideButtonTitle forBaseContentSize:CGSizeMake(AUTO_WIDTH(500), AUTO_WIDTH(30))];

    return titleSize.height + 13 + timeSize.height + 13 + imageHeight + 13 + contentSize.height + 13 + detailSize.height + 13 + BOTTOM_CELL_MARGIN * 2;
}

@end
